#!/usr/bin/lua 

-- Copyright: (C) 2011 Robotics, Brain and Cognitive Sciences - Italian Institute of Technology (IIT)
-- Author: Ali Paikan <ali.paikan@iit.it>
-- Copy Policy: Released under the terms of the LGPLv2.1 or later, see LGPL.TXT


-- LUA_CPATH should have the path to yarp-lua binding library (i.e. yarp.so, yarp.dll) 
require("yarp")

-- initialize yarp network
yarp.Network()


--
-- load a log file
--
function load_log(filename)
  local file = io.open(filename, "r")
  if file == nil then
    print("cannot open '"..filename.."'")
    return nil
  end
  data = {}
  for line in file:lines() do      
      data[#data + 1] = line
  end
  file:close()
  print("'"..filename.."' is loaded!")
  return data
end

--
-- search in a table
--
function inTable(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return key end
    end
    return nil
end

--
-- splits string by a text delimeter
--
function string:split(inSplitPattern, outResults)
   if not outResults then
      outResults = { }
   end
   local theStart = 1
   local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
   while theSplitStart do
      table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
   end
   table.insert( outResults, string.sub( self, theStart ) )
   return outResults
end

function help() 
    local msg = [[
help            : show help
exit            : exit portadmin
load <filename> : loads a connections list file 
attach <portmonitor> <context> [send|recv] : attach a portmonitor to the list of connections
detach          : dettach any portmonitors from the list of connections
]]
    print(msg)
end

function attach(cons, plugin, context, side)
    if side ~= "send" and side ~= "recv" then
        print("'"..side.."' is not correct. Available options are 'send' and 'recv'.")
        return false
    end
    if cons == nil or #cons == 0 then
        print("Connections list is empty. Did you load any connection list file?")
        return false
    end
    for i=1,#cons do
        local ports = cons[i]:split(",")
        if #ports ~= 3 then
            print("Error while parsing the connection list file at line "..i)
            return false
        end
        -- triming the spaces
        src = ports[1]:match "^%s*(.-)%s*$"
        dest = ports[2]:match "^%s*(.-)%s*$"
        car = ports[3]:match "^%s*(.-)%s*$"
        local ret = yarp.NetworkBase_connect(src, dest,
                                 car.."+"..side..".portmonitor+context."..context.."+file."..plugin)
        if ret == false then
            print("Cannot connect '"..src.."' to '"..dest.."' using plugin '"..plugin.."'")
        end
    end
    return true
end

function detach(cons)
    if cons == nil or #cons == 0 then
        print("Connections list is empty. Did you load any connection list file?")
        return false
    end
    for i=1,#cons do
        local ports = cons[i]:split(",")
        if #ports ~= 3 then
            print("Error while parsing the connection list file at line "..i)
            return false
        end
        -- triming the spaces
        src = ports[1]:match "^%s*(.-)%s*$"
        dest = ports[2]:match "^%s*(.-)%s*$"
        car = ports[3]:match "^%s*(.-)%s*$"
        local ret = yarp.NetworkBase_connect(src, dest, car)
        if ret == false then
            print("Cannot reconnect '"..src.."' to '"..dest.."' using carrier '"..car.."'")
        end
    end
    return true
end

-------------------------------------------------------
-- main 
-------------------------------------------------------
logo = [[
                  _            _           _       
 _ __   ___  _ __| |_ __ _  __| |_ __ ___ (_)_ __  
| '_ \ / _ \| '__| __/ _` |/ _` | '_ ` _ \| | '_ \ 
| |_) | (_) | |  | || (_| | (_| | | | | | | | | | |
| .__/ \___/|_|   \__\__,_|\__,_|_| |_| |_|_|_| |_|
|_|

type 'help' for more information.
]]

print(logo)

if #arg > 0 then
    cons = load_log(arg[1])
end

repeat
    io.write(">> ") io.flush()
    local cmd = io.read()
    cmd = cmd:match "^%s*(.-)%s*$"
    if cmd == "exit" or cmd == "quit" then break end
    tokens = cmd:split(" ")
    -- loading the file
    if tokens[1] == "help" then
        help()
    elseif tokens[1] == "load" then
        if #tokens < 2 then 
            print("Usage: load <filename>.") 
        else
            cons = load_log(tokens[2]) 
        end
    elseif tokens[1] == "attach" then    
        if #tokens < 3 then 
            print("Usage: attach <portmonitor> <context> [send|recv].") 
        else
            local side = "recv"
            if #tokens > 3 then side = tokens[4] end
            attach(cons, tokens[2], tokens[3], side)
        end
    elseif tokens[1] == "detach" then    
        if #tokens > 1 then 
            print("Usage: detach") 
        else
            detach(cons)
        end

    else
        print("'"..cmd.."' is not correct. type 'help' for more information.")
    end
until false


