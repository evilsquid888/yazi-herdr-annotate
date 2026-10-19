# yazi-herdr-annotate

Browse files in [Yazi](https://yazi-rs.github.io) inside [Herdr](https://herdr.dev), press
`Enter` on any text file, and review it in
[herdr-annotate](https://github.com/plannotator/herdr-annotate)'s plannotator-tui. Your
comments go straight to the agent you were working with.

herdr-annotate's own file tree (`Ctrl+B O`) only lists Markdown files. This glue lets you
comment on any text file: code, logs, config, plain text.

## How it works

```
Ctrl+B Y            Yazi opens in a split (herdr-yazi plugin)
Enter on a file     Yazi runs annotate-open.sh <file>
                    → plannotator-tui herdr open <file> --deliver-to <agent pane>
v / c / E           select, comment, send the review to the agent
```

The feedback goes to the agent pane that was focused when Yazi opened. If there isn't one,
it goes to the first agent in the same tab, then the first one in the same workspace.

## Requirements

- Herdr 0.9.3 or newer
- [plannotator/herdr-annotate](https://github.com/plannotator/herdr-annotate), the **Full** variant (it ships plannotator-tui)
- [speardragon/herdr-yazi](https://github.com/speardragon/herdr-yazi) and Yazi 25.x/26.x (uses the `%s1` opener syntax)
- `jq`, and `ya` (ships with Yazi) for the column-toggle plugin
- Linux or macOS

## Install

```sh
herdr plugin install plannotator/herdr-annotate
herdr plugin install speardragon/herdr-yazi
git clone https://github.com/evilsquid888/yazi-herdr-annotate
cd yazi-herdr-annotate && ./install.sh
```

`install.sh` copies `annotate-open.sh` into `~/.config/yazi/`, sets up the [column toggles](#column-toggles), and appends
`yazi-annotate.toml` to `yazi.toml`, backing that file up first. If your `yazi.toml` already
has an `[opener]` or `[open]` table, the script stops instead of appending, and you merge the
two tables by hand.

Then add the key bindings from [`herdr-keys.toml`](herdr-keys.toml) to
`~/.config/herdr/config.toml`, run `herdr server reload-config`, and restart Yazi.

## Which files open in annotate

- **By extension:** `md markdown mdx txt text log rst org adoc csv tsv`
- **By MIME type:** `text/*` (which covers most source code), JSON, YAML, TOML, XML, shell
  scripts, and empty files

Everything else (images, PDFs, archives) keeps Yazi's normal opener. Press `O` on a file to
pick a different opener, such as your editor.

## Column toggles

`install.sh` also installs Yazi's
[toggle-pane](https://github.com/yazi-rs/plugins/tree/main/toggle-pane.yazi) plugin and adds
these keys from [`yazi-keymap.toml`](yazi-keymap.toml). Press `Shift+T` and a menu of the
choices pops up.

| Keys | Does |
|---|---|
| `T` `p` | Show or hide the parent column (left) |
| `T` `c` | Show or hide the current column (middle) |
| `T` `r` | Show or hide the preview column (right) |
| `T` `T` | Preview fills the whole pane, then back to normal |

Press `~` or `F1` in Yazi to see every key binding.

## Gotchas this handles

- **Yazi 26 opener syntax.** The selected file is `%s1`, not `"$1"`. With `$1`, `Enter` does
  nothing.
- **Plugin environment.** Yazi runs inside the herdr-yazi plugin pane, so `HERDR_PLUGIN_ID`
  and its sibling variables point at `ray.file-explorer`. Without remapping them to
  `annotate`, plannotator-tui fails with `plugin pane entrypoint 'doc' not found`.

## Troubleshooting

Every open is logged to `~/.local/state/yazi/annotate-open.log`. Set `PLANNOTATOR_TUI` to
use a specific plannotator-tui binary.

## License

MIT
