# Notice

FORK is a modified version of **Concat** (https://github.com/jub0t/Concat),
Copyright (C) 2026 Jareer and Concat contributors, licensed under
AGPL-3.0-or-later. The original copyright and SPDX headers in the source files
are kept as they were.

## Changes made in FORK

- Renamed the app to "FORK"; new Android package ID `app.fork.editor`.
- Replaced the app icon and removed upstream logos and screenshots (the Concat
  name and logo are the upstream author's trademarks: see
  `UPSTREAM_TRADEMARK.md`).
- Android target SDK raised from 35 to 36.
- Added `android/` (Gradle project) and `build-aab.sh` to build a Google Play
  App Bundle; replaced upstream CI workflows with `.github/workflows/play-aab.yml`.
- User-visible strings and default folder names changed from "Concat" to "FORK".
- Internal crate names, code comments and upstream issue links still say
  "concat"; this is intentional, to keep merging upstream fixes easy.

Later changes are recorded in the git history of the public repository.
