# vim

My Vim configuration: a [vim-bootstrap](https://github.com/editor-bootstrap/vim-bootstrap)
baseline (generated 2023-09-26, `c` + `python`, molokai theme) plus a pile of
personal additions, kept in `~/.config/vim` and managed with
[vim-plug](https://github.com/junegunn/vim-plug).

## Install

One line, clones this repo into `~/.config/vim`, wires Vim to it, installs the
plugins and the bundled fonts:

```bash
curl -fL https://raw.githubusercontent.com/cshen/vim/main/install.sh | bash
```

Options go after `bash -s --`, for example
`curl -fL https://raw.githubusercontent.com/cshen/vim/main/install.sh | bash -s -- --skip-fonts`.

Prefer to drive it yourself? Clone and run the same script:

```bash
git clone https://github.com/cshen/vim.git ~/.config/vim
~/.config/vim/install.sh
```

If `~/.config/vim` already exists and is not empty the installer stops with
`~/.config/vim exists, remove it before u install`. That is deliberate: it will
not guess whether the directory holds your own edits. Move it aside or delete
it first:

```bash
mv ~/.config/vim ~/.config/vim.bak     # or: rm -rf ~/.config/vim
```

The one exception is running `install.sh` from inside an existing checkout at
`~/.config/vim`: that counts as an in-place install and skips the clone.

`install.sh --help` lists the flags: `--repo URL`, `--skip-plugins`,
`--skip-fonts`.

## What the installer does

1. Refuses to touch a non-empty `~/.config/vim` (see above).
2. Clones the repo there, or copies it when you run the script from a checkout
   somewhere else.
3. Makes sure Vim finds the config. Vim 9.1+ reads `~/.config/vim/vimrc` on its
   own through the XDG lookup, and this script probes for that. On older builds
   it writes a small `~/.vimrc` that puts the config directory on
   `runtimepath` and sources the real `vimrc`. If you already have your own
   `~/.vimrc` it is left untouched and the two lines you need are printed.
4. Runs `:PlugInstall` for the bundles listed in `vimrc`, then reports any
   plugin that did not land (it retries once first).
5. Copies `fonts/*.ttf` into `~/Library/Fonts` on macOS or
   `~/.local/share/fonts` on Linux, skipping files that are already identical.

## Requirements

Required: `vim` (8.0+, 9.1+ recommended), `git`, and `curl` for the one-liner.
The config also leans on a few optional tools, all of which degrade quietly
when missing:

| Tool | Used for |
| --- | --- |
| `rg` or `ag` | `,f` grepping, fzf file lists |
| `fzf` | `,e`, `,b`, `,y` pickers |
| `make` and a compiler | building `vimproc.vim` |
| `shellcheck`, `autopep8`, `pylint` | ALE linting of shell and Python |
| `shfmt` | `vim-shfmt` (formatting on save is off, `g:shfmt_fmt_on_save = 0`) |
| `age` | transparent editing of `*.age` files |
| `node` | GitHub Copilot (`:Copilot setup`) |
| Nerd Font | powerline glyphs in the status line and indent guides |

## Layout

| Path | What it is |
| --- | --- |
| `vimrc` | main config: plugins, options, mappings |
| `vimrc.local` | personal overrides and GUI/macOS specifics, sourced by `vimrc` |
| `autoload/plug.vim` | vendored vim-plug, so bootstrap needs no download |
| `fonts/` | Cascadia Code plus Caskaydia Cove Nerd Font |
| `install.sh` | installer described above |

The config also reads `~/.config/vim/vimrc.local.bundles` if you create it
(extra `Plug` lines, sourced inside `plug#begin`). Plugins live in
`~/.local/share/vim/plugged`, sessions in `~/.local/share/vim/session`, swap
files in `~/.local/share/vim`.

## Plugins

Navigation and files: `nerdtree`, `vim-nerdtree-tabs`, `fzf` + `fzf.vim`,
`tagbar`, `grep.vim`, `split-manpage.vim`.

Editing: `vim-commentary`, `tComment`, `delimitMate`, `supertab`, `ultisnips` +
`vim-snippets`, `vim-highlightedyank`, `vimproc.vim`.

UI: `vim-airline` plus themes, `molokai`, `indentLine`, `CSApprox`.

Git: `vim-gitgutter`, `vim-rhubarb`. **`vim-fugitive` is commented out** in
`vimrc`, so the `,g*` mappings and `,o` (`:GBrowse`) do nothing until you
re-enable it, easiest via `vimrc.local.bundles`.

Linting and language support: `ale`, `vim-shfmt`, `c.vim`,
`requirements.txt.vim`, `vim-fish`, `nushell-syntax-vim`, `typst.vim`,
`vim-applescript`, `copilot.vim`.

Sessions: `vim-session` + `vim-misc`. And `vim-bootstrap-updater`, which pulls
upstream vim-bootstrap changes into `vimrc`.

## Keys worth knowing

`<leader>` is `,`.

| Key | Action |
| --- | --- |
| `F2` / `F3` / `F4` | NERDTree find / toggle / Tagbar |
| `,e`, `,b`, `,y` | fzf files, buffers, command history |
| `,f` | project-wide grep |
| `,h` / `,v` | split / vsplit |
| `,sh` | terminal in the current window |
| `,z` `,x` | previous / next buffer, `,c` closes one |
| `,so` `,ss` `,sd` `,sc` | session open, save, delete, close |
| `,<space>` | clear search highlighting |
| `Tab` / `S-Tab` / `S-t` | next tab, previous tab, new tab |
| `Ctrl-j/k/l/h` | move between windows |
| `cc` | toggle comment |
| `YY`, `XX`, `,p` | yank, cut, paste via the system clipboard |
| `,ga` … `,gr` | fugitive commands (plugin currently disabled) |
| `++`, `--`, `==`, `;;` | font size up, down, reset, cycle (GUI) |

In insert mode `ttime` expands to the current timestamp and `F1` acts as Esc.
`n`/`N` keep matches centered, and modelines are honored (`modelines=10`).

## Customising

Put your own settings in `vimrc.local` (or in a separate file that it sources).
Keeping them there instead of in `vimrc` means `vimrc` stays close to the
upstream vim-bootstrap output.

Things you will probably want to touch in `vimrc.local`: the GUI font
(`g:fnt_types`, `g:fnt_sizes`, currently Cascadia Code at 13), the ALE linter
list (Python with `autopep8` + `pylint`, shell with `shellcheck`), the
trailing-whitespace-on-save autocmd, and the `age` key paths
(`~/.config/age/cs.priv.key`, `cs.pub.key`) for encrypted files.

Note that `vimrc.local` sets `set shell=/bin/bash`, `set clipboard=unnamedplus`
and points `runtimepath` at `/opt/homebrew/opt/fzf`, a Homebrew-on-macOS path.
Adjust those lines on other setups.

## Updating and removing

```bash
git -C ~/.config/vim pull     # config update, then :PlugUpdate inside vim
```

To uninstall:

```bash
rm -f ~/.vimrc                # only exists if the installer wrote the shim
rm -rf ~/.config/vim ~/.local/share/vim
```

Fonts copied into `~/Library/Fonts` (or `~/.local/share/fonts`) keep the repo's
file names, so you can remove those by name if you want them gone.

## Troubleshooting

`E185: Cannot find color scheme 'molokai'` or plugins missing: the bundles were
not installed, run `:PlugInstall` inside Vim (needs network access).

Garbled status line or indent guides: the font is missing, install
`fonts/CaskaydiaCoveNerdFont-*.ttf` and select it in your terminal.

Plugins are not loaded at all: check `:echo $MYVIMRC`. It should point at
`~/.config/vim/vimrc` (or `~/.vimrc` with the shim). A stray `~/.vimrc` or
`~/.vim/vimrc` takes precedence over the XDG path, which is why the installer
warns about it.
