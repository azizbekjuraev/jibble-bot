# JibbleBot

A free, open-source bot that automates clocking in and out of [Jibble](https://web.jibble.io).
Set it up once, schedule it, and stop logging in by hand.

It drives a real browser via ChromeDriver, so it works exactly like a manual login — no Jibble API key required, no Jibble plan upgrade needed.

## What it does

- `JibbleBot.clock_in/0` — opens Jibble, logs in, clicks **Clock In**, confirms.
- `JibbleBot.clock_out/0` — opens Jibble, logs in, clicks **Clock Out**, confirms.

Two ready-to-run shell scripts (`clock_in.sh`, `clock_out.sh`) wrap these so you can trigger them from cron, launchd, Shortcuts, Alfred, or any scheduler.

> **Heads up:** this guide is written for **macOS**. The bot will work on Linux/Windows too, but you'll need to adapt the browser path in `lib/jibble_bot.ex` and use your platform's package manager instead of Homebrew.

---

## Step-by-step install (from scratch)

If you've never used a terminal-based dev tool before, follow these in order. Open the **Terminal** app (`Cmd+Space`, type "Terminal", hit Enter) and paste each command.

### 1. Install Homebrew (macOS package manager)

If you don't already have Homebrew, install it:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Verify it works:

```bash
brew --version
```

If you see something like `Homebrew 4.x.x`, you're good.

### 2. Install Elixir

Elixir is the language this bot is written in. Install it with Homebrew:

```bash
brew install elixir
```

Verify:

```bash
elixir --version
```

You should see `Elixir 1.19` or newer.

### 3. Install Brave Browser

The bot uses Brave by default (a free Chrome-compatible browser):

```bash
brew install --cask brave-browser
```

Open Brave once after install so macOS doesn't block it later. You can sign into your Google account or not — it doesn't matter for the bot.

> **Prefer Chrome?** Install Chrome instead (`brew install --cask google-chrome`), then edit line 3 of `lib/jibble_bot.ex`:
> ```elixir
> @brave_binary "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
> ```

### 4. Install ChromeDriver

ChromeDriver is the bridge that lets the bot control the browser. **Its version must match your browser's version.**

```bash
brew install --cask chromedriver
```

The first time you run it, macOS will block it as an "unverified developer". Fix it once with:

```bash
xattr -d com.apple.quarantine $(which chromedriver)
```

Verify:

```bash
chromedriver --version
```

Compare that to your Brave version (Brave menu → **About Brave**). The major version numbers should match. If they don't:

```bash
brew upgrade --cask chromedriver
# or
brew upgrade --cask brave-browser
```

### 5. Download this project

```bash
cd ~/Desktop
git clone <this-repo-url> jibble_bot
cd jibble_bot
```

(If you don't have `git`, install it with `brew install git` first.)

### 6. Install project dependencies

```bash
mix deps.get
```

This downloads the two libraries the bot needs (`jason` and `httpoison`). On first run, Elixir may ask you to install **Hex** and **Rebar** — type `Y` and hit Enter.

### 7. Add your Jibble credentials

Create a file called `.env` in the project folder:

```bash
echo "JIBBLE_EMAIL=you@example.com" > .env
echo "JIBBLE_PASSWORD=your-password" >> .env
```

Replace the email and password with your real Jibble login. The `.env` file is gitignored — it never leaves your machine.

### 8. Make the shell scripts executable

```bash
chmod +x clock_in.sh clock_out.sh
```

### 9. Test it

```bash
./clock_in.sh
```

A Brave window should pop open, log into Jibble, click **Clock In**, then close itself. If it worked, try the other one:

```bash
./clock_out.sh
```

That's it — you're set up.

---

## Automating it (the whole point)

To clock in at 9:00 AM and clock out at 6:00 PM, Monday–Friday, add it to **cron**:

1. Open your crontab:

   ```bash
   crontab -e
   ```

   (If it asks which editor, type `1` for nano — easiest.)

2. Paste these two lines, replacing `azizbekjuraev` with your macOS username:

   ```cron
   0 9  * * 1-5 /Users/azizbekjuraev/Desktop/jibble_bot/clock_in.sh  >> /tmp/jibble.log 2>&1
   0 18 * * 1-5 /Users/azizbekjuraev/Desktop/jibble_bot/clock_out.sh >> /tmp/jibble.log 2>&1
   ```

3. Save and exit (in nano: `Ctrl+O`, Enter, `Ctrl+X`).

To confirm it's installed:

```bash
crontab -l
```

Check `/tmp/jibble.log` after the scheduled time to confirm it ran.

> **macOS may ask for permission** the first time cron runs the script — System Settings → Privacy & Security → Full Disk Access → add `/usr/sbin/cron`.

---

## Running it manually

You don't have to use cron. You can also run it whenever you want:

```bash
./clock_in.sh     # clock in now
./clock_out.sh    # clock out now
```

Or from an interactive Elixir shell:

```bash
iex -S mix
iex> JibbleBot.clock_in()
iex> JibbleBot.clock_out()
```

---

## Troubleshooting

**"Failed to find element"**
Jibble changed a button's `data-testid` attribute. Open Jibble in your browser, right-click the button → **Inspect**, find the new `data-testid="..."` value, and update the matching selector in `lib/jibble_bot.ex`.

**"session not created: This version of ChromeDriver only supports Chrome version X"**
Your ChromeDriver and Brave/Chrome versions don't match. Run `brew upgrade --cask chromedriver` and `brew upgrade --cask brave-browser`.

**"chromedriver cannot be opened because the developer cannot be verified"**
Run `xattr -d com.apple.quarantine $(which chromedriver)` once.

**Cron job never runs**
Cron doesn't inherit your normal `PATH`. The included shell scripts already use absolute paths, so check `/tmp/jibble.log` for the real error. Also make sure cron has Full Disk Access in macOS System Settings.

**Login fails**
Double-check your `.env` file — no quotes around the values, no trailing spaces.

---

## How it works (for the curious)

`lib/jibble_bot.ex` starts a local ChromeDriver process, opens a WebDriver session pointing at the Brave binary, navigates to `web.jibble.io`, fills in the login form, clicks the Clock In/Out button, and confirms in the side panel. When done, it closes the session and kills ChromeDriver. That's the whole tool — about 170 lines of Elixir.

## License

Free to use, modify, and share. No warranty — if Jibble changes their UI, you may need to tweak a selector. PRs welcome.
