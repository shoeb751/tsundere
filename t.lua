#! /usr/bin/env lua

-- Keep the above line empty, nix uses to inject package.path
--[[--
Main command line interface to execute library
functions

This script expects the following directory structure:

```
├── lib
│   ├── binoverride.lua
│   ├── http.lua
│   ├── json.lua
|   ...
├── mods
│   ├── 01_main
|   ...
├── t -> t.lua
└── t.lua

```

`mods` directory contains a list of directories that will be called *Collection*.
Each *Collection* contains lua files, each containing a lua module.

`lib` directory contains a list of lua files containing universal modules that are
either needed by the `t` script, or by modules in the Collection.

TODO: Convention to add dependedncy listing for modules in *Collection*s

This script has been written in such a
way that you should be able to execute moudules
in `mods` by just scoping them on command line
For Eg.
```bash
$ t sys init
```
will run the `init` function in `mods.*.sys` module
iterating over each directory, one at a time

To pass arguments to the functions, you can just
append them to the command line and they will appear
in order to the library function.
For Eg.
```bash
$ t sys init hello world
```
is equivalent to calling:
```lua
local sys = require ("modules.diri.sys")
sys.init("hello","world")
```
for all instances of diri in the `mods` directory

Need to make documentation more clear
@script t
]]

--[[
Feature: Module directory should be configurable
Options:
    * Environment Variable? (Simplest to implment,
    most difficult for users to use)
    * Command Line? (This is not possible,
    as this will change the functionining
    and require implementing a command line parser)
    * Config file? (Can be implemented, but will also be good
    to have an API to change the configs etc. Config params will
    namespaced, and "modules can access their configs only"?)
]]
__DEBUG = os.getenv("LUA_DEBUG") or false
--[[
Feature: File logging with debug capabiliy
This will use the mlib library that is created for this purpose
mlib needs to be loaded once the package path has been updated
or it will not be able to find it
I had initially created a seperate file for this, but adding code here
is the easier way to proceed as a lot of tooling will need changing
if this file stays in a non standard location
This is kind of the Core Functionality of tsundere, and hence having it
in this file should be OK, if it is demarcated properly
]]

-- Config related
--[[
This is suppsed to get config from the config file
It assumes that the configs are in lua format
and can be included without any issues

-- Need to figure out the safety of loaded config
This allows to include config just once and validates that
eveything is strings. If anything else is encountered
Then importing is aborted.
-- Need to add pcall for config require, so that things do not
-- fail when config require fails if file not present etc
Sample config file
```
$ cat ~/.config/tsundere/config.lua
local config = {}

config.log = {}

config.log.file = "<log file location>"

return config
```
]]
-- get config
local package_path_old = package.path
-- TODO: remove the hardcode in future if possible
package.path = string.format("%s/.config/tsundere/?.lua", os.getenv("HOME"))
local config = require("config")
package.path = package_path_old
-- end get config
-- Log Related
--[[
This is a simple logging module to make sure that
tsundere is easy to debug.
Will have a basic implementation.

I rather not mess with the print API here
But just remember that I had that thought
I did not go ahead with it as a lot of current
modules require access to print to interact with the terminal
and there is no easy way to confirm that the modified print behavior
does not break anything
]]
local log = {}
local local_config = {}
local log_ts = "%Y-%m-%d %X +08"

function log.init(cfg)
    local_config = cfg
end

--[[
p = print
Normal print, but will go to file rather than terminal
]]
function log.p(...)
    local write_fd
    local ok, log_fd, err = pcall(io.open, local_config.file, "a+")
    -- if it fails to open the file
    -- ok can be true and log_fd will be nil
    -- this allows printing to terminal when log file cannot be opened
    -- Can break program if stderr is not redirected (which it should be before piping)
    if not ok or not log_fd then
        write_fd = io.stderr
        write_fd:write(string.format("Log Open failed: %s\n", err))
    else
        write_fd = log_fd
    end
    local ts = tostring(os.date(log_ts))
    local function write_line(fd, line, debug)
        if debug then
            fd:write(string.format('%s [DBG] %s\n', ts, line))
        else
            fd:write(string.format('%s [INF] %s\n', ts, line))
        end
    end
    local logline_table = {}
    local first_arg = select(1, ...)
    local debug_enabled = first_arg == "[DBG]"
    for i, v in ipairs({ ... }) do
        if debug_enabled and i == 1 then
            -- table.insert(logline_table, tostring(v))
        else
            table.insert(logline_table, tostring(v))
        end
    end
    local logline = table.concat(logline_table, " ")
    for i1 in string.gmatch(logline, '[^\r\n]+') do
        if debug_enabled then
            write_line(write_fd, i1, true)
        else
            write_line(write_fd, i1)
        end
    end
    write_fd:close()
end

--[[
d = debug output
Will have a conditional to print only
when debug flag is on
]]
function log.d(...)
    if __DEBUG then
        log.p("[DBG]", ...)
    end
end

log.init(config.log or {})
local l = log.p or print -- log: print to file
local p = print          -- print to stdout
local d = log.d or print -- debug to file

d("Tsundere mlib Initialised")
-- END Core Functionality Function Definitions
-- END mlib

local MOD_DIR = os.getenv("T_MOD_DIR") or nil
local LIB_DIR = os.getenv("T_LIB_DIR") or nil
d("Mod_Dir_env:", MOD_DIR)
d("Lib_Dir_env:", LIB_DIR)
-- Setting up paths relative to binary
--local path_to_binary = arg[0]
local cmd = "realpath " .. arg[0]
local cmd_run = assert(io.popen(cmd), "Binary Path Find Failure")
local path_to_binary = cmd_run:read('*a'):gsub('\n$', '')
cmd_run:close()
local path_to_binary_directory = string.gsub(path_to_binary, '/+t.lua$', '')

-- there might be problems with finding the proper path,
-- but that will just lead to the script to fail rather
-- than run random code. No not adding a check to see if
-- the path we get is proper

package.path = package.path .. ";" .. path_to_binary_directory .. "/?.lua"


-- Adding LIB_DIR to the package.path

if LIB_DIR then
    package.path = package.path .. ";" .. LIB_DIR .. "/?.lua"
end

-- local helper functions

HELPTEXT = [[
Usage:
    t <module-name> <function-name> [<arg1> <arg2> ...]
For eg.
    t test get_repos shoeb751
    Will run get_repos("shoeb751") contained in test.lua
    in the first sequential dir in the mods directory
]]

local function help_exit(inp)
    local out = inp or "Unknown Error"
    p("ERROR: " .. out)
    p(HELPTEXT)
    os.exit(1)
end


-- override for invoking the command using different names and tying the name to specific functions
local binary_name = string.match(arg[0], '[^/]+$')

--[[
Feature: Binary Override
This allows for the program to autoload a module without actually specifying it
by running the program using a custom binary name which is a symbolic link to
the original `t` binary

Lets say, you want to run:
```
t redQ ping
```
But you use reqQ module a lot, and want a faster way to access it.
We will first symlink a new binary `red` to point to `t`, and we will
add the following entry in the binary override table:
Binary override table example:
```
local binary_override_table = {
    red = function ()
        table.insert(arg, 1, "redQ")
    end
}
```
This will make the following two commands equivalent:
```
t reqQ ping

red ping
```
for faster access you can make your shortcut to be `r` instead
]]


local ok, binary_override_table = pcall(require, "lib/binoverride")

if ok and binary_override_table and binary_override_table[binary_name] then
    binary_override_table[binary_name]()
end

-- Check for proper invocation
if #arg < 2 then
    help_exit("Insufficient Arguments")
end

-- MOD_DIR based logic
local mod_dir = string.format("%s/mods", path_to_binary_directory)
if MOD_DIR then
    mod_dir = MOD_DIR
end

-- get directories in modules folder
local cmd_mods = 'cd ' .. mod_dir .. " 2>/dev/null && find -L . -maxdepth 1 -mindepth 1 -type d"
local cmd_mods_run = assert(io.popen(cmd_mods), "Could not find modules")
local modules_string = cmd_mods_run:read('*a')
cmd_mods_run:close()
d("Modules String:", modules_string)
local modules_table = {}
for i, v in modules_string:gmatch('[^\n]+') do
    local modname_temp = i:gsub('^%./', '')
    table.insert(modules_table, modname_temp)
end

-- check for the existence of the module in all directories
local mod = nil

-- keeping a copy of the package path
local ppath = package.path
for i, v in ipairs(modules_table) do
    local modname = arg[1]
    -- change package path to allow module load
    -- Update path to add the loaded modules dir
    package.path = table.concat({
        ppath,
        mod_dir .. "/" .. v .. "/?.lua",
        mod_dir .. "/" .. v .. "/?/init.lua" }, ";")
    local ok, mod_load = pcall(require, modname)
    if ok then
        mod = mod_load
        break
    else
        d("Checking for module in: ", v)
        d(ok, mod_load)
    end
end

-- if no module is loaded, mod will be empty
if mod == nil then
    help_exit("Module Does not exist")
end

-- Implementing Help for all modules
--[[
TODO: Rethink the help funtion
Right now the info function is awesome to use,
But as it is directed towards writing to stdout rather
than returning a value, it is difficult to integrate
with the help function
Need to think if this is required anymore
]]
mod.help = function()
    p("Functions Available:\n")
    for k, v in pairs(mod) do
        d("---")
        d(k)
        d("--")
        d(mod.info(k))
        d("-")
        p(k .. ": " .. tostring(mod.info(k) or nil))
    end
end

-- Implementing coditional info for all modules
if not mod.info then
    mod.info = function()
        return "No info"
    end
end

local func = mod[arg[2]]
if not func then
    help_exit("Function does not exist")
end
func(table.unpack(arg, 3))
