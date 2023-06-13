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

type t = { y: int; m: int; d: int }

type dow = Mon | Tue | Wed | Thu | Fri | Sat | Sun

let show_dow = function
  | Mon -> "Monday"
  | Tue -> "Tuesday"
  | Wed -> "Wednesday"
  | Thu -> "Thursday"
  | Fri -> "Friday"
  | Sat -> "Saturday"
  | Sun -> "Sunday"

let int_of_dow = function
  | Mon -> 0
  | Tue -> 1
  | Wed -> 2
  | Thu -> 3
  | Fri -> 4
  | Sat -> 5
  | Sun -> 6

let dow_of_int = function
  | 0 -> Mon
  | 1 -> Tue
  | 2 -> Wed
  | 3 -> Thu
  | 4 -> Fri
  | 5 -> Sat
  | 6 -> Sun
  | _ -> invalid_arg "dow_of_int"

let show { y; m; d } =
  Printf.sprintf "%04d-%02d-%02d" y m d

let cmp a b =
  let c = Int.compare a.y b.y in
  if c <> 0 then c else
    let c = Int.compare a.m b.m in
    if c <> 0 then c else
      Int.compare a.d b.d

let to_unix_tm date: Unix.tm =
  {
    tm_sec = 0;
    tm_min = 0;
    tm_hour = 12; (* Try to avoid edge cases... *)
    tm_mday = date.d;
    tm_mon = date.m - 1;
    tm_year = date.y - 1900;
    tm_wday = 0;
    tm_yday = 0;
    tm_isdst = false;
  }

let of_unix_tm (tm: Unix.tm) =
  {
    y = tm.tm_year + 1900;
    m = tm.tm_mon + 1;
    d = tm.tm_mday;
  }

let today () =
  of_unix_tm (Unix.localtime (Unix.time ()))

let make date =
  of_unix_tm (to_unix_tm date)

let dow date =
  let _, tm = Unix.mktime (to_unix_tm date) in
  match tm.tm_wday with
    | 0 -> Sun
    | 1 -> Mon
    | 2 -> Tue
    | 3 -> Wed
    | 4 -> Thu
    | 5 -> Fri
    | 6 -> Sat
    | _ -> assert false (* bug in Unix? *)
