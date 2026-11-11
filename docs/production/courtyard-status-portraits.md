# Courtyard detailed status portraits

The bottom-left active-unit card uses a larger, smoothly filtered head-and-shoulder
portrait inside a restrained gold frame. It retains the active actor's name,
class, HP, MP, and armor values and does not change combat or selection behavior.

## Existing art, unchanged identity

In Compact appearance, Zane's mage skin and Kael's swordsman skin use bust crops
from the matching approved painterly sheets in
`demos/isometric-2v2/prototypes/isometric/assets/character-sets/painterly/originals/`.
Their source PNGs are untouched. These are the detailed counterparts of the
current class appearances, not a narrative recasting or new generated artwork.
The turn queue, forecasts, action banners, and battlefield sprites stay unchanged.

Original appearance retains its existing character-specific art. Enemies retain
their existing portrait crops. Unavailable detailed sources fall back to the
existing identity portrait; unknown identities return no image. Changing skin
or advancing a real turn refreshes the status portrait immediately. Inspecting
another combatant does not mix that combatant's portrait with the active unit's
resource values.

## Export and verification

The two detailed painterly source sheets are now intentionally included in the
standalone export presets. Other unused source sheets stay excluded. This avoids
a native-only result that silently falls back to compact portraits on the Web.

`tests/blooming_hud/StatusPortraitTest.tscn` covers sources, cached crops,
appearance changes, inspection, layout containment, resource preservation and
real turn progression. The existing HUD scale/layout tests cover accessibility
sizes and expanded/collapsed rails.

`tests/blooming_capture/StatusPortraitCapture.tscn` renders the real battle from
the exported production PCK at 1920×1080, 1366×768, 960×540, and an 844×390
landscape window using the existing canvas stretch. The release workflow saves
six screenshots in `courtyard-release-evidence/status-portraits/` and rejects
missing detailed packed resources. Landscape-window capture is not a physical
phone/touch, portrait-orientation, or performance acceptance claim.

This document describes the change and repeatable checks, not a deployment
claim. Verify the live `courtyard/build-info.json` for the deployed commit.
