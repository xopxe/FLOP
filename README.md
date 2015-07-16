RonSimu - Ron Protocol Over NS3 Simulatior with DCE
======

This project consist of two different things:
- Rong. The Ron Protocol Generation 2.
- The NS3 Simulator with ns-3-dce module and small modifications to simulate the protocol.

Steps to configure and build the project after you clone it:

- Download all the submodules:
  - git submodule init
  - git submodule update

- Download bake: 
  hg clone http://code.nsnam.org/bake (you need Mercurial installed)

- Set variable for bake:
  - export BAKE_HOME=\`pwd\`/bake
  - export PATH=$PATH:$BAKE_HOME
  - export PYTHONPATH=$PYTHONPATH:$BAKE_HOME

- Configure bake:
  - bake.py configure -c bakeconf_rong.xml -p rong -i ns3 --sourcedir=.
  
- Download dependencies:
  - bake.py download
  (If libc-debug is not found you need to install it. libc6-dbg in Ubuntu)

- Build and install:
  - bake.py build
  
- Build lua static:
  - Follow the indications in lua-static/README.md 

Running an example:

- Copy some files into ns3:
  - sh utils/config-dce-flopmicro.sh

- Run a simulation:
  - cd ns-3-dce-git
  - ./waf --run dce-ron-microbus
  
- Explanation:
  The simulation scenario is defined in _ns-3-dce-git/myscripts/rom/dce-rong-microbus.cc_. It specifies a scenario with 6 nodes over 1000sec. It contains 4 static nodes closely placed (nodes 1..4), and two mobile nodes (5 and 6) moving on the perifery and approaching the first 4 only from time to time.  

  The config-dce-flopmicro.sh script creates one directory per node (named _ns-3-dce-git/files-X_ where X is 0..5) and copies the main script.
The ouptut of the script is sent to _files-*/var/log/*/_  

  The script is "utils/flopmicro.lua". It holds the code running in each node. What it does, roughly, is to publish 20 chunks, 100kb each, on node 1. The nodes subscribe to the chunks in order (as soon as thery get one they request the next). Chunk posting starts at t=100s, once per 10s. Receivers start at t=100 for node1, t=110 for node2, etc.  


