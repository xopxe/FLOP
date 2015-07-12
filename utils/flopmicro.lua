-- this should be copied  in  ns-3-dce-git/"files-N"
-- set this in __N__HERE__ label below
local N = assert(tonumber(__N__HERE__), 'must set N value before running') 

--local experiment = 'symmetrical'

local n = N + 1
-- local cant_tokens=$2

--require 'strict'
--look for packages one folder up.
package.path = package.path .. ';;;../../?.lua;../../?/init.lua'

local log = require 'lumen.log'

log.format = '%T %m-%s: %l'
--log.setlevel('DETAIL', 'RONG')
log.setlevel('ALL', 'FLOP')
log.setlevel('ALL', 'RONG')
log.setlevel('ALL', 'TRW')
log.setlevel('ALL', 'BSW')
log.setlevel('ALL', 'RON')
log.setlevel('ALL', 'EPIDEMIC')
log.setlevel('ALL', 'TEST')
log.setlevel('ALL', 'SELECTOR')
--log.setlevel('ALL')

local sched = require 'lumen.sched'

local selector = require 'lumen.tasks.selector'
selector.init({service='luasocket'})

local notifaction_rate = 300    -- secs between notifs
local token_creation_probability = 1/2 --for trw

local conf = {
  name = 'node'..n, --must be unique
  protocol_port = 8888,
  listen_on_ip = '10.1.0.'..n, 
  broadcast_to_ip = '10.1.255.255', --adress used when broadcasting
  udp_opts = {
    broadcast	= 1,
    dontroute	= 0,
  },
  send_views_timeout =  5, --5

  inventory_size = 5,

	--[[  
  protocol = 'ron',
  max_hop_count = math.huge,
  delay_message_emit = 1,
  message_inhibition_window = 300,
  reserved_owns =50,
  max_owning_time = math.huge,
  max_ownnotif_transmits = math.huge,
  max_notif_transmits = 5, --10
  max_notifid_tracked = 5000,
	ranking_find_replaceable = 'find_replaceable_fifo',
  min_n_broadcasts = 0,
	gamma = 0.9998,
	p_encounter = 0.1,
	min_p = 0,
	--]]

	---[[  
  protocol = 'flop',
  max_hop_count = math.huge,
  delay_message_emit = 1,
  message_inhibition_window = 10,
  reserved_owns =50,
  max_owning_time = math.huge,
  max_ownnotif_transmits = math.huge,
  max_notif_transmits = 10, --10
  max_notifid_tracked = 5000,
	ranking_find_replaceable = 'find_fifo_not_on_path',
  min_n_broadcasts = 0,
  max_path_count = 3,
  q_decay = 0.999,
  q_reinf = 0.1,
  view_skip_list = false,
	--]]
  
	--[[  
  protocol = 'trw',
  transfer_port = 0,
  token_hold_time = 200,
  --]]
  
	--[[
  protocol = 'epidemic',
  transfer_port = 0,
  max_hop_count = 10000,
	--]]

	--[[
  protocol = 'bsw',
  transfer_port = 0,
  max_hop_count = 10000,
  start_copies = 64,
	--]]

  --neighborhood_window = 1, -- for debugging, should be disabled


}

io.stdout:setvbuf('line') 
math.randomseed(n)

for k, v in pairs(conf) do
  log('TEST', 'INFO', 'Configuration %s=%s', tostring(k), tostring(v))
end

log('TEST', 'INFO', 'Creating service %s', tostring(n))
local rong = require 'rong'.new(conf)


local number_of_chunks = 20

local send_notification = function(chunk)
  log('TEST', 'INFO', 'NOTIFICATING chunk %s', tostring(chunk))
  rong:notificate(
    'N'..chunk,
    {
      filename = 'file.avi',
      chunk = chunk,
    }  
  )
end

if n==1 then
  local sender = sched.run( function()
    sched.sleep(100)
    for i=1, number_of_chunks do
      send_notification(i)
      sched.sleep(10)
    end
  end)
else
  sched.run(function()
    local s = rong:subscribe(
      'SUB@'..conf.name, 
      {
        {'filename', '=', 'none' },
      }
    )
    --log('TEST', 'INFO', 'SUBSCRIBING FOR chunk%s%s', tostring(s.filter[1][2]), tostring(s.filter[1][3]))
    local arrived = {}
    sched.sigrun({s}, function(s, n) 
      if not arrived[n.id] then 
        log('TEST', 'INFO', 'ARRIVED FOR %s: %s',tostring(s.id), tostring(n.id))
        for k, v in pairs (n.data) do
          log('TEST', 'INFO', '>>>>> %s=%s',tostring(k), tostring(v))
        end
        arrived[n.id] = true
      end
    end)
  
    sched.sleep(100)
    sched.sleep(100)
    for i=1,number_of_chunks do
      rong:update_subscription(
        'SUB@'..conf.name, 
        {
          {'chunk', '>=', i},
          {'filename', '=', 'file.avi' },
        }
      )
      log('TEST', 'INFO', 'SUBSCRIBING FOR chunk%s%s', tostring(s.filter[1][2]), tostring(s.filter[1][3]))
      sched.sleep(10)
    end
  end)
end


sched.run(function()
  while true do
    sched.sleep(conf.send_views_timeout*20)
       
    for sid, s in pairs(rong.view) do
      local out = {}
      for n, _ in pairs (s.meta.visited) do out[#out+1] = n end
      log('TEST', 'INFO', 'VISITED FOR %s = {%s}', sid, table.concat(out,' '))
    end
    
    local taskcount = 0
    for taskd, _ in pairs (sched.tasks) do taskcount=taskcount+1 end
    log('TEST', 'INFO', 'Lua Ram: %i, Lumen: %i tasks', 
      collectgarbage('count')*1024, taskcount)    
  end
end)


sched.loop()
