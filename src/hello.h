#ifndef HELLO_WORLD_S
#define HELLO_WORLD_S
void helloWorld();

#ifdef HELLO_WORLD_IMPL
#include <stdio.h>

void helloWorld()
{
   printf("Hello World from a single header file\n");
}
#endif

#endif