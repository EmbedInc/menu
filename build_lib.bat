@echo off
rem
rem   BUILD_LIB
rem
rem   Build the MENU library.
rem
setlocal
call build_pasinit

call src_insall %srcdir% %libname%

call src_pas %srcdir% %libname%_tree

call src_lib %srcdir% %libname%
call src_msg %srcdir% %libname%
