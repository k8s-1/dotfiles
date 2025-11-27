# Neovim Config

## Prerequisites
### Core neovim dependencies
- color-supported tty
- nerdfont (to see icons properly, e.g. MesloLGLDZNerdFont-Regular.ttf)
- ripgrep
- fzf
- fd

### Plugin dependencies
- npm (required to install bashls)
- shellcheck (required by bashls)

## LSP, linting, formatting
- install the language server via mason :Mason OR configure in mason.lua for persistence
- add it to init.lua to load it
- lsp handles linting and formatting

https://neovim.io/doc/user/lsp.html
```
:checkhealth vim.lsp
```

## Structure
```
.
├── init.lua
├── lua
│   ├── config
│   │   ├── autocmds.lua
│   │   ├── keymaps.lua
│   │   └── options.lua
│   └── plugins
│       └── plugin.lua
│       └── ...
└── README.md
```

Plugins are lazy-loaded by :Lazy package manager,
initialized in init.lua in the root directory.

:Lazy expects a list of lua tables containing plugin specs specs,
to structure the project efficiently, they are declared in the plugins folder.

Plugin git hashes are automatically version-controlled in lazy-lock.json.

## Disabling a plugin
Rename the .lua file suffix of plugins/plugin.lua
or delete the config file.

## Quick Lua guide
* Load a module
require() 

* Try..catch statement
pcall

* Lua hashmaps, called 'table'
{}
{a, b, 123}
{"someval"}

* Functions
function add (a)
  local sum = 0
  for i,v in ipairs(a) do
    sum = sum + v
  end
  return sum
end

* Variables
globalvar
local localvar

## Future Roadmap
- https://github.com/rmagatti/auto-session
- https://github.com/cljoly/telescope-repo.nvim?tab=readme-ov-file
- https://github.com/ahmedkhalf/project.nvim

## Workflow Tips
- ctrl+6 to toggle between current and alternative buffer
- :b <TAB> to browse buffers quickly

- C-w s split buffer horizontal
- C-w v split buffer vertical
- C-w = reset split size
- C-w o hide all except current buffer

:wrap toggle line wrap

- compare open splits
:windo diffthis

- sa, sd, sr -> vim surround

- zz -> centre view

- delete around pagragraph
dap

- get keybinds
:noremap

- navigate long doc
50%
- get to specific line
:600

- paste into word
viwp
- paste into quotes
vi"p
- paste another register into quotes
vi""2p



## Themes
### Currently supported plugin :colorscheme
- capuccin (default)
- gruvbox
- kanagawa
- everfrost


