#!/usr/bin/env bash
# All-in-one installer for the Magento Template Hints Toggle Chrome extension.
#
# Usage:
#   ./install.sh                # clone (if needed) and open chrome://extensions
#   ./install.sh --launch       # launch Chrome with the extension auto-loaded
#   ./install.sh --dir <path>   # install into a custom directory
#   ./install.sh --help
#
# Note: Chrome blocks permanent install of unpacked extensions for security.
# This script either (a) opens chrome://extensions so you can Load unpacked,
# or (b) launches a Chrome instance with --load-extension (extension lives
# only for that session unless you ghim it via Developer mode).

set -euo pipefail

REPO_URL="git@github.com:chuccv/chrome-templatehints-ext.git"
DEFAULT_DIR="${HOME}/chrome-templatehints-ext"
TARGET_DIR="${DEFAULT_DIR}"
MODE="open"   # open | launch

log()  { printf "\033[1;34m[*]\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m[✓]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[!]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[x]\033[0m %s\n" "$*" >&2; }

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --launch) MODE="launch"; shift ;;
    --dir)    TARGET_DIR="${2:?--dir requires a path}"; shift 2 ;;
    -h|--help) usage ;;
    *) err "Unknown arg: $1"; exit 1 ;;
  esac
done

# --- 1. Ensure source is on disk -------------------------------------------
if [[ -d "${TARGET_DIR}/.git" ]]; then
  log "Repo already at ${TARGET_DIR}, pulling latest"
  git -C "${TARGET_DIR}" pull --ff-only || warn "Pull skipped (offline or diverged)"
elif [[ -f "${TARGET_DIR}/manifest.json" ]]; then
  log "Found manifest at ${TARGET_DIR} (not a git clone) — using as-is"
else
  command -v git >/dev/null || { err "git is not installed"; exit 1; }
  log "Cloning ${REPO_URL} -> ${TARGET_DIR}"
  git clone "${REPO_URL}" "${TARGET_DIR}"
fi
ok "Source ready at ${TARGET_DIR}"

# --- 2. Sanity-check the extension files -----------------------------------
for f in manifest.json background.js icon128.png; do
  [[ -f "${TARGET_DIR}/${f}" ]] || { err "Missing ${f}"; exit 1; }
done
ok "Extension files OK"

# --- 3. Find a Chrome / Chromium binary ------------------------------------
CHROME_BIN=""
for cand in google-chrome google-chrome-stable chromium chromium-browser brave-browser microsoft-edge; do
  if command -v "$cand" >/dev/null 2>&1; then
    CHROME_BIN="$(command -v "$cand")"
    break
  fi
done

if [[ -z "${CHROME_BIN}" ]]; then
  warn "No Chrome/Chromium binary found in PATH."
  warn "Install via apt:   sudo apt install google-chrome-stable"
  warn "Or load manually:  open chrome://extensions, enable Developer mode,"
  warn "                   click 'Load unpacked', pick ${TARGET_DIR}"
  exit 0
fi
ok "Browser: ${CHROME_BIN}"

# --- 4. Launch ---------------------------------------------------------------
if [[ "${MODE}" == "launch" ]]; then
  log "Launching Chrome with --load-extension=${TARGET_DIR}"
  warn "Chrome may show a warning bar about unpacked extensions — keep it enabled."
  nohup "${CHROME_BIN}" \
    --load-extension="${TARGET_DIR}" \
    "chrome://extensions" \
    >/dev/null 2>&1 &
  ok "Chrome launched (PID $!)"
else
  log "Opening chrome://extensions — then click 'Load unpacked' and pick:"
  printf "      \033[1m%s\033[0m\n" "${TARGET_DIR}"
  nohup "${CHROME_BIN}" "chrome://extensions" >/dev/null 2>&1 &
fi

ok "Done."
