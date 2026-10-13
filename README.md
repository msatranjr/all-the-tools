# all-the-tools

Public bootstrap; private tool inventory.

```bash
curl -fsSL https://raw.githubusercontent.com/msatranjr/all-the-tools/main/install.sh | bash
```

The bootstrap installs missing Node.js 22+, Git and GitHub CLI, signs you into GitHub, then loads your private inventory and displays a tool selector. Prerequisite definitions, tool names and install configuration live in the private all-the-tools-inventory repository, not here.

To skip the selector, pass a tool ID:

```bash
curl -fsSL https://raw.githubusercontent.com/msatranjr/all-the-tools/main/install.sh | bash -s -- notes
```

Use --list to list your inventory after authentication. Requires Bash, curl and an interactive terminal for authentication/admin prompts. Supported: Git Bash on Windows with winget, macOS with Homebrew (installed if absent), Linux with apt/dnf. Package installation may prompt for administrator access. No notebook data or credentials are published, and shell startup files are unchanged.
