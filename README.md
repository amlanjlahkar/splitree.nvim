I don't use a filetree navigation system inside (neo)vim but occasionally when navigating through a comparatively large foreign codebase, it's nice to be able to know where and how a particular file is placed inside the project.

For this I wrote **`:Splitree`**, a user command which allows me to check current file's location inside current working directory.

[![demo](https://asciinema.org/a/632258.svg)](https://asciinema.org/a/632258)

---

## Requirements

- Neovim >= 0.8.0
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (for asynchronous process execution)
- The Unix `tree` command available in $PATH


## Installation and Usage

Install as any other normal plugin.

The `:Splitree` ex command can be registered through the `setup` method exposed by the `splitree` module.

It is possible to pass custom arguments to `tree` through the `args` key parameter.

> [!NOTE]
> Specify arguments one at a time to avoid possible conflicts

```lua
require("splitree").setup({
    args = { "-I", "node_modules" },
})
```

## Drawbacks

As of now, the logic that determines the location of the required file in the output buffer is quite fragile.
I wrote it to serve my need without worrying much about optimization and potential edge cases still be present which may lead to failure in identification.

Secondly, it's not compatible with windows at this moment.

PRs addressing any of these issues are encouraged and welcomed.
