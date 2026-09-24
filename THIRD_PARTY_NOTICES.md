# Licenses and assets

## Offscreen

Original: https://github.com/dayaki/offscreen
Base commit: 1f519218f86477c955f02aba8a945473a6678add
Copyright (c) 2026 Dayo Akinkuowo — MIT.
The notice and permission text are retained in LICENSE and the app bundle.
The scheduler, original tests, native infrastructure, theme foundation derive from that repository. The former icon has been replaced in 2.2.

## Molaway

The two open rings are original vector artwork developed for this project with ChatGPT/Codex assistance, under the project MIT license. Shared geometry: Sources/Offscreen/Support/BrandGeometry.swift; renderer: Scripts/make-icon.swift. AppIcon.icns/AppIcon.png are generated from that geometry without downloaded assets or fonts. The same mark is used in the interface and adapted to timer progress in the menu bar. This is not trademark clearance.

Modifications: Burak Yelkenci, with ChatGPT/Codex assistance. MIT, subject to applicable rights. This project is not endorsed by OpenAI or the original Offscreen author.

Resources/Sounds/{soft,rise,fall,bell}.wav are simple sine-wave compositions generated for Molaway, distributed under the project MIT license. No third-party audio samples are used. The generation script is in Scripts/make-sounds.py.

System sound choices are played through macOS NSSound. Apple sound files and system symbol artwork are not copied into the repository. SF Symbols are referenced at runtime via Apple APIs.

No third-party Swift package dependencies are included. Apple SDK frameworks are provided by macOS/Xcode under Apple's terms.
