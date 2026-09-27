# Claude Split for Multi Profile Management

Run multiple **Claude Desktop** and **Claude Code** accounts side by side on macOS without repeatedly logging out.

Claude split is a small shell utility. It does not copy, inspect, or store your passwords or OAuth tokens. Claude performs authentication normally; the tool only gives each profile isolated local state and routes Desktop OAuth callbacks to the profile that initiated them.

> Unofficial community project. Not affiliated with or endorsed by Anthropic.

## Why

A second Claude Desktop window is easy to start with a separate Electron `user-data-dir`, but there is a less obvious problem: browser authentication returns through the system-wide `claude://` URL scheme. macOS normally associates that scheme with the stock Claude app, so Chrome can send a named profile's OAuth callback back to the default Claude instance.

This project handles both sides:

- isolated Claude Code config/auth contexts;
- isolated Claude Desktop cookies, local storage, sessions, and app state;
- a tiny per-profile macOS URL-router app;
- temporary `claude://` reassignment while a named profile is signing in;
- automatic restoration of the stock Claude handler after the callback;

## Requirements

- macOS;
- Claude Desktop installed in `/Applications/Claude.app`;
- Claude Code installed and available as `claude`;
- `duti` for automatic browser OAuth callback routing.

Install `duti` once:

```bash
brew install duti
```

Named Desktop profiles can still launch without `duti`; only automatic browser-login routing requires it.

## Install

```bash
git clone https://github.com/samrand96/claude-split.git
cd claude-split
./install.sh
```

If `~/.local/bin` is not on `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then:

```bash
clp doctor
```

## Quick start

Your existing installation is the special `default` profile:

```bash
clp code default
clp desktop default
```

Create a second account/profile:

```bash
clp add work
```

Authenticate Claude Code into the intended account:

```bash
clp login work
clp auth work
```

For the **first Desktop login** (or any later browser-based re-login), use:

```bash
clp desktop-login work
```

This is intentionally different from a normal launch. `desktop-login` temporarily routes the system `claude://` scheme to the `work` profile. Complete sign-in in Chrome and choose **Open** when Chrome asks to open the app. The OAuth callback is forwarded to the `work` Desktop instance and the normal Claude URL handler is restored automatically.

After the profile is authenticated, normal launches are simply:

```bash
clp desktop work
clp code work
```

You can run several profiles concurrently:

```text
Terminal 1:  clp code default
Terminal 2:  clp code work
Desktop 1:   clp desktop default
Desktop 2:   clp desktop work
```

## Commands

```text
clp add <profile>                       Create an isolated profile
clp list                                List profiles
clp use <profile>                       Save the active profile
clp current                             Show the active profile

clp auth [profile]                      Show Claude Code auth for the profile
clp login [profile]                     Log that profile into Claude Code
clp logout [profile]                    Log that profile out of Claude Code

clp code [profile] [-- args...]         Launch Claude Code
clp desktop [profile]                   Launch an already-authenticated Desktop profile
clp desktop-login [profile]             Launch Desktop with browser OAuth routing enabled
clp both [profile] [-- args...]         Launch Desktop and Claude Code

clp callback <profile> <claude://URL>   Manually forward a deep link to a profile
clp handler                             Show the current claude:// handler
clp handler reset                       Restore the stock Claude handler

clp doctor                              Diagnose the setup
clp path <profile>                      Show profile storage paths
clp purge <profile>                     Delete local data for a named profile
```

## Why `desktop-login` exists

Claude Desktop responds to the system-wide `claude://` URL scheme. A browser-based login eventually redirects to a URL such as:

```text
claude://login/...
```

Without routing, macOS gives that URL to its registered Claude handler, normally the default app. That means merely launching two Electron instances with different `--user-data-dir` values is **not sufficient for multi-account login**.

For every named profile, `clp` creates a tiny AppleScript application under:

```text
~/Applications/Claude Split/Claude Split - <profile>.app
```

The helper contains no credentials. Its only jobs are:

1. receive `claude://` from LaunchServices;
2. call `clp` with the profile name and callback URL;
3. launch the real signed `/Applications/Claude.app` executable using that profile's Desktop and Code directories;
4. restore `claude://` to the stock Claude bundle after an OAuth callback.

`duti` is used to switch the URL-scheme handler reliably.

### Manual escape hatch

If a browser ever gives you the callback URL but routing does not happen automatically:

```bash
clp callback work 'claude://login/...'
```

To force the normal handler back at any time:

```bash
clp handler reset
```

## Claude Code auth isolation

Each named profile gets its own config directory:

```text
~/.local/share/claude-split/profiles/<profile>/code/
```

For that profile, `clp` launches Claude Code with:

```text
CLAUDE_CONFIG_DIR=<profile code dir>
CLAUDE_SECURESTORAGE_CONFIG_DIR=<profile code dir>
```

Use this before opening the corresponding Desktop account:

```bash
clp auth work
```

That makes it easy to verify which Claude Code identity is associated with the profile.

## Avoiding stale authentication overrides

A shell can contain old settings from local LLMs, gateways, cloud providers, or development proxies. These can make Claude Code behave differently from Claude Desktop. For every Claude process it launches, `clp` removes overrides including:

```text
ANTHROPIC_API_KEY
ANTHROPIC_AUTH_TOKEN
ANTHROPIC_BASE_URL
ANTHROPIC_CUSTOM_HEADERS
CLAUDE_CODE_USE_VERTEX
CLAUDE_CODE_USE_BEDROCK
CLAUDE_CODE_USE_FOUNDRY
GOOGLE_APPLICATION_CREDENTIALS
HTTP_PROXY / HTTPS_PROXY / ALL_PROXY
http_proxy / https_proxy / all_proxy
NODE_OPTIONS
```

This cleanup is process-local. It does **not** modify your shell, repositories, or project `.env` files.

Run:

```bash
clp doctor
```

if CLI and Desktop behave differently.

## Storage

```text
~/.local/share/claude-split/
├── active-profile
├── pending-desktop-auth
├── logs/
└── profiles/
    ├── work/code/
    └── client-a/code/

~/Library/Application Support/Claude-Split/
├── work/
└── client-a/

~/Applications/Claude Split/
├── Claude Split - work.app
└── Claude Split - client-a.app
```

The existing default Claude directories are not moved or rewritten.

## Normal workflow

```bash
# personal/default
clp code default
clp desktop default

# work
clp code work
clp desktop work

# if work Desktop needs to authenticate again
clp desktop-login work
```

## Troubleshooting

See what macOS currently uses for `claude://`:

```bash
clp handler
```

Restore normal routing:

```bash
clp handler reset
```

See paths for a profile:

```bash
clp path work
```

See the named Desktop process log:

```bash
tail -f ~/.local/share/claude-split/logs/desktop-work.log
```

If `clp desktop-login work` says `duti` is missing:

```bash
brew install duti
```

Then retry.

## Remove a profile

```bash
clp purge work
```

You must type the profile name to confirm. The utility deliberately does not read or delete secret Keychain values.

## Uninstall

```bash
./uninstall.sh
```

Uninstall restores the stock Claude URL handler before removing the launchers and helper apps. Profile data is retained.

## Security

No API keys, OAuth tokens, cookies, or passwords are placed in this repository. Profile state remains in local Claude directories and macOS credential storage.

See [SECURITY.md](SECURITY.md).

## License

MIT.
