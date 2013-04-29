
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name BraveMIPS -dir "D:/Study/DTU/1/02211/BraveMIPS/source/planAhead_run_3" -part xc6slx45csg324-3
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "D:/Study/DTU/1/02211/BraveMIPS/source/mpg.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {D:/Study/DTU/1/02211/BraveMIPS/source} }
set_property target_constrs_file "atlys.ucf" [current_fileset -constrset]
add_files [list {atlys.ucf}] -fileset [get_property constrset [current_run]]
link_design
