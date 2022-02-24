#ifndef HELLO_WORLD_S
#define HELLO_WORLD_S
#include <stdio.h>
void helloWorld();

#ifdef HELLO_WORLD_IMPL
void helloWorld()
{
   printf("Hello World from a single header file\n");
}
#endif

#endif