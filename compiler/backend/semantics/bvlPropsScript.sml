open preamble bvlTheory bvlSemTheory clos_to_bvlTheory bvl_constTheory;
open prim_tagsTheory;

val _ = new_theory"bvlProps";

val with_same_code = Q.store_thm("with_same_code[simp]",
  `(s:'ffi bvlSem$state) with code := s.code = s`,
  srw_tac[][bvlSemTheory.state_component_equality])

val dec_clock_with_code = Q.store_thm("dec_clock_with_code[simp]",
  `bvlSem$dec_clock n (s with code := c) = dec_clock n s with code := c`,
  EVAL_TAC );

val do_app_with_code = Q.store_thm("do_app_with_code",
  `bvlSem$do_app op vs s = Rval (r,s') ⇒
   domain s.code ⊆ domain c ⇒
   do_app op vs (s with code := c) = Rval (r,s' with code := c)`,
  srw_tac[][do_app_def] >>
  BasicProvers.CASE_TAC >> full_simp_tac(srw_ss())[] >>
  BasicProvers.CASE_TAC >> full_simp_tac(srw_ss())[] >>
  every_case_tac >> full_simp_tac(srw_ss())[LET_THM] >> srw_tac[][] >>
  full_simp_tac(srw_ss())[SUBSET_DEF] >> METIS_TAC[]);

val do_app_with_code_err = Q.store_thm("do_app_with_code_err",
  `bvlSem$do_app op vs s = Rerr e ⇒
   (domain c ⊆ domain s.code ∨ e ≠ Rabort Rtype_error) ⇒
   do_app op vs (s with code := c) = Rerr e`,
  srw_tac[][do_app_def] >>
  BasicProvers.CASE_TAC >> full_simp_tac(srw_ss())[] >>
  BasicProvers.CASE_TAC >> full_simp_tac(srw_ss())[] >>
  every_case_tac >> full_simp_tac(srw_ss())[LET_THM] >> srw_tac[][] >>
  full_simp_tac(srw_ss())[SUBSET_DEF] >> METIS_TAC[]);

val initial_state_simp = Q.store_thm("initial_state_simp[simp]",
  `(initial_state f c k).code = c ∧
   (initial_state f c k).ffi = f ∧
   (initial_state f c k).clock = k ∧
   (initial_state f c k).refs = FEMPTY ∧
   (initial_state f c k).globals = []`,
   srw_tac[][initial_state_def]);

val initial_state_with_simp = Q.store_thm("initial_state_with_simp[simp]",
  `initial_state f c k with clock := k1 = initial_state f c k1 ∧
   initial_state f c k with code := c1 = initial_state f c1 k`,
  EVAL_TAC);

val bool_to_tag_11 = store_thm("bool_to_tag_11[simp]",
  ``bool_to_tag b1 = bool_to_tag b2 ⇔ (b1 = b2)``,
  srw_tac[][bool_to_tag_def] >> EVAL_TAC >> simp[])

val _ = Q.store_thm("Boolv_11[simp]",`bvlSem$Boolv b1 = Boolv b2 ⇔ b1 = b2`,EVAL_TAC>>srw_tac[][]);

val find_code_EVERY_IMP = store_thm("find_code_EVERY_IMP",
  ``(find_code dest a (r:'ffi bvlSem$state).code = SOME (q,t)) ==>
    EVERY P a ==> EVERY P q``,
  Cases_on `dest` \\ full_simp_tac(srw_ss())[find_code_def] \\ REPEAT STRIP_TAC
  \\ BasicProvers.EVERY_CASE_TAC \\ SRW_TAC [] [] \\ full_simp_tac(srw_ss())[]
  \\ BasicProvers.EVERY_CASE_TAC \\ SRW_TAC [] [] \\ full_simp_tac(srw_ss())[]
  \\ `?x1 l1. a = SNOC x1 l1` by METIS_TAC [SNOC_CASES] \\ full_simp_tac(srw_ss())[]
  \\ BasicProvers.EVERY_CASE_TAC \\ SRW_TAC [] [] \\ full_simp_tac(srw_ss())[]
  \\ BasicProvers.EVERY_CASE_TAC \\ SRW_TAC [] [] \\ full_simp_tac(srw_ss())[]
  \\ BasicProvers.EVERY_CASE_TAC \\ SRW_TAC [] [] \\ full_simp_tac(srw_ss())[]
  \\ BasicProvers.EVERY_CASE_TAC \\ SRW_TAC [] [] \\ full_simp_tac(srw_ss())[]
  \\ FULL_SIMP_TAC std_ss [GSYM SNOC_APPEND,FRONT_SNOC]);

val do_app_err = Q.store_thm("do_app_err",
  `do_app op vs s = Rerr e ⇒ (e = Rabort Rtype_error)`,
  srw_tac[][do_app_def] >> every_case_tac >> full_simp_tac(srw_ss())[LET_THM] >> srw_tac[][]);

val evaluate_LENGTH = prove(
  ``!xs s env. (\(xs,s,env).
      (case evaluate (xs,s,env) of (Rval res,s1) => (LENGTH xs = LENGTH res)
            | _ => T))
      (xs,s,env)``,
  HO_MATCH_MP_TAC evaluate_ind \\ REPEAT STRIP_TAC
  \\ FULL_SIMP_TAC (srw_ss()) [evaluate_def]
  \\ SRW_TAC [] [] \\ SRW_TAC [] []
  \\ BasicProvers.EVERY_CASE_TAC \\ FULL_SIMP_TAC (srw_ss()) []
  \\ REV_FULL_SIMP_TAC std_ss [] \\ FULL_SIMP_TAC (srw_ss()) [])
  |> SIMP_RULE std_ss [];

val _ = save_thm("evaluate_LENGTH", evaluate_LENGTH);

val evaluate_IMP_LENGTH = store_thm("evaluate_IMP_LENGTH",
  ``(evaluate (xs,s,env) = (Rval res,s1)) ==> (LENGTH xs = LENGTH res)``,
  REPEAT STRIP_TAC \\ MP_TAC (SPEC_ALL evaluate_LENGTH) \\ full_simp_tac(srw_ss())[]);

val evaluate_CONS = store_thm("evaluate_CONS",
  ``evaluate (x::xs,env,s) =
      case evaluate ([x],env,s) of
      | (Rval v,s2) =>
         (case evaluate (xs,env,s2) of
          | (Rval vs,s1) => (Rval (HD v::vs),s1)
          | t => t)
      | t => t``,
  Cases_on `xs` \\ full_simp_tac(srw_ss())[evaluate_def]
  \\ Cases_on `evaluate ([x],env,s)` \\ full_simp_tac(srw_ss())[evaluate_def]
  \\ Cases_on `q` \\ full_simp_tac(srw_ss())[evaluate_def]
  \\ IMP_RES_TAC evaluate_IMP_LENGTH
  \\ Cases_on `a` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `t` \\ full_simp_tac(srw_ss())[]);

val evaluate_SNOC = store_thm("evaluate_SNOC",
  ``!xs env s x.
      evaluate (SNOC x xs,env,s) =
      case evaluate (xs,env,s) of
      | (Rval vs,s2) =>
         (case evaluate ([x],env,s2) of
          | (Rval v,s1) => (Rval (vs ++ v),s1)
          | t => t)
      | t => t``,
  Induct THEN1
   (full_simp_tac(srw_ss())[SNOC_APPEND,evaluate_def] \\ REPEAT STRIP_TAC
    \\ Cases_on `evaluate ([x],env,s)` \\ Cases_on `q` \\ full_simp_tac(srw_ss())[])
  \\ full_simp_tac(srw_ss())[SNOC_APPEND,APPEND]
  \\ ONCE_REWRITE_TAC [evaluate_CONS]
  \\ REPEAT STRIP_TAC
  \\ Cases_on `evaluate ([h],env,s)` \\ Cases_on `q` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `evaluate (xs,env,r)` \\ Cases_on `q` \\ full_simp_tac(srw_ss())[]
  \\ Cases_on `evaluate ([x],env,r')` \\ Cases_on `q` \\ full_simp_tac(srw_ss())[evaluate_def]
  \\ IMP_RES_TAC evaluate_IMP_LENGTH
  \\ Cases_on `a''` \\ full_simp_tac(srw_ss())[LENGTH]
  \\ REV_FULL_SIMP_TAC std_ss [LENGTH_NIL] \\ full_simp_tac(srw_ss())[]);

val evaluate_APPEND = store_thm("evaluate_APPEND",
  ``!xs env s ys.
      evaluate (xs ++ ys,env,s) =
      case evaluate (xs,env,s) of
        (Rval vs,s2) =>
          (case evaluate (ys,env,s2) of
             (Rval ws,s1) => (Rval (vs ++ ws),s1)
           | res => res)
      | res => res``,
  Induct \\ full_simp_tac(srw_ss())[APPEND,evaluate_def] \\ REPEAT STRIP_TAC
  THEN1 REPEAT BasicProvers.CASE_TAC
  \\ ONCE_REWRITE_TAC [evaluate_CONS]
  \\ REPEAT BasicProvers.CASE_TAC \\ full_simp_tac(srw_ss())[]);

val evaluate_SING = Q.store_thm("evaluate_SING",
  `(evaluate ([x],env,s) = (Rval a,p1)) ==> ?d1. a = [d1]`,
  REPEAT STRIP_TAC \\ IMP_RES_TAC evaluate_IMP_LENGTH
  \\ Cases_on `a` \\ full_simp_tac(srw_ss())[LENGTH_NIL]);

val evaluate_code = store_thm("evaluate_code",
  ``!xs env s1 vs s2.
      (evaluate (xs,env,s1) = (vs,s2)) ==> s2.code = s1.code``,
  recInduct evaluate_ind \\ REPEAT STRIP_TAC
  \\ POP_ASSUM MP_TAC \\ ONCE_REWRITE_TAC [evaluate_def]
  \\ FULL_SIMP_TAC std_ss []
  \\ BasicProvers.FULL_CASE_TAC
  \\ REPEAT STRIP_TAC \\ SRW_TAC [] [dec_clock_def]
  \\ Cases_on`q`  \\ FULL_SIMP_TAC (srw_ss())[]
  \\ POP_ASSUM MP_TAC
  \\ BasicProvers.CASE_TAC \\ FULL_SIMP_TAC (srw_ss())[]
  \\ SRW_TAC[][] \\ SRW_TAC[][]
  \\ POP_ASSUM MP_TAC
  \\ BasicProvers.CASE_TAC \\ FULL_SIMP_TAC (srw_ss())[]
  \\ SRW_TAC[][] \\ IMP_RES_TAC do_app_const \\ SRW_TAC[][]
  \\ POP_ASSUM MP_TAC
  \\ BasicProvers.CASE_TAC \\ FULL_SIMP_TAC (srw_ss())[]
  \\ SRW_TAC[][] \\ SRW_TAC[][dec_clock_def]);

val evaluate_mk_tick = Q.store_thm ("evaluate_mk_tick",
  `!exp env s n.
    evaluate ([mk_tick n exp], env, s) =
      if s.clock < n then
        (Rerr(Rabort Rtimeout_error), s with clock := 0)
      else
        evaluate ([exp], env, dec_clock n s)`,
  Induct_on `n` >>
  srw_tac[][mk_tick_def, evaluate_def, dec_clock_def, FUNPOW] >>
  full_simp_tac(srw_ss())[mk_tick_def, evaluate_def, dec_clock_def] >>
  srw_tac[][] >>
  full_simp_tac (srw_ss()++ARITH_ss) [dec_clock_def, ADD1]
  >- (`s with clock := s.clock = s`
             by srw_tac[][state_component_equality] >>
      srw_tac[][])
  >- (`s.clock = n` by decide_tac >>
      full_simp_tac(srw_ss())[]));

val evaluate_MAP_Const = store_thm("evaluate_MAP_Const",
  ``!exps.
      evaluate (MAP (K (Op (Const i) [])) (exps:'a list),env,t1) =
        (Rval (MAP (K (Number i)) exps),t1)``,
  Induct \\ full_simp_tac(srw_ss())[evaluate_def,evaluate_CONS,do_app_def]);

val evaluate_Bool = Q.store_thm("evaluate_Bool[simp]",
  `evaluate ([Bool b],env,s) = (Rval [Boolv b],s)`,
  EVAL_TAC)

fun split_tac q = Cases_on q \\ Cases_on `q` \\ FULL_SIMP_TAC (srw_ss()) []

val evaluate_expand_env = Q.store_thm("evaluate_expand_env",
  `!xs a s env.
     FST (evaluate (xs,a,s)) <> Rerr(Rabort Rtype_error) ==>
     (evaluate (xs,a ++ env,s) = evaluate (xs,a,s))`,
  recInduct evaluate_ind \\ REPEAT STRIP_TAC \\ POP_ASSUM MP_TAC
  \\ ONCE_REWRITE_TAC [evaluate_def] \\ ASM_SIMP_TAC std_ss []
  THEN1 (split_tac `evaluate ([x],env,s)` \\ split_tac `evaluate (y::xs,env,r)`)
  THEN1 (Cases_on `n < LENGTH env` \\ FULL_SIMP_TAC (srw_ss()) []
         \\ SRW_TAC [] [rich_listTheory.EL_APPEND1] \\ DECIDE_TAC)
  THEN1 (split_tac `evaluate ([x1],env,s)` \\ SRW_TAC [] [])
  THEN1 (split_tac `evaluate (xs,env,s)`)
  THEN1 (split_tac `evaluate ([x1],env,s)`)
  THEN1 (split_tac `evaluate ([x1],env,s1)` \\ BasicProvers.CASE_TAC >> simp[])
  THEN1 (split_tac `evaluate (xs,env,s)`)
  THEN1 (SRW_TAC [] [])
  THEN1 (split_tac `evaluate (xs,env,s1)`));

val inc_clock_def = Define `
  inc_clock ck s = s with clock := s.clock + ck`;

val inc_clock_code = Q.store_thm ("inc_clock_code",
  `!n (s:'ffi bvlSem$state). (inc_clock n s).code = s.code`,
  srw_tac[][inc_clock_def]);

val inc_clock_refs = Q.store_thm ("inc_clock_refs",
  `!n (s:'ffi bvlSem$state). (inc_clock n s).refs = s.refs`,
  srw_tac[][inc_clock_def]);

val inc_clock_ffi = Q.store_thm ("inc_clock_ffi[simp]",
  `!n (s:'ffi bvlSem$state). (inc_clock n s).ffi = s.ffi`,
  srw_tac[][inc_clock_def]);

val inc_clock_clock = Q.store_thm ("inc_clock_clock[simp]",
  `!n (s:'ffi bvlSem$state). (inc_clock n s).clock = s.clock + n`,
  srw_tac[][inc_clock_def]);

val inc_clock0 = Q.store_thm ("inc_clock0",
  `!n (s:'ffi bvlSem$state). inc_clock 0 s = s`,
  simp [inc_clock_def, state_component_equality]);

val _ = export_rewrites ["inc_clock_refs", "inc_clock_code", "inc_clock0"];

val inc_clock_add = Q.store_thm("inc_clock_add",
  `inc_clock k1 (inc_clock k2 s) = inc_clock (k1 + k2) s`,
  simp[inc_clock_def,state_component_equality]);

val dec_clock_code = Q.store_thm ("dec_clock_code",
  `!n (s:'ffi bvlSem$state). (dec_clock n s).code = s.code`,
  srw_tac[][dec_clock_def]);

val dec_clock_refs = Q.store_thm ("dec_clock_refs",
  `!n (s:'ffi bvlSem$state). (dec_clock n s).refs = s.refs`,
  srw_tac[][dec_clock_def]);

val dec_clock_ffi = Q.store_thm ("dec_clock_ffi[simp]",
  `!n (s:'ffi bvlSem$state). (dec_clock n s).ffi = s.ffi`,
  srw_tac[][dec_clock_def]);

val dec_clock0 = Q.store_thm ("dec_clock0",
  `!n (s:'ffi bvlSem$state). dec_clock 0 s = s`,
  simp [dec_clock_def, state_component_equality]);

val _ = export_rewrites ["dec_clock_refs", "dec_clock_code", "dec_clock0"];

val do_app_change_clock = Q.store_thm("do_app_change_clock",
  `(do_app op args s1 = Rval (res,s2)) ==>
   (do_app op args (s1 with clock := ck) = Rval (res,s2 with clock := ck))`,
  SIMP_TAC std_ss [do_app_def]
  \\ BasicProvers.EVERY_CASE_TAC
  \\ full_simp_tac(srw_ss())[LET_DEF] \\ SRW_TAC [] [] \\ full_simp_tac(srw_ss())[] \\
  CCONTR_TAC >> full_simp_tac(srw_ss())[] >>
  srw_tac[][] >>
  full_simp_tac(srw_ss())[]);

val do_app_change_clock_err = Q.store_thm("do_app_change_clock_err",
  `(do_app op args s1 = Rerr e) ==>
   (do_app op args (s1 with clock := ck) = Rerr e)`,
  SIMP_TAC std_ss [do_app_def]
  \\ BasicProvers.EVERY_CASE_TAC
  \\ full_simp_tac(srw_ss())[LET_DEF] \\ SRW_TAC [] [] \\ full_simp_tac(srw_ss())[]);

val evaluate_add_clock = Q.store_thm ("evaluate_add_clock",
  `!exps env s1 res s2.
    evaluate (exps,env,s1) = (res, s2) ∧
    res ≠ Rerr(Rabort Rtimeout_error)
    ⇒
    !ck. evaluate (exps,env,inc_clock ck s1) = (res, inc_clock ck s2)`,
  recInduct evaluate_ind >>
  srw_tac[][evaluate_def]
  >- (Cases_on `evaluate ([x], env,s)` >> full_simp_tac(srw_ss())[] >>
      Cases_on `q` >> full_simp_tac(srw_ss())[] >> srw_tac[][] >>
      Cases_on `evaluate (y::xs,env,r)` >> full_simp_tac(srw_ss())[] >>
      Cases_on `q` >> full_simp_tac(srw_ss())[] >> srw_tac[][] >> full_simp_tac(srw_ss())[])
  >- (Cases_on `evaluate ([x1],env,s)` >> full_simp_tac(srw_ss())[] >>
      Cases_on `q` >> full_simp_tac(srw_ss())[] >> srw_tac[][] >> full_simp_tac(srw_ss())[])
  >- (Cases_on `evaluate (xs,env,s)` >>
      full_simp_tac(srw_ss())[] >>
      Cases_on `q` >>
      full_simp_tac(srw_ss())[] >>
      srw_tac[][] >> full_simp_tac(srw_ss())[])
  >- (Cases_on `evaluate (xs,env,s)` >> full_simp_tac(srw_ss())[] >>
      Cases_on `q` >> full_simp_tac(srw_ss())[] >> srw_tac[][] >> full_simp_tac(srw_ss())[] >>
      BasicProvers.EVERY_CASE_TAC >>
      full_simp_tac(srw_ss())[] >> srw_tac[][] >> full_simp_tac(srw_ss())[])
  >- (Cases_on `evaluate ([x1],env,s1)` >> full_simp_tac(srw_ss())[] >>
      Cases_on `q` >> full_simp_tac(srw_ss())[] >> srw_tac[][] >> full_simp_tac(srw_ss())[] >>
      Cases_on`e`>>full_simp_tac(srw_ss())[]>>srw_tac[][]>>full_simp_tac(srw_ss())[])
  >- (Cases_on `evaluate (xs,env,s)` >> full_simp_tac(srw_ss())[] >>
      Cases_on `q` >> full_simp_tac(srw_ss())[] >> srw_tac[][] >> full_simp_tac(srw_ss())[] >>
      srw_tac[][inc_clock_def] >>
      BasicProvers.EVERY_CASE_TAC >>
      full_simp_tac(srw_ss())[] >>
      imp_res_tac do_app_const >>
      imp_res_tac do_app_change_clock >>
      imp_res_tac do_app_change_clock_err >>
      full_simp_tac(srw_ss())[] >>
      srw_tac[][])
  >- (srw_tac[][] >>
      full_simp_tac(srw_ss())[inc_clock_def, dec_clock_def] >>
      srw_tac[][] >>
      `s.clock + ck - 1 = s.clock - 1 + ck` by (srw_tac [ARITH_ss] [ADD1]) >>
      metis_tac [])
  >- (Cases_on `evaluate (xs,env,s1)` >>
      full_simp_tac(srw_ss())[] >>
      Cases_on `q` >>
      full_simp_tac(srw_ss())[] >>
      srw_tac[][] >>
      BasicProvers.EVERY_CASE_TAC >>
      full_simp_tac(srw_ss())[] >>
      srw_tac[][] >>
      rev_full_simp_tac(srw_ss())[inc_clock_def, dec_clock_def] >>
      srw_tac[][]
      >- decide_tac >>
      `r.clock + ck - (ticks + 1) = r.clock - (ticks + 1) + ck` by srw_tac [ARITH_ss] [ADD1] >>
      metis_tac []));

val do_app_io_events_mono = Q.store_thm("do_app_io_events_mono",
  `do_app op vs s1 = Rval (x,s2) ⇒
   s1.ffi.io_events ≼ s2.ffi.io_events ∧
   (IS_SOME s1.ffi.final_event ⇒ s2.ffi = s1.ffi)`,
  srw_tac[][do_app_def] >> every_case_tac >> full_simp_tac(srw_ss())[LET_THM] >> srw_tac[][] >> full_simp_tac(srw_ss())[] >>
  full_simp_tac(srw_ss())[ffiTheory.call_FFI_def] >> every_case_tac >> full_simp_tac(srw_ss())[] >> srw_tac[][]);

val evaluate_io_events_mono = Q.store_thm("evaluate_io_events_mono",
  `!exps env s1 res s2.
    evaluate (exps,env,s1) = (res, s2)
    ⇒
    s1.ffi.io_events ≼ s2.ffi.io_events ∧
    (IS_SOME s1.ffi.final_event ⇒ s2.ffi = s1.ffi)`,
  recInduct evaluate_ind >>
  srw_tac[][evaluate_def] >>
  every_case_tac >> full_simp_tac(srw_ss())[] >>
  srw_tac[][] >> rev_full_simp_tac(srw_ss())[] >>
  metis_tac[IS_PREFIX_TRANS,do_app_io_events_mono])

val Boolv_11 = store_thm("Boolv_11[simp]",``bvlSem$Boolv b1 = Boolv b2 ⇔ b1 = b2``,EVAL_TAC>>srw_tac[][]);

val do_app_inc_clock = Q.prove(
  `do_app op vs (inc_clock x y) =
   map_result (λ(v,s). (v,s with clock := x + y.clock)) I (do_app op vs y)`,
  Cases_on`do_app op vs y` >>
  imp_res_tac do_app_change_clock_err >>
  TRY(Cases_on`a`>>imp_res_tac do_app_change_clock) >>
  full_simp_tac(srw_ss())[inc_clock_def] >> simp[])

val dec_clock_1_inc_clock = Q.prove(
  `x ≠ 0 ⇒ dec_clock 1 (inc_clock x s) = inc_clock (x-1) s`,
  simp[state_component_equality,inc_clock_def,dec_clock_def])

val dec_clock_1_inc_clock2 = Q.prove(
  `s.clock ≠ 0 ⇒ dec_clock 1 (inc_clock x s) = inc_clock x (dec_clock 1 s)`,
  simp[state_component_equality,inc_clock_def,dec_clock_def])

val dec_clock_inc_clock = Q.prove(
  `¬(s.clock < n) ⇒ dec_clock n (inc_clock x s) = inc_clock x (dec_clock n s)`,
  simp[state_component_equality,inc_clock_def,dec_clock_def])

val evaluate_add_to_clock_io_events_mono = Q.store_thm("evaluate_add_to_clock_io_events_mono",
  `∀exps env s extra.
    (SND(evaluate(exps,env,s))).ffi.io_events ≼
    (SND(evaluate(exps,env,inc_clock extra s))).ffi.io_events ∧
    (IS_SOME((SND(evaluate(exps,env,s))).ffi.final_event) ⇒
     (SND(evaluate(exps,env,inc_clock extra s))).ffi =
     (SND(evaluate(exps,env,s))).ffi)`,
  recInduct evaluate_ind >>
  srw_tac[][evaluate_def] >>
  TRY (
    rename1`Boolv T` >>
    qmatch_assum_rename_tac`IS_SOME _.ffi.final_event` >>
    ntac 4 (BasicProvers.CASE_TAC >> full_simp_tac(srw_ss())[] >> rev_full_simp_tac(srw_ss())[]) >>
    ntac 2 (TRY (BasicProvers.CASE_TAC >> full_simp_tac(srw_ss())[] >> rev_full_simp_tac(srw_ss())[])) >>
    srw_tac[][] >> full_simp_tac(srw_ss())[] >> rev_full_simp_tac(srw_ss())[]) >>
  every_case_tac >> full_simp_tac(srw_ss())[] >> rev_full_simp_tac(srw_ss())[] >>
  full_simp_tac(srw_ss())[dec_clock_1_inc_clock,dec_clock_1_inc_clock2] >>
  imp_res_tac evaluate_add_clock >> rev_full_simp_tac(srw_ss())[] >> full_simp_tac(srw_ss())[] >> srw_tac[][] >>
  imp_res_tac evaluate_io_events_mono >> rev_full_simp_tac(srw_ss())[] >> full_simp_tac(srw_ss())[] >> srw_tac[][] >>
  rev_full_simp_tac(srw_ss())[do_app_inc_clock] >> full_simp_tac(srw_ss())[] >> srw_tac[][] >> full_simp_tac(srw_ss())[] >>
  imp_res_tac do_app_io_events_mono >>
  TRY(fsrw_tac[ARITH_ss][] >>NO_TAC) >>
  full_simp_tac(srw_ss())[dec_clock_inc_clock] >>
  metis_tac[evaluate_io_events_mono,SND,IS_PREFIX_TRANS,Boolv_11,PAIR,
            inc_clock_ffi,dec_clock_ffi]);

val take_drop_lem = Q.prove (
  `!skip env.
    skip < LENGTH env ∧
    skip + SUC n ≤ LENGTH env ∧
    DROP skip env ≠ [] ⇒
    EL skip env::TAKE n (DROP (1 + skip) env) = TAKE (n + 1) (DROP skip env)`,
  Induct_on `n` >>
  srw_tac[][take1, hd_drop] >>
  `skip + SUC n ≤ LENGTH env` by decide_tac >>
  res_tac >>
  `LENGTH (DROP skip env) = LENGTH env - skip` by srw_tac[][LENGTH_DROP] >>
  `SUC n < LENGTH (DROP skip env)` by decide_tac >>
  `LENGTH (DROP (1 + skip) env) = LENGTH env - (1 + skip)` by srw_tac[][LENGTH_DROP] >>
  `n < LENGTH (DROP (1 + skip) env)` by decide_tac >>
  srw_tac[][TAKE_EL_SNOC, ADD1] >>
  `n + (1 + skip) < LENGTH env` by decide_tac >>
  `(n+1) + skip < LENGTH env` by decide_tac >>
  srw_tac[][EL_DROP] >>
  srw_tac [ARITH_ss] []);

val evaluate_genlist_vars = Q.store_thm ("evaluate_genlist_vars",
  `!skip env n st.
    n + skip ≤ LENGTH env ⇒
    evaluate (GENLIST (λarg. Var (arg + skip)) n, env, st)
    =
    (Rval (TAKE n (DROP skip env)), st)`,
  Induct_on `n` >>
  srw_tac[][evaluate_def, DROP_LENGTH_NIL, GSYM ADD1] >>
  srw_tac[][Once GENLIST_CONS] >>
  srw_tac[][Once evaluate_CONS, evaluate_def] >>
  full_simp_tac (srw_ss()++ARITH_ss) [] >>
  first_x_assum (qspecl_then [`skip + 1`, `env`] mp_tac) >>
  srw_tac[][] >>
  `n + (skip + 1) ≤ LENGTH env` by decide_tac >>
  full_simp_tac(srw_ss())[] >>
  srw_tac[][combinTheory.o_DEF, ADD1, GSYM ADD_ASSOC] >>
  `skip + 1 = 1 + skip ` by decide_tac >>
  full_simp_tac(srw_ss())[] >>
  `LENGTH (DROP skip env) = LENGTH env - skip` by srw_tac[][LENGTH_DROP] >>
  `n < LENGTH env - skip` by decide_tac >>
  `DROP skip env ≠ []`
        by (Cases_on `DROP skip env` >>
            full_simp_tac(srw_ss())[] >>
            decide_tac) >>
  metis_tac [take_drop_lem]);

val evaluate_var_reverse = Q.store_thm ("evaluate_var_reverse",
  `!xs env ys (st:'ffi bvlSem$state).
   evaluate (MAP Var xs, env, st) = (Rval ys, st)
   ⇒
   evaluate (REVERSE (MAP Var xs), env, st) = (Rval (REVERSE ys), st)`,
  Induct_on `xs` >>
  srw_tac[][evaluate_def] >>
  full_simp_tac(srw_ss())[evaluate_APPEND] >>
  pop_assum (mp_tac o SIMP_RULE (srw_ss()) [Once evaluate_CONS]) >>
  srw_tac[][] >>
  BasicProvers.EVERY_CASE_TAC >>
  full_simp_tac(srw_ss())[evaluate_def] >>
  BasicProvers.EVERY_CASE_TAC >>
  srw_tac[][] >>
  res_tac >>
  full_simp_tac(srw_ss())[]);

val evaluate_genlist_vars_rev = Q.store_thm ("evaluate_genlist_vars_rev",
  `!skip env n st.
    n + skip ≤ LENGTH env ⇒
    evaluate (REVERSE (GENLIST (λarg. Var (arg + skip)) n), env, st) =
    (Rval (REVERSE (TAKE n (DROP skip env))), st)`,
  srw_tac[][] >>
  imp_res_tac evaluate_genlist_vars >>
  pop_assum (qspec_then `st` assume_tac) >>
  `GENLIST (λarg. Var (arg + skip):bvl$exp) n = MAP Var (GENLIST (\arg. arg + skip) n)`
           by srw_tac[][MAP_GENLIST, combinTheory.o_DEF] >>
  full_simp_tac(srw_ss())[] >>
  metis_tac [evaluate_var_reverse]);

val evaluate_isConst = Q.store_thm("evaluate_isConst",
  `!xs. EVERY isConst xs ==>
        (evaluate (xs,env,s) = (Rval (MAP (Number o getConst) xs),s))`,
  Induct \\ full_simp_tac(srw_ss())[evaluate_def]
  \\ ONCE_REWRITE_TAC [evaluate_CONS]
  \\ Cases \\ full_simp_tac(srw_ss())[isConst_def]
  \\ Cases_on `o'` \\ full_simp_tac(srw_ss())[isConst_def]
  \\ Cases_on `l` \\ full_simp_tac(srw_ss())[isConst_def,evaluate_def,do_app_def,getConst_def]);

val do_app_refs_SUBSET = store_thm("do_app_refs_SUBSET",
  ``(do_app op a r = Rval (q,t)) ==> FDOM r.refs SUBSET FDOM t.refs``,
  full_simp_tac(srw_ss())[do_app_def]
  \\ NTAC 5 (full_simp_tac(srw_ss())[SUBSET_DEF,IN_INSERT] \\ SRW_TAC [] []
  \\ BasicProvers.EVERY_CASE_TAC
  \\ full_simp_tac(srw_ss())[LET_DEF,dec_clock_def]));

val evaluate_refs_SUBSET_lemma = prove(
  ``!xs env s. FDOM s.refs SUBSET FDOM (SND (evaluate (xs,env,s))).refs``,
  recInduct evaluate_ind \\ REPEAT STRIP_TAC \\ full_simp_tac(srw_ss())[evaluate_def]
  \\ BasicProvers.EVERY_CASE_TAC \\ full_simp_tac(srw_ss())[]
  \\ REV_FULL_SIMP_TAC std_ss []
  \\ IMP_RES_TAC SUBSET_TRANS
  \\ full_simp_tac(srw_ss())[dec_clock_def] \\ full_simp_tac(srw_ss())[]
  \\ IMP_RES_TAC do_app_refs_SUBSET \\ full_simp_tac(srw_ss())[SUBSET_DEF]);

val evaluate_refs_SUBSET = store_thm("evaluate_refs_SUBSET",
  ``(evaluate (xs,env,s) = (res,t)) ==> FDOM s.refs SUBSET FDOM t.refs``,
  REPEAT STRIP_TAC \\ MP_TAC (SPEC_ALL evaluate_refs_SUBSET_lemma) \\ full_simp_tac(srw_ss())[]);

val get_vars_def = Define `
  (get_vars [] env = SOME []) /\
  (get_vars (n::ns) env =
     if n < LENGTH env then
       (case get_vars ns env of
        | NONE => NONE
        | SOME vs => SOME (EL n env :: vs))
     else NONE)`

val isVar_def = Define `
  (isVar ((Var n):bvl$exp) = T) /\ (isVar _ = F)`;

val destVar_def = Define `
  (destVar ((Var n):bvl$exp) = n)`;

val evaluate_Var_list = Q.store_thm("evaluate_Var_list",
  `!l. EVERY isVar l ==>
       (evaluate (l,env,s) = (Rerr(Rabort Rtype_error),s)) \/
       ?vs. (evaluate (l,env,s) = (Rval vs,s)) /\
            (get_vars (MAP destVar l) env = SOME vs) /\
            (LENGTH vs = LENGTH l)`,
  Induct \\ full_simp_tac(srw_ss())[evaluate_def,get_vars_def] \\ Cases \\ full_simp_tac(srw_ss())[isVar_def]
  \\ ONCE_REWRITE_TAC [evaluate_CONS] \\ full_simp_tac(srw_ss())[evaluate_def]
  \\ Cases_on `n < LENGTH env` \\ full_simp_tac(srw_ss())[]
  \\ REPEAT STRIP_TAC \\ full_simp_tac(srw_ss())[destVar_def]);

val bVarBound_def = tDefine "bVarBound" `
  (bVarBound n [] <=> T) /\
  (bVarBound n ((x:bvl$exp)::y::xs) <=>
     bVarBound n [x] /\ bVarBound n (y::xs)) /\
  (bVarBound n [Var v] <=> v < n) /\
  (bVarBound n [If x1 x2 x3] <=>
     bVarBound n [x1] /\ bVarBound n [x2] /\ bVarBound n [x3]) /\
  (bVarBound n [Let xs x2] <=>
     bVarBound n xs /\ bVarBound (n + LENGTH xs) [x2]) /\
  (bVarBound n [Raise x1] <=> bVarBound n [x1]) /\
  (bVarBound n [Tick x1] <=>  bVarBound n [x1]) /\
  (bVarBound n [Op op xs] <=> bVarBound n xs) /\
  (bVarBound n [Handle x1 x2] <=>
     bVarBound n [x1] /\ bVarBound (n + 1) [x2]) /\
  (bVarBound n [Call ticks dest xs] <=> bVarBound n xs)`
  (WF_REL_TAC `measure (exp1_size o SND)`
   \\ REPEAT STRIP_TAC \\ TRY DECIDE_TAC
   \\ SRW_TAC [] [bvlTheory.exp_size_def] \\ DECIDE_TAC);

val bEvery_def = tDefine "bEvery" `
  (bEvery P [] <=> T) /\
  (bEvery P ((x:bvl$exp)::y::xs) <=>
     bEvery P [x] /\ bEvery P (y::xs)) /\
  (bEvery P [Var v] <=> P (Var v)) /\
  (bEvery P [If x1 x2 x3] <=> P (If x1 x2 x3) /\
     bEvery P [x1] /\ bEvery P [x2] /\ bEvery P [x3]) /\
  (bEvery P [Let xs x2] <=> P (Let xs x2) /\
     bEvery P xs /\ bEvery P [x2]) /\
  (bEvery P [Raise x1] <=> P (Raise x1) /\ bEvery P [x1]) /\
  (bEvery P [Tick x1] <=> P (Tick x1) /\ bEvery P [x1]) /\
  (bEvery P [Op op xs] <=> P (Op op xs) /\ bEvery P xs) /\
  (bEvery P [Handle x1 x2] <=> P (Handle x1 x2) /\
     bEvery P [x1] /\ bEvery P [x2]) /\
  (bEvery P [Call ticks dest xs] <=> P (Call ticks dest xs) /\ bEvery P xs)`
  (WF_REL_TAC `measure (exp1_size o SND)`
   \\ REPEAT STRIP_TAC \\ TRY DECIDE_TAC
   \\ SRW_TAC [] [bvlTheory.exp_size_def] \\ DECIDE_TAC);

val _ = export_rewrites["bEvery_def","bVarBound_def"];

val bVarBound_EVERY = Q.store_thm("bVarBound_EVERY",
  `∀ls. bVarBound P ls ⇔ EVERY (λe. bVarBound P [e]) ls`,
  Induct >> simp[] >> Cases >> simp[] >>
  Cases_on`ls`>>simp[]);

val bEvery_EVERY = Q.store_thm("bEvery_EVERY",
  `∀ls. bEvery P ls ⇔ EVERY (λe. bEvery P [e]) ls`,
  Induct >> simp[] >> Cases >> simp[] >>
  Cases_on`ls`>>simp[]);

val _ = export_theory();
