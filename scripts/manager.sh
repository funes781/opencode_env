#!/usr/bin/env bash

SKILLS_CONFIG=".opencode/skills-config.json"
SKILLS_DIR=".opencode/skills"
WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

load_skills() {
  if ! command -v jq &>/dev/null; then
    echo -e "${RED}Error: jq is required. Install it with: apt install jq${NC}"
    exit 1
  fi
  if ! command -v curl &>/dev/null; then
    echo -e "${RED}Error: curl is required. Install it with: apt install curl${NC}"
    exit 1
  fi
  if [ ! -f "$SKILLS_CONFIG" ]; then
    echo -e "${RED}Error: $SKILLS_CONFIG not found${NC}"
    exit 1
  fi
  SKILL_COUNT=$(jq '.skills | length' "$SKILLS_CONFIG")
  if [ "$SKILL_COUNT" -eq 0 ]; then
    echo -e "${RED}No skills defined in $SKILLS_CONFIG${NC}"
    exit 1
  fi
}

get_skill_name() { jq -r ".skills[$1].name" "$SKILLS_CONFIG"; }
get_skill_label() { jq -r ".skills[$1].label" "$SKILLS_CONFIG"; }
get_skill_desc() { jq -r ".skills[$1].description // empty" "$SKILLS_CONFIG"; }
get_skill_github() { jq -r ".skills[$1].github_url" "$SKILLS_CONFIG"; }
get_skill_script() { jq -r ".skills[$1].script_url" "$SKILLS_CONFIG"; }
get_skill_refs() { jq -r ".skills[$1].references_source" "$SKILLS_CONFIG"; }

draw_menu() {
  local selected=$1
  shift
  local current_checked=("$@")
  local i name label desc
  local menu=""

  local term_width=$(tput cols 2>/dev/null || echo 80)
  local desc_width=$((term_width - 5))
  [ "$desc_width" -lt 20 ] && desc_width=20

  menu+="\033[H\033[J"
  menu+="${BOLD}${CYAN}╔════════════════════════════════════════════════╗${NC}\n"
  menu+="${BOLD}${CYAN}║        OpenCode Skill Manager                  ║${NC}\n"
  menu+="${BOLD}${CYAN}╚════════════════════════════════════════════════╝${NC}\n"
  menu+="\n"
  menu+="  ${YELLOW}Select skills to install (↑/↓ navigate, Space toggle, Enter confirm):${NC}\n"
  menu+="\n"

  for i in $(seq 0 $((SKILL_COUNT - 1))); do
    name=$(get_skill_name "$i")
    label=$(get_skill_label "$i")
    desc=$(get_skill_desc "$i")

    if [ "$i" -eq "$selected" ]; then
      menu+="  \033[36m▸\033[0m "
    else
      menu+="    "
    fi

    if [ "${current_checked[$i]}" = "1" ]; then
      menu+="\033[32m[x]\033[0m \033[1m${label}\033[0m\n"
    else
      menu+="\033[33m\033[1m[ ]\033[0m \033[1m${label}\033[0m\n"
    fi

    if [ -n "$desc" ]; then
      while IFS= read -r line; do
        menu+="     \033[90m${line}\033[0m\n"
      done <<< "$(printf '%s' "$desc" | fold -s -w "$desc_width")"
    fi
  done

  menu+="\033[J"
  menu+="  ${BOLD}Keys:${NC} ${CYAN}↑/↓${NC} navigate | ${GREEN}Space${NC} toggle | ${YELLOW}Enter${NC} install | ${RED}q${NC} quit\n"

  printf "%b" "$menu"
}

read_key() {
  local key
  if ! read -rsN1 key </dev/tty 2>/dev/null; then
    return 1
  fi
  if [ "$key" = $'\x1b' ]; then
    local seq
    if read -rsN1 -t 0.05 seq </dev/tty 2>/dev/null; then
      if [ "$seq" = "[" ] || [ "$seq" = "O" ]; then
        local rest
        read -rsN1 -t 0.05 rest </dev/tty 2>/dev/null || true
        case "$seq$rest" in
          '[A'|'OA') echo "UP" ;;
          '[B'|'OB') echo "DOWN" ;;
          '[C'|'OC') echo "RIGHT" ;;
          '[D'|'OD') echo "LEFT" ;;
          *) ;;
        esac
      fi
    fi
  elif [ "$key" = " " ]; then
    echo "SPACE"
  elif [ "$key" = $'\n' ] || [ "$key" = $'\r' ]; then
    echo "ENTER"
  elif [ "$key" = "q" ] || [ "$key" = "Q" ]; then
    echo "QUIT"
  fi
}

install_skill() {
  local idx=$1

  local name label github_url script_url refs_source
  name=$(get_skill_name "$idx")
  label=$(get_skill_label "$idx")
  github_url=$(get_skill_github "$idx")
  script_url=$(get_skill_script "$idx")
  refs_source=$(get_skill_refs "$idx")

  local target_dir="$SKILLS_DIR/$name"
  local target_refs="$target_dir/references"

  echo -e "${YELLOW}Installing: $label${NC}"

  mkdir -p "$target_refs"

  if [ -n "$github_url" ] && [ "$github_url" != "null" ]; then
    echo -e "  ${CYAN}→${NC} Downloading SKILL.md..."
    if curl -fsSL "$github_url" -o "$target_dir/SKILL.md" 2>/dev/null; then
      echo -e "  ${GREEN}✓${NC} SKILL.md downloaded"
    else
      echo -e "  ${RED}✗${NC} Failed to download SKILL.md (URL may not exist yet)"
      cat > "$target_dir/SKILL.md" <<-MDEOF
---
name: $name
description: "$label"
---

# $label

Skill description coming soon.
MDEOF
      echo -e "  ${YELLOW}→${NC} Created placeholder SKILL.md"
    fi
  fi

  if [ -n "$script_url" ] && [ "$script_url" != "null" ]; then
    echo -e "  ${CYAN}→${NC} Downloading script..."
    if curl -fsSL "$script_url" -o "$target_dir/script.sh" 2>/dev/null; then
      chmod +x "$target_dir/script.sh"
      echo -e "  ${GREEN}✓${NC} Script downloaded"
    else
      echo -e "  ${RED}✗${NC} Failed to download script (URL may not exist yet)"
    fi
  fi

  if [ -n "$refs_source" ] && [ "$refs_source" != "null" ] && [ "$refs_source" != "$target_refs" ]; then
    if [[ "$refs_source" =~ ^https://github\.com/([^/]+)/([^/]+)/tree/([^/]+)/(.+) ]]; then
      echo -e "  ${CYAN}→${NC} Downloading references from GitHub..."
      local gh_owner="${BASH_REMATCH[1]}"
      local gh_repo="${BASH_REMATCH[2]}"
      local gh_branch="${BASH_REMATCH[3]}"
      local gh_path="${BASH_REMATCH[4]}"
      local tmp_refs
      tmp_refs=$(mktemp -d)
      if curl -fsSL "https://github.com/$gh_owner/$gh_repo/archive/$gh_branch.tar.gz" -o "$tmp_refs/repo.tar.gz" 2>/dev/null; then
        tar xzf "$tmp_refs/repo.tar.gz" -C "$tmp_refs" 2>/dev/null
        local extracted
        for d in "$tmp_refs"/*/; do extracted="$d"; break; done
        if [ -n "$extracted" ] && [ -d "${extracted}${gh_path}" ]; then
          cp -r "${extracted}${gh_path}"/* "$target_refs/" 2>/dev/null
          echo -e "  ${GREEN}✓${NC} References downloaded"
        else
          echo -e "  ${YELLOW}→${NC} References path not found in archive"
        fi
      else
        echo -e "  ${RED}✗${NC} Failed to download repository archive"
      fi
      rm -rf "$tmp_refs"
    elif [[ "$refs_source" =~ ^https?:// ]]; then
      echo -e "  ${CYAN}→${NC} Downloading references..."
      local tmp_refs
      tmp_refs=$(mktemp -d)
      if curl -fsSL "$refs_source" -o "$tmp_refs/references.tar.gz" 2>/dev/null; then
        tar xzf "$tmp_refs/references.tar.gz" -C "$target_refs" 2>/dev/null && \
          echo -e "  ${GREEN}✓${NC} References downloaded" || \
          echo -e "  ${YELLOW}→${NC} Downloaded file is not a tar archive"
      else
        echo -e "  ${RED}✗${NC} Failed to download references"
      fi
      rm -rf "$tmp_refs"
    elif [ -d "$refs_source" ]; then
      echo -e "  ${CYAN}→${NC} Copying references..."
      cp -r "$refs_source"/* "$target_refs/" 2>/dev/null && \
        echo -e "  ${GREEN}✓${NC} References copied" || \
        echo -e "  ${YELLOW}→${NC} No reference files to copy"
    else
      echo -e "  ${YELLOW}→${NC} References source '$refs_source' not found, skipping"
    fi
  fi

  echo -e "  ${GREEN}✓${NC} Skill installed at ${BOLD}$target_dir${NC}"
  echo ""
}

is_skill_installed() {
  [ -d "$SKILLS_DIR/$(get_skill_name "$1")" ]
}

interactive_menu() {
  local current=0
  checked=()
  for i in $(seq 0 $((SKILL_COUNT - 1))); do
    if is_skill_installed "$i"; then
      checked+=("1")
    else
      checked+=("0")
    fi
  done

  if [ -t 0 ]; then
    old_stty=$(stty -g 2>/dev/null || true)
  fi
  trap 'stty echo 2>/dev/null; tput cnorm 2>/dev/null; tput rmcup 2>/dev/null; exit' INT TERM
  tput civis 2>/dev/null
  tput smcup 2>/dev/null

  while true; do
    draw_menu "$current" "${checked[@]}"

    action=$(read_key)

    case "$action" in
      UP)
        ((current = current > 0 ? current - 1 : SKILL_COUNT - 1))
        ;;
      DOWN)
        ((current = current < SKILL_COUNT - 1 ? current + 1 : 0))
        ;;
      SPACE)
        if [ "${checked[$current]}" = "1" ]; then
          checked[$current]="0"
        else
          checked[$current]="1"
        fi
        ;;
      ENTER)
        break
        ;;
      QUIT)
        tput rmcup 2>/dev/null
        tput cnorm 2>/dev/null
        echo -e "\n${YELLOW}Cancelled.${NC}"
        stty echo 2>/dev/null || true
        exit 0
        ;;
    esac
  done

  stty echo 2>/dev/null || true
  tput rmcup 2>/dev/null
  tput cnorm 2>/dev/null
  trap - INT TERM

  printf '\033[H\033[J'
  echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║        Installing Selected Skills              ║${NC}"
  echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════╝${NC}"
  echo ""

  local installed=0
  local removed=0
  for i in $(seq 0 $((SKILL_COUNT - 1))); do
    if [ "${checked[$i]}" = "1" ]; then
      if ! is_skill_installed "$i"; then
        install_skill "$i"
        ((installed++))
      else
        echo -e "  ${YELLOW}→${NC} $(get_skill_label "$i") already installed, skipping"
      fi
    else
      if is_skill_installed "$i"; then
        echo -e "  ${YELLOW}→${NC} Removing $(get_skill_label "$i")..."
        rm -rf "$SKILLS_DIR/$(get_skill_name "$i")"
        echo -e "  ${GREEN}✓${NC} Removed"
        ((removed++))
      fi
    fi
  done

  if [ "$installed" -gt 0 ] || [ "$removed" -gt 0 ]; then
    echo ""
    [ "$installed" -gt 0 ] && echo -e "${GREEN}${BOLD}✓ $installed skill(s) installed${NC}"
    [ "$removed" -gt 0 ] && echo -e "${YELLOW}${BOLD}✓ $removed skill(s) removed${NC}"
    echo -e "  Run: ${CYAN}opencode${NC} to apply changes"
  else
    echo -e "${YELLOW}No changes.${NC}"
  fi
  echo ""
}

main() {
  cd "$WORKSPACE_ROOT"
  load_skills
  interactive_menu
}

main "$@"
