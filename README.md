# claude-split-macos

Run multiple **Claude Desktop** and **Claude Code** accounts side by side on macOS without logging out every time.

`claude-split-macos` is a small shell utility. It does not copy, inspect, or store your passwords or OAuth tokens. Claude handles authentication normally; this tool only gives each profile its own local state directories.

> Unofficial community project. Not affiliated with or endorsed by Anthropic.

## Why

Claude Desktop normally has one application profile, and Claude Code normally uses one config/credential context. If you have personal, work, and client accounts, switching accounts manually is tedious and can leave stale provider or API environment variables behind.

This tool gives you:

- multiple Claude Desktop instances at the same time;
- multiple Claude Code logins at the same time in separate terminals;
- a special `default` profile that leaves your existing Claude installation untouched;
- unlimited extra named profiles (`work`, `personal`, `client-a`, ...);
- isolated CLI configuration + credential slots for named profiles;
- isolated Desktop cookies, local storage, sessions, and app state for named profiles;
- a `doctor` command that warns about environment variables that can override Claude authentication.

## Requirements

- macOS;
- Claude Desktop installed in `/Applications/Claude.app` for Desktop profiles;
- Claude Code installed and available as `claude` for CLI profiles.

Apple Silicon and Intel Macs are supported by the launcher. On Apple Silicon, extra Desktop instances are explicitly launched as native `arm64`.

## Install

Clone the repository and run:

```bash
git clone https://github.com/samrand96/claude-split-macos.git
cd claude-split-macos
./install.sh
```

After the repository is public, you can also use the one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/samrand96/claude-split-macos/main/install.sh | bash
```

If `~/.local/bin` is not on your `PATH`, add:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then:

```bash
clp doctor
```

## Publish your own fork/repository

If you downloaded the source archive rather than cloning it, authenticate GitHub CLI once and publish with:

```bash
brew install gh       # only if gh is not installed
gh auth login         # only if gh is not authenticated
./publish.sh
```

`publish.sh` creates a public repository named `claude-split-macos` under the authenticated GitHub account, initializes Git when needed, and pushes `main`. You can choose another name or visibility:

```bash
./publish.sh my-claude-profiles public
./publish.sh my-private-copy private
```

## Quick start

Your current Claude installation is always available as `default`:

```bash
clp code default
clp desktop default
```

Create a second profile:

```bash
clp add work
```

Bind the CLI profile to the intended account first:

```bash
clp login work
clp auth work
```

`clp auth work` is deliberately part of the workflow: it shows exactly which Claude account that profile will use, so stale `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, local-gateway, Vertex, or proxy variables cannot silently select another authentication path.

Launch Claude Code using that account:

```bash
clp code work
```

Launch a separate Claude Desktop instance:

```bash
clp desktop work
```

The Desktop instance receives the **same `CLAUDE_CONFIG_DIR` and secure credential slot** as `clp code work`, while its Electron cookies/session state live in a separate user-data directory. This keeps the Desktop Code tab aligned with the selected CLI profile instead of falling back to the machine-default Claude Code account. The Desktop chat side still has its own login UI; on first launch, sign that Desktop window into the same account reported by `clp auth work`.

You can keep both open simultaneously:

```text
Terminal 1:  clp code default
Terminal 2:  clp code work
Desktop 1:   clp desktop default
Desktop 2:   clp desktop work
```

## Commands

```text
clp add <profile>                 Create a profile
clp list                          List profiles
clp use <profile>                 Save the active profile
clp current                       Show the active profile
clp auth [profile]                Show the exact Claude Code identity for a profile
clp login [profile]               Log a profile into Claude Code
clp logout [profile]              Log a profile out of Claude Code
clp code [profile] [-- args...]   Launch Claude Code
clp desktop [profile]             Launch Claude Desktop
clp both [profile] [-- args...]   Launch Desktop and Claude Code
clp doctor                        Diagnose the local setup
clp path <profile>                Show profile directories
clp purge <profile>               Permanently delete local profile data
```

Examples:

```bash
clp add personal
clp add work
clp add client-a

clp use work
clp code
clp desktop

clp code personal -- --model opus
clp both client-a
```

## How it works

### Claude Desktop

Each named profile gets a separate Electron user-data directory:

```text
~/Library/Application Support/Claude-Split/<profile>/
```

The launcher asks macOS LaunchServices to start a **new Claude instance** (`open -n`) and injects the profile environment using macOS `open --env`. It sets both `CLAUDE_USER_DATA_DIR` and `--user-data-dir` for Desktop state, plus the same `CLAUDE_CONFIG_DIR` / `CLAUDE_SECURESTORAGE_CONFIG_DIR` used by that profile's CLI. Different local state means different Desktop cookies/login/session data, while the Desktop Code tab inherits the matching Claude Code authentication context.

The special `default` profile simply opens the normal `/Applications/Claude.app` and keeps using:

```text
~/Library/Application Support/Claude/
```

### Claude Code

Each named profile gets:

```text
~/.local/share/claude-split/profiles/<profile>/code/
```

For that process the launcher sets:

```text
CLAUDE_CONFIG_DIR=<profile directory>
CLAUDE_SECURESTORAGE_CONFIG_DIR=<same profile directory>
```

This separates Claude Code configuration and its selected secure credential slot. On macOS, Claude Code keeps OAuth credentials in Keychain rather than placing the secret directly in this repository or script.

`CLAUDE_CONFIG_DIR` selects the profile configuration root. Current macOS Claude Code builds namespace Keychain credentials by the selected config/secure-storage directory. `CLAUDE_SECURESTORAGE_CONFIG_DIR` is still treated as an implementation-level compatibility control and is set to the same directory so CLI and Desktop Code launches resolve the same credential slot.

### Authentication environment variables

Variables such as these can override an interactive Claude login:

```text
ANTHROPIC_API_KEY
ANTHROPIC_AUTH_TOKEN
ANTHROPIC_BASE_URL
CLAUDE_CODE_USE_VERTEX
CLAUDE_CODE_USE_BEDROCK
CLAUDE_CODE_USE_FOUNDRY
GOOGLE_APPLICATION_CREDENTIALS
```

Every `clp code` and `clp desktop` launch intentionally strips these provider/auth overrides so that the selected Claude.ai profile owns authentication. It also strips `HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY` (upper/lowercase) and `NODE_OPTIONS`, because stale development proxy/Node overrides can make Claude CLI behave differently from Desktop. This cleanup affects only the launched Claude process; it does not modify your shell or projects.

Run:

```bash
clp doctor
```

if Claude behaves differently in the terminal than in Desktop.

## Storage

```text
~/.local/share/claude-split/
├── active-profile
├── logs/
└── profiles/
    ├── work/code/
    └── client-a/code/

~/Library/Application Support/Claude-Split/
├── work/
└── client-a/
```

The existing default Claude directories are never moved or rewritten.

## Remove a profile

See its paths first:

```bash
clp path work
```

Permanent deletion is intentionally explicit:

```bash
clp purge work
```

You must type the profile name to confirm. An orphaned profile-specific Claude Code Keychain entry may remain; the utility deliberately does not read or manipulate secret Keychain values.

## Uninstall

```bash
./uninstall.sh
```

This removes only the `clp`/`claude-split` launchers. Profile data is retained so uninstalling cannot accidentally destroy Claude sessions.

## Caveats

- Every Desktop profile is a complete Electron instance, so each uses additional RAM.
- When Claude Desktop updates itself, close all running profile instances first.
- Desktop chat login and Claude Code login are separate layers. Use `clp login <profile>` + `clp auth <profile>` to pin/verify the Code identity, then sign the named Desktop window into the matching account on its first launch.
- Deep-link login callbacks can be ambiguous when several Claude instances are open. If a browser callback focuses the wrong instance, close the other Claude Desktop instances for the first login of that profile, complete login, then reopen them.
- `CLAUDE_SECURESTORAGE_CONFIG_DIR` is not currently documented by Anthropic and could change between Claude Code releases.
- This project targets normal Claude.ai account logins. API-key, Vertex, Bedrock, or Foundry profiles are deliberately not mixed into named account profiles.

## Security model

`claude-split-macos` never reads or exports your Claude OAuth secret. Profile isolation is achieved by choosing different local state/config paths. Authentication itself remains inside Claude and macOS Keychain.

The tool is intentionally small enough to audit before installing.

## License

MIT

## Authentication sanity check

Before opening a work/client profile, verify it explicitly:

```bash
clp auth default
clp auth work
```

They should report different accounts when the profiles are meant to be different. If a named profile is not logged in:

```bash
clp login work
clp auth work
```

If Claude ever reports both `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_API_KEY`, an old `ANTHROPIC_BASE_URL`, Vertex credentials, or `ECONNREFUSED` from a stale local proxy, run:

```bash
clp doctor
```

`clp` removes those overrides only from the Claude process it launches. Your normal terminal environment remains untouched.

## Desktop troubleshooting

A named Desktop profile should be started with:

```bash
clp desktop work
```

Do **not** replace that with a plain `open -a Claude`, because a plain launch has no profile-specific `CLAUDE_CONFIG_DIR` and will use the default Desktop/Code context. For the first login of a new Desktop profile, if the browser callback focuses another already-running Claude window, quit the other Desktop instances temporarily, run `clp desktop work`, finish login, and then reopen the other profiles.
