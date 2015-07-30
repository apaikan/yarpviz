#!/usr/bin/lua 

-- Copyright: (C) 2015 iCub Facility - Italian Institute of Technology (IIT)
-- Author: Ali Paikan <ali.paikan@iit.it>
-- Copy Policy: Released under the terms of the LGPLv2.1 or later, see LGPL.TXT


-- LUA_CPATH should have the path to yarp-lua binding library (i.e. yarp.so, yarp.dll) 
require("yarp")

-- initialize yarp network
yarp.Network()

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

--
--  gets a list of the yarp ports
--
function yarp_name_list() 
  local style = yarp.ContactStyle()
  style.quiet = true
  style.timeout = 3.0

  local cmd = yarp.Bottle()
  local reply = yarp.Bottle()
  cmd:addString("list")
  local ret = yarp.NetworkBase_writeToNameServer(cmd, reply, style)
  if ret == false or reply:size() ~= 1 then
    print("Error")
  end

  local str = reply:get(0):asString()
  local fields = str:split("registration name /")
  ports_map = {}
  for i = 1, #fields do
     local s = fields[i]
     local name = s:split("ip")
     name = name[1]:gsub("^%s*(.-)%s*$", "%1")
     if name ~= "" then
       name = "/"..name
       if name ~= yarp.NetworkBase_getNameServerName() then 
         ports_map[name] = "P"..i
       end     
     end     
  end
  return ports_map
end

function get_port_con(port_name)
  local ping = yarp.Port()  
  ping:open("/anon_rpc");  
  ping:setAdminMode(true)
  local ret = yarp.NetworkBase_connect(ping:getName(), port_name)
  if ret == false then
      print("Cannot connect to " .. port_name)
      return nil, nil, nil
  end
  local cmd = yarp.Bottle()
  local reply = yarp.Bottle()
  cmd:addString("list")
  cmd:addString("out")  
  if ping:write(cmd, reply) == false then
      print("Cannot write to " .. port_name)
      ping:close()
      return nil, nil, nil
  end  
  outs_list = {}
  outs_carlist = {}
  for i=0,reply:size()-1 do 
    out_name = reply:get(i):asString()
    outs_list[#outs_list+1] = out_name
    -- get the carrier
    cmd:clear()
    local reply2 = yarp.Bottle()
    cmd:addString("list")
    cmd:addString("out")
    cmd:addString(out_name)
    if ping:write(cmd, reply2) == false then
      print("Cannot write to " .. port_name)
      ping:close()
      return nil, outs_list, nil 
    end
    outs_carlist[#outs_carlist+1] = reply2:find("carrier"):asString()
  end 

  cmd:clear()
  reply:clear()
  cmd:addString("list")
  cmd:addString("in")  
  if ping:write(cmd, reply) == false then
      print("Cannot write to " .. port_name)
      ping:close()
      return nil, outs_list, outs_carlist
  end  
  ins_list = {}
  for i=0,reply:size()-1 do 
    ins_list[#ins_list+1] = reply:get(i):asString()
  end 
  ping:close()
  return ins_list, outs_list, outs_carlist
end

---------------------------------------------------------------------
---  main 
---------------------------------------------------------------------

param = ""
for i=1,#arg do
  param = param .. arg[i] .. " "
end
prop = yarp.Property()
prop:fromArguments(param)

if prop:check("help") then
  print("Usage: yarpviz.lua [OPTIONS]\n")
  print("Known values for OPTION are:\n")
  print("  --out  <output_name>\t Output file name (default: output.txt)")
  print("  --type <output_type>\t Output type: pdf, eps, svg, jpg, png, txt (default: txt)")
  print("  --gen  <generator>  \t Graphviz-based graph generator: dot, neato, twopi, circo (default: dot)")
  print("  --only-cons         \t Shows only the ports with a connections")
  os.exit()
end

local ports = yarp_name_list()

typ = "txt"
if prop:check("type") then typ = prop:find("type"):asString() end
if typ == "txt" then 
    -- creating dot file
    local filename = "output.txt"
    if prop:check("out") then filename = prop:find("out"):asString() end
    local file = io.open(filename, "w")
    if file == nil then
      print("cannot open", filename)
      os.exit()
    end 

    for name,node in pairs(ports) do   
       print("checking "..name.." ...")
       local ins, outs, cars = get_port_con(name, "out")
       if outs ~= nil then
           for i=1,#outs do       
             file:write(name..", "..outs[i]..", "..cars[i].."\n")
           end
       end    
    end
    file:close()
    os.exit()
end

-- creating dot file
local filename = "output."..typ
if prop:check("out") then filename = prop:find("out"):asString() end
local file = io.open(filename..".dot", "w")
if file == nil then
  print("cannot open", filename..".dot")
  os.exit()
end  
  

dot_header = [[
digraph "" {
  graph [ranksep="1.0", nodesp="0.5", rankdir="LR", overlap="false", packmode="graph", fontname="Arial", fontsize="12", concentrate="true", bgcolor="#FFFFFF"];
  node [style="filled", color="blue", fillcolor="#F0F0F0", label="", sides="4", fontcolor="black", fontname="Arial", fontsize="12", shape="ellipse"];
  edge [color="#CC0044", label="", fontname="Arial", fontsize="8", fontcolor="#555555"];]]
  
file:write(dot_header.."\n")

for name,node in pairs(ports) do 
    if prop:check("only-cons") == true then
        local ins, outs, cars = get_port_con(name)
        if ins ~= nil and outs ~= nil then 
            if #outs ~= 0 or #ins ~=1 then
                file:write(node.." [label=\""..name.."\"]\n")
            end    
        end    
     else
        file:write(node.." [label=\""..name.."\"]\n")
    end 
end

for name,node in pairs(ports) do   
   print("checking "..name.." ...")
   local ins, outs, cars = get_port_con(name, "out")
   if outs ~= nil then 
       for i=1,#outs do
         local to = ports[outs[i]]
         file:write(node.." -> "..to.."\n")
       end
   end    
end

file:write("}\n")
file:close()


gen = "dot"
if prop:check("gen") then gen = prop:find("gen"):asString() end
typ = "pdf"

-- creating pdf
os.execute(gen.." -T"..typ.." -o "..filename.." "..filename..".dot")

-- Deinitialize yarp network
yarp.Network_fini()
