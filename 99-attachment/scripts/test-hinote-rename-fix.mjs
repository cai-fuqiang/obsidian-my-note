import { readFileSync } from "node:fs";
import assert from "node:assert/strict";

const bundle = readFileSync(".obsidian/plugins/hi-note/main.js", "utf8");

assert.match(
  bundle,
  /vault\.on\("rename",async\(e,t\)=>\{try\{let A=await c\.ensureServicesInitialized\(\);await A\.highlightManager\.handleFileRename\(t,e\.path\)\}catch\(A\)\{console\.error\("\[HiNote\] Failed to migrate highlights after file rename:",A\)\}\}\)/,
  "rename handler should initialize HiNote services before migrating highlights",
);

assert.match(
  bundle,
  /async handleFileRename\(e,t\)\{let A=this\.getStoragePathForFile\(e\),i=Qe\.toSafeFileName\(t\),o=`\$\{Qe\.getHighlightsDir\(this\.vaultPath\)\}\/\$\{i\}`;try\{/,
  "highlight migration should compute the target storage path without creating a stale mapping first",
);

assert.doesNotMatch(
  bundle,
  /async handleFileRename\(e,t\)\{let A=this\.getStoragePathForFile\(e\),i=this\.getStoragePathForFile\(t\);try\{/,
  "highlight migration should not call getStoragePathForFile(newPath) before the old data is read",
);
