# BitForge Commit Message Protocol

## 1. Tone & Style

- **Detail Level:** Exhaustive. Do not summarize with "updated files." Explain _what_ changed inside the functions.
  - Exception: Files in `Locales/` folder.
- **Visuals:** Use emojis liberally to categorize change types.
- **Voice:** Professional yet expressive.

## 2. Structure Template

Every message must follow this structure:

### [Emoji] [Keyword] - [Action]

- **Action:** Brief summary of the high-level goal within 50 characters.

### 🏗️ Architecture

- List any updated widgets.

### ⚡ Performance & Caching

- Mention API optimizations.

### 🧹 Cleansing & Refactor

- Detail removed variables, sorted functions, or deleted dead code.

## 3. Emoji Mapping (Mandatory)

- 🚀 New Feature / Module
- 🐛 Bug Fix
- ⚡ Performance Tuning
- 🧹 Code Cleansing/Refactor
- 🏗️ Structural/MVC Change
- 📝 Documentation / Meta
