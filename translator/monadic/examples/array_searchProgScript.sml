(*
  An example showing how to use the monadic translator to translate monadic
  array search functions, including exceptions.
 *)

open preamble ml_monad_translator_interfaceLib

val _ = new_theory "array_searchProg"

(* Create the data type to handle the array. *)
val _ = Datatype `
  state_array = <| arr : num list |>`; (* single resizeable array *)

(* Data type for the exceptions *)
val _ = Hol_datatype`
  state_exn = Subscript`;

val config =  global_state_config |>
              with_state ``:state_array`` |>
              with_exception ``:state_exn`` |>
              with_resizeable_arrays
                [("arr", ``[] : num list``,
                  ``Subscript``, ``Subscript``)];

(* Initialize the translation *)
val _ = start_translation config;

(* Monadic translations *)

(* HOW TO PROVE TERMINATION? *)
(*
val linear_search_aux_def = Define `
  linear_search_aux (value:num) (start_index:num) =
    do
      len <- arr_length;
      if start_index ≥ len then
        return NONE
      else
        do
          elem <- (arr_sub start_index);
          if elem = value then
            return (SOME start_index)
          else
            linear_search_aux value (start_index + 1)
        od
    od
`
*)

val linear_search_aux_def = Define `
  linear_search_aux (value:num) (start_index:num) =
    do
      if start_index = 0n then
        return NONE
      else
        do
          elem <- (arr_sub (start_index - 1));
          if elem = value then
            return (SOME start_index)
          else
            linear_search_aux value (start_index - 1)
        od
    od
`

val linear_search_def = Define `
  linear_search value = do len <- arr_length; linear_search_aux value len od
`

val binary_search_aux_def = tDefine "binary_search_aux" `
  binary_search_aux value start finish =
    do
      len <- arr_length;
      if start ≥ finish ∨ finish > len then return NONE else
          let mid = (finish + start) DIV 2n in
            do
              elem <- arr_sub mid;
              if value = elem then return (SOME mid)
              else if value < elem then
                binary_search_aux value start mid
              else
                binary_search_aux value (mid + 1n) finish
            od
  od
`
  (
    WF_REL_TAC `measure (λ (_, start, finish) . finish - start)` >>
    rw[] >>
    fs[NOT_GREATER_EQ, NOT_GREATER, ADD1] >>
    `start <= (finish + start) DIV 2` by fs[X_LE_DIV]
    >- DECIDE_TAC
    >- fs[DIV_LT_X]
  );

val binary_search_def = Define `
  binary_search value =
    do len <- arr_length; binary_search_aux value 0 len od`;

val linear_search_aux_v = m_translate linear_search_aux_def;
val linear_search_v = m_translate linear_search_def;

val binary_search_aux_v = m_translate binary_search_aux_def;
val binary_search_v = m_translate binary_search_def;

val _ = export_theory ();