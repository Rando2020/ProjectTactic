# Haste candidate verification — 2026-11-10

Base: `400f68f9272d69ada1fe090c73c32383cd59885f`. Engine: Godot 4.6.3 stable.

## Candidate checks

The actual Skills menu, ally target review, cancel, duplicate Confirm, one 10 MP charge, one status application, unchanged HP, 1.5× speed, refreshed projected order and unchanged actual CT are tested. Explicit lifecycle probes cover three target status ticks, movement, recipient death, reapplication, reduced motion, teardown and a fresh battle. The test seeds nondefault saved JP and learned ownership before entering practice and verifies they remain unchanged.

The original local run passed 47 focused assertions in source and exported PCK, 35 supported courtyard native scenes, the 78-script parser, GUI selection checks, 3,118 readability assertions, 183 Python tool tests and 35 Web-package tests. Independent review found and fixed the aura depth relative to the actor's actual z=10 visual; the effective-depth assertion first failed and then passed. Three staging checks cover unchanged production sources/art, overwrite refusal and recursive input/output refusal.

After the temporary workspace was replaced, the candidate source and tests were recovered from the recorded implementation, against the same unchanged base. All 47 focused native checks and all three staging checks passed again. A fresh-import log inspection then caught an autoload PNG preload error hidden by the engine's zero exit status. The clean-import log gate reproduced the failure before the fix; texture loading now occurs when the effect is instantiated, after import. No original production project files changed.

## Remaining gates

The isolated workflow checks fresh-import logs, captures four actual-engine images and exports a review-only Web package. CI and graphical inspection must be recorded before claiming rendered acceptance. Native headless or PCK validation is not browser, physical-touch, performance, full-match or audible-audio acceptance.

The PNG remains one static application layer with transform animation, not a newly authored animation sequence. It remains an unapproved source candidate. Neither `/courtyard/` nor `/tactics/` is modified or deployed by this change.
