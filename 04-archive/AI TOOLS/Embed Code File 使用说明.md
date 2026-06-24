# Embed Code File 使用说明

本文记录本地 `Embed Code File` 和 `Code Link` 插件最近增加的代码块显示能力。

## 重新加载

修改插件文件后，需要重载插件或重启 Obsidian，设置项和样式才会生效。

## 自动换行

### Embed Code File

在 Obsidian 设置中打开:

`Community plugins` -> `Embed Code File` -> `Wrap code blocks`

效果:

- 关闭: 代码长行保持单行，通过横向滚动查看。
- 打开: 代码长行自动折行。

单个 `embed-*` 代码块可以用 `WRAP` 覆盖全局设置:

````md
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "336-337,407-419"
TITLE: "type_initialize() properties"
WRAP: false
```
````

`WRAP` 支持 `true` 或 `false`。写了 `WRAP` 时，以当前代码块参数为准；不写时，使用插件设置页里的全局 `Wrap code blocks`。

### Code Link

在 Obsidian 设置中打开:

`Community plugins` -> `Code Link` -> `Wrap code blocks`

效果同上。这个开关会影响 `Code Link` 的 embed 预览和 hover 预览。

## 显示源码行号

在 Obsidian 设置中打开:

`Community plugins` -> `Embed Code File` -> `Show line numbers`

行号使用源码原始行号，不是展示片段从 1 开始的行号。

示例:

````md
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "336-337,407-419"
TITLE: "type_initialize() properties"
```
````

如果 `LINES` 跳过了中间代码，插件会显示省略号行。省略号行不占源码行号。

## 折叠代码块

`Embed Code File` 支持按代码块单独开启折叠。

```yaml
FOLDABLE: true
COLLAPSED: false
```

参数含义:

- `FOLDABLE: true`: 标题栏可点击折叠或展开代码块。
- `COLLAPSED: true`: 初始状态折叠。默认是 `false`。

示例:

````md
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "336-337,407-419"
TITLE: "type_initialize() properties"
FOLDABLE: true
COLLAPSED: true
```
````

折叠状态不会写入文件，也不会持久化到本地存储。重新渲染后，以 `COLLAPSED` 参数作为初始状态。

## 单个代码块字号

`Embed Code File` 支持用 `FONT_SIZE` 单独设置当前代码块字号。

```yaml
FONT_SIZE: "14px"
```

支持的单位:

- `px`
- `em`
- `rem`
- `%`

示例:

````md
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "336-337,407-419"
TITLE: "type_initialize() properties"
FONT_SIZE: "13px"
```
````

不写 `FONT_SIZE` 时，使用 Obsidian 当前代码块默认字号。

## 行注释

`Embed Code File` 支持按源码原始行号添加注释。

基本写法:

````md
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "336-337,407-419"
TITLE: "type_initialize() properties"
COMMENTS:
  407: "这里设置当前 TypeImpl 的 class type"
  410: "调用父类 class_base_init"
```
````

### 注释显示方式

通过 `COMMENT_STYLE` 设置默认显示方式:

```yaml
COMMENT_STYLE: "above"
```

支持三种值:

- `above`: 注释显示在目标代码行上一行。默认值，适合长说明。
- `inline`: 注释显示在目标代码行右侧，适合短说明。
- `icon`: 行号旁显示 `!` 图标，鼠标悬停查看注释；点击 `!` 可固定注释窗口，固定后可拖动、缩放和关闭。

示例:

````md
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "336-337,407-419"
TITLE: "type_initialize() properties"
COMMENT_STYLE: "above"
COMMENTS:
  407: "默认使用 above"
  410:
    style: "inline"
    text: "这一条覆盖为行尾注释"
  414:
    style: "icon"
    text: "这一条覆盖为图标注释"
```
````

单条注释可以用字符串，也可以用对象:

```yaml
COMMENTS:
  407: "短注释"
  410:
    style: "inline"
    text: "带独立显示方式的注释"
```

## 多行注释

多行注释建议使用 YAML 的 `|-`:

```yaml
COMMENTS:
  407: |-
    第一行说明。
    第二行说明。
```

如果注释是对象，则 `text` 也可以使用 `|-`:

```yaml
COMMENTS:
  414:
    style: "icon"
    text: |-
      第一行说明。
      第二行说明。
```

## Markdown 注释

注释内容支持 Markdown，例如加粗、行内代码、列表和链接。

```yaml
COMMENTS:
  2305: |-
    **CPU model name**, e.g.

    - `qemu64`
    - `phenom`
    - `Haswell`

    等等
```

列表在注释框里会使用紧凑间距，避免普通 Markdown 正文列表那种较大的段落间距。

## 局部脚注标注

注释内容里可以使用局部脚注，把上方正文里的标记和下方解释联系起来。语法接近 Markdown 脚注，但只在当前注释框内部生效，不会污染整篇笔记的脚注编号。

基本写法:

```yaml
COMMENTS:
  9746:
    style: "icon"
    text: |-
      `~host_feat`[^host] 表示 host/KVM 不支持的 features。
      `requested_features & ~host_feat`[^mask] 得到 unavailable_features。

      [^host]: host(kvm) 不支持 guest 设置的 features。
      [^mask]: guest 请求了，但是 host 不支持。
```

渲染后，正文里的 `[^host]`、`[^mask]` 会变成 `[1]`、`[2]` 这样的上标标记，下方会生成对应解释区。

### 大段脚注和代码块

脚注文本较长，或者需要写代码块时，使用 `|-` 块级写法:

````yaml
COMMENTS:
  9746:
    style: "icon"
    text: |-
      `host_feat`[^host] 是 host 支持能力的 mask。
      `unavailable_features`[^unavailable] 表示 guest 请求但 host 不支持的部分。

      [^host]: |-
        `host_feat` 来自 KVM/host 的能力查询。

        这里可以写多段说明，也可以写列表:

        - bit 为 1: host 支持
        - bit 为 0: host 不支持

        ```c
        uint64_t host_feat =
            x86_cpu_get_supported_feature_word(NULL, w);
        ```

      [^unavailable]: |-
        这个表达式保留 guest 请求但 host 不支持的 bits:

        ```c
        unavailable_features = requested_features & ~host_feat;
        ```
````

长脚注或包含代码块的脚注默认折叠，避免注释窗口被大段解释撑得太长。

### 脚注交互

- 鼠标悬停正文里的 `[1]`，下方对应脚注会高亮。
- 鼠标悬停下方脚注标题，正文里对应的 `[1]` 会高亮。
- 点击正文里的 `[1]`，会展开对应脚注，并滚动到该脚注位置。
- 脚注标题可以点击展开或折叠。
- `icon` 注释窗口固定后，脚注联动仍然只在当前注释窗口内生效。

## 嵌套 embed-code-file

`COMMENTS` 里的 Markdown 可以再写一层 `embed-*` 代码块，用来在注释中展开相关源码片段。

外层代码块建议使用 4 个反引号，这样内层的 3 个反引号不会提前结束外层代码块:

`````md
````embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "407-419"
TITLE: "type_initialize() caller"
COMMENTS:
  410: |-
    这里可以展开另一个源码片段:

    ```embed-cpp
    PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
    LINES: "336-337"
    TITLE: "parent snippet"
    ```
````
`````

嵌套深度限制为一层:

- 顶层 `embed-*`: 支持。
- 顶层注释里的内层 `embed-*`: 支持。
- 内层 `embed-*` 的注释里继续嵌套: 不支持，会显示 `ERROR: nested embed-code-file depth limit exceeded`。

## 完整示例

````md
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
LINES: "2303-2344"
TITLE: "X86CPUModel, X86CPUDefinition"
FOLDABLE: true
COLLAPSED: false
FONT_SIZE: "13px"
WRAP: false
COMMENT_STYLE: "above"
COMMENTS:
  2305: |-
    **CPU model name**, e.g.

    - `qemu64`
    - `phenom`
    - `Haswell`

    等等
  2306:
    style: "inline"
    text: "CPUID 基本功能范围的最高叶子号"
  2320:
    style: "icon"
    text: |-
      这里比较关键。

      用来描述 model 的各个 feature leaf。
```
````

## 注意事项

- `COMMENTS` 的 key 必须是源码原始行号。
- 注释只会匹配实际展示出来的源码行。
- 省略号行不会显示源码行号，也不会匹配注释。
- `WRAP` 和 `FONT_SIZE` 只影响当前代码块。
- `FOLDABLE` 依赖标题栏；如果没有手写 `TITLE`，插件会使用文件路径作为标题。
- `icon` 模式适合不想打断代码阅读的长说明。
- 行尾注释 `inline` 更适合短句，长 Markdown 列表建议使用 `above` 或 `icon`。
