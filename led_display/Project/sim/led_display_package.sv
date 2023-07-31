

package led_display_package;
   
   typedef struct packed {
      logic [(64 - 1):0] red;
      logic [(64 - 1):0] green;
      logic [(64 - 1):0] blue;
   } pxl_col_t;
   
endpackage
