#pragma once
#include "led_display.h"


class Matrix {
   public:
      rgb_row_t matrix[NUM_ROWS];
      rgb_row_t* pMatrix = matrix;
      void set_pixel(rgb_row_t* mat, colour_t col, uint32_t r, uint32_t c);
      void print_properties(void);
};