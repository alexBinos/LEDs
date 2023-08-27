#pragma once
#include "led_display.h"

//#define MATRIX_DEBUG

class Matrix {
   public:
      rgb_row_simple_t matrix[NUM_ROWS];
      rgb_row_simple_t* pMatrix = matrix;
      void set_pixel(colour_t col, uint32_t r, uint32_t c);
      void print_properties(void);
};
