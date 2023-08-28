#include "led_display.h"
#include "matrix.h"

int main() {
   Matrix m;
   m.print_properties();
   
   m.set_pixel(RED, 6, 40);
   
   m.draw_horizontal(RED, 2, 24, 60);

   m.clear_matrix();

   m.draw_vertical(RED, 6, 12, 14);

   return 0;

}
