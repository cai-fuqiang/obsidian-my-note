<claude-mem-context>
# Memory Context

# [obsidian-my-note] recent context, 2026-05-27 1:13pm GMT+8

Legend: 🎯session 🔴bugfix 🟣feature 🔄refactor ✅change 🔵discovery ⚖️decision 🚨security_alert 🔐security_note
Format: ID TIME TYPE TITLE
Fetch details: get_observations([IDs]) | Search: mem-search skill

Stats: 16 obs (4,914t read) | 87,187t work | 94% savings

### May 21, 2026
S125 Diagnose why obsidian-code-link plugin shows directories but not files in Obsidian vault (May 21 at 1:52 PM)
S123 Debug why code-link Obsidian plugin shows directories but not files (May 21 at 1:52 PM)
222 1:54p 🔵 Obsidian code-link plugin shows only directories, not files
223 " 🔵 Investigating code-link plugin directory-only display bug
224 1:57p 🔵 Obsidian code-link plugin only shows directories, not files
225 " 🔵 code-link plugin only defines tree-sitter queries for 7 languages
226 " 🔵 Located `lang_ext_default` definition in code-link plugin source
228 " 🔵 Mapped full query construction flow for code-link symbol extraction
229 " 🔵 Confirmed `_tagsScm()` simply returns `LangScmMap[this._name]` — return value is null for unsupported languages
227 " 🔵 code-link `lang_ext_default` covers ~30+ languages, far exceeding 7 in `LangScmMap`
230 1:58p 🔵 Located `CodeFileParser` class at main.js:16158
231 " 🔵 Confirmed exact parse pipeline: `getLang`→`_langLoader.load`→`tagsQuery()`→`TagTree`
232 1:59p 🔵 `LangLoader.load()` throws, not returns null, for unsupported languages
233 " 🔵 C files in QEMU project need tree-sitter WASM package download despite C being supported
234 2:00p 🔵 code-link Obsidian plugin SCM query path identified
235 " 🔵 Code-link plugin Python SCM query only covers class and function definitions
236 2:01p 🔵 C/C++ SCM queries exist but limited in code-link plugin
237 2:05p 🔵 Code-link plugin SCM query coverage varies widely by language
S126 Diagnose obsidian-code-link plugin showing directories but not files in Obsidian vault (May 21 at 2:11 PM)
S127 Diagnose obsidian-code-link plugin showing directories but not files in Obsidian vault (May 21 at 2:13 PM)
S129 检查现有资源 — 做之前先看有没有现成的 (May 21 at 2:14 PM)
S128 Obsidian plugin to reference code blocks from elixir.bootlin.com or GitHub projects (May 21 at 2:57 PM)
**Investigated**: Nothing yet — no tool executions or file operations observed in primary session

**Learned**: User wants an Obsidian plugin that can fetch/embed source code from Bootlin's Linux cross-reference (elixir.bootlin.com) or GitHub repos, likely for embedded/kernel development note-taking in Obsidian

**Completed**: No work has started. Session is in early ideation phase only.

**Next Steps**: Session appears to be awaiting initial investigation — likely next steps: explore Obsidian plugin structure, research elixir.bootlin.com API, design plugin architecture


Access 87k tokens of past work via get_observations([IDs]) or mem-search skill.
</claude-mem-context>