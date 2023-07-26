#include <stdio.h>
#include "hashmap.h"

#include "isolate_name_server.h"

static struct hashmap_s hashmap;

int initNameServer() {
    const unsigned initial_size = 10;    
    return hashmap_create(initial_size, &hashmap);
}

Dart_Handle lookupPortByName(const char* name) {
    Dart_Port* port = hashmap_get(&hashmap, name, strlen(name));
    if (port != NULL) {
        return Dart_NewSendPort(*port);
    } else {        
        return Dart_Null();
    }
}

int registerPortWithName(Dart_Port port, const char*  name) {
    void* existing = hashmap_get(&hashmap, name, strlen(name));
    if (existing != NULL) {
        return 1; 
    }
    Dart_Port* val = malloc(sizeof(int));
    *val = port;
    return hashmap_put(&hashmap, name, strlen(name), val);
}

int removePortNameMapping(const char* name) {
    return hashmap_remove(&hashmap, name, strlen(name));
}
