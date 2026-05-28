import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const plugin = readFileSync(".obsidian/plugins/embed-code-file/main.js", "utf8");
const styles = readFileSync(".obsidian/plugins/embed-code-file/styles.css", "utf8");
const docs = readFileSync("AI TOOLS/Embed Code File 使用说明.md", "utf8");

assert.match(
  plugin,
  /EMBED_CODE_FILE_RENDER_CLASS\s*=\s*"obsidian-embed-code-file-render"/,
  "plugin should mark every embed-code-file render container"
);

assert.match(
  plugin,
  /MAX_NESTED_EMBED_DEPTH\s*=\s*1/,
  "plugin should allow exactly one nested embed-code-file render"
);

assert.match(
  plugin,
  /nestedEmbedDepth\(el\)/,
  "plugin should count nested embed-code-file ancestors"
);

assert.match(
  plugin,
  /embedDepth\s*>\s*MAX_NESTED_EMBED_DEPTH/,
  "plugin should reject embeds deeper than one nested level"
);

assert.match(
  plugin,
  /const sourcePath = ctx\?\.sourcePath \|\| "";/,
  "code block processor should preserve Obsidian sourcePath for nested markdown rendering"
);

assert.match(
  plugin,
  /this\.applyLineComments\(el, lineNumbers, lineComments, sourcePath\)/,
  "line comment renderer should receive sourcePath"
);

assert.match(
  plugin,
  /renderCommentMarkdown\(el, text, sourcePath\)/,
  "comment markdown renderer should accept sourcePath"
);

assert.match(
  plugin,
  /parseLocalFootnotes\(text\)/,
  "comment renderer should parse local footnote definitions"
);

assert.match(
  plugin,
  /obsidian-embed-code-file-footnote-ref/,
  "comment renderer should create local footnote reference markers"
);

assert.match(
  plugin,
  /obsidian-embed-code-file-footnotes/,
  "comment renderer should append a local footnote section"
);

assert.match(
  plugin,
  /renderLocalFootnotes\(el, parsed, sourcePath\)/,
  "comment renderer should render local footnotes after markdown body rendering"
);

assert.match(
  plugin,
  /this\.renderCommentMarkdown\(footnoteBodyEl, footnote\.text, sourcePath\)/,
  "local footnote bodies should be rendered as markdown so code blocks and lists work"
);

assert.match(
  styles,
  /\.obsidian-embed-code-file-comment \.obsidian-embed-code-file-render/,
  "nested embed-code-file renders should have comment-specific spacing"
);

assert.doesNotMatch(
  plugin,
  /iconEl\.appendChild\(tooltipEl\)/,
  "icon comments should not keep tooltip content inside the icon"
);

assert.doesNotMatch(
  plugin,
  /iconEl\.setAttribute\("aria-label",\s*lineComment\.text\)/,
  "icon comments should not expose the full comment text through aria-label because Obsidian shows it as a duplicate tooltip"
);

assert.match(
  plugin,
  /lineRow\.appendChild\(tooltipEl\)/,
  "icon comment tooltip should be a code-row sibling so CSS can size it to the code columns"
);

assert.match(
  styles,
  /\.obsidian-embed-code-file-code-row:has\(\.obsidian-embed-code-file-comment-icon:is\(:hover,\s*:focus-visible\)\) > \.obsidian-embed-code-file-comment-tooltip/,
  "icon comment tooltip should be shown from the hovered or focused row icon"
);

assert.match(
  plugin,
  /obsidian-embed-code-file-comment-tooltip-content/,
  "icon comment tooltip should render markdown into a dedicated content area"
);

assert.match(
  plugin,
  /togglePinnedIconComment/,
  "icon comment tooltip should support pinning from the icon"
);

assert.match(
  plugin,
  /document\.body\.appendChild\(tooltipEl\)/,
  "pinned icon comment tooltip should move to document.body for stable fixed positioning"
);

assert.match(
  plugin,
  /pinnedParent/,
  "pinned icon comment tooltip should remember its original parent"
);

assert.match(
  plugin,
  /startDraggingIconComment/,
  "pinned icon comment tooltip should support dragging"
);

assert.match(
  styles,
  /\.obsidian-embed-code-file-comment-table[\s\S]*width:\s*100%/,
  "comment table should fill the code block width"
);

assert.match(
  styles,
  /\.obsidian-embed-code-file-comment-table[\s\S]*grid-template-columns:\s*max-content\s+minmax\(0,\s*1fr\)\s+max-content/,
  "comment table should allocate remaining code block width to the code column"
);

assert.match(
  styles,
  /\.obsidian-embed-code-file-comment-tooltip[\s\S]*grid-column:\s*1\s*\/\s*-1/,
  "icon comment tooltip should span the full code block grid"
);

assert.match(
  styles,
  /\.obsidian-embed-code-file-comment-tooltip[\s\S]*width:\s*100%/,
  "icon comment tooltip should use the full code block width"
);

assert.match(
  styles,
  /\.obsidian-embed-code-file-comment-tooltip\.is-pinned[\s\S]*position:\s*fixed[\s\S]*resize:\s*both/,
  "pinned icon comment tooltip should be fixed and resizable"
);

assert.match(
  docs,
  /嵌套 embed-code-file/,
  "usage docs should describe nested embed-code-file comments"
);

console.log("embed-code-file nesting regression checks passed");
