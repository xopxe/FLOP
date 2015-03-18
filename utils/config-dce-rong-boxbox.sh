#!/bin/sh

cant_nodes=$1
cant_tokens=$2

aux=$(($cant_nodes-1))

for i in `seq 0 $aux`; do

  mkdir ns-3-dce-git/"files-$i"
  
  n=$(($i+1))
	
	echo "--require 'strict'
--look for packages one folder up.
package.path = package.path .. ';;;../../?.lua;../../?/init.lua'

local sched = require 'lumen.sched'
local log = require 'lumen.log'
--log.setlevel('DETAIL', 'RONG')
log.setlevel('ALL', 'RONG')
log.setlevel('ALL', 'TRW')
log.setlevel('ALL', 'RON')
log.setlevel('ALL', 'TEST')
--log.setlevel('ALL')

local selector = require 'lumen.tasks.selector'
selector.init({service='luasocket'})

local n = $n
local total_nodes = $cant_nodes

local notifaction_rate = 500    -- secs between notifs

local conf = {
  name = 'node'..n, --must be unique
  protocol_port = 8888,
  listen_on_ip = '10.1.0.'..n, 
  broadcast_to_ip = '10.1.255.255', --adress used when broadcasting
  udp_opts = {
    broadcast	= 1,
    dontroute	= 0,
  },
  send_views_timeout =  60, --5
  
  protocol = 'ron',
  max_hop_count = math.huge,
  inventory_size = 50,
  delay_message_emit = 20,
  reserved_owns =50,
  max_owning_time = math.huge,
  max_ownnotif_transmits = math.huge,
  max_notif_transmits = 10,

  max_notifid_tracked = 5000,

	ranking_find_replaceable = 'find_replaceable_fifo',
  min_n_broadcasts = 0,

	gamma = 0.9998,
	p_encounter = 0.05,
	min_p = 0,

}


math.randomseed(n)

log('TEST', 'INFO', 'Creating service %s', tostring(n))
local rong = require 'rong'.new(conf)

if n==2 or n==3 then 
	local s = rong:subscribe(
		'SUB1@'..conf.name, 
		{
		  {'target', '=', 'node'..n },
		}
	)
	log('TEST', 'INFO', 'SUBSCRIBING FOR target=%s', tostring(s.filter[1][3]))
	sched.sigrun({s}, function(s, n) 
		log('TEST', 'INFO', 'ARRIVED FOR %s: %s',tostring(s.id), tostring(n.id))
		for k, v in pairs (n.data) do
		  log('TEST', 'INFO', '>>>>> %s=%s',tostring(k), tostring(v))
		end
	end)
end

local send_notification = function(target)
  log('TEST', 'INFO', 'NOTIFICATING FOR target=%s: %s', 
    target,'N'..sched.get_time()..'@'..conf.name)
  rong:notificate(
    'N'..sched.get_time()..'@'..conf.name,
    {
      q = 'X',
      target = target,
    }  
  )
end

if n==1 then
	sched.run( function()
		while true do
			send_notification('node3')
		  sched.sleep(notifaction_rate)
		end
	end)
end

sched.loop()
"  >> ns-3-dce-git/files-$i/'rong-node.lua'

done
