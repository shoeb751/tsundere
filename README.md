# Tsundre

A tool to create shell automation sequences using lua
For documentation, visit https://github.shoeb.pw/tsundre

## Getting Started:

1) Clone this repo:
   ```
   git clone https://github.com/shoeb751/tsundere.git && cd tsundere
   ```
2) Add it to your PATH - without this you will have to use absolute path
   of the `t` binary
3) Clone some modules to `mods` dir: 
   `mkdir mods && cd mods && git clone https://github.com/shoeb751/tsundere_basic_mod.git testmod`
4) Call the module using t <modname> <function_name> [<func_arg_1> <func_arg_2> ...]
   For eg. `./t test get_repos shoeb751`
5) You should be able to use help for a module by running: `./t test help`
6) Note that to run the test, you will need luasocket and luasec libraries
   installed as they are not included in this project.

## Contributing

1) If more featues are desired, you can create an issue, and it can be discussed there.
2) I am open to contributions - just make sure that the code is clear and has
   ldoc compatible documentation

## Licence

1) I expect attribution if something is built on top of this
2) Do not sell this to to anyone - this is free software

## TODO

System for creating a config file, which lists down modules
and pulling those modules from either git or http zip/tar
by running a command like `t mod sync`

Config file will be: `mods.lua` (Added to repo as `mods.lua.sample`)

~~Need to decide where to keep the code for this, as mods is directory is not managed by git~~ Will be keeping the code in the test modules git repo, and in future make it to mean basic modules
