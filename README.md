# Philipp's Repository for CMake Modules

This is my small collection of CMake modules that might be useful.

How to Integrate
----------------

The modules can be directly placed in your Git project. I like to put them into
the `CMake/Modules` subdirectory. To do so, type:

    $ cd <project-dir>
    $ git subtree add --squash --prefix=CMake/Modules https://github.com/philippvr/cmake-modules.git master

Then add `list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/CMake/Modules")` to
your top-level `CMakeLists.txt` to let CMake find the new modules. To pull
changes of the modules from this repository, type:

    $ cd <project-dir>
    $ git subtree pull --squash --prefix=CMake/Modules https://github.com/philippvr/cmake-modules.git master

See also `man git-subtree` for infos about Git's subtree command.
