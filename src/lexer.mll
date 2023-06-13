(**********************************************************************************)
(* MIT License                                                                    *)
(*                                                                                *)
(* Copyright (c) 2023 Romain Bardou                                               *)
(*                                                                                *)
(* Permission is hereby granted, free of charge, to any person obtaining a copy   *)
(* of this software and associated documentation files (the "Software"), to deal  *)
(* in the Software without restriction, including without limitation the rights   *)
(* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      *)
(* copies of the Software, and to permit persons to whom the Software is          *)
(* furnished to do so, subject to the following conditions:                       *)
(*                                                                                *)
(* The above copyright notice and this permission notice shall be included in all *)
(* copies or substantial portions of the Software.                                *)
(*                                                                                *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     *)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    *)
(* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         *)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  *)
(* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  *)
(* SOFTWARE.                                                                      *)
(**********************************************************************************)

{
  open Parser

  let keyword s =
    match String.lowercase_ascii s with
      | "t" | "tod" | "today" -> TODAY
      | "tom" | "tomorrow" -> TOMORROW
      | "next" -> NEXT
      | "week" -> WEEK
      | "month" -> MONTH
      | "year" -> YEAR
      | "later" -> LATER
      | "daily" -> DAILY
      | "every" -> EVERY
      | "from" -> FROM
      | "mon" | "monday" -> DOW Mon
      | "tue" | "tuesday" -> DOW Tue
      | "wed" | "wednesday" -> DOW Wed
      | "thu" | "thursday" -> DOW Thu
      | "fri" | "friday" -> DOW Fri
      | "sat" | "saturday" -> DOW Sat
      | "sun" | "sunday" -> DOW Sun
      | _ -> failwith ("invalid annotation: " ^ s)
}

let blank = [' ' '\t' '\r']

rule line = parse
  | '-'
      blank* '[' blank* ['x' 'X'] blank* ']'
      (blank* '(' ([^')']* as annotation) ')')?
      blank* (_* as title)
    { Some (AST.Item { checked = true; annotation; title }) }
  | '-'
      (blank* '[' blank* ']')?
      (blank* '(' ([^')']* as annotation) ')')?
      blank* (_* as title)
    { Some (AST.Item { checked = false; annotation; title }) }
  | blank*
    { None }
  | _* as annotation
    { Some (AST.Section annotation) }

and annotation_token = parse
  | '\n' { assert false (* split lines first please *) }
  | [' ' '\t' '\r']+ { annotation_token lexbuf }
  | '-' { DASH }
  | '(' { LPAR }
  | ')' { RPAR }
  | ['0'-'9']+ as x {
      match int_of_string_opt x with
        | None ->
            keyword x
        | Some i ->
            INT i
    }
  | "—" [^'\n']+ { annotation_token lexbuf (* ignore comments *) }
  | [^'\n' ' ' '\t' '\r' '-' '(' ')']+ as x { keyword x }
  | eof { EOF }
