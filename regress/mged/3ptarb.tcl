puts "*** Testing '3ptarb' command ***"

if {![info exists make_primitives_list]} {  
   source regression_resources.tcl
}

3ptarb 3ptarb_test.s 0 0 0 10 0 0 10 10 0 z 0 10 6

puts "*** '3ptarb' testing completed ***\n"
