# 资源导航

```dataviewjs
const get = (p, ...keys) => keys.map(k => p[k]).find(v => v != null);
const pages = dv.pages('"03-resource" and -"03-resource/1000-Templates"')
  .where(p => get(p, "show in nav", "show-in-nav") === true)
  .array();

const dir = p => p.file.folder.replace(/^03-resource\/?/, "").replace(/\d+-/g, "");
const date = v => !v ? "-" : v.toFormat ? v.toFormat("yyyy-MM-dd") : String(v).replace(/[ T].*/, "");
const status = s => ({ done: "✅", doing: "✏️", suspend: "⏸️" }[s] ?? "📋");

function alias(p) {
  const file = app.vault.getAbstractFileByPath(p.file.path);
  const aliases = app.metadataCache.getFileCache(file)?.frontmatter?.aliases;
  const first = Array.isArray(aliases) ? aliases.find(Boolean) : aliases;
  return String(first ?? "").trim() || p.file.name;
}

const link = p => dv.fileLink(p.file.path, false, alias(p));
const priority = p => get(p, "priority") ?? 99;
const created = p => get(p, "create date", "create-date");
const completed = p => get(p, "complete date", "complete-date");
const days = p => {
  const start = dv.date(date(created(p)));
  const end = dv.date(date(completed(p)));
  return start && end ? `${Math.round(end.diff(start, "days").days)}天` : "-";
};
const state = { name: "", priority: "", from: "", to: "" };
const root = dv.container;

function filtered() {
  return pages.filter(p => {
    const name = `${alias(p)} ${p.file.name}`.toLowerCase();
    const day = date(created(p));
    return (!state.name || name.includes(state.name.toLowerCase()))
      && (!state.priority || String(priority(p)) === state.priority)
      && (!state.from || day >= state.from)
      && (!state.to || day <= state.to);
  });
}

function input(label, key, type = "text") {
  const box = document.createElement("label");
  box.textContent = `${label} `;
  const el = document.createElement("input");
  el.type = type;
  el.dataset.key = key;
  el.value = state[key];
  el.oninput = () => {
    const start = el.selectionStart;
    const end = el.selectionEnd;
    state[key] = el.value.trim();
    render(key, start, end);
  };
  box.appendChild(el);
  return box;
}

function render(focusKey, start, end) {
  root.empty();
  const bar = root.createDiv();
  bar.append(input("名称", "name"));
  bar.append(input("优先级", "priority", "number"));
  bar.append(input("开始", "from", "date"));
  bar.append(input("结束", "to", "date"));

  const list = filtered();

  dv.header(2, "按优先级");
  dv.table(["文件", "优先级", "状态"],
  list
    .sort((a, b) => priority(a) - priority(b) || alias(a).localeCompare(alias(b)))
    .map(p => [link(p), priority(p), status(get(p, "status"))]));

  dv.header(2, "按目录");
  dv.table(["文件", "目录", "状态"],
  list
    .sort((a, b) => dir(a).localeCompare(dir(b)) || priority(a) - priority(b) || alias(a).localeCompare(alias(b)))
    .map(p => [link(p), dir(p), status(get(p, "status"))]));

  dv.header(2, "按日期");
  dv.table(["文件", "状态", "创建", "完成", "耗时"],
  list
    .sort((a, b) => String(created(b) ?? "").localeCompare(String(created(a) ?? "")))
    .map(p => [link(p), status(get(p, "status")), date(created(p)), date(completed(p)), days(p)]));

  if (focusKey) {
    const el = root.querySelector(`[data-key="${focusKey}"]`);
    el?.focus();
    el?.setSelectionRange?.(start, end);
  }
}

render();
```
