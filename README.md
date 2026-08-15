# PeekMD 📝

**PeekMD** is a lightweight, native macOS utility that brings the missing **"Create New Markdown File"** action to Finder's blank-background context menu and turns macOS Quick Look (**Spacebar**) into an instant, rich Markdown previewer.

---

## ✨ Features

- 📂 **Finder Right-Click Creation**: Right-click the empty background of any Finder window to immediately create a new `.md` file in that directory.
- 🛡️ **Collision-Safe**: Never overwrites existing files (`Untitled.md`, `Untitled 2.md`, `Untitled 3.md`, ...).
- 🔍 **Instant Quick Look Preview**: Select any Markdown file in Finder and hit **Spacebar** for sub-millisecond, formatted preview.
- 📊 **GitHub & Obsidian Syntax**:
  - GFM Tables with alignments
  - Task lists / Checkboxes (`- [ ]`, `- [x]`)
  - Fenced code blocks with language badges & syntax highlighting
  - Obsidian-style Callouts (`[!NOTE]`, `[!TIP]`, `[!WARNING]`, `[!IMPORTANT]`, `[!CAUTION]`)
  - LaTeX / Math expressions (`$...$`, `$$...$$`)
  - YAML frontmatter presentation
- 🖼️ **Local Asset Resolution**: Automatically renders relative local images (`images/diagram.png`).
- 🎨 **Adaptive Themes**: Beautiful Apple San Francisco typography with automatic Light/Dark mode and multiple style themes (System, GitHub, Minimal, Academic).
- 🖥️ **Integrated Standalone Viewer**: Full-fidelity document reader with live preview, word & line counters, and one-click "Edit in External Editor" actions.

---

## 🏗️ Architecture

```text
PeekMD (MarkdownFinder.app)
│
├── Main macOS App
│   ├── Settings & preferences
│   ├── Monitored location management
│   ├── Quick setup & onboarding guide
│   └── Standalone Markdown viewer
│
├── Finder Sync Extension (FIFinderSync)
│   ├── Blank-background container context-menu integration
│   ├── Collision-safe file creator
│   └── Auto-select in Finder via NSWorkspace
│
├── Quick Look Preview Extension (QLPreviewProvider)
│   ├── Spacebar instant preview for UTType.markdown (.md, .markdown)
│   └── Base64 local asset resolver
│
└── Shared MarkdownRenderer Package
    ├── CommonMark & GFM parser
    ├── HTML generator
    ├── Light/Dark CSS theme styles
    └── Math & Callout engines
```

---

## 🛠️ Building & Running

### Prerequisites
- macOS 13.0+
- Xcode or Command Line Tools with Swift 5.9+

### Automated Build & Test
```bash
# Run unit test suites (21 automated tests)
./Scripts/test.sh

# Build the complete .app bundle with embedded extensions
./Scripts/build.sh

# Install to ~/Applications and register Finder extensions
./Scripts/install_and_register.sh
```

---

## 📜 License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

Copyright © 2026 Ravindu Palihakkara.
