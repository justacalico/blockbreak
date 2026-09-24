# BlockBreak

An incremental idle mining game. Swing your pickaxe, shatter blocks, collect
resources, craft stronger pickaxes, and dig through every biome from the
Plains to The End.

## Features

- Tap (or hold) to swing your pickaxe and break blocks
- 10 upgradeable pickaxe tiers, each with its own strength and crit chance
- 12 biomes to unlock, each with unique blocks and gear
- PPS gear that mines for you, even while the app is closed
- Chests with random loot, rare blocks, and pickaxe drops
- Abilities that permanently boost your mining
- Prestige: convert your haul into Runic and start over stronger
- Fully offline, progress is saved automatically

## Install

### Android
Download the signed APK or AAB from the
[releases page](https://gitlab.com/HttpAnimations/blockbreak/-/releases).

### iOS (AltStore)
Add the AltStore source and install the IPA:
`https://httpanimations.gitlab.io/blockbreak/altstore/apps.json`

### Linux
`.tar.gz`, `.zip`, `.deb`, `.rpm`, and `.AppImage` builds are published on the
releases page for x86_64 and arm64.

### Windows / macOS
Windows `.zip` (x86_64 + arm64) and macOS `.dmg`/`.zip` (arm64) are on the
releases page.

### Web
The latest release is playable at
`https://httpanimations.gitlab.io/blockbreak/`.

## Development

```bash
flutter pub get
flutter test --coverage
flutter run
```

Versioning is handled by [cocogitto](https://github.com/cocogitto/cocogitto).
Commits must follow Conventional Commits (`type: 描述`). Never edit
`CHANGELOG.md` or the version in `pubspec.yaml` by hand; `cog bump` generates
both.

## License

[AGPL-3.0](LICENSE)
