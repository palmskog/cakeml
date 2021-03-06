(*
  Tactics and utilities for data-cost proofs
*)

structure costLib = struct

open preamble basis compilationLib costPropsTheory;
open dataSemTheory data_monadTheory dataLangTheory;


(* *********************** *)
(* * Auxiliary functions * *)
(* *********************** *)

fun diff_code code1 code2 = let
  val l1 = code1
           |> concl                |> rhs
           |> dest_comb            |> snd
           |> listSyntax.dest_list |> fst;
  val l2 = code2
           |> concl                |> rhs
           |> dest_comb            |> snd
           |> listSyntax.dest_list |> fst;
  val [(p1,p2)] = filter (not o (uncurry aconv)) (zip l1 l2)
  in (p1,p2)
  end

fun diff_codes code1 code2 = let
  val l1 = code1
           |> concl                |> rhs
           |> dest_comb            |> snd
           |> listSyntax.dest_list |> fst;
  val l2 = code2
           |> concl                |> rhs
           |> dest_comb            |> snd
           |> listSyntax.dest_list |> fst;
  in filter (not o (uncurry aconv)) (zip l1 l2)
  end

(* val _ = translation_extends "basisProg"; *)

fun whole_prog u = get_ml_prog_state ()
  |> ml_progLib.clean_state
  |> ml_progLib.remove_snocs
  |> ml_progLib.get_prog

fun ops_in_prog prog_def =
  let
    fun rpt_rator t = rpt_rator (rator t) handle _ => t
    val terms = find_terms (can (match_term ``_ : closLang$op``)) ((rhs o concl) prog_def)
  in foldl (fn (x,l) => if exists (aconv x) l then l else (x::l)) [] (map rpt_rator terms)
  end

(* fun top_goal_pat pat = *)
(*     let val (_,goal) = top_goal () *)
(*     in find_terms (can (match_term pat)) goal *)
(*     end *)

val s = ``s:('c,'ffi) dataSem$state``

val _ = sptreeSyntax.temp_add_sptree_printer ()

(* *********** *)
(* * Tactics * *)
(* *********** *)

(* Conversion with memoization  *)
fun mem_conv c =
  let val memory = ref ([] : (term * thm) list)
  in fn t => (snd (first (aconv t o fst) (!memory)))
             handle HOL_ERR _ =>
                    let val th = QCONV c t
                    in memory := (t,th) :: (!memory);
                       th
                    end
  end

(* Evaluate a subterm of the goal *)
fun eval_goalsub_tac pat (asms,goal) =
   let
   val tm = goal |> find_term (can (match_term pat))
   val th = EVAL tm
   in PURE_ONCE_REWRITE_TAC [th] (asms,goal)
   end

(* Generate all possible lookup for a code sptree *)
fun mk_code_lookup code_tm code_def = EVERY_lookup
  |> Q.ISPEC code_tm
  |> CONV_RULE (PATH_CONV "rrr" (K code_def))
  |> CONV_RULE (RAND_CONV EVAL)
  |> SIMP_RULE (srw_ss()) []

(* Generate all possible lookup for frame sizes *)
fun mk_frame_lookup frame_tm frame_def = EVERY_lookup
  |> Q.ISPEC frame_tm
  |> CONV_RULE (PATH_CONV "rrrr" (K frame_def))
  |> CONV_RULE (RAND_CONV EVAL)
  |> SIMP_RULE (srw_ss()) []

(* remove makespace bindings *)
val strip_makespace =
  qmatch_goalsub_abbrev_tac `bind _ rest_mkspc _`
  \\ REWRITE_TAC [ bind_def, makespace_def, add_space_def]
  \\ eval_goalsub_tac ``dataSem$cut_env _ _`` \\ simp []
  \\ eval_goalsub_tac ``dataSem$state_locals_fupd _ _``
  \\ Q.UNABBREV_TAC `rest_mkspc`

fun mk_strip_assign code_lookup frame_lookup =
  qmatch_goalsub_abbrev_tac `bind _ rest_ass _`
  \\ REWRITE_TAC [ bind_def           , assign_def
                 , op_space_reset_def , closLangTheory.op_case_def
                 , cut_state_opt_def  , option_case_def
                 , do_app_def         , data_spaceTheory.op_space_req_def
                 , do_space_def       , closLangTheory.op_distinct
                 , MEM                , IS_NONE_DEF
                 , add_space_def      , check_lim_def
                 , do_stack_def       , flush_state_def
                 , bvi_to_dataTheory.op_requires_names_eqn ]
  \\ BETA_TAC
  \\ TRY(eval_goalsub_tac ``dataSem$cut_state _ _`` \\ simp [])
  \\ TRY(eval_goalsub_tac ``dataSem$get_vars    _ _`` \\ simp [])
  \\ simp [ do_app_aux_def    , set_var_def       , lookup_def
          , domain_IS_SOME    , code_lookup       , size_of_heap_def
          , consume_space_def , with_fresh_ts_def , stack_consumed_def
          , frame_lookup      , allowed_op_def    , size_of_stack_def
          , flush_state_def   , vs_depth_def      , eq_code_stack_max_def
          , lookup_insert     , semanticPrimitivesTheory.copy_array_def
          , size_of_stack_frame_def
          , backend_commonTheory.small_enough_int_def ]
  \\ (fn (asm, goal) => let
        val pat   = ``sptree$lookup _ _``
        val terms = find_terms (can (match_term pat)) goal
        val simps = map (PATH_CONV "lr" EVAL) terms
      in ONCE_REWRITE_TAC simps (asm,goal) end)
  \\ simp [frame_lookup]
  \\ eval_goalsub_tac ``dataSem$state_locals_fupd _ _``
  \\ Q.UNABBREV_TAC `rest_ass`

fun mk_open_tailcall code_lookup frame_lookup =
  ASM_REWRITE_TAC [ tailcall_def , find_code_def
                  , get_vars_def , get_var_def
                  , lookup_def   , timeout_def
                  , flush_state_def]
  \\ simp [code_lookup,lookup_def,frame_lookup]
  \\ IF_CASES_TAC >- (simp [data_safe_def,size_of_def,frame_lookup] \\ EVAL_TAC)
  \\ REWRITE_TAC [ call_env_def   , dec_clock_def
                 , to_shallow_thm , to_shallow_def
                 , flush_state_def ]
  \\ simp []
  \\ eval_goalsub_tac ``dataSem$state_locals_fupd _ _``

val close_tailcall =
  ho_match_mp_tac data_safe_res
  \\ reverse conj_tac >- (rw [] \\ pairarg_tac \\ rw [])

fun mk_make_tailcall open_tailcall =
  open_tailcall \\ close_tailcall

fun mk_open_call code_lookup frame_lookup =
  simp [ call_def      , find_code_def  , push_env_def
       , get_vars_def  , call_env_def   , dec_clock_def
       , cut_env_def   , domain_def     , data_safe_def
       , EMPTY_SUBSET  , get_var_def    , size_of_stack_def
       , lookup_def    , domain_IS_SOME , frame_lookup
       , code_lookup   , lookup_def     , domain_IS_SOME
       , lookup_insert , flush_state_def
       , size_of_stack_frame_def]
  \\ IF_CASES_TAC >- (simp [data_safe_def,size_of_def,frame_lookup]
                     (* This deals with the symbolic cases *)
                     \\ TRY (fs [size_of_stack_def,GREATER_DEF]
                            \\ EVAL_TAC \\ NO_TAC)
                     \\ EVAL_TAC)
  \\ REWRITE_TAC [ push_env_def   , to_shallow_def
                 , to_shallow_thm , flush_state_def]
  \\ eval_goalsub_tac ``dataSem$state_locals_fupd _ _``

val close_call =
  qmatch_goalsub_abbrev_tac `f (dataSem$state_locals_fupd _ _)`
  \\ qmatch_goalsub_abbrev_tac `f s`
  \\ `data_safe (f s)` suffices_by
     (EVERY_CASE_TAC \\ rw [data_safe_def]
     \\ fs [data_safe_def,data_safe_move
           ,set_var_safe_for_space]
     \\ drule_then drule pop_env_safe_for_space
     \\ fs [set_var_safe_for_space])
  \\ Q.UNABBREV_TAC `f`
  \\ Q.UNABBREV_TAC `s`

fun mk_make_call open_call =
  open_call \\ close_call

(* val (asms,goal) = top_goal() *)

fun mk_strip_call open_call (asms,goal) =
  let val free_names = map (fn tm => fst (dest_var tm)) (free_varsl (goal::asms))
      fun next_name n name =
          let val new_name = name^"_"^(Int.toString n)
          in if n = 0
             then if mem name free_names
                  then next_name (n+1) name
                  else [QUOTE name]
             else if mem new_name free_names
             then next_name (n+1) name
             else [QUOTE new_name]
          end
  in (qmatch_goalsub_abbrev_tac (`bind _ ` @ (next_name 0 "rest_call") @ ` _`)
     \\ ONCE_REWRITE_TAC [bind_def]
     \\ open_call \\ rw [data_safe_def]) (asms,goal)
  end

val make_if =
  simp [if_var_def,data_safe_def,lookup_def,flush_state_def]
  \\ REWRITE_TAC [ isBool_def
                 , backend_commonTheory.bool_to_tag_def
                 , backend_commonTheory.true_tag_def
                 , backend_commonTheory.false_tag_def]
  \\ simp [pop_env_def]
  \\ eval_goalsub_tac ``dataSem$state_locals_fupd _ _``

end
