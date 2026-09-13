# Official plugin registry template

Publish this directory as the root of `kevendai/Rainmeter_todo-plugin-registry` with GitHub Pages. The stable client reads `index-v1.json` from the Pages root and ignores entries whose `official` value is not `true`.

Before publishing:

1. Release each `.rwplugin` and `.sha256` from its own plugin repository.
2. Download the three release assets into one directory and run `pwsh ./scripts/Set-RegistryHashes.ps1 -PackageDirectory <path>`.
3. Run `pwsh ./scripts/Test-Registry.ps1` (the hash script also runs it automatically).
4. Enable GitHub Pages for the repository root.

The validation workflow rejects placeholders, duplicate IDs, non-official entries, malformed versions, non-GitHub release URLs, and mismatches between the index and per-plugin detail files.
