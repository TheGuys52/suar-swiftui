# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Suar is an iOS app for reading theater scripts with VoiceOver and accessibility support, powered by Vision OCR and AI-assisted script parsing. iOS 17+, SwiftUI, Feature-Driven MVVM-C architecture.

## Common Commands

```bash
# Generate Xcode project (run after every project.yml change or adding new files)
xcodegen generate

# Run SwiftLint
swiftlint

# Run SwiftLint with auto-fix
swiftlint --fix

```

## Architecture

### Pattern: Feature-Driven MVVM-C

Each feature lives under `Suar/Suar/Features/<FeatureName>/` with:
- `Coordinators/` or `<FeatureName>Coordinator.swift` — handles navigation and view wiring
- `Views/` — SwiftUI views
- `ViewModels/` or `<FeatureName>ViewModel.swift` — Observable view models

### App Layer

- [SuarApp.swift](Suar/Suar/App/SuarApp.swift) — entry point, sets up SwiftData container
- [DIContainer.swift](Suar/Suar/App/DIContainer.swift) — global service/repository registry (singleton)
- [AppCoordinator.swift](Suar/Suar/App/AppCoordinator.swift) — root coordinator, defines `AppRoute` enum

### Navigation

- [Router.swift](Suar/Suar/Core/Navigation/Router.swift) — `@Observable` NavigationPath wrapper, handles push/pop/sheet
- [AppRoute.swift](Suar/Suar/Core/Navigation/AppRoute.swift) — `Hashable` route enum for NavigationStack destination
- [CoordinatorProtocol.swift](Suar/Suar/Core/Navigation/CoordinatorProtocol.swift) — protocol each feature coordinator conforms to

### Data Flow: PDF Import → Parsing → Display

```
PDF File
  → VisionOCRService.extractText(from:)
    → [Int: String] (pageNumber → rawText)
  → AIScriptParserService.parseScript(rawPagesText:scriptTitle:sourceFileName:onProgress:)
    → Script (with ScriptPage → ScriptBlock hierarchy)
  → SwiftData (persisted via ScriptRepository)
  → ScriptPageViewModel (loaded from repository)
  → ScriptPageView (displayed to user)
```

### OCR + AI Parsing Pipeline (AIScriptParserService)

The AI parser processes pages in 3 phases:

1. **Page filtering**: Pages with <3 non-empty lines are excluded from AI processing (but still preserved as empty ScriptPage entries).
2. **Chunking**: Remaining pages are batched into chunks of 4 (configurable via `chunkSize` param). Each chunk → one LLM API call. The LLM returns a structured JSON response with `mergedStartBlock`, `newBlocks`, and `trailingUnresolvedBlock`.
3. **Page filling**: After all chunks, any original OCR page that received no blocks gets an empty ScriptPage entry. If the first page is empty (cover page), a `sceneHeader` block with the script title is inserted.

**ChunkParseResult fields**:
- `mergedStartBlock`: First block of the new chunk that continues an unresolved block from the previous chunk (content merged).
- `newBlocks`: All complete blocks parsed within the current chunk.
- `trailingUnresolvedBlock`: The last block of the chunk that is incomplete (`isTrailingResolved=false`) — carried forward to the next chunk.

**AI response format** (3-field JSON per block):
```json
{
  "type": "dialogue|sceneHeader|stageDirection",
  "characterName": "8. WANITA",
  "cueDescription": "(tersenyum)" | null,
  "content": "Dialogue text here",
  "startPage": 2,
  "endPage": 3 | null,
  "isTrailingResolved": false
}
```

**Ordinal number preservation**: Character names retain ordinal prefixes (e.g., "8. WANITA" stays "8. WANITA", not "WANITA"). Enforced in both the regex parser and the AI parser system prompt.

**Progress reporting**: `onProgress(currentPage, totalPages)` reports based on the last contentful page of each chunk. HomeViewModel maps this to `0.7 + (parseRatio * 0.20)` within the 70–90% parsing phase.

### Data Models (SwiftData)

- `Script` — top-level, has many `ScriptPage`
  - `pageCount`: Int — total original OCR page count
  - `lastReadPage`: Int — persisted reading position
- `ScriptPage` — one page's raw text, has many `ScriptBlock`
  - `pageNumber`: Int — 1-based page index
  - `blocks`: [ScriptBlock] — parsed content for this page
- `ScriptBlock` — individual parsed block (dialogue, stage direction, scene heading, etc.)
  - `orderIndex`: Int — global order across all pages
  - `startPageNumber: Int?` — page where this block starts (optional for migration safety)
  - `endPageNumber: Int?` — page where this block ends (null = single page)

Relationship chain: `Script` → `ScriptPage` → `ScriptBlock`

### Services

- `VisionOCRService` — Vision framework OCR. Takes a file URL (PDF/image) and returns `[Int: String]` mapping page number to raw extracted text.
- `ScriptParserService` — Rule-based script parser (regex state machine). Suitable for smaller scripts.
- `AIScriptParserService` — LLM-powered script parser using the Olagon Gateway. Batches pages into chunks (default: 4 pages/chunk) to prevent API timeout on large PDFs. Handles cover page detection, cross-page dialogue merging, and page boundary resolution. Uses `OLLAGON_API_KEY` from Info.plist.

Services are accessed via `DIContainer.shared.ocrService`, `DIContainer.shared.parserService`, `DIContainer.shared.scriptParserService`.

### Repositories

- `ScriptRepository` — SwiftData CRUD operations for Script/ScriptPage/ScriptBlock

### Dependency Injection

`DIContainer` is a `@unchecked Sendable` singleton. Register implementations after SwiftData `ModelContainer` is ready via `DIContainer.shared.configure(modelContext:)`.

### Core Utilities

- `Core/Accesibility/` — `AccesibleTouchTargetModifier` (44pt touch target), `ScriptCustomRotor` (VoiceOver rotor support)
- `Core/DesignSystem/UIColor+Theme.swift` — color tokens
- `Core/Mocks/` — mock implementations of services/repositories for testing

## Workflow Notes

- **Never commit `.xcodeproj`** — all target configuration lives in `project.yml`, run `xcodegen generate` after changes
- **Add new Swift files outside Xcode** → run `xcodegen generate` so Xcode picks them up
- **Branch naming:** `feat/<name>`, `fix/<name>`, `chore/<name>`
- **Commit messages:** conventional commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`)
- Lefthook runs `swiftlint --fix` on staged files pre-commit, `xcodegen generate` post-merge/post-checkout
- **AI Parser**: `AIScriptParserService` uses the Olagon Gateway LLM. API key in Info.plist (`OLLAGON_API_KEY`). Chunk size defaults to 4 pages/call. System prompt enforces 3-field JSON output and ordinal number preservation in character names.

## Testing

Tests live in `Suar/SuarTests/`. Uses ViewInspector for SwiftUI inspection. Mock implementations under `Core/Mocks/`.
