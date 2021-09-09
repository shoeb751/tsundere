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
will run the `init` function in `modules.*.sys` module
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
for all instances of diri in the modules directory

Need to make documentation more clear
@script t
]]
local path_to_binary = arg[0]
local cmd ="realpath " .. arg[0]
local cmd_run = io.popen(cmd)
local path_to_binary = cmd_run:read('*a'):gsub('\n$','')
cmd_run:close()
local path_to_binary_directory = string.gsub(path_to_binary, '/+t.lua$', '')

-- there might be problems with finding the proper path,
-- but that will just lead to the script to fail rather
-- than run random code. No not adding a check to see if
-- the path we get is proper

package.path = package.path .. ";" .. path_to_binary_directory .. "/?.lua"

-- local helper functions

HELPTEXT=[[
Usage:
    t <module-name> <function-name> [<arg1> <arg2> ...]
For eg.
    t test get_repos shoeb751
    Will run get_repos("shoeb751") contained in test.lua
    in the first sequential dir in the mods directory
]]

local function help_exit(inp)
    local out = inp or "Unknown Error"
    print("ERROR: " .. out)
    print(HELPTEXT)
    os.exit(1)
end

-- Check for proper invocation

if #arg < 2 then
    help_exit("Insufficient Arguments")
end

-- get directories in modules folder
local cmd = 'cd ' .. path_to_binary_directory .. "/mods && find -L . -maxdepth 1 -mindepth 1 -type d"
local cmd_run = io.popen(cmd)
local modules_string = cmd_run:read('*a')
cmd_run:close()

local modules_table = {}
for i, v in modules_string:gmatch('[^\n]+') do
    local modname_temp = i:gsub('^%./', '')
    table.insert(modules_table, modname_temp)
end

-- check for the existence of the module in all directories
local mod = nil
for i, v in ipairs(modules_table) do
    local modname = "mods." .. v .. "." .. arg[1]
    local ok, mod_load = pcall(require, modname)
    if ok then
        mod = mod_load
        break
    end
end

-- if no module is loaded, mod will be empty
if mod == nil then
    help_exit("Module Does not exist")
end

-- Implementing Help for all modules
mod.help = function()
    print("Functions Available:\n")
    for k, v in pairs(mod) do
        print(k)
    end
end
local func = mod[arg[2]]
if not func then
    help_exit("Function does not exist")
end
func(table.unpack(arg, 3))
