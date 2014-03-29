(*Generated by Lem from intLang4.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasivesTheory semanticPrimitivesTheory astTheory bigStepTheory intLang2Theory intLang3Theory compilerLibTheory;

val _ = numLib.prefer_num();



val _ = new_theory "intLang4"

(* The fourth intermediate language (IL4). Removes pattern-matching and
 * variable names.
 *
 * The AST of IL4 differs from IL3 in that it uses de Bruijn indices, there are
 * no Mat expressions, Handle expressions are simplified to catch and bind any
 * exception without matching on it, and there are new Tag_eq and El
 * expressions for checking the constructor of a compound value and retrieving
 * its arguments. 
 *
 * The values and semantics of IL4 are the same as IL3, modulo the changes to
 * expressions.
 *
 *)

(*open import Pervasives*)
(*open import SemanticPrimitives*)
(*open import Ast*)
(*open import BigStep*)
(*open import IntLang2*)
(*open import IntLang3*)
(*open import CompilerLib*)
(*
open import Lib
open import List_extra
*)

(* TODO: Lem's builtin find index has a different type *)
(*val find_index : forall 'a. 'a -> list 'a -> nat -> maybe nat*) (* to pick up the definition in miscTheory *)

(* TODO: move *)
val _ = type_abbrev((*  'a *) "store_genv" , ``: 'a store # ( 'a option) list``);

val _ = Hol_datatype `
 uop_i4 =
    Opderef_i4
  | Opref_i4
  | Init_global_var_i4 of num
  | Tag_eq_i4 of num
  | El_i4 of num`;


val _ = Hol_datatype `
 exp_i4 =
    Raise_i4 of exp_i4
  | Handle_i4 of exp_i4 => exp_i4
  | Lit_i4 of lit
  | Con_i4 of num => exp_i4 list
  | Var_local_i4 of num
  | Var_global_i4 of num
  | Fun_i4 of exp_i4
  | Uapp_i4 of uop_i4 => exp_i4
  | App_i4 of op => exp_i4 => exp_i4
  | If_i4 of exp_i4 => exp_i4 => exp_i4
  | Let_i4 of exp_i4 => exp_i4
  | Letrec_i4 of exp_i4 list => exp_i4
  | Extend_global_i4 of num`;


val _ = Hol_datatype `
 v_i4 =
    Litv_i4 of lit
  | Conv_i4 of num => v_i4 list
  | Closure_i4 of v_i4 list => exp_i4
  | Recclosure_i4 of v_i4 list => exp_i4 list => num
  | Loc_i4 of num`;


(*val uop_to_i4 : uop_i2 -> uop_i4*)
 val _ = Define `

(uop_to_i4 Opderef_i2 = Opderef_i4)
/\
(uop_to_i4 Opref_i2 = Opref_i4)
/\
(uop_to_i4 (Init_global_var_i2 n) = (Init_global_var_i4 n))`;


(*val sIf_i4 : exp_i4 -> exp_i4 -> exp_i4 -> exp_i4*)
val _ = Define `

(sIf_i4 e1 e2 e3 =  
(if (e2 = Lit_i4 (Bool T)) /\ (e3 = Lit_i4 (Bool F)) then e1 else
  (case e1 of
    Lit_i4 (Bool b) => if b then e2 else e3
  | _ => If_i4 e1 e2 e3
  )))`;


(*val fo_i4 : exp_i4 -> bool*)
 val _ = Define `

(fo_i4 (Raise_i4 _) = T)
/\
(fo_i4 (Handle_i4 e1 e2) = (fo_i4 e1 /\ fo_i4 e2))
/\
(fo_i4 (Lit_i4 _) = T)
/\
(fo_i4 (Con_i4 _ es) = (fo_list_i4 es))
/\
(fo_i4 (Var_local_i4 _) = F)
/\
(fo_i4 (Var_global_i4 _) = F)
/\
(fo_i4 (Fun_i4 _) = F)
/\
(fo_i4 (Uapp_i4 uop _) = ((uop <> Opderef_i4) /\ (! n. uop <> El_i4 n)))
/\
(fo_i4 (App_i4 op _ _) = (op <> Opapp))
/\
(fo_i4 (If_i4 _ e2 e3) = (fo_i4 e2 /\ fo_i4 e3))
/\
(fo_i4 (Let_i4 _ e2) = (fo_i4 e2))
/\
(fo_i4 (Letrec_i4 _ e) = (fo_i4 e))
/\
(fo_i4 (Extend_global_i4 _) = T)
/\
(fo_list_i4 [] = T)
/\
(fo_list_i4 (e::es) = (fo_i4 e /\ fo_list_i4 es))`;


(*val pure_uop_i4 : uop_i4 -> bool*)
 val _ = Define `

(pure_uop_i4 Opderef_i4 = T)
/\
(pure_uop_i4 Opref_i4 = F)
/\
(pure_uop_i4 (Init_global_var_i4 _) = F)
/\
(pure_uop_i4 (Tag_eq_i4 _) = T)
/\
(pure_uop_i4 (El_i4 _) = T)`;


(*val pure_op : op -> bool*)
 val _ = Define `

(pure_op (Opn opn) = ((opn <> Divide) /\ (opn <> Modulo)))
/\
(pure_op (Opb _) = T)
/\
(pure_op Equality = F)
/\
(pure_op Opapp = F)
/\
(pure_op Opassign = F)`;


(*val pure_i4 : exp_i4 -> bool*)
 val _ = Define `

(pure_i4 (Raise_i4 _) = F)
/\
(pure_i4 (Handle_i4 e1 _) = (pure_i4 e1))
/\
(pure_i4 (Lit_i4 _) = T)
/\
(pure_i4 (Con_i4 _ es) = (pure_list_i4 es))
/\
(pure_i4 (Var_local_i4 _) = T)
/\
(pure_i4 (Var_global_i4 _) = T)
/\
(pure_i4 (Fun_i4 _) = T)
/\
(pure_i4 (Uapp_i4 uop e) = (pure_uop_i4 uop /\ pure_i4 e))
/\
(pure_i4 (App_i4 op e1 e2) = (pure_i4 e1 /\ (pure_i4 e2 /\
  (pure_op op \/ ((op = Equality) /\ (fo_i4 e1 /\ fo_i4 e2))))))
/\
(pure_i4 (If_i4 e1 e2 e3) = (pure_i4 e1 /\ (pure_i4 e2 /\ pure_i4 e3)))
/\
(pure_i4 (Let_i4 e1 e2) = (pure_i4 e1 /\ pure_i4 e2))
/\
(pure_i4 (Letrec_i4 _ e) = (pure_i4 e))
/\
(pure_i4 (Extend_global_i4 _) = F)
/\
(pure_list_i4 [] = T)
/\
(pure_list_i4 (e::es) = (pure_i4 e /\ pure_list_i4 es))`;


(*val ground_i4 : nat -> exp_i4 -> bool*)
 val _ = Define `

(ground_i4 n (Raise_i4 e) = (ground_i4 n e))
/\
(ground_i4 n (Handle_i4 e1 e2) = (ground_i4 n e1 /\ ground_i4 (n+ 1) e2))
/\
(ground_i4 _ (Lit_i4 _) = T)
/\
(ground_i4 n (Con_i4 _ es) = (ground_list_i4 n es))
/\
(ground_i4 n (Var_local_i4 k) = (k < n))
/\
(ground_i4 _ (Var_global_i4 _) = T)
/\
(ground_i4 n (Fun_i4 e) = (ground_i4 (n+ 1) e))
/\
(ground_i4 n (Uapp_i4 _ e) = (ground_i4 n e))
/\
(ground_i4 n (App_i4 _ e1 e2) = (ground_i4 n e1 /\ ground_i4 n e2))
/\
(ground_i4 n (If_i4 e1 e2 e3) = (ground_i4 n e1 /\ (ground_i4 n e2 /\ ground_i4 n e3)))
/\
(ground_i4 n (Let_i4 e1 e2) = (ground_i4 n e1 /\ ground_i4 (n+ 1) e2))
/\
(ground_i4 n (Letrec_i4 es e) = (ground_list_i4 ((n+LENGTH es)+ 1) es /\ ground_i4 (n+LENGTH es) e))
/\
(ground_i4 _ (Extend_global_i4 _) = T)
/\
(ground_list_i4 _ [] = T)
/\
(ground_list_i4 n (e::es) = (ground_i4 n e /\ ground_list_i4 n es))`;


(*val sLet_i4 : exp_i4 -> exp_i4 -> exp_i4*)
 val _ = Define `

(sLet_i4 e1 (Var_local_i4 0) = e1)
/\
(sLet_i4 e1 e2 =  
(if pure_i4 e1 /\ ground_i4( 0) e2
  then e2
  else Let_i4 e1 e2))`;


(* bind elements 0..k of the variable n in reverse order above e (first element
 * becomes most recently bound) *)
(*val Let_Els_i4 : nat -> nat -> exp_i4 -> exp_i4*)
 val Let_Els_i4_defn = Hol_defn "Let_Els_i4" `

(Let_Els_i4 _ 0 e = e)
/\
(Let_Els_i4 n k e =  
(sLet_i4 (Uapp_i4 (El_i4 (k -  1)) (Var_local_i4 n))
     (Let_Els_i4 (n+ 1) (k -  1) e)))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn Let_Els_i4_defn;

(* return an expression that evaluates to whether the pattern matches the most
 * recently bound variable *)
(*val pat_to_i4 : pat_i2 -> exp_i4*)
(* return an expression that evaluates to whether all the m patterns match the
 * m most recently bound variables; n counts 0..m *)
(*val pats_to_i4 : nat -> list pat_i2 -> exp_i4*)
 val pat_to_i4_defn = Hol_defn "pat_to_i4" `

(pat_to_i4 (Pvar_i2 _) = (Lit_i4 (Bool T)))
/\
(pat_to_i4 (Plit_i2 l) = (App_i4 Equality (Var_local_i4( 0)) (Lit_i4 l)))
/\
(pat_to_i4 (Pcon_i2 tag []) =  
(App_i4 Equality (Var_local_i4( 0)) (Con_i4 tag [])))
/\
(pat_to_i4 (Pcon_i2 tag ps) =  
(sIf_i4 (Uapp_i4 (Tag_eq_i4 tag) (Var_local_i4( 0)))
    (Let_Els_i4( 0) (LENGTH ps) (pats_to_i4( 0) ps))
    (Lit_i4 (Bool F))))
/\
(pat_to_i4 (Pref_i2 p) =  
(sLet_i4 (Uapp_i4 Opderef_i4 (Var_local_i4( 0)))
    (pat_to_i4 p)))
/\
(pats_to_i4 _ [] = (Lit_i4 (Bool T)))
/\
(pats_to_i4 n (p::ps) =  
(sIf_i4 (sLet_i4 (Var_local_i4 n) (pat_to_i4 p))
    (pats_to_i4 (n+ 1) ps)
    (Lit_i4 (Bool F))))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn pat_to_i4_defn;

(* given a pattern in a context of bound variables where the most recently
 * bound variable is the value to be matched, return a function that binds new
 * variables (including all the pattern variables) over an expression and the
 * new context of bound variables for the expression as well as the number of
 * newly bound variables *)
(*val row_to_i4 : list (maybe varN) -> pat_i2 -> list (maybe varN) * nat * (exp_i4 -> exp_i4)*)
(*val cols_to_i4 : list (maybe varN) -> nat -> nat -> list pat_i2 -> list (maybe varN) * nat * (exp_i4 -> exp_i4)*)
 val row_to_i4_defn = Hol_defn "row_to_i4" `

(row_to_i4 (NONE::bvs) (Pvar_i2 x) = ((SOME x::bvs), 0, (\ e .  e)))
/\
(row_to_i4 bvs (Plit_i2 _) = (bvs, 0, (\ e .  e)))
/\
(row_to_i4 bvs (Pcon_i2 _ ps) = (cols_to_i4 bvs( 0)( 0) ps))
/\
(row_to_i4 bvs (Pref_i2 p) =  
(let (bvs,m,f) = (row_to_i4 (NONE::bvs) p) in
    (bvs,( 1+m), (\ e .  sLet_i4 (Uapp_i4 Opderef_i4 (Var_local_i4( 0))) (f e)))))
/\
(row_to_i4 _ _ = ([], 0, (\ e .  e))) (* should not happen *)
/\
(cols_to_i4 bvs _ _ [] = (bvs, 0, (\ e .  e)))
/\
(cols_to_i4 bvs n k (p::ps) =  
(let (bvs,m,f) = (row_to_i4 (NONE::bvs) p) in
  let (bvs,ms,fs) = (cols_to_i4 bvs ((n+ 1)+m) (k+ 1) ps) in
    (bvs,(( 1+m)+ms),       
(\ e . 
           sLet_i4 (Uapp_i4 (El_i4 k) (Var_local_i4 n))
             (f (fs e))))))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn row_to_i4_defn;

(* translate to i4 under a context of bound variables *)
(*val exp_to_i4 : list (maybe varN) -> exp_i2 -> exp_i4*)
(*val exps_to_i4 : list (maybe varN) -> list exp_i2 -> list exp_i4*)
(*val funs_to_i4 : list (maybe varN) -> list (varN * varN * exp_i2) -> list exp_i4*)
(* assumes the value being matched is most recently bound *)
(*val pes_to_i4 : list (maybe varN) -> list (pat_i2 * exp_i2) -> exp_i4*)
 val exp_to_i4_defn = Hol_defn "exp_to_i4" `

(exp_to_i4 bvs (Raise_i2 e) = (Raise_i4 (exp_to_i4 bvs e)))
/\
(exp_to_i4 bvs (Handle_i2 e1 pes) =  
(Handle_i4 (exp_to_i4 bvs e1) (pes_to_i4 (NONE::bvs) pes)))
/\
(exp_to_i4 _ (Lit_i2 l) = (Lit_i4 l))
/\
(exp_to_i4 bvs (Con_i2 tag es) = (Con_i4 tag (exps_to_i4 bvs es)))
/\
(exp_to_i4 bvs (Var_local_i2 x) = (Var_local_i4 (the( 0) (misc$find_index (SOME x) bvs( 0)))))
/\
(exp_to_i4 _ (Var_global_i2 n) = (Var_global_i4 n))
/\
(exp_to_i4 bvs (Fun_i2 x e) = (Fun_i4 (exp_to_i4 (SOME x::bvs) e)))
/\
(exp_to_i4 bvs (Uapp_i2 uop e) = (Uapp_i4 (uop_to_i4 uop) (exp_to_i4 bvs e)))
/\
(exp_to_i4 bvs (App_i2 op e1 e2) =  
(App_i4 op (exp_to_i4 bvs e1) (exp_to_i4 bvs e2)))
/\
(exp_to_i4 bvs (If_i2 e1 e2 e3) =  
(sIf_i4 (exp_to_i4 bvs e1) (exp_to_i4 bvs e2) (exp_to_i4 bvs e3)))
/\
(exp_to_i4 bvs (Mat_i2 e pes) =  
(sLet_i4 (exp_to_i4 bvs e) (pes_to_i4 (NONE::bvs) pes)))
/\
(exp_to_i4 bvs (Let_i2 x e1 e2) =  
(sLet_i4 (exp_to_i4 bvs e1) (exp_to_i4 (SOME x::bvs) e2)))
/\
(exp_to_i4 bvs (Letrec_i2 funs e) =  
(let bvs = ((MAP (\p .  
  (case (p ) of ( (f,_,_) ) => SOME f )) funs) ++ bvs) in
  Letrec_i4 (funs_to_i4 bvs funs) (exp_to_i4 bvs e)))
/\
(exp_to_i4 _ (Extend_global_i2 n) = (Extend_global_i4 n))
/\
(exps_to_i4 _ [] = ([]))
/\
(exps_to_i4 bvs (e::es) =  
(exp_to_i4 bvs e :: exps_to_i4 bvs es))
/\
(funs_to_i4 _ [] = ([]))
/\
(funs_to_i4 bvs ((_,x,e)::funs) =  
(exp_to_i4 (SOME x::bvs) e :: funs_to_i4 bvs funs))
/\
(pes_to_i4 bvs [(p,e)] = 
  ((case row_to_i4 bvs p of (bvs,_,f) => f (exp_to_i4 bvs e) )))
/\
(pes_to_i4 bvs ((p,e)::pes) =  
(sIf_i4 (pat_to_i4 p)
    ((case row_to_i4 bvs p of (bvs,_,f) => f (exp_to_i4 bvs e) ))
    (pes_to_i4 bvs pes)))
/\
(pes_to_i4 _ _ = (Var_local_i4( 0)))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn exp_to_i4_defn; (* should not happen *)

(*val do_uapp_i4 : store_genv v_i4 -> uop_i4 -> v_i4 -> maybe (store_genv v_i4 * v_i4)*)
val _ = Define `
 (do_uapp_i4 (s,genv) uop v =  
((case uop of
      Opderef_i4 =>
        (case v of
            Loc_i4 n =>
              (case store_lookup n s of
                  SOME v => SOME ((s,genv),v)
                | NONE => NONE
              )
          | _ => NONE
        )
    | Opref_i4 =>
        let (s',n) = (store_alloc v s) in
          SOME ((s',genv), Loc_i4 n)
    | Init_global_var_i4 idx =>
        if idx < LENGTH genv then
          (case EL idx genv of
              NONE => SOME ((s, LUPDATE (SOME v) idx genv), Litv_i4 Unit)
            | SOME _ => NONE
          )
        else
          NONE
    | Tag_eq_i4 n =>
        (case v of
            Conv_i4 tag _ =>
              SOME ((s,genv), Litv_i4 (Bool (tag = n)))
          | _ => NONE
        )
    | El_i4 n =>
        (case v of
            Conv_i4 _ vs =>
              if n < LENGTH vs then
                SOME ((s,genv), EL n vs)
              else
                NONE
          | _ => NONE
        )
  )))`;


(*val build_rec_env_i4 : list exp_i4 -> list v_i4 -> list v_i4*)
val _ = Define `
 (build_rec_env_i4 funs cl_env =  
(GENLIST (Recclosure_i4 cl_env funs) (LENGTH funs)))`;


(*val exn_env_i4 : list v_i4*)
val _ = Define `
 (exn_env_i4 = ([]))`;


(*val do_eq_i4 : v_i4 -> v_i4 -> eq_result*)
 val do_eq_i4_defn = Hol_defn "do_eq_i4" `

(do_eq_i4 (Litv_i4 l1) (Litv_i4 l2) =  
(Eq_val (l1 = l2)))
/\
(do_eq_i4 (Loc_i4 l1) (Loc_i4 l2) = (Eq_val (l1 = l2)))
/\
(do_eq_i4 (Conv_i4 tag1 vs1) (Conv_i4 tag2 vs2) =  
(if (tag1 = tag2) /\ (LENGTH vs1 = LENGTH vs2) then
    do_eq_list_i4 vs1 vs2
  else
    Eq_val F))
/\
(do_eq_i4 (Closure_i4 _ _) (Closure_i4 _ _) = Eq_closure)
/\
(do_eq_i4 (Closure_i4 _ _) (Recclosure_i4 _ _ _) = Eq_closure)
/\
(do_eq_i4 (Recclosure_i4 _ _ _) (Closure_i4 _ _) = Eq_closure)
/\
(do_eq_i4 (Recclosure_i4 _ _ _) (Recclosure_i4 _ _ _) = Eq_closure)
/\
(do_eq_i4 _ _ = Eq_type_error)
/\
(do_eq_list_i4 [] [] = (Eq_val T))
/\
(do_eq_list_i4 (v1::vs1) (v2::vs2) =  
((case do_eq_i4 v1 v2 of
      Eq_closure => Eq_closure
    | Eq_type_error => Eq_type_error
    | Eq_val r =>
        if ~ r then
          Eq_val F
        else
          do_eq_list_i4 vs1 vs2
  )))
/\
(do_eq_list_i4 _ _ = (Eq_val F))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn do_eq_i4_defn;

(*val do_app_i4 : list v_i4 -> store v_i4 -> op -> v_i4 -> v_i4 -> maybe (list v_i4 * store v_i4 * exp_i4)*)
val _ = Define `
 (do_app_i4 env' s op v1 v2 =  
((case (op, v1, v2) of
      (Opapp, Closure_i4 env e, v) =>
        SOME ((v::env), s, e)
    | (Opapp, Recclosure_i4 env funs n, v) =>
        if n < LENGTH funs then
          SOME ((v::((build_rec_env_i4 funs env)++env)), s, EL n funs)
        else
          NONE
    | (Opn op, Litv_i4 (IntLit n1), Litv_i4 (IntLit n2)) =>
        if ((op = Divide) \/ (op = Modulo)) /\ (n2 =( 0 : int)) then
          SOME (exn_env_i4, s, Raise_i4 (Con_i4 div_tag []))
        else
          SOME (env', s, Lit_i4 (IntLit (opn_lookup op n1 n2)))
    | (Opb op, Litv_i4 (IntLit n1), Litv_i4 (IntLit n2)) =>
        SOME (env', s, Lit_i4 (Bool (opb_lookup op n1 n2)))
    | (Equality, v1, v2) =>
        (case do_eq_i4 v1 v2 of
            Eq_type_error => NONE
          | Eq_closure => SOME (exn_env_i4, s, Raise_i4 (Con_i4 eq_tag []))
          | Eq_val b => SOME (env', s, Lit_i4 (Bool b))
        )
    | (Opassign, (Loc_i4 lnum), v) =>
        (case store_assign lnum v s of
          SOME st => SOME (env', st, Lit_i4 Unit)
        | NONE => NONE
        )
    | _ => NONE
  )))`;


(*val do_if_i4 : v_i4 -> exp_i4 -> exp_i4 -> maybe exp_i4*)
val _ = Define `
 (do_if_i4 v e1 e2 =  
(if v = Litv_i4 (Bool T) then
    SOME e1
  else if v = Litv_i4 (Bool F) then
    SOME e2
  else
    NONE))`;


val _ = Hol_reln ` (! ck env l s.
T
==>
evaluate_i4 ck env s (Lit_i4 l) (s, Rval (Litv_i4 l)))

/\ (! ck env e s1 s2 v.
(evaluate_i4 ck s1 env e (s2, Rval v))
==>
evaluate_i4 ck s1 env (Raise_i4 e) (s2, Rerr (Rraise v)))

/\ (! ck env e s1 s2 err.
(evaluate_i4 ck s1 env e (s2, Rerr err))
==>
evaluate_i4 ck s1 env (Raise_i4 e) (s2, Rerr err))

/\ (! ck s1 s2 env e1 v e2.
(evaluate_i4 ck s1 env e1 (s2, Rval v))
==>
evaluate_i4 ck s1 env (Handle_i4 e1 e2) (s2, Rval v))

/\ (! ck s1 s2 env e1 e2 v bv.
(evaluate_i4 ck env s1 e1 (s2, Rerr (Rraise v)) /\
evaluate_i4 ck (v::env) s2 e2 bv)
==>
evaluate_i4 ck env s1 (Handle_i4 e1 e2) bv)

/\ (! ck s1 s2 env e1 e2 err.
(evaluate_i4 ck env s1 e1 (s2, Rerr err) /\
((err = Rtimeout_error) \/ (err = Rtype_error)))
==>
evaluate_i4 ck env s1 (Handle_i4 e1 e2) (s2, Rerr err))

/\ (! ck env tag es vs s s'.
(evaluate_list_i4 ck env s es (s', Rval vs))
==>
evaluate_i4 ck env s (Con_i4 tag es) (s', Rval (Conv_i4 tag vs)))

/\ (! ck env tag es err s s'.
(evaluate_list_i4 ck env s es (s', Rerr err))
==>
evaluate_i4 ck env s (Con_i4 tag es) (s', Rerr err))

/\ (! ck env n s.
(LENGTH env > n)
==>
evaluate_i4 ck env s (Var_local_i4 n) (s, Rval (EL n env)))

/\ (! ck env n s.
(~ (LENGTH env > n))
==>
evaluate_i4 ck env s (Var_local_i4 n) (s, Rerr Rtype_error))

/\ (! ck env n v s genv.
((LENGTH genv > n) /\
(EL n genv = SOME v))
==>
evaluate_i4 ck env (s,genv) (Var_global_i4 n) ((s,genv), Rval v))

/\ (! ck env n s genv.
((LENGTH genv > n) /\
(EL n genv = NONE))
==>
evaluate_i4 ck env (s,genv) (Var_global_i4 n) ((s,genv), Rerr Rtype_error))

/\ (! ck env n s genv.
(~ (LENGTH genv > n))
==>
evaluate_i4 ck env (s,genv) (Var_global_i4 n) ((s,genv), Rerr Rtype_error))

/\ (! ck env e s.
T
==>
evaluate_i4 ck env s (Fun_i4 e) (s, Rval (Closure_i4 env e)))

/\ (! ck env uop e v v' s1 s2 count s3 genv2 genv3.
(evaluate_i4 ck env s1 e (((count,s2),genv2), Rval v) /\
(do_uapp_i4 (s2,genv2) uop v = SOME ((s3,genv3),v')))
==>
evaluate_i4 ck env s1 (Uapp_i4 uop e) (((count,s3),genv3), Rval v'))

/\ (! ck env uop e v s1 s2 count genv2.
(evaluate_i4 ck env s1 e (((count,s2),genv2), Rval v) /\
(do_uapp_i4 (s2,genv2) uop v = NONE))
==>
evaluate_i4 ck env s1 (Uapp_i4 uop e) (((count,s2),genv2), Rerr Rtype_error))

/\ (! ck env uop e err s s'.
(evaluate_i4 ck env s e (s', Rerr err))
==>
evaluate_i4 ck env s (Uapp_i4 uop e) (s', Rerr err))

/\ (! ck env op e1 e2 v1 v2 env' e3 bv s1 s2 s3 count s4 genv3.
(evaluate_i4 ck env s1 e1 (s2, Rval v1) /\
(evaluate_i4 ck env s2 e2 (((count,s3),genv3), Rval v2) /\
((do_app_i4 env s3 op v1 v2 = SOME (env', s4, e3)) /\
(((ck /\ (op = Opapp)) ==> ~ (count =( 0))) /\
evaluate_i4 ck env' (((if ck then bigStep$dec_count op count else count),s4),genv3) e3 bv))))
==>
evaluate_i4 ck env s1 (App_i4 op e1 e2) bv)

/\ (! ck env op e1 e2 v1 v2 env' e3 s1 s2 s3 count s4 genv3.
(evaluate_i4 ck env s1 e1 (s2, Rval v1) /\
(evaluate_i4 ck env s2 e2 (((count,s3),genv3), Rval v2) /\
((do_app_i4 env s3 op v1 v2 = SOME (env', s4, e3)) /\
((count = 0) /\
((op = Opapp) /\
ck)))))
==>
evaluate_i4 ck env s1 (App_i4 op e1 e2) ((( 0,s4),genv3),Rerr Rtimeout_error))

/\ (! ck env op e1 e2 v1 v2 s1 s2 s3 count genv3.
(evaluate_i4 ck env s1 e1 (s2, Rval v1) /\
(evaluate_i4 ck env s2 e2 (((count,s3),genv3),Rval v2) /\
(do_app_i4 env s3 op v1 v2 = NONE)))
==>
evaluate_i4 ck env s1 (App_i4 op e1 e2) (((count,s3),genv3), Rerr Rtype_error))

/\ (! ck env op e1 e2 v1 err s1 s2 s3.
(evaluate_i4 ck env s1 e1 (s2, Rval v1) /\
evaluate_i4 ck env s2 e2 (s3, Rerr err))
==>
evaluate_i4 ck env s1 (App_i4 op e1 e2) (s3, Rerr err))

/\ (! ck env op e1 e2 err s s'.
(evaluate_i4 ck env s e1 (s', Rerr err))
==>
evaluate_i4 ck env s (App_i4 op e1 e2) (s', Rerr err))

/\ (! ck env e1 e2 e3 v e' bv s1 s2.
(evaluate_i4 ck env s1 e1 (s2, Rval v) /\
((do_if_i4 v e2 e3 = SOME e') /\
evaluate_i4 ck env s2 e' bv))
==>
evaluate_i4 ck env s1 (If_i4 e1 e2 e3) bv)

/\ (! ck env e1 e2 e3 v s1 s2.
(evaluate_i4 ck env s1 e1 (s2, Rval v) /\
(do_if_i4 v e2 e3 = NONE))
==>
evaluate_i4 ck env s1 (If_i4 e1 e2 e3) (s2, Rerr Rtype_error))

/\ (! ck env e1 e2 e3 err s s'.
(evaluate_i4 ck env s e1 (s', Rerr err))
==>
evaluate_i4 ck env s (If_i4 e1 e2 e3) (s', Rerr err))

/\ (! ck env e1 e2 v bv s1 s2.
(evaluate_i4 ck env s1 e1 (s2, Rval v) /\
evaluate_i4 ck (v::env) s2 e2 bv)
==>
evaluate_i4 ck env s1 (Let_i4 e1 e2) bv)

/\ (! ck env e1 e2 err s s'.
(evaluate_i4 ck env s e1 (s', Rerr err))
==>
evaluate_i4 ck env s (Let_i4 e1 e2) (s', Rerr err))

/\ (! ck env funs e bv s.
(evaluate_i4 ck ((build_rec_env_i4 funs env)++env) s e bv)
==>
evaluate_i4 ck env s (Letrec_i4 funs e) bv)

/\ (! ck env n s genv.
T
==>
evaluate_i4 ck env (s,genv) (Extend_global_i4 n) ((s,(genv++GENLIST (\n .  
  (case (n ) of ( _ ) => NONE )) n)), Rval (Litv_i4 Unit)))

/\ (! ck env s.
T
==>
evaluate_list_i4 ck env s [] (s, Rval []))

/\ (! ck env e es v vs s1 s2 s3.
(evaluate_i4 ck env s1 e (s2, Rval v) /\
evaluate_list_i4 ck env s2 es (s3, Rval vs))
==>
evaluate_list_i4 ck env s1 (e::es) (s3, Rval (v::vs)))

/\ (! ck env e es err s s'.
(evaluate_i4 ck env s e (s', Rerr err))
==>
evaluate_list_i4 ck env s (e::es) (s', Rerr err))

/\ (! ck env e es v err s1 s2 s3.
(evaluate_i4 ck env s1 e (s2, Rval v) /\
evaluate_list_i4 ck env s2 es (s3, Rerr err))
==>
evaluate_list_i4 ck env s1 (e::es) (s3, Rerr err))`;
val _ = export_theory()

