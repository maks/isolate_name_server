#!/bin/sh

# build the minimal basic native code, HARDCODED to paths on Ubuntu 22.04
cd native || exit
rm *.o *.so

echo "Dart SDK installed in $DART_HOME"
ls -l $DART_HOME/include/dart_api_dl.c

gcc -c -Wall -Werror -fpic isolate_name_server.c $DART_HOME/include/dart_api_dl.c
gcc -shared -o libnameserver.so isolate_name_server.o dart_api_dl.o