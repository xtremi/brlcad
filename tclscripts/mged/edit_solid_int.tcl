##
#				E D I T _ S O L I D _ I N T . T C L
#
# Authors -
#	Bob Parker
#
# Source -
#	The U. S. Army Research Laboratory
#	Aberdeen Proving Ground, Maryland  21005
#
# Distribution Notice -
#	Re-distribution of this software is restricted, as described in
#       your "Statement of Terms and Conditions for the Release of
#       The BRL-CAD Package" agreement.
#
# Description -
#	This is a solid editor for MGED that allows the user to edit the
#	solid internally (i.e. the solid currently being edited --> MGED's es_int).
#
# Acknowledgements -
#	This editor is based on Glen Durfee's editobj.tcl (to edit solids)
#	and solcreate.tcl (to create solids).
#

# Call this routine to initialize the "solid_data" array
solid_data_init

## - init_edit_solid_int
#
proc init_edit_solid_int { id } {
    global mged_gui
    global solid_data
    global esolint_control

    set w .$id.edit_solid_int

    if { [winfo exists $w] } {
	raise $w
	return
    }

    if ![info exists esolint_control($id,inc_op)] {
	set esolint_control($id,inc_op) $solid_data(entry,incr_op)
    }

    if ![info exists esolint_control($id,dec_op)] {
	set esolint_control($id,dec_op) $solid_data(entry,decr_op)
    }

    if ![info exists esolint_control($id,format_string)] {
	set esolint_control($id,format_string) $solid_data(entry,fmt)
    }

    if ![info exists esolint_control($id,cflag)] {
	set esolint_control($id,cflag) 0
    }

    set esolint_info [get_edit_solid]
    set esolint_control(name) [lindex $esolint_info 0]
    set esolint_control(type) [lindex $esolint_info 1]
    set esolint_vals [lrange $esolint_info 2 end]

    set esolint_info [get_edit_solid -c]
    set esolint_control(pathname) [lindex $esolint_info 0]
    set esolint_cvals [lrange $esolint_info 2 end]

    set row -1
    toplevel $w -screen $mged_gui($id,screen)

    incr row
    set esolint_control(form_name) $w.sformF._F
    set esolint_control(form) $row
    set esolint_control($id,cmd) "put_edit_solid $esolint_control(type)"
    if $esolint_control($id,cflag) {
	esolint_build_form $id $w.sformF "** SOLID -- $esolint_control(name): $esolint_control(type)" $esolint_control(type) $esolint_vals disabled 1 1 1 1
    } else {
	esolint_build_form $id $w.sformF "** SOLID -- $esolint_control(name): $esolint_control(type)" $esolint_control(type) $esolint_vals normal 1 1 1 1
    }
    grid $w.sformF -row $row -column 0 -sticky nsew -padx 8 -pady 8
    grid rowconfigure $w $row -weight 1

    incr row
    set esolint_control(form_cname) $w.scformF._F
    set esolint_control(cform) $row
    set esolint_control($id,context_cmd) "put_edit_solid -c $esolint_control(type)"
    if $esolint_control($id,cflag) {
	esolint_build_form $id $w.scformF "** PATH -- $esolint_control(pathname): $esolint_control(type)" $esolint_control(type) $esolint_cvals normal 1 2 1 1
    } else {
	esolint_build_form $id $w.scformF "** PATH -- $esolint_control(pathname): $esolint_control(type)" $esolint_control(type) $esolint_cvals disabled 1 2 1 1
    }
    grid $w.scformF -row $row -column 0 -sticky nsew -padx 8
    grid rowconfigure $w $row -weight 1

    incr row
    frame $w._F$row -relief groove -bd 2
    #
    frame $w.decF
    label $w.decL -text "-operator:" -width 9 -anchor e
    entry $w.decE -relief sunken -bd 2 -textvar esolint_control($id,dec_op)
    grid $w.decL $w.decE -in $w.decF -sticky nsew
    grid columnconfigure $w.decF 0 -weight 0
    grid columnconfigure $w.decF 1 -weight 1
    #
    frame $w.incF
    label $w.incL -text "+operator:" -width 9 -anchor e
    entry $w.incE -relief sunken -bd 2 -textvar esolint_control($id,inc_op)
    grid $w.incL $w.incE -in $w.incF -sticky nsew
    grid columnconfigure $w.incF 0 -weight 0
    grid columnconfigure $w.incF 1 -weight 1
    #
    frame $w.fmtF
    label $w.fmtL -text "format:" -width 9 -anchor e
    entry $w.fmtE -relief sunken -bd 2 -textvar esolint_control($id,format_string)
    grid $w.fmtL $w.fmtE -in $w.fmtF -sticky nsew
    grid columnconfigure $w.fmtF 0 -weight 0
    grid columnconfigure $w.fmtF 1 -weight 1
    bind $w.fmtE <Return> "esolint_format_entries $id"
    #
    grid $w.decF x $w.incF -sticky nsew -in $w._F$row -padx 8 -pady 8
    grid $w.fmtF x x -sticky nsew -in $w._F$row -padx 8 -pady 8
    grid columnconfigure $w._F$row 0 -weight 1
    grid columnconfigure $w._F$row 1 -weight 0
    grid columnconfigure $w._F$row 2 -weight 1
    grid $w._F$row -row $row -column 0 -sticky nsew -padx 8 -pady 8
    grid rowconfigure $w $row -weight 0

    incr row
    checkbutton $w.contextCB -relief flat -bd 2 -text "Context Edit"\
	     -offvalue 0 -onvalue 1 -variable esolint_control($id,cflag)\
	     -command "esolint_toggle_context $id $w"
    grid $w.contextCB -row $row -column 0 -sticky nsew -padx 8
    grid rowconfigure $w $row -weight 0

    incr row
    set esolint_control(buttons) $row
    frame $w._F$row -borderwidth 2
    button $w.applyB -text "Apply" -command "esolint_apply $id $w"
    button $w.resetB -text "Reset" -command "esolint_reset"
    button $w.acceptB -text "Accept" -command "press accept"
    button $w.rejectB -text "Reject" -command "press reject"
    button $w.dismissB -text "Dismiss" -command "destroy $w"
    grid $w.applyB x $w.resetB x $w.acceptB $w.rejectB $w.dismissB -sticky nsew -in $w._F$row
    grid columnconfigure $w._F$row 1 -weight 1
    grid columnconfigure $w._F$row 3 -weight 1
    grid $w._F$row -row $row -column 0 -sticky nsew -padx 6 -pady 8
    grid rowconfigure $w $row -weight 0

    # only one column
    grid columnconfigure $w 0 -weight 1

    wm protocol $w WM_DELETE_WINDOW "catch { destroy $w }"
    wm geometry $w $mged_gui($id,edit_info_pos)
    wm title $w "Internal Solid Editor ($id)"
}

## - esolint_build_form
#
# This proc builds a solid form for creating/editing solids.
#
proc esolint_build_form { id w name type vals state_val do_gui do_cmd do_entries do_state } {
    global base2local
    global local2base
    global solid_data
    global esolint_control

    set row -1
    set sform $w._F

    if $do_gui {
	frame $w -relief groove -bd 2
	frame $sform

	incr row
	label $sform.name -text $name -anchor w
	grid $sform.name -row $row -columnspan 10 -sticky nsew
	grid rowconfigure $sform $row -weight 0
    }

    incr row
    set form [db form $type]
    set len [llength $form]

    for { set i 0 } { $i<$len } { incr i; incr row } {
	set attr [lindex $form $i]
	incr i

	switch $do_cmd {
	    1 {
		set esolint_control($id,cmd) [eval concat \[set esolint_control($id,cmd)\] $attr \\\"]
	    }
	    2 {
		set esolint_control($id,context_cmd) [eval concat \[set esolint_control($id,context_cmd)\] $attr \\\"]
	    }
	}

	if $do_gui {
	    if { [catch { label $sform._$attr\L -text "$solid_data(labels,$attr)" \
		    -anchor w }]!=0 } {
		label $sform._$attr\L -text "$attr" -anchor w
	    }
	    grid $sform._$attr\L -row $row -column 0 -sticky nsew
	    grid columnconfigure $sform 0 -weight 0
	}
	
	set field [lindex $form $i]
	set fieldlen [llength $field]
	for { set num 0 } { $num<$fieldlen } { incr num } {
	    if { [string first "%f" $field]>-1 } {
		if $do_gui {
		    button $sform._$attr\decB$num -text \- -command \
			    "esolint_dec $id $sform._$attr\E$num"
		    button $sform._$attr\incB$num -text \+ -command \
			    "esolint_inc $id $sform._$attr\E$num"
		    entry $sform._$attr\E$num -width 6 -relief sunken

		    grid $sform._$attr\decB$num -row $row -column [expr $num * 3 + 1] -sticky nsew
		    grid $sform._$attr\E$num -row $row -column [expr $num * 3 + 2] -sticky nsew
		    grid $sform._$attr\incB$num -row $row -column [expr $num * 3 + 3] -sticky nsew
		    grid columnconfigure $sform [expr $num * 3 + 1] -weight 0
		    grid columnconfigure $sform [expr $num * 3 + 2] -weight 1
		    grid columnconfigure $sform [expr $num * 3 + 3] -weight 0
		}


		if $do_entries {
		    # Bummer, we have to enable the entry to set its value programmatically
		    set save_state [$sform._$attr\E$num configure -state]
		    $sform._$attr\E$num configure -state normal
		    $sform._$attr\E$num delete 0 end
		    $sform._$attr\E$num insert insert \
			    [format $esolint_control($id,format_string) [expr [lindex \
			    [lindex $vals $i] $num] * $base2local]]
		    $sform._$attr\E$num configure -state [lindex $save_state 4]
		}

		if $do_state {
		    $sform._$attr\decB$num configure -state $state_val
		    $sform._$attr\incB$num configure -state $state_val
		    $sform._$attr\E$num configure -state $state_val
		}

		switch $do_cmd {
		    1 {
			set esolint_control($id,cmd) [eval concat \[set esolint_control($id,cmd)\] \
				\\\[expr \\\[$sform._$attr\E$num get\\\] * $local2base\\\]]
		    }
		    2 {
			set esolint_control($id,context_cmd) [eval concat \[set esolint_control($id,context_cmd)\] \
				\\\[expr \\\[$sform._$attr\E$num get\\\] * $local2base\\\]]
		    }
		}
	    } else {
		# XXXX Temporary debugging
		puts "esolint_build_form: skipping field"
	    }
	}

	if $do_gui {
	    grid rowconfigure $sform $row -weight 1
	}

	switch $do_cmd {
	    1 {
		set esolint_control($id,cmd) [eval concat \[set esolint_control($id,cmd)\] \\\"]
	    }
	    2 {
		set esolint_control($id,context_cmd) [eval concat \[set esolint_control($id,context_cmd)\] \\\"]
	    }
	}
    }

    if $do_gui {
	grid $sform -sticky nsew -row 0 -column 0 -padx 8 -pady 8
	grid columnconfigure $w 0 -weight 1
	grid rowconfigure $w 0 -weight 1
    }
}

## - esolint_apply
#
proc esolint_apply { id w } {
    global esolint_control

    if $esolint_control($id,cflag) {
	eval [set esolint_control($id,context_cmd)]
    } else {
	eval [set esolint_control($id,cmd)]
    }

    esolint_update
}

## - esolint_inc
#
proc esolint_inc { id entryfield } {
    global esolint_control

    set val [$entryfield get]

    $entryfield delete 0 end
    $entryfield insert insert [format $esolint_control($id,format_string) [expr $esolint_control($id,inc_op)]]
}

## - esolint_dec
#
proc esolint_dec { id entryfield } {
    global esolint_control

    set val [$entryfield get]

    $entryfield delete 0 end
    $entryfield insert insert [format $esolint_control($id,format_string) [expr $esolint_control($id,dec_op)]]
}

## - esolint_reset
#
proc esolint_reset {} {
    reset_edit_solid
    esolint_update
}

proc esolint_format_entries { id } {
    global esolint_control

    if $esolint_control($id,cflag) {
	foreach child [winfo children $esolint_control(form_name)] {
	    if { [winfo class $child] == "Entry" } {
		$child configure -state normal
		set val [$child get]
		$child delete 0 end
		$child insert insert [format $esolint_control($id,format_string) $val]
		$child configure -state disabled
	    }
	}

	foreach child [winfo children $esolint_control(form_cname)] {
	    if { [winfo class $child] == "Entry" } {
		set val [$child get]
		$child delete 0 end
		$child insert insert [format $esolint_control($id,format_string) $val]
	    }
	}
    } else {
	foreach child [winfo children $esolint_control(form_name)] {
	    if { [winfo class $child] == "Entry" } {
		set val [$child get]
		$child delete 0 end
		$child insert insert [format $esolint_control($id,format_string) $val]
	    }
	}

	foreach child [winfo children $esolint_control(form_cname)] {
	    if { [winfo class $child] == "Entry" } {
		$child configure -state normal
		set val [$child get]
		$child delete 0 end
		$child insert insert [format $esolint_control($id,format_string) $val]
		$child configure -state disabled
	    }
	}
    }
}

proc esolint_toggle_context { id w } {
    global esolint_control

    if $esolint_control($id,cflag) {
	esolint_build_form $id $w.sformF \
		"** SOLID -- $esolint_control(name): $esolint_control(type)" \
		$esolint_control(type) {} disabled 0 0 0 1
	esolint_build_form $id $w.scformF \
		"** PATH -- $esolint_control(pathname): $esolint_control(type)" \
		$esolint_control(type) {} normal 0 0 0 1
    } else {
	esolint_build_form $id $w.sformF \
		"** SOLID -- $esolint_control(name): $esolint_control(type)" \
		$esolint_control(type) {} normal 0 0 0 1
	esolint_build_form $id $w.scformF \
		"** PATH -- $esolint_control(pathname): $esolint_control(type)" \
		$esolint_control(type) {} disabled 0 0 0 1
    }
}

proc esolint_update {} {
    global mged_players
    global solid_data
    global esolint_control

    set esolint_info [get_edit_solid]
    set esolint_vals [lrange $esolint_info 2 end]

    set esolint_cinfo [get_edit_solid -c]
    set esolint_cvals [lrange $esolint_cinfo 2 end]

    foreach id $mged_players {
	set w .$id.edit_solid_int
	if ![winfo exists $w] {
	    continue
	}

	# set entries for non-context form
	esolint_build_form $id $w.sformF \
		"** SOLID -- $esolint_control(name): $esolint_control(type)" \
		$esolint_control(type) $esolint_vals {} 0 0 1 0

	# set entries for context form
	esolint_build_form $id $w.scformF \
		"** PATH -- $esolint_control(pathname): $esolint_control(type)" \
		$esolint_control(type) $esolint_cvals {} 0 0 1 0
    }
}

proc esolint_destroy { id } {
    global mged_gui

    if ![winfo exists .$id.edit_solid_int] {
	return
    }

    regexp "\[-+\]\[0-9\]+\[-+\]\[0-9\]+" [wm geometry .$id.edit_solid_int] match
    set mged_gui($id,edit_info_pos) $match
    destroy .$id.edit_solid_int
}
