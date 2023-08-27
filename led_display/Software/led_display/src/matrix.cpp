#include "matrix.h"

void Matrix::print_properties(void) {
   std::cout << "Matrix class. " << NUM_ROWS << " elements." << std::endl;
   return;
}

void Matrix::set_pixel(colour_t col, uint32_t r, uint32_t c) {
   #ifdef MATRIX_DEBUG
      std::cout << "Setting pixel row " << r << " column " << c << " to ";

      switch (col) {
         case RED: {
            std::cout << "red";
            break;
         }

         case GREEN: {
            std::cout << "green";
            break;
         }

         case BLUE: {
            std::cout << "blue";
            break;
         }
      }
      std::cout << std::endl;
   #endif

   bool tnb;         // Top/bottom select
   uint32_t row_idx; // Row index
   bool lnr;         // Left right select
   uint32_t col_idx; // Column index

   lnr = (c >= 32);
   tnb = (r >= 16);
   col_idx = (c % 32);
   row_idx = (r % 16);
   
   this->matrix[row_idx].row[tnb].red[lnr] |= (1 << col_idx);

   return;
}
