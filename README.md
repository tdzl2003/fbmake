FBMake (Fast-Build Make) is a lua-based build tool.

Description
-----------
TODO: Translate Description into English

FBMake (Fast-Build Make) 是一个基于Lua语言的构建工具。

FBMake基于New BSD协议，您可以自由的使用、分发它，在此之前请阅读附带的协议说明文件LICENSE.md

它使用工程风格的make定义，支持编写各种插件来获得更丰富的功能。

它支持多个平台、多种不同的编译工具，支持不同IDE的工程创建。

受益于[Lua](www.lua.org)语言与[LuaJIT](www.luajit.org)项目，FBMake提供极具扩展性的功能同时，具备超卓的性能。


###目前支持的操作系统：
Windows

###目前支持的IDE：


Documentation
-------------


Installation
------------

If you download zip file, you should also download [luajit](http://luajit.org/download.html).

If you cloned with git, use "Submodule Update" command for TotoriseGit or run "git submodule update" command in shell.

You should build luajit executable before using fbmake. Follow the [luajit installation guide](http://luajit.org/install.html), and copy luajit binaries into fbmake directory.

Don't forget to set path environment or to create alias for fbmake shell script.

type "fbmake -v" to check if fbmake is ok to use.

History
-------
