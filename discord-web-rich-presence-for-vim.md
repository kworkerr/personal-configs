# Discord Web Rich Presence for Vim

A lightweight Discord Rich Presence setup for Linux using Vim, Node.js, arRPC, Firefox, and Violentmonkey — without installing the Discord desktop client.

## Overview

This setup displays the file currently being edited in Vim as a Discord activity.

Example:

```text
Vim Presence
C Programming
Editing banana.c
Elapsed time
```

The activity updates when switching Vim buffers, while the elapsed-time counter continues running without restarting.

The setup consists of four components:

- **Vim:** writes the current filename to a state file.
- **Node.js:** monitors the state file and publishes Rich Presence.
- **arRPC:** provides a local RPC interface for Discord.
- **Firefox + Violentmonkey:** connects Discord Web to the local arRPC server.

The arRPC bridge is experimental and relies on Discord Web internals, so updates to Discord or the bridge may require adjustments.

## Requirements

- Linux with a graphical session running dwl.
- Firefox with the Violentmonkey extension.
- Node.js 20 or newer recommended.
- npm.
- `wl-copy` for copying the userscript to the clipboard.
- A Discord application created in the Discord Developer Portal.

References:

- [OpenAsar/arRPC](https://github.com/OpenAsar/arrpc)
- [Violentmonkey](https://violentmonkey.github.io/)
- [@xhayper/discord-rpc](https://www.npmjs.com/package/@xhayper/discord-rpc)

## 1. Create a Discord application

Open the [Discord Developer Portal](https://discord.com/developers/applications).

1. Create an application named `Vim Presence`.
2. Open **General Information**.
3. Copy the **Application ID**. This is the client ID used by the Node.js program.
4. Open **Rich Presence → Art Assets**.
5. Upload a square Vim logo and give the asset the key `vim_logo`.

The asset key must match the key used in the program. Do not share account credentials or Discord session cookies.

## 2. Set up the Node.js project

Create the project directory and install the RPC library:

```sh
mkdir -p ~/dev/vim-presence
cd ~/dev/vim-presence

npm init -y
npm install @xhayper/discord-rpc
```

Create `index.cjs`:

```js
const fs = require("node:fs");
const path = require("node:path");
const { Client } = require("@xhayper/discord-rpc");

const activityFile = path.join(
    process.env.HOME,
    ".cache/vim-presence"
);

const client = new Client({
    clientId: "YOUR_APPLICATION_ID"
});

let previousFile = "";
let sessionStart = null;

function updateActivity() {
    let filename;

    try {
        filename = fs.readFileSync(activityFile, "utf8").trim();
    } catch {
        return;
    }

    if (!filename || filename === previousFile) {
        return;
    }

    // Set the timer only once per Node.js process.
    if (sessionStart === null) {
        sessionStart = new Date();
    }

    previousFile = filename;

    client.user?.setActivity({
        details: `Editing ${filename}`,
        state: "C Programming",
        startTimestamp: sessionStart,
        largeImageKey: "vim_logo",
        largeImageText: "Vim"
    });

    console.log(`Activity updated: ${filename}`);
}

client.on("ready", () => {
    console.log("Connected to arRPC!");

    updateActivity();

    fs.watchFile(
        activityFile,
        { interval: 500 },
        updateActivity
    );
});

client.on("error", err => {
    console.error("RPC error:", err);
});

client.login().catch(err => {
    console.error("Failed to connect:", err);
});
```

Replace `YOUR_APPLICATION_ID` with the Application ID created earlier.

If you have not uploaded an image asset, remove the `largeImageKey` and `largeImageText` properties.

### How the timer works

The `sessionStart` variable stores the timestamp used by Rich Presence.

- The first filename starts the timer.
- Switching to another file updates the activity details but reuses the same timestamp.
- The timer resets when the Node.js process starts again.

This means switching between `banana.c`, `main.c`, and `noise.c` will not reset the displayed elapsed time.

## 3. Configure Vim

Add the following to `~/.vimrc`:

```vim
augroup discord_presence
    autocmd!
    autocmd BufEnter * call writefile(
        \ [expand('%:t')],
        \ expand('~/.cache/vim-presence')
        \ )
augroup END
```

This writes the current buffer's filename to `~/.cache/vim-presence` whenever Vim enters a buffer.

Create the initial state file:

```sh
mkdir -p ~/.cache
: > ~/.cache/vim-presence
```

For example, opening `banana.c` writes:

```text
banana.c
```

The Node.js program reads this file and updates the activity whenever its contents change.

The current hook tracks buffer changes, not whether Vim is still open. Consequently, the state file may retain the last filename after Vim exits.

## 4. Configure arRPC

Run arRPC:

```sh
npx --yes arrpc
```

Keep it running during the initial test. It will be launched automatically by dwl later.

## 5. Configure Firefox and Violentmonkey

Install [Violentmonkey for Firefox](https://addons.mozilla.org/firefox/addon/violentmonkey/). Create a new userscript and replace its entire contents with the code below.

This is the working bridge version for this setup. It retries discovering Discord's internal modules for up to 10 seconds. Discord Web's internal code can change without notice, so the bridge may need future maintenance.

```js
// ==UserScript==
// @name         arRPC Bridge - Discord Web
// @namespace    local.vim-presence
// @version      1.1.0
// @description  Connect Discord Web to local arRPC
// @match        https://discord.com/*
// @run-at       document-idle
// @inject-into  page
// @grant        none
// @noframes
// ==/UserScript==

(() => {
    'use strict';

    let Dispatcher;
    let lookupAsset;
    let lookupApp;
    const apps = {};

    console.log('[Vim Presence] Userscript iniciado');

    const eachCandidate = (mod, fn) => {
        if (!mod) return;
        try { fn(mod); } catch {}
        try { if (mod.default) fn(mod.default); } catch {}
        try {
            for (const key of Reflect.ownKeys(mod)) {
                try { fn(mod[key]); } catch {}
            }
        } catch {}
    };

    const getWebpackRequire = () => {
        const chunks = window.webpackChunkdiscord_app;
        if (!chunks || typeof chunks.push !== 'function') return null;

        const reqs = [];
        chunks.push([
            [`vim-presence-${Date.now()}`],
            {},
            req => { if (req) reqs.push(req); }
        ]);
        chunks.pop();

        const hasSource = (req, ...needles) => {
            for (const id in req?.m) {
                let source;
                try { source = req.m[id]?.toString?.(); } catch { continue; }
                if (source && needles.every(s => source.includes(s))) return true;
            }
            return false;
        };

        return reqs.find(req =>
            hasSource(req, 'getAssetImage: size must === [') &&
            hasSource(req, 'Invalid Origin', 'coverImage', '.application')
        ) || reqs.at(-1) || null;
    };

    const findModule = (req, ...needles) => {
        if (!req?.m) return;
        for (const id in req.m) {
            let source;
            try { source = req.m[id]?.toString?.(); } catch { continue; }
            if (!source || !needles.every(s => source.includes(s))) continue;
            try { return req(id); } catch {}
        }
    };

    const findInCache = (req, test, depth = 4) => {
        if (!req?.c) return;
        const seen = new WeakSet();
        let found;

        const walk = (value, remainingDepth) => {
            if (found || !value ||
                (typeof value !== 'object' && typeof value !== 'function')) return;
            if (value === window || value === document ||
                value === globalThis || seen.has(value)) return;

            seen.add(value);
            try {
                if (test(value)) { found = value; return; }
            } catch {}
            if (!remainingDepth) return;
            eachCandidate(value, item => walk(item, remainingDepth - 1));
        };

        for (const id in req.c) {
            const mod = req.c[id]?.exports;
            if (!mod) continue;
            walk(mod, depth);
            if (found) return found;
        }
    };

    const discoverInternals = async () => {
        for (let attempt = 0; attempt < 40; attempt++) {
            try {
                const req = getWebpackRequire();

                if (req && !Dispatcher) {
                    Dispatcher = findInCache(req, candidate =>
                        typeof candidate?.dispatch === 'function' &&
                        typeof candidate?.subscribe === 'function' &&
                        Array.isArray(candidate._waitQueue)
                    );
                }

                if (req && !lookupAsset) {
                    const mod = findModule(req, 'getAssetImage: size must === [');
                    eachCandidate(mod, candidate => {
                        if (typeof candidate !== 'function') return;
                        const source = candidate.toString();
                        if (source.includes('APPLICATION_ASSETS_FETCH_SUCCESS') &&
                            source.includes('startsWith("http:")')) {
                            lookupAsset = async (appId, name) =>
                                (await candidate(appId, [name]))[0];
                        }
                    });
                }

                if (req && !lookupApp) {
                    const mod = findModule(req, 'Invalid Origin', 'coverImage', '.application');
                    eachCandidate(mod, candidate => {
                        if (typeof candidate !== 'function') return;
                        const source = candidate.toString();
                        if (source.includes('Invalid Origin') &&
                            source.includes('coverImage') &&
                            source.includes('.application')) {
                            lookupApp = async appId => {
                                const socket = {};
                                await candidate(socket, appId);
                                return socket.application;
                            };
                        }
                    });
                }

                if (Dispatcher && lookupAsset && lookupApp) {
                    console.log('[Vim Presence] Discord internals encontrados');
                    return true;
                }
            } catch (err) {
                console.warn('[Vim Presence] Tentativa de descoberta falhou', err);
            }

            await new Promise(resolve => setTimeout(resolve, 250));
        }

        console.error('[Vim Presence] Não foi possível localizar:', {
            Dispatcher: !!Dispatcher,
            lookupAsset: !!lookupAsset,
            lookupApp: !!lookupApp
        });
        return false;
    };

    const ws = new WebSocket('ws://127.0.0.1:1337');

    ws.addEventListener('open', () =>
        console.log('[Vim Presence] Conectado ao arRPC'));
    ws.addEventListener('error', () =>
        console.error('[Vim Presence] Erro no WebSocket do arRPC'));
    ws.addEventListener('close', event =>
        console.warn('[Vim Presence] WebSocket fechado:', event.code, event.reason));

    ws.onmessage = async event => {
        try {
            const msg = JSON.parse(event.data);

            if (!await discoverInternals()) {
                throw new Error('Discord internals indisponíveis');
            }

            if (msg.activity?.assets?.large_image) {
                msg.activity.assets.large_image = await lookupAsset(
                    msg.activity.application_id, msg.activity.assets.large_image);
            }
            if (msg.activity?.assets?.small_image) {
                msg.activity.assets.small_image = await lookupAsset(
                    msg.activity.application_id, msg.activity.assets.small_image);
            }

            if (msg.activity) {
                const appId = msg.activity.application_id;
                if (!apps[appId]) apps[appId] = await lookupApp(appId);
                if (!msg.activity.name) msg.activity.name = apps[appId].name;
            }

            Dispatcher.dispatch({ type: 'LOCAL_ACTIVITY_UPDATE', ...msg });
        } catch (err) {
            console.error('[Vim Presence] Falha ao atualizar atividade:', err);
        }
    };
})();
```

Save the script and check the following:

1. **Enable** is on.
2. **Run-At** is `document-idle`.
3. **Injection mode** is `page`.
4. Firefox has permission to let `discord.com` access other apps and services on the device.
5. Reload Discord Web with `Ctrl + Shift + R`.

The `@inject-into page` directive is essential: the bridge needs access to Discord Web's JavaScript objects.

## 6. Test the complete setup

Start arRPC in one terminal:

```sh
npx --yes arrpc
```

Start the Rich Presence client in another:

```sh
cd ~/dev/vim-presence
node index.cjs
```

Open Discord Web in Firefox, then open a file in Vim:

```sh
vim banana.c
```

Expected Node.js output:

```text
Connected to arRPC!
Activity updated: banana.c
```

The activity should display `Editing banana.c`. Switching to another Vim buffer should update the filename while keeping the original elapsed-time timestamp.

For example:

| Action | Activity | Timer |
|---|---|---|
| Open `banana.c` | Editing banana.c | Starts |
| Switch to `main.c` | Editing main.c | Continues |
| Switch to `noise.c` | Editing noise.c | Continues |
| Restart Node.js | Current filename | Resets on the next update |

## 7. Start everything automatically with dwl

Append the following to `~/.config/dwl/autostart.sh`, preserving the existing commands:

```sh
# Discord Rich Presence
mkdir -p "$HOME/.cache"

npx --yes arrpc \
    >> "$HOME/.cache/arrpc.log" 2>&1 &

sleep 2

(
    cd "$HOME/dev/vim-presence" || exit 1
    exec node index.cjs
) >> "$HOME/.cache/vim-presence.log" 2>&1 &
```

Check the script's syntax:

```sh
sh -n ~/.config/dwl/autostart.sh &&
    echo "Syntax OK"
```

The next time dwl starts, arRPC and the Node.js publisher will launch in the background.

Firefox must still load Discord Web for the userscript to run. If the browser starts on a different page, the bridge will not connect until Discord Web is opened.

The timer starts when the publisher first detects a filename after startup. It continues across buffer changes, but restarting the computer or Node.js process resets the timer.

## 8. Troubleshooting

### Check the arRPC log

```sh
tail -n 30 ~/.cache/arrpc.log
```

A successful browser connection should produce a message resembling:

```text
[arRPC > bridge] web connected
```

If the bridge immediately disconnects, check the Firefox permission and verify that `@inject-into page` is present. In the Firefox Console, look for `[Vim Presence] Conectado ao arRPC`, `[Vim Presence] Discord internals encontrados`, or `[Vim Presence] Não foi possível localizar`; the last message lists which internal components were not found.

### Check the Node.js log

```sh
tail -n 30 ~/.cache/vim-presence.log
```

The message `Connected to arRPC!` confirms that the publisher established its RPC connection. `Activity updated: filename` confirms that it detected a filename change.

If the publisher works but the activity is invisible, verify that Discord Web is connected, the userscript is enabled, the Application ID is correct, and Discord's activity privacy settings permit sharing activities.

### The logo does not appear

Verify all three items:

1. The image was uploaded to the correct Discord application.
2. Its asset key matches `largeImageKey` exactly.
3. The Node.js program was restarted after changing its code.

### Restarting a process manually

Stop the relevant process with `Ctrl+C` in its foreground terminal, then relaunch it.

For normal operation, avoid starting additional copies when the autostart processes are already running.

## Notes and limitations

- arRPC is an experimental third-party implementation, not an official Discord service.
- The bridge accesses Discord Web's internal JavaScript objects, which can change without notice.
- The elapsed-time counter persists across file changes as long as the Node.js process remains running.
- The counter resets after restarting Node.js or rebooting the computer.
- The current Vim hook records buffer changes, not whether Vim is still open. The state file can retain the last filename after Vim exits.
- The setup is designed to avoid the Discord desktop client's memory overhead, but it still uses Node.js, a local RPC server, Firefox, and a browser userscript.

## References

- [OpenAsar/arRPC repository and bridge example](https://github.com/OpenAsar/arrpc)
- [Violentmonkey metadata documentation](https://violentmonkey.github.io/api/metadata-block/)
- [Violentmonkey injection contexts](https://violentmonkey.github.io/posts/inject-into-context/)
- [@xhayper/discord-rpc on npm](https://www.npmjs.com/package/@xhayper/discord-rpc)