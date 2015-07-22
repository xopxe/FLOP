RonSimu - Ron Protocol Over NS3 Simulatior with DCE
======

This project consist of two different things:
- Rong. The Ron Protocol Generation 2.
- The NS3 Simulator with ns-3-dce module and small modifications to simulate the protocol.

Steps to configure and build the project:

- Install tools:

```
~$ sudo apt-get install lua5.1 liblua5.1-0-dev luarocks
~$ sudo luarocks install loop
```

- Clone the repository

```
~$ git clone https://github.com/mrichart/RonSimu.git
~$ cd RonSimu/
~/RonSimu$ git checkout xopxe
~/RonSimu$ git submodule init
~/RonSimu$ git submodule update
~/RonSimu$ cd ns-3-dce-git
~/RonSimu/ns-3-dce-git$ git checkout xopxe
~/RonSimu/ns-3-dce-git$ cd ..
```

- Build the platform

```
~/RonSimu$ hg clone http://code.nsnam.org/bake
~/RonSimu$ export BAKE_HOME=`pwd`/bake
~/RonSimu$ export PATH=$PATH:$BAKE_HOME
~/RonSimu$ export PYTHONPATH=$PYTHONPATH:$BAKE_HOME
~/RonSimu$ bake.py configure -c bakeconf_rong.xml -p rong -i ns3 --sourcedir=.
~/RonSimu$ bake.py download
```
Note, the last step will warn of one failure ">> Searching for system dependency pygraphviz - Problem". Thats ok, but nothing else should fail)

```
~/RonSimu$ bake.py build
```

- Build lua with statically linked libraries

```
~/RonSimu$ cd lua-static/luasocket-2.0.2/src/
~/RonSimu/lua-static/luasocket-2.0.2/src$ precompiler.lua -o luasocketscripts -l "?.lua" socket.lua socket/ftp.lua socket/http.lua socket/smtp.lua socket/tp.lua socket/url.lua mime.lua ltn12.lua
~/RonSimu/lua-static/luasocket-2.0.2/src$ preloader.lua -o fullluasocket luasocket.h mime.h luasocketscripts.h
~/RonSimu/lua-static/luasocket-2.0.2/src$ make static copy clean
~/RonSimu/lua-static/luasocket-2.0.2/src$ cd ../../lua-5.1.5/src/
~/RonSimu/lua-static/lua-5.1.5/src$ make ns3 copy clean
~/RonSimu/lua-static/lua-5.1.5/src$ cd ../../../
```

- (Re)Create directories and copy node scripts

```
~/RonSimu$ rm -rf ns-3-dce-git/files-*; sh utils/config-dce-rong-flopmicro.sh 
```

- Run the simulation

```
~/RonSimu$ cd ns-3-dce-git
~/RonSimu/ns-3-dce-git$ ./waf --run dce-rong-microbus
```

- Explanation:
  The simulation scenario is defined in _ns-3-dce-git/myscripts/rom/dce-rong-microbus.cc_. It specifies a scenario with 6 nodes over 1000sec. It contains 4 static nodes closely placed (nodes 1..4), and two mobile nodes (5 and 6) moving on the perifery and approaching the first 4 only from time to time.  

  The config-dce-flopmicro.sh script creates one directory per node (named _ns-3-dce-git/files-X_ where X is 0..5) and copies the main script.
The ouptut of the script is sent to _files-*/var/log/*/_  

  The script is "utils/flopmicro.lua". It holds the code running in each node. What it does, roughly, is to publish 20 chunks, 100kb each, on node 1. The nodes subscribe to the chunks in order (as soon as thery get one they request the next). Chunk posting starts at t=100s, once per 10s. Receivers start at t=100 for node1, t=110 for node2, etc.  


