# Val CLI

Security & risk intelligence from your terminal. Val is the command-line interface for the [Valoryck](https://valoryck.com) GRC platform.

## Install

### Homebrew (macOS/Linux)

```bash
brew install valoryck/tap/val
```

### Scoop (Windows)

```powershell
scoop bucket add valoryck https://github.com/valoryck/scoop-valoryck.git
scoop install val
```

### Shell script

```bash
# macOS/Linux
curl -fsSL https://raw.githubusercontent.com/valoryck/val/main/install.sh | sh

# Windows (PowerShell)
irm https://raw.githubusercontent.com/valoryck/val/main/install.ps1 | iex
```

### Manual download

Download the latest release from the [Releases page](https://github.com/valoryck/val/releases).

## Quick start

```bash
# Authenticate
val login

# Ask Val anything
val -p "what are our open high-severity risks?"

# Interactive conversation
val chat

# Query GRC data
val risks list --format json
val issues list

# Pipe code for security review
git diff | val -p "review for security vulnerabilities"
```

## CI/CD

Set `VAL_API_TOKEN` to skip interactive login:

```bash
export VAL_API_TOKEN="your-session-token"
val -p "assess risk of deploying without pentest" --format json
```

Exit codes: `0` success, `1` error, `2` auth error, `3` tenant required, `4` dataplane unreachable.

## Shell completions

```bash
# bash
eval "$(val completion bash)"

# zsh
eval "$(val completion zsh)"

# fish
val completion fish | source

# powershell
val completion powershell | Out-String | Invoke-Expression
```

## Commands

| Command | Description |
|---------|-------------|
| `val login` | Authenticate via browser |
| `val logout` | Clear stored credentials |
| `val status` | Show auth status and tenant |
| `val tenants` | List available tenants |
| `val chat` | Interactive conversation |
| `val -p "..."` | One-shot query |
| `val risks list` | List risks |
| `val issues list` | List issues |
| `val version` | Print version info |

## License

Proprietary. Copyright 2026 Valoryck AB.
