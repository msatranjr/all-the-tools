#!/usr/bin/env bash
set -euo pipefail

main() {
# Notes CLI bootstrap. No notebook data or shell startup files are modified.
has() { command -v "$1" >/dev/null 2>&1; }
node_ok() { has node && has npm && node -e 'if(Number(process.versions.node.split(".")[0])<22)process.exit(1)'; }
as_root() { if [[ "$EUID" == 0 ]]; then "$@"; else sudo "$@"; fi; }
missing=()
for tool in git gh curl tar; do has "$tool" || missing+=("$tool"); done
node_ok || missing+=(nodejs)
if (( ${#missing[@]} )); then
  printf 'Installing prerequisites: %s\n' "${missing[*]}"
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      has winget.exe || { echo 'Install Microsoft App Installer (winget), then rerun.' >&2; exit 1; }
      for tool in "${missing[@]}"; do
        case "$tool" in
          nodejs) package=OpenJS.NodeJS.LTS;;
          git) package=Git.Git;;
          gh) package=GitHub.cli;;
          *) echo 'Update Git Bash to provide curl and tar.' >&2; exit 1;;
        esac
        winget.exe install --id "$package" --exact --source winget < /dev/tty
      done
      for folder in '/c/Program Files/nodejs' '/c/Program Files/GitHub CLI' '/c/Program Files/Git/cmd'; do
        [[ ! -d "$folder" ]] || export PATH="$folder:$PATH"
      done
      ;;
    Darwin)
      if ! has brew; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/tty
        if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"; else eval "$(/usr/local/bin/brew shellenv)"; fi
      fi
      for tool in "${missing[@]}"; do
        if [[ "$tool" == nodejs ]]; then
          if brew list --versions node >/dev/null 2>&1; then brew upgrade node; else brew install node; fi
        else brew install "$tool"; fi
      done
      ;;
    Linux)
      if has apt-get; then
        as_root apt-get update
        as_root apt-get install -y ca-certificates curl tar "${missing[@]}"
        has npm || as_root apt-get install -y npm
      elif has dnf; then
        as_root dnf install -y ca-certificates curl tar "${missing[@]}"
        has npm || as_root dnf install -y npm
      else
        echo 'Automatic Linux installation requires apt or dnf.' >&2; exit 1
      fi
      if ! node_ok; then
        case "$(uname -m)" in x86_64) arch=x64;; aarch64|arm64) arch=arm64;; *) echo 'Unsupported Node architecture' >&2; exit 1;; esac
        runtime_root="${XDG_DATA_HOME:-$HOME/.local/share}/all-the-tools/runtime"
        mkdir -p "$runtime_root"
        runtime_tmp=$(mktemp -d "$runtime_root/.download.XXXXXXXX")
        trap 'rm -rf -- "$runtime_tmp"' EXIT
        curl -fsSL https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt -o "$runtime_tmp/sums"
        filename=$(awk -v arch="$arch" '$2 ~ ("^node-v22[.][0-9.]+-linux-" arch "[.]tar[.]gz$") {print $2}' "$runtime_tmp/sums")
        [[ -n "$filename" && "$filename" != *$'\n'* ]] || { echo 'Could not identify Node runtime.' >&2; exit 1; }
        curl -fsSL "https://nodejs.org/dist/latest-v22.x/$filename" -o "$runtime_tmp/$filename"
        (cd "$runtime_tmp"; grep "  $filename$" sums | sha256sum -c -)
        runtime_dir="$runtime_root/$(date +%s)-$$"
        mkdir "$runtime_dir"
        tar -xzf "$runtime_tmp/$filename" --strip-components=1 -C "$runtime_dir"
        export PATH="$runtime_dir/bin:$PATH"
        rm -rf -- "$runtime_tmp"; trap - EXIT
      fi
      ;;
    *) echo 'Unsupported operating system.' >&2; exit 1;;
  esac
fi
hash -r
for tool in node npm git gh curl tar; do has "$tool" || { echo "$tool is unavailable. Restart your terminal and rerun." >&2; exit 1; }; done
node_ok || { echo 'Node.js 22+ is unavailable. Restart your terminal and rerun.' >&2; exit 1; }
if ! gh auth status --hostname github.com >/dev/null 2>&1; then
  gh auth login --hostname github.com --git-protocol https --web < /dev/tty
fi


inventory_dir=$(mktemp -d)
trap 'rm -rf -- "$inventory_dir"' EXIT
echo 'Loading your private tool inventory…'
gh api repos/msatranjr/all-the-tools-inventory/tarball/main > "$inventory_dir/inventory.tar.gz"
tar -xzf "$inventory_dir/inventory.tar.gz" --strip-components=1 -C "$inventory_dir"
bash "$inventory_dir/install.sh" "$@"
}
main "$@"
