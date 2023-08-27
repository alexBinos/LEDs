#include "led_display.h"
#include "matrix.h"

int main() {
   Matrix m;
   m.print_properties();
   
   m.set_pixel(RED, 6, 40);
   
   return 0;

}
