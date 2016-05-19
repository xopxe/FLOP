local string = string

-- this should be copied  in  ns-3-dce-git/"files-N"
-- set this in __N__HERE__ label below
-- This will be done by the installation script.
local N = assert(tonumber(__N__HERE__), 'must set N value before running') 
local seed = tonumber(__SEED__HERE__) or N
local proto = assert('__PROTO__HERE__')
local scenario = assert('__SCENARIO__HERE__')


local n = N + 1

--require 'strict'
--look for packages one folder up.
package.path = package.path .. ';;;../../?.lua;../../?/init.lua'

local log = require 'lumen.log'
local socket = require 'socket'
local start_time = socket.gettime()

log.format = '%T %m-%s: %l'

--[[
--log.setlevel('DETAIL', 'RONG')
log.setlevel('DETAIL', 'FLOP')
log.setlevel('DETAIL', 'RONG')
log.setlevel('DETAIL', 'SELECTOR')
log.setlevel('ALL', 'HTTP')
log.setlevel('ALL', 'TEST')
--log.setlevel('ALL')
--]]
log.setlevel('ALL', 'FLOP')
log.setlevel('ALL', 'RON')
log.setlevel('ALL', 'RONG')
log.setlevel('ALL', 'EPIDEMIC')
log.setlevel('ALL', 'BSW')
log.setlevel('DETAIL', 'SELECTOR')
log.setlevel('ALL', 'HTTP')
log.setlevel('ALL', 'TEST')


local number_of_messages = 60
local inter_messages_time = 60


scenarios = {
  ['separation'] = {[2]={1,3}},
  ['counterflow'] = {[1]={3}, [3]={1}},
  ['overlay'] = {[1]={2, 3}},
}

local emitter = scenarios[scenario]

-- This is the configuration for the flop service
local conf = {
  --pick_server = pick_server,
  
  name = 'node'..n, --must be unique
  protocol_port = 8888,
  listen_on_ip = '10.1.0.'..n, 
  broadcast_to_ip = '10.1.255.255', --adress used when broadcasting
  udp_opts = {
    broadcast	= 1,
    dontroute	= 0,
  },
  
  -- rate of the beacon broadcast
  send_views_timeout =  20,

  -- buffer size
  inventory_size = 10,
  reserved_owns = 10, -- for the messages publishes by the node itself

  protocol = proto,
  
  --protocol = 'flop',
  --protocol = 'ron',
  --protocol = 'bsw',
  
  
  --protocol = 'epidemic',

  --ranking_find_replaceable = 'find_fifo_not_on_path',
  --ranking_find_replaceable = 'find_replaceable_fifo',
  
  
  max_hop_count = math.huge,
  
  -- notification forwarding prameters
  delay_message_emit = 1,
  message_inhibition_window = 5, --10,
  
  -- buffer management parameters
  max_owning_time = math.huge,
  max_ownnotif_transmits = math.huge, --20,
  max_notif_transmits = math.huge, --20,
  max_chunk_downloads = math.huge, --3, -- how many times will allow a chunk to be downloaded
  max_notifid_tracked = 5000,
  view_skip_list = false,
  min_n_broadcasts = 0,
  
  -- routing parameters
  -- flop
  max_path_count = 4,
  q_decay = 0.9999,
  q_reinf = 0.005,
  
  -- ron
	gamma = 0.99,
	p_encounter = 0.05,
	min_p = 0,
  min_n_broadcasts = 0,

  -- bsw
  start_copies = 64,
  transfer_port = 0,
  --max_hop_count = math.huge,

  -- epidemic
  transfer_port = 0,
  --max_hop_count = 5,

  
  -- timeout before aborting a chunk download
  -- http_get_timeout = 1,
  
  --attachments = {},
  
  -- where the chunks will be served
  --[[
  http_conf = {
    ip='10.1.0.'..n, 
    port=8080,
  },
  --]]

  --neighborhood_window = 1, -- for debugging, should be disabled
}


local sched = require 'lumen.sched'
local selector = require 'lumen.tasks.selector'
selector.init({service='luasocket'})

io.stdout:setvbuf('line') 

math.randomseed(seed)

for k, v in pairs(conf) do
  log('TEST', 'INFO', 'Configuration %s=%s', tostring(k), tostring(v))
end
log('TEST', 'INFO', 'Creating service %s', tostring(n))
local rong = require 'rong'.new(conf)

local send_notification = function(target, seq)
  local mid = target..'#'..seq --must be a filename
  sched.run(function()
    sched.sleep(0)
    log('TEST', 'INFO', 'NOTIFICATING %s on %s', tostring(mid), conf.name)
    rong:notificate(
      mid,
      {
        target = target,
        seq = seq,
        data = string.rep('x',100)
      }  
    )
  end)
end

local get_client_task = function(target)
  return function()
    local arrived = {}
    sched.sleep(math.random()) --small random sleep to avoid synchronization
    
    -- initialize subscription
    log('TEST', 'INFO', 'SUBSCRIBING on %s FOR %s', conf.name, target)
    local s = rong:subscribe(
      'SUB'..target..'@'..conf.name, 
      {
        {'target', '=', target },
      }
    )
    log('TEST', 'INFO', 'SUBSCRIBED on %s FOR %s', conf.name, target)
    
    sched.sigrun({s, buff_mode='keep_last'}, function(sig, n)
      if not arrived[n.id] then
        log('TEST', 'INFO', 'ARRIVED on %s FOR %s: %s', target, tostring(s.id), tostring(n.id))
        arrived[n.id] = true
      end
    end)
  end
end


---[[
-- periodically log internal data
if conf.protocol == 'flop' then
  sched.run(function()
    while true do
      sched.sleep(conf.send_views_timeout*5)
         
      for sid, s in pairs(rong.view) do
        local out = {}
        for n, _ in pairs (s.meta.visited) do out[#out+1] = n end
        log('TEST', 'INFO', 'VISITED FOR %s = {%s}', sid, table.concat(out,' '))
        out = {}
        for n, q in pairs (s.meta.q) do out[#out+1] =n..'='..string.format('%.2f',q) end
        log('TEST', 'INFO', 'NODE Qs FOR %s = {%s}', sid, table.concat(out,','))
      end

    end
  end)
end
--]]

sched.run(function()
  while true do
    sched.sleep(conf.send_views_timeout*5)
       
    local bufftot = {}
    for nid, n in pairs(rong.inv) do
      local count = bufftot[n.data.target] or 0
      count = count + 1
      bufftot[n.data.target] = count
    end
    for k, v in pairs(bufftot) do
      log('TEST', 'INFO', 'INVENTORY COUNT %s : %s', k, tostring(v))
    end
    
    for sid, s in pairs(rong.view) do
      log('TEST', 'INFO', 'SUB QUALITY %s : %s', sid, tostring(s.meta.p))
    end
    
    
    local taskcount = 0
    for taskd, _ in pairs (sched.tasks) do taskcount=taskcount+1 end
    log('TEST', 'INFO', 'Lua Ram: %i, Lumen: %i tasks', 
      collectgarbage('count')*1024, taskcount)    
  end
end)

local client_task
for _, destinations in pairs (emitter) do
  for _, flow_id in ipairs (destinations) do
    if flow_id==n then
      client_task = client_task or get_client_task('node'..n)
      break
    end
  end
  if client_task then break end;
end
if client_task then sched.run(client_task) end

local start_transmiting = 500
sched.run(function()
  sched.sleep(start_transmiting)
  for i=1, number_of_messages do
    for _, flow_id in ipairs (emitter[n] or {}) do
      send_notification('node'..flow_id, i)
    end
    local sleeptime = start_time+start_transmiting+(i*inter_messages_time) - socket.gettime()
    log('TEST', 'INFO', 'Going to sleep start_time:%s start_transmiting:%s i:%s inter_messages_time:%s socket.gettime():%s : %s',
      start_time, start_transmiting, i, inter_messages_time, socket.gettime(), sleeptime) 
    if sleeptime<0 then sleeptime=0 end
    sched.sleep( sleeptime )
  end
end)

sched.loop()
