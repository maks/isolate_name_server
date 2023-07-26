#!/bin/sh

# build the minimal basic native code, HARDCODED to paths on Ubuntu 22.04
cd native || exit
rm *.o *.so
# gcc -c -Wall -Werror -fpic return_port.cc /usr/lib/dart/include/dart_api_dl.c
# gcc -shared -o libreturnport.so return_port.o dart_api_dl.o

echo Dart SDK location:
which dart

echo check expected path:
ls /usr/lib/dart

gcc -c -Wall -Werror -fpic isolate_name_server.c /usr/lib/dart/include/dart_api_dl.c
gcc -shared -o libnameserver.so isolate_name_server.o dart_api_dl.o