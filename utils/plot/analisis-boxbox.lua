#!/bin/lua

local tonumber, ipairs, pairs, string = tonumber, ipairs, pairs, string 

function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end

local subscriptions = {}
local notifications = {}
local buffocup = {}
local notif_arrived = {}
local community_labels = {}

local process_file = function (filename)
  local f = assert(io.open(filename,'r'))
	local ts
  local node_number
  
  local broadcast_bytes = 0
  local get_bytes = 0

  for line in f:lines() do
    local sid, bytes, nid, flow_id, mid, label
    
    if not node_number then 
      --1262304000 TEST-INFO: Creating service 5
      ts, node_number = line:match('^(%S*) TEST%-INFO: Creating service (%d+)$')
      node_number = tonumber(node_number)
      if node_number then buffocup[node_number] = {} end
    end
    
    
    --1262304262.0081 FLOP-DEBUG: Broadcast view (654 bytes)    
    ts, bytes = line:match('^(%S*) FLOP%-DEBUG: Broadcast view %((%S*) bytes%)$')
    ts = tonumber(ts)
    if ts and bytes then
      broadcast_bytes = broadcast_bytes + bytes
    else
      -- 1262304005.9669 TEST-INFO: SUBSCRIBED on node1 FOR red
      ts, nid, flow_id = line:match('^(%S*) TEST%-INFO: SUBSCRIBED on (%S+) FOR (%S+)$')
      ts = tonumber(ts)
      if ts and nid and flow_id  then
        subscriptions[nid] = subscriptions[nid] or {}
        subscriptions[nid][flow_id] = 0
      else
        --1262304119.3288 TEST-INFO: ARRIVED on red FOR SUBred@node1: red#1
        ts, flow_id, nid, mid = line:match('^(%S*) TEST%-INFO: ARRIVED on (%S+) FOR .*@(%S+): (%S+)$')
        ts = tonumber(ts)
        --print ('-->', ts, flow_id, nid)
        if ts and nid and flow_id and mid then
          --if ts>1000 then 
            subscriptions[nid][flow_id] = subscriptions[nid][flow_id]+1
            notif_arrived[mid] = (notif_arrived[mid] or 0) + 1
          --end
          
        else
          --1262304125 TEST-INFO: NOTIFICATING green#3 on node2        
          ts, flow_id = line:match('^(%S*) TEST%-INFO: NOTIFICATING (%S+)#.+$')
          ts = tonumber(ts)
          if ts and flow_id  then
            --if ts>1000 then 
              notifications[flow_id] = notifications[flow_id] or 0
              notifications[flow_id] = notifications[flow_id] + 1
            --end
          else
            --1262306500 TEST-INFO: INVENTORY COUNT red : 5
            local count
            ts, flow_id, count = line:match('^(%S*) TEST%-INFO: INVENTORY COUNT (%S+) : (%d+)$')
            ts = tonumber(ts)
            if ts and flow_id and count then
              local buffocup_node = buffocup[node_number] or {}
              buffocup[node_number] = buffocup_node

              print('INV', ts, node_number, flow_id, count)
 
              buffocup_node[ts]=buffocup_node[ts] or {}
              buffocup_node[ts][flow_id] = tonumber(count)
              
            else
              --1262308704 TEST-INFO: COMMUNITY LABEL node3
              ts, label = line:match('^(%S*) TEST%-INFO: COMMUNITY LABEL (node%S+)$')
              ts = tonumber(ts)
              if ts and label then
                local label_rec = {ts=ts, label=label, nid=node_number}
                community_labels[#community_labels+1] = label_rec
              end
            end
            
          end
          
        end
      end
    end
      
    ts = tonumber(ts)
		if not ts then ts = tonumber(line:match('^(%S*) ')) end
  end
  if not ts then 
    print ('WARNING, A NO LOG ENTRY FOUND IN', filename) 
    f:close()
    return
  end
  
  f:close()
end

---[[
local filecount = 0
local files = os.capture('ls ../../ns-3-dce-git/files-*/var/log/*/stdout')
for file in files:gmatch('%S+') do
	process_file(file)
  filecount = filecount+1
end
--]]

for k, v in pairs(notif_arrived) do
  print ('arrived:', k, v)
end


print ('NOTIFS:')
for flow_id, count in pairs (notifications) do
  print (flow_id, ':', count, 'sent')
end
print ('SUBS:')
for nid, v in pairs (subscriptions) do
  print ('on', nid)
  for flow_id, count in pairs (v) do
    print ('', flow_id, ':', count, 'received')
  end
end


for _, label_rec in ipairs(community_labels) do
  print ('LABEL', label_rec.ts, label_rec.nid, label_rec.label)
end


local out_occup ={}
local sort_out_occup ={}
local found_flow_ids = {}

for ifile = 1, filecount do 
--for i = 4, 4 do 
  --local buffocup_node = buffocup[node_number] or {}
  --buffocup_node[ts]=buffocup_node[ts] or {}
  --buffocup_node[ts][flow_id] = count
  
  local buffocup_node = buffocup[ifile]
  for ts, v in pairs (buffocup_node) do
    ts=math.floor(ts)
    for flow_id, count in pairs(v) do
      --print (ts, ifile, flow_id, count)
      if not out_occup[ts] then
        out_occup[ts] = {[ifile] = {[flow_id] = count}}
        if not found_flow_ids[flow_id] then 
          found_flow_ids[flow_id] = true
          found_flow_ids[#found_flow_ids+1] = flow_id
        end
        
        sort_out_occup[#sort_out_occup+1] = ts
      else
        if not out_occup[ts][ifile] then
          --print ('+')
          out_occup[ts][ifile] = {[flow_id] = count}
          if not found_flow_ids[flow_id] then 
            found_flow_ids[flow_id] = true
            found_flow_ids[#found_flow_ids+1] = flow_id
          end
        else
          --print ('*', ts, ifile, flow_id, count)
          out_occup[ts][ifile][flow_id] = count
        end
      end
    end
  end

  table.sort(sort_out_occup, function(v1,v2) return tonumber(v1)<tonumber(v2) end)

  --[[
  print('Node', ifile)
  for i, ts in ipairs(jbuffocup) do
    local reg = jbuffocup[ jbuffocup[i] ]
    print(ts, reg[ 'red' ], reg[ 'green' ])
  end
  --]]
end

--print ('>>>>>>>',out_occup[1262308904][13] )
table.sort(found_flow_ids, function(a,b) return a<b end)


local last_ratio = {}
for i, ts in ipairs(sort_out_occup) do
  local treg = out_occup[ts]
  io.write(ts..' ')
  for ifile = 1, filecount do    
    local reg = treg[ifile]
    --io.write(ifile..':'..tostring(reg and true or false)..' ')
    if reg then
      local p = (reg[found_flow_ids[1]] or 0) / ((reg[found_flow_ids[1]] or 0) + (reg[found_flow_ids[2]] or 0))
      last_ratio[ifile] = p
      io.write(p..' ')
    else
      io.write((last_ratio[ifile] or '-')..' ')
      --io.write('- ')
      --io.write('['..ifile..'] ')
    end
    
    --if ts==1262308904 and ifile==13 then 
    --  print ('<<<<<<<<<', out_occup[1262304204][13]["red"])
    --end
    
  end
  io.write('\n') 

end


--for k, v in pairs(total_get_bytes_from) do 
--end

--[[
process_file('../../ns-3-dce-git/files-0/var/log/23976/stdout')
process_file('../../ns-3-dce-git/files-1/var/log/50144/stdout')
process_file('../../ns-3-dce-git/files-2/var/log/49853/stdout')
--]]

