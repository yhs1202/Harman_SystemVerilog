# ============================================================
# Vivado Build Script
# - Project name = current directory name
# - Expects src/ and constr/ subdirectories
# ============================================================

# Use current directory name as project name
set proj_dir [file normalize [pwd]]
set proj_name [file tail $proj_dir]

# User settings -----------------------------
set top "top"                        ;# Top-level module name (edit this)
set part "xc7a35ticsg324-1L"         ;# Device part (example: Basys-3)
set srcdir   "$proj_dir/src"
set constrdir "$proj_dir/constr"
set outdir   "$proj_dir/out"
file mkdir $outdir
# -------------------------------------------

puts ">>> Building project: $proj_name"
puts ">>> Part: $part"
puts ">>> Top module: $top"

# Create a non-project flow
create_project $proj_name $outdir -part $part -force
set_msg_config -id {Common 17-55} -new_severity {WARNING}

# Add RTL sources
add_files -fileset sources_1 [glob -nocomplain "$srcdir/**/*.v"]
add_files -fileset sources_1 [glob -nocomplain "$srcdir/**/*.sv"]

# Set top module
set_property top $top [current_fileset]

# Add constraints
add_files -fileset constrs_1 [glob -nocomplain "$constrdir/*.xdc"]

# Run synthesis
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# Run implementation and generate bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# Copy the generated bitstream to out/
set bitfile [glob -nocomplain "$outdir/${proj_name}.runs/impl_1/*.bit"]
if {[llength $bitfile]} {
    set final_bit "$outdir/${proj_name}.bit"
    file copy -force [lindex $bitfile 0] $final_bit
    puts ">>> Bitstream generated: $final_bit"
} else {
    puts "!!! ERROR: Bitstream not found."
}
puts ">>> Build completed."