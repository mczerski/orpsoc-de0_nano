
# XST Script for ORPSoCv2 synthesis

run 
-ifn $BOARD.prj
-ifmt mixed
-top $BOARD
-ofn $BOARD.ngc 
-ofmt NGC 
-p $PART
-opt_mode Speed 
-opt_level 2
-vlgincdir {../rtl $RTL_COMPONENT_PATHS }
-uc $BOARD.xcf


