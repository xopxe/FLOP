RonSimu - Ron Protocol Over NS3 Simulatior with DCE
======

This project consist of two different things:
- Rong. The Ron Protocol Generation 2.
- The NS3 Simulator with ns-3-dce module and small modifications to simulate the protocol.

Steps to configure and build the project:

- Install tools:

```
~$ sudo apt-get install lua5.1 liblua5.1-0-dev luarocks python-pygccxml qt4-dev-tools python-pygoocanvas python-setuptools python-dev autoconf p7zip-full cmake bzr 
~$ sudo luarocks install loop
```

- Clone the repository

```
~$ git clone https://github.com/rfuentess/FLOP.git
~$ cd RonSimu/
~/FLOP$ git submodule init
~/FLOP$ git submodule update
~/FLOP$ cd ns-3-dce-git
~/FLOP/ns-3-dce-git$ git checkout xopxe
~/FLOP/ns-3-dce-git$ cd ..
```

- Build the platform

```
~/FLOP$ hg clone http://code.nsnam.org/bake
~/FLOP$ export BAKE_HOME=`pwd`/bake
~/FLOP$ export PATH=$PATH:$BAKE_HOME
~/FLOP$ export PYTHONPATH=$PYTHONPATH:$BAKE_HOME
~/FLOP$ bake.py configure -c bakeconf_rong.xml -p rong -i ns3 --sourcedir=.
~/FLOP$ bake.py download
```
Note, the last step will warn of one failure: ">> Searching for system dependency pygraphviz - Problem". Thats ok.

FIXME: now seems to be failing pygccxml, which seems to be safe also.

```
~/FLOP$ bake.py build
```

If install fails, you may be missing some packages. Use "bake.py check" and "bake.py download -v" to find out what you're missing.


- Build lua with statically linked libraries

```
~/FLOP$ cd lua-static/luasocket-2.0.2/src/
~/FLOP/lua-static/luasocket-2.0.2/src$ precompiler.lua -o luasocketscripts -l "?.lua" socket.lua socket/ftp.lua socket/http.lua socket/smtp.lua socket/tp.lua socket/url.lua mime.lua ltn12.lua
~/FLOP/lua-static/luasocket-2.0.2/src$ preloader.lua -o fullluasocket luasocket.h mime.h luasocketscripts.h
~/FLOP/lua-static/luasocket-2.0.2/src$ make static copy clean
~/FLOP/lua-static/luasocket-2.0.2/src$ cd ../../lua-5.1.5/src/
~/FLOP/lua-static/lua-5.1.5/src$ make ns3 copy clean
~/FLOP/lua-static/lua-5.1.5/src$ cd ../../../
```

- Run the simulation

```
~/FLOP$ ./runsims2.sh

```

- Explanation:

  The runsims script does the following:
  * Runs the simulation 5 times, storing the results in the util/plot/flopnalisis2.txt file.
  * Each simulation run consists of the following:
    * (re)create the ns-3-dce-git/files-* folders, where the the environment for each node is stored.
    * Run the utils/config-dce-rong-cell2.sh script, that will generate the main program for each node and store it in the above mentioned folder.
    * Run ther mobility scenario, in this case dce-rong-cell (the source is at ns-3-dce-git/myscripts/ron/dce-rong-cell.cc)
    * The log for each execution is in ns-3-dce-git/files-*\/var/log/*\/
    * The log parsing script is run.



