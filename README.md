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
  - Follow the indications in the corresponding README

Running an example:

- Copy some files into ns3:
  - sh utils/config-dce-rong.sh 12 4

- Run a simulation:
  - cd ns-3-dce-git
  - ./waf --run dce-ron-simple
  
  
