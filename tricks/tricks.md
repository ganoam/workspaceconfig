# NVIM

## Attach a second UI to an already running server

find the address of the running server: `:echo v:servername`

attach a second UI: `nvim --server {addr} --remote-ui`

## format (for treesitter-supported languages):

`gg=G`
