#! /usr/bin/env lua
--[[--
Main command line interface to execute library
functions

This script has been written in such a
way that you should be able to execute moudules
in lib by just scoping them on command line
For Eg.
```bash
$ t sys init
```
will run the `init` function in `lib.sys` module

To pass arguments to the functions, you can just
append them to the command line and they will appear
in order to the library function.
For Eg.
```bash
$ t sys init hello world
```
is equivalent to calling:
```lua
local sys = require ("lib.sys")
sys.init("hello","world")
```
@script t
]]

package.path = package.path .. ";/home/yui/data/work/Tsundere/?.lua"

local function help_exit(inp)
    local out = inp or "Help"
    print(out)
    os.exit(1)
end

if #arg < 2 then help_exit("Insufficient Arguments") end

local modname = "lib." .. arg[1]
local ok, mod = pcall(require,modname)
if not ok then help_exit("Module Does not exist") end

-- Implementing Help for all modules
mod.help = function()
    print("Functions Available:\n")
    for k,v in pairs(mod) do
        print(k)
    end
end
local func = mod[arg[2]]
if not func  then help_exit("Function does not exist") end
func(table.unpack(arg,3))