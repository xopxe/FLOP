-- this should be copied  in  ns-3-dce-git/"files-N"
-- set this in __N__HERE__ label below
local N = assert(tonumber(__N__HERE__), 'must set N value before running') 

--local experiment = 'transitive'
local experiment = 'symmetrical'


local n = N + 1
-- local cant_tokens=$2

--require 'strict'
--look for packages one folder up.
package.path = package.path .. ';;;../../?.lua;../../?/init.lua'

local log = require 'lumen.log'

log.format = '%T %m-%s: %l'
--log.setlevel('DETAIL', 'RONG')
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
  send_views_timeout =  100, --5

  inventory_size = 30,

	---[[  
  protocol = 'ron',
  max_hop_count = math.huge,
  delay_message_emit = 1,
  message_inhibition_window = 300,
  reserved_owns = 500,
  max_owning_time = math.huge,
  max_ownnotif_transmits = math.huge,
  max_notif_transmits = 20, --10
  max_notifid_tracked = 5000,
	ranking_find_replaceable = 'find_replaceable_fifo',
  min_n_broadcasts = 0,
	gamma = 0.9998,
	p_encounter = 0.1,
	min_p = 0,
	--]]

	--[[  
  protocol = 'flop',
  max_hop_count = math.huge,
  delay_message_emit = 1,
  message_inhibition_window = 300,
  reserved_owns =50,
  max_owning_time = math.huge,
  max_ownnotif_transmits = math.huge,
  max_notif_transmits = 10, --10
  max_notifid_tracked = 5000,
	ranking_find_replaceable = 'find_fifo_not_on_path',
  min_n_broadcasts = 0,
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
  start_copies = 32,
	--]]

  --neighborhood_window = 1, -- for debugging, should be disabled


}

io.stdout:setvbuf('line') 
math.randomseed(n)

if conf.protocol=='trw' then
  conf.inventory_size = math.huge
  if math.random() < token_creation_probability then
    conf.create_token = 'TOKEN_'..math.random(2^30)
  end
end

for k, v in pairs(conf) do
  log('TEST', 'INFO', 'Configuration %s=%s', tostring(k), tostring(v))
end


log('TEST', 'INFO', 'Creating service %s', tostring(n))
local rong = require 'rong'.new(conf)

if n<=3 then 
	local s = rong:subscribe(
		'SUB1@'..conf.name, 
		{
		  {'target', '=', 'node'..n },
		}
	)
	local arrived = {}
	log('TEST', 'INFO', 'SUBSCRIBING FOR target=%s', tostring(s.filter[1][3]))
	sched.sigrun({s}, function(s, n) 
		if not arrived[n.id] then 
		  log('TEST', 'INFO', 'ARRIVED FOR %s: %s',tostring(s.id), tostring(n.id))
		  for k, v in pairs (n.data) do
		    log('TEST', 'INFO', '>>>>> %s=%s',tostring(k), tostring(v))
		  end
		  arrived[n.id] = true
		end
	end)
end

local mcounter=1
local send_notification = function(target)
  log('TEST', 'INFO', 'NOTIFICATING FOR target=%s: %s', 
    target,'N'..mcounter..'@'..conf.name)
  rong:notificate(
    'N'..mcounter..'@'..conf.name,
    {
      --q = string.rep('X',20),
      target = target,
    }  
  )
	mcounter = mcounter+1
end

local targets, sender
if experiment == 'symmetrical' then
  targets = {'node1', 'node3'}
  if n==2 then
    sender = sched.run( function()
      while true do
        for _, target in ipairs(targets) do
          send_notification(target)
          sched.sleep(notifaction_rate/#targets)
        end
      end
    end)
  end
elseif experiment == 'transitive' then
  targets = {'node2', 'node3'}
  if n==1 then
    sender = sched.run( function()
      while true do
        for _, target in ipairs(targets) do
          send_notification(target)
          sched.sleep(notifaction_rate/#targets)
        end
      end
    end)
  end
else
  error ('unsupported experiment: ' .. tostring(experiment))
end

sched.run(function()
    sched.sleep(90000)
    sender:kill()
    sched.sleep(10000)
end)

sched.run(function()
  while true do
    sched.sleep(conf.send_views_timeout*20)
    local totals = {}
    for _, target in ipairs(targets) do
      totals[target] = 0
    end
    for mid, m in pairs(rong.inv) do
      if m.data.target and totals[m.data.target] then
        totals[m.data.target] = totals[m.data.target] + 1
      end
    end
    local s = ''
    for mid, total in pairs(totals) do
      s = s .. mid ..' '..total..' '
    end
    log('TEST', 'INFO', 'BUFFER CONTENT: %s', s)
    
    if conf.protocol=='ron' then
      for sid, s in pairs(rong.view) do
        log('TEST', 'INFO', 'SUBSCRIPTION P FOR %s = %f', sid, s.meta.p)
      end
    end
    
    local taskcount = 0
    for taskd, _ in pairs (sched.tasks) do taskcount=taskcount+1 end
    log('TEST', 'INFO', 'Lua Ram: %i, Lumen: %i tasks', 
      collectgarbage('count')*1024, taskcount)    
  end
end)


sched.loop()
