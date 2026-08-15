<div align="center">
  <img src="assets/local-image-test.png" width="120" alt="PeekMD Logo" />
  <h1>PeekMD</h1>
  <p align="center">
    <b>A fast, beautiful, native Markdown Quick Look and viewer for macOS</b>
  </p>
  <p align="center">
    <a href="https://github.com/oneloop/PeekMD/releases"><img src="https://img.shields.io/badge/release-v2.0.0-blue.svg" alt="Release" /></a>
    <a href="https://github.com/oneloop/PeekMD/actions"><img src="https://img.shields.io/badge/build-passing-brightgreen.svg" alt="Build Status" /></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License" /></a>
  </p>
</div>

---

## Features

- **CommonMark & GFM Support**: Complete AST-backed Markdown rendering.
- **Obsidian Extensions**: Callouts, wikilinks, math, footnotes.
- **Zero Configuration**: Works instantly with Finder Quick Look.

<details>
  <summary><b>Click to expand Installation & Build instructions</b></summary>

### Building from Source

1. Clone repository:
   ```bash
   git clone https://github.com/oneloop/PeekMD.git
   cd PeekMD
   ```

2. Build and run:
   ```bash
   ./Scripts/build.sh
   ```

</details>

## Comparison Table

| Feature | PeekMD | Basic QuickLook | Legacy Apps |
| :--- | :---: | :---: | :---: |
| GFM Tables | Yes | No | Partial |
| Tokenized Syntax Highlighting | Yes | No | Broken |
| LaTeX Math | Yes | No | No |
| Obsidian Callouts | Yes | No | No |

## Keyboard Shortcuts

Press <kbd>Space</kbd> in Finder to preview any `.md` file.
