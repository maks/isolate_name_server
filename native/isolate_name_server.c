#include <stdio.h>
#include <pthread.h>

#include "hashmap.h"

#include "isolate_name_server.h"

static struct hashmap_s hashmap;
pthread_mutex_t lock;

int initNameServer() {
    const unsigned initial_size = 10;    
    return hashmap_create(initial_size, &hashmap);
}

Dart_Handle lookupPortByName(const char* name) {
    pthread_mutex_lock(&lock);
    Dart_Port* port = hashmap_get(&hashmap, name, strlen(name));
    pthread_mutex_unlock(&lock);
    if (port != NULL) {
        return Dart_NewSendPort(*port);
    } else {        
        return Dart_Null();
    }
}

int registerPortWithName(Dart_Port port, const char*  name) {
    pthread_mutex_lock(&lock);
    void* existing = hashmap_get(&hashmap, name, strlen(name));
    if (existing != NULL) {
        pthread_mutex_unlock(&lock);
        return 1; 
    }
    Dart_Port* val = malloc(sizeof(int));
    *val = port;
    pthread_mutex_unlock(&lock);
    return hashmap_put(&hashmap, name, strlen(name), val);
}

int removePortNameMapping(const char* name) {
    pthread_mutex_lock(&lock);
    int err = hashmap_remove(&hashmap, name, strlen(name));
    pthread_mutex_unlock(&lock);
    return err;
}
