#pragma once
#include <iostream>

#define NUM_ROWS 16

typedef struct {
   volatile uint32_t red[2];
   volatile uint32_t green[2];
   volatile uint32_t blue[2];
} pxl_row_t;

typedef struct {
   pxl_row_t top;
   pxl_row_t bot;
} rgb_row_t;

typedef enum {
   RED,
   GREEN,
   BLUE
} colour_t;
