# Changelog

All notable changes to **CharInspectPlus** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-06-16

Major rewrite for Midnight **12.0.7** (Revelations). The addon now uses a
lightweight NexEnhance-style engine with saved settings, a Blizzard Settings
panel, and live enable/disable toggles.

### Added
- **Modular core.** `Engine`, `Database`, `API`, `Functions`, `Locales`, and
  `Commands` replace the old monolithic layout. One shared event dispatcher;
  everything lives on the addon namespace (`CharInspectPlus`).
- **Saved variables.** `CharInspectPlusDB` with per-character profile support.
- **Live configuration.** Master enable plus separate toggles for the Character
  and Inspect frames. Changes apply immediately — no `/reload` required for
  layout and backgrounds.
- **Blizzard Settings panel.** Landing page (version, description, slash
  commands) and a **General** page with all options. `/cip config` opens
  settings directly on the General page.
- **Slash commands.** `/cip`, `/charinspect`, and `/charinspectplus` with
  `help`, `config`, `modules`, and `toggle <module>`.
- **Inspect average item level.** Readout above the weapon slots, refreshed via
  `C_PaperDollInfo.GetInspectItemLevel` with Midnight Secret guards.
- **Character model zoom.** `OrbitCamera` zoom scaling on the gear tab
  (`ModelScene` has no `SetCamDistanceScale`).
- **Developer rules.** `.cursor/rules/` conventions for Midnight Secret Values,
  patch 12.0.7 notes, and code style.

### Changed
- **Interface `120007`.** Targets Revelations / patch 12.0.7 retail.
- **Single module.** `CharacterFrames` combines the former `CharacterFrame` and
  `InspectUI` modules.
- **Secret value guards.** `F.NotSecret()` wraps inspect class textures and
  item level display (replaces raw `issecretvalue` checks).
- **Item slot styling.** Only frames whose name contains `Slot` are resized,
  so buttons like **Inspect Talents** keep their correct size.
- **Inspect layout.** Non-gear tabs restore Blizzard `ButtonFrameTemplate`
  inset anchors instead of reusing the widened paper-doll inset.

### Fixed
- **Reputation and Currency tabs.** The `UpdateSize` hook no longer forces the
  paper-doll inset anchor on Rep/Currency; Blizzard's width (`400`) and
  `BOTTOMRIGHT` inset are left intact.
- **Collapsed character gear tab.** Widened `640×431` layout applies only when
  `CharacterFrame.Expanded` is true; collapsed gear respects Blizzard sizing.
- **Inspect PVP and Guild tabs.** Default panel size and dual-anchor inset
  restored when leaving the gear tab (button-bar offset matches each subframe).
- **Combat lockdown.** Layout restores deferred to `PLAYER_REGEN_ENABLED` when
  toggling off inside combat.

### Notes
- Stripped slot borders cannot be fully restored without `/reload` — layout,
  sizes, and backgrounds toggle live; texture stripping is one-way for the
  session.
- If you also run **NexEnhance**, disable its **Character Frames** skin module
  to avoid double-hooking the same UI.

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
