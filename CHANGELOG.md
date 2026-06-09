# Changelog

All notable changes to **CharInspectPlus** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.6] - 2026-06-08

### Fixed
- **Inspect frame talents button shrinking.** The talents button
  (`InspectPaperDollItemsFrame.InspectTalents`) is a child `Button` of the inspect
  paper-doll frame, so the item-slot styling pass was resizing it to `37x37` along
  with the real equipment slots. It is now excluded from the slot styling loop and
  keeps its correct size and position.

### Changed
- **Midnight (12.0) Secret Value safety.** The class-based inspect background now
  guards `UnitClass("target")` with `issecretvalue()` before its truthiness check and
  string concatenation, preventing errors when inspecting units inside instances where
  unit data can be a Secret Value. The guard is written so older clients without the
  `issecretvalue` global continue to work.

### Notes
- Interface versions: `120005` (Midnight), `110105` / `110205` (The War Within).
