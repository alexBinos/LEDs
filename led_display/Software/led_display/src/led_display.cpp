#include <iostream>
#include "led_display.h"

int main() {
   rgb_row_t Row[NUM_ROWS];
   rgb_row_t* pRow = Row;

   pRow->top.red[0] = 0x55555555;
   pRow->top.red[1] = 0xAAAAAAAA;
   
   return 0;

}
