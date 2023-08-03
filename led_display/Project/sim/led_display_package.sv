

package led_display_package;
   
   localparam integer GL_NUM_COL_PIXELS = 64;
   localparam integer GL_RGB_COL_W = 3 * GL_NUM_COL_PIXELS;
   localparam integer GL_NUM_COL_PIXELS_W = $clog2(GL_NUM_COL_PIXELS + 1);
   
   typedef struct packed {
      logic [(GL_NUM_COL_PIXELS - 1):0] red;
      logic [(GL_NUM_COL_PIXELS - 1):0] green;
      logic [(GL_NUM_COL_PIXELS - 1):0] blue;
   } pxl_col_t;
   
endpackage
