#pragma once
#include "led_display.h"

//#define MATRIX_DEBUG

class Matrix {
   public:
      rgb_row_simple_t matrix[NUM_ROWS];
      rgb_row_simple_t* pMatrix = matrix;
      
      void clear_matrix(void);
      void set_pixel(colour_t clr, uint32_t r, uint32_t c);
      void draw_horizontal(colour_t clr, uint32_t r, uint32_t c1, uint32_t c2);
      void draw_vertical(colour_t clr, uint32_t r1, uint32_t r2, uint32_t c);
      
      void print_properties(void);
};
