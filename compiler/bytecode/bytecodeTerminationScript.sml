open HolKernel boolLib bossLib BytecodeTheory
val _ = new_theory"bytecodeTermination"

val _ = save_thm ("bc_fetch_aux_def", bc_fetch_aux_def);
val _ = export_rewrites["bc_fetch_aux_def"];
val _ = save_thm("bc_fetch_def",bc_fetch_def);
val _ = save_thm("bump_pc_def",bump_pc_def);
val _ = save_thm("bc_find_loc_def",bc_find_loc_def);
val _ = save_thm("bc_find_loc_aux_def",bc_find_loc_aux_def);
val _ = save_thm("bc_next_rules",bc_next_rules);
val _ = save_thm("bc_next_ind",bc_next_ind);
val _ = save_thm("bc_next_cases",bc_next_cases);
val _ = save_thm("bc_stack_op_cases",bc_stack_op_cases);
val _ = save_thm("bc_stack_op_ind",bc_stack_op_ind);
val _ = save_thm("bool_to_tag_def",bool_to_tag_def);
val _ = save_thm("bool_to_val_def",bool_to_val_def);
val _ = save_thm("unit_tag_def",unit_tag_def);
val _ = save_thm("unit_val_def",unit_val_def);
val _ = save_thm("closure_tag_def",closure_tag_def);
val _ = save_thm("block_tag_def",block_tag_def);
val _ = save_thm("is_Label_def",is_Label_def);
val _ = export_rewrites["is_Label_def","bool_to_tag_def","bool_to_val_def",
                        "unit_tag_def","unit_val_def","closure_tag_def",
                        "block_tag_def"];
val _ = Parse.overload_on("next_addr", ``λil ls. SUM (MAP (SUC o il) (FILTER ($~ o is_Label) ls))``)

val _ = export_theory()
