# The verification loop

How a change gets proven in this repository, for any agent and any tool. Three
layers, in order of cost. A change is not done because the first one passed.

1. **Static and unit** (`bin/check`): seconds. Never skipped.
2. **Visual** (preview catalog + screenshots): for a component or a screen.
3. **End to end** (dusk driving a real Chrome): for anything a person clicks, at
   desktop and at mobile width both.

## 1. The static gate

```sh
bin/check              # everything, in parallel
bin/check --fast       # analyze + pint only
bin/check flutter      # one half; also backend
```

## 2. The visual loop, for components and screens

```
CREATE -> SCREENSHOT -> ANALYZE -> FIX -> VERIFY
```

Three rounds maximum. Stop and surface the problem if a full round produces no
improvement, rather than looping on the same finding.

- **CREATE** using semantic tokens and existing components. Check
  `docs/component-registry.md` before building a new widget.
- **SCREENSHOT** light and dark, from the preview catalog:

  ```sh
  ./bin/fsa dusk:navigate --route=/preview
  ./bin/fsa dusk:screenshot -o .ac/evidence/<name>-light.png
  # switch the catalog to dark, then:
  ./bin/fsa dusk:screenshot -o .ac/evidence/<name>-dark.png
  ```

- **ANALYZE** with the `component-visual-reviewer` reviewer
  (`.claude/agents/component-visual-reviewer.md` for Claude Code; other tools can
  read that file as the scoring rubric). It scores token compliance, dark/light
  parity, spacing, typography, and radii, and returns BLOCKING and ADVISORY items.
- **FIX** every BLOCKING item. ADVISORY items only when they need no scope creep.
- **VERIFY** by re-screenshotting and re-scoring.

## 3. The end-to-end walk with dusk

`fluttersdk_dusk` drives a running Flutter app over VM Service extensions: it
reads the Semantics tree as a YAML snapshot with stable `[ref=eN]` handles and
dispatches real gestures through a six-check actionability gate.

Every verb below has a second face. `.mcp.json` wires `./bin/fsa mcp:serve` as a
project MCP server, so an agent whose client reads that file gets the same dusk,
telescope and artisan surface as tools rather than as shell commands. Both routes
drive the same running app through the same per-project state under
`~/.artisan/sessions/`, so they are interchangeable and can be mixed within one
walk. This file stays written in CLI form because that is the form that can be
pasted into a terminal and read back in a log.

That entry is machine-shaped, and the committed one is the POSIX shape. **On
Windows, run `dart run :dispatcher mcp:install`**: `bin/fsa` is a `sh` script, so
`mcp:install` skips that shape on Windows by design and falls back to a `dart run`
command it can spawn. Regenerating is the fix rather than hand-editing the file,
because the tool already knows which of its three shapes a machine has, and it is
idempotent and preserves any other server entry.

It is committed in the fast shape because that is what the fast path is for:
measured here, `./bin/fsa list` is 0.63s against 5.21s for
`dart run :dispatcher list`, and a dusk walk pays that per command rather than
once. `bin/fsa` keys its build cache on `pubspec.lock`, and a fresh clone now
carries that lock, so the cache key is already correct before the first
`flutter pub get`, which is still the first step either route needs.

Boot the backend, then the app:

```sh
cd backend && php artisan serve --port=8000
./bin/fsa start --device=chrome --cdp-port=9223
```

Two boot failures read as "the app is broken" rather than as a missing service:

- **Redis**, when the backend's cache or rate limiter is configured for it. Every
  API call 500s on `Connection refused`, login included. `redis-server --port 6379`
  is enough.
- **Reverb**, when `.env` sets `BROADCAST_CONNECTION=reverb`. The boot-time Echo
  connect throws an uncaught exception if the socket refuses, and that kills the
  whole Flutter boot: nothing renders, the snapshot is empty, and there is no error
  on screen. The tell is a console showing Env / Cache / Database / Locale ready
  and then a WebSocket error. `php artisan reverb:start --port=8080`.

If `fsa start` times out on a cold web build, run `flutter run -d chrome` yourself
and write `~/.artisan/state.json` with the `pid`, `vmServiceUri`, `webPort`,
`vmServicePort`, `projectRoot`, and `device` so the dusk CLI can find the app.

### Responsive: desktop and mobile are both required

The shell swaps at `lg` (1024px): a sidebar plus content column above it, a bottom
tab bar below. A change to any screen is verified on both sides of that line, since
they are different widget trees. Useful widths: 390 (phone, no sidebar), 768
(tablet portrait, still the mobile shell), 1200, and 1440 or wider.

Resize through CDP `Browser.getWindowForTarget` + `Browser.setWindowBounds`.
**Not** `Emulation.setDeviceMetricsOverride`: Flutter web reads its logical size
from the host element, so that override grows the screenshot canvas while the app
keeps laying out at the old width, and everything renders doubled and clipped.

### Driver behavior worth knowing

- `dusk:tap --ref=eN` is the tap verb; there is no `dusk:click`.
- `dusk:wait` prints a human line rather than JSON. Parse the text.
- If `dusk:snap` returns an empty tree on a web build, `dusk:navigate` returns a
  populated one, so navigate-then-read is the way in.
- `dusk:scroll` may not move a page whose scrollable is owned by the shell rather
  than the content. A real `Input.dispatchMouseEvent type: 'mouseWheel'` does.
- `fsa tinker --eval=...` does not work against a web-server device (dwds answers
  `NoSuchMethodError`). Use CDP `Runtime.evaluate`.

### Traps that produce confident wrong measurements

- An exact-label lookup over the semantics tree resolves to the **sidebar** nav
  item, which carries the same label as the page it opens. Constrain the search to
  the content region or you will measure the sidebar and conclude two pages differ.
- A hardcoded content-region threshold (`x > 300`) is wrong at other widths: at
  1200px the container starts further left, at 390px there is no sidebar at all.
  Derive it from the width under test.
- "The bottom-most content node" matches an aggregate parent whose box spans the
  whole page, so an overlap check reads true on every page including unchanged
  ones. Look at the screenshot.

## 4. Reading a system that is already running

The three layers above run locally against code you just wrote, and they fail
loudly. Answering a question about a system that is ALREADY running, whether in
production or in a live local stack, fails quietly instead: nothing goes red, you
get a number, and the number is wrong. Rule the harness out before filing a defect.

- **Read the identifier, never guess it.** A field or translation key that looks
  right by naming convention is not the same as one you confirmed exists. A missing
  column reads back as null and a missing translation key echoes itself, and
  neither is distinguishable from genuinely empty data. Confirm the identifier
  against the schema or the source file, not against what the name implies.
- **Take a before/after boundary from the artifact, not from your estimate of when
  you acted.** A count bounded by "the N minutes since I made the change" can
  include events that happened before the fix actually landed; a file's own
  modification time is the real boundary.
- **The machine's clock and the app's clock can disagree.** A server running on
  local time beside an app running on UTC (or the reverse) makes a timestamp
  comparison read as hours of downtime when it is minutes of clock skew. Print
  both clocks in the same command before drawing a conclusion from a timestamp.
- **A count command's exit status can look like failure when the count is a
  correct zero.** `grep -c` exits non-zero on a zero count, and a fallback
  triggered by that exit code masks a genuine, correct measurement.
- **A value assembled once and cached does not pick up a later change to the
  thing it was built from.** A rendered string or composed view built before a
  locale switch, a config change, or a data update stays stale until it is
  rebuilt; rebuild the artifact fresh before concluding a change did not take
  effect.
- **Reading a value at the wrong point in a request pipeline attributes to the
  app what a layer in front of it did.** A header or scheme set by a reverse
  proxy, read by hitting the app server directly instead of through the proxy,
  reads as unset or wrong.
- **A 404 is not a regression until the route is confirmed to exist right now**,
  not from memory of when it was added.
- **A single timeout is not evidence of a wall.** When a system enforces a
  shared budget across retries, a later call inheriting a smaller remaining
  budget is not evidence of new instability. Repeat the measurement before
  concluding anything from one slow or failed call.

## What counts as evidence

A claim needs the artifact behind it: the `bin/check` summary, the screenshot pair,
the snapshot or the response body. "Should work" and "green locally" are not
evidence, and neither is a passing test that could not have failed. Screenshots and
snapshots go under `.ac/evidence/`.

A claim about a running system needs one thing more: the reading has to survive
section 4. A count is only evidence once its boundary comes from the artifact, an
identifier only once it was read rather than guessed, and a single timeout is
never evidence of a wall.
