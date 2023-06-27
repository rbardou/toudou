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

let error s =
  prerr_endline ("Toudou: " ^ s);
  exit 1

let error x = Printf.ksprintf error x

let copy_file a b =
  let inch = open_in a in
  Fun.protect ~finally: (fun () -> close_in inch) @@ fun () ->
  let outch = open_out b in
  Fun.protect ~finally: (fun () -> close_out outch) @@ fun () ->
  let bytes = Bytes.create 4096 in
  let rec loop () =
    let len = input inch bytes 0 (Bytes.length bytes) in
    if len > 0 then (
      output outch bytes 0 len;
      loop ()
    )
  in
  loop ()

let read_lines filename =
  let ch = open_in filename in
  Fun.protect ~finally: (fun () -> close_in ch) @@ fun () ->
  let rec read acc =
    match input_line ch with
      | exception End_of_file ->
          List.rev acc
      | line ->
          read (line :: acc)
  in
  read []

let parse_line i line =
  let i = i + 1 in (* line numbers start at 1 *)
  try
    let parse_annotation annotation =
      Parser.annotation Lexer.annotation_token (Lexing.from_string annotation)
    in
    let line = Lexer.line (Lexing.from_string line) in
    Fun.flip Option.map line @@ function
    | Item { checked = _; annotation = None; title = _ } as x ->
        x
    | Item { checked; annotation = Some annotation; title } ->
        Item { checked; annotation = Some (parse_annotation annotation); title }
    | Section annotation ->
        Section (parse_annotation annotation)
  with
    | Failure e ->
        error "line %d: %s" i e
    | Parsing.Parse_error ->
        error "line %d: parse error" i

let output_frequency out (freq: AST.frequency) =
  match freq with
    | Daily ->
        out "daily"
    | Weekly dow ->
        out "every ";
        out (Date.show_dow dow)
    | Monthly d ->
        out (Printf.sprintf "every %02d" d)
    | Yearly { m; d } ->
        out (Printf.sprintf "every %02d-%02d" m d)

let output_annotation ~with_comment today out (annotation: Date.t AST.annotation) =
  match annotation with
    | Date date ->
        out (Date.show date);
        let c = Date.cmp date today in
        if with_comment && c >= 0 then (
          out " — ";
          if c = 0 then
            out "Today"
          else if Date.cmp date (Date.make { today with d = today.d + 1 }) = 0 then
            out "Tomorrow"
          else
            out (Date.show_dow (Date.dow date))
        )
    | Frequency (freq, None) ->
        output_frequency out freq
    | Frequency (freq, Some from) ->
        output_frequency out freq;
        out " from ";
        out (Date.show from)
    | Later ->
        out "later"

let output_item ~with_annotation today out
    ({ checked; annotation; title }: Date.t AST.annotation AST.item) =
  out "- ";
  if checked then
    out "[x] "
  else (
    match annotation with
      | None ->
          out "[ ] "
      | Some (Date d) ->
          if Date.cmp d today <= 0 then out "[ ] "
      | Some (Frequency _ | Later) ->
          ()
  );
  (
    match annotation with
      | None ->
          ()
      | Some annotation ->
          if with_annotation then (
            out "(";
            output_annotation ~with_comment: false today out annotation;
            out ") "
          )
  );
  out title;
  out "\n"

let rec resolve_date (today: Date.t) (date: AST.date): Date.t =
  match date with
    | Day_of_month d ->
        if today.d >= d then
          Date.make { y = today.y; m = today.m + 1; d }
        else
          Date.make { y = today.y; m = today.m; d }
    | Day_of_year { m; d } ->
        if today.m > m || (today.m = m && today.d >= d) then
          Date.make { y = today.y + 1; m; d }
        else
          Date.make { y = today.y; m; d }
    | Day d ->
        Date.make d
    | Today ->
        today
    | Tomorrow ->
        Date.make { today with d = today.d + 1 }
    | Dow dow ->
        let today_dow = Date.dow today in
        let today_dow_i = Date.int_of_dow today_dow in
        let dow_i = Date.int_of_dow dow in
        let dow_diff = dow_i - today_dow_i in
        if dow_diff > 0 then
          Date.make { today with d = today.d + dow_diff }
        else
          Date.make { today with d = today.d + dow_diff + 7 }
    | Next_week ->
        resolve_date today (Dow Mon)
    | Next_month ->
        resolve_date today (Day_of_month 01)
    | Next_year ->
        resolve_date today (Day_of_year { m = 01; d = 01 })

let resolve_dates_in_annotation today (annotation: AST.date AST.annotation):
  Date.t AST.annotation =
  match annotation with
    | Date d -> Date (resolve_date today d)
    | Frequency (_, None) as x -> x
    | Frequency (f, Some d) -> Frequency (f, Some (resolve_date today d))
    | Later -> Later

let resolve_dates today (line: AST.date AST.annotation AST.line):
  Date.t AST.annotation AST.line =
  match line with
    | Item { checked = _; annotation = None; title = _ } as x ->
        x
    | Item { checked; annotation = Some annotation; title } ->
        Item {
          checked;
          annotation = Some (resolve_dates_in_annotation today annotation);
          title;
        }
    | Section annotation ->
        Section (resolve_dates_in_annotation today annotation)

let apply_sections (lines: Date.t AST.annotation AST.line list):
  Date.t AST.annotation AST.item list =
  let rec parse (current_annotation: Date.t AST.annotation option) acc
      (lines: Date.t AST.annotation AST.line list) =
    match lines with
      | [] ->
          List.rev acc
      | AST.Section annotation :: tail ->
          parse (Some annotation) acc tail
      | Item { checked; annotation; title } :: tail ->
          let annotation =
            match annotation with
              | None ->
                  current_annotation
              | Some _ ->
                  annotation
          in
          let item: Date.t AST.annotation AST.item =
            {
              checked;
              annotation;
              title;
            }
          in
          parse current_annotation (item :: acc) tail
  in
  parse None [] lines

let instantiate_recurring_item today (item: Date.t AST.annotation AST.item):
  Date.t AST.annotation AST.item list =
  let new_from (freq: AST.frequency) =
    resolve_date today (
      match freq with
        | Daily ->
            Tomorrow
        | Weekly dow ->
            Dow dow
        | Monthly d ->
            Day_of_month d
        | Yearly md ->
            Day_of_year md
    )
  in
  match item.annotation with
    | None | Some (Date _) | Some Later ->
        [ item ]
    | Some (Frequency (freq, None)) ->
        (* Don't instantiate (the item was just added) but update [from]. *)
        let new_from = new_from freq in
        [ { item with annotation = Some (Frequency (freq, Some new_from)) } ]
    | Some (Frequency (freq, Some from)) ->
        if
          (* Don't instantiate if [from] is in the future. *)
          Date.cmp from today > 0
        then
          [ item ]
        else
          let new_from = new_from freq in
          [
            { item with annotation = None };
            { item with annotation = Some (Frequency (freq, Some new_from)) };
          ]

let update_date today (x: Date.t AST.annotation AST.item) =
  if x.checked then
    match x.annotation with
      | None | Some Later ->
          { x with annotation = Some (AST.Date today) }
      | Some (Date d) ->
          if Date.cmp d today > 0 then
            { x with annotation = Some (Date today) }
          else
            x
      | Some (Frequency _) ->
          x
  else
    match x.annotation with
      | Some (Date d) ->
          if Date.cmp d today <= 0 then
            { x with annotation = Some (Date today) }
          else
            x
      | None ->
          { x with annotation = Some (Date today) }
      | Some (Frequency _ | Later) ->
          x

let by_date_and_checked today
    (a: Date.t AST.annotation AST.item) (b: Date.t AST.annotation AST.item) =
  let date (a: Date.t AST.annotation AST.item) =
    match a.annotation with
      | Some (Date x) -> x
      | Some Later -> { y = max_int; m = max_int; d = max_int - 1 }
      | Some (Frequency _) -> { y = max_int; m = max_int; d = max_int }
      | None -> today
  in
  let c = Date.cmp (date a) (date b) in
  if c <> 0 then c else
    match a.checked, b.checked with
      | false, false | true, true -> 0
      | false, true -> 1
      | true, false -> -1

let group_by_annotation (items: Date.t AST.annotation AST.item list):
  (Date.t AST.annotation option * Date.t AST.annotation AST.item list) list =
  let rec group previous_groups current_annotation current_group
      (items: Date.t AST.annotation AST.item list) =
    match items with
      | [] ->
          List.rev ((current_annotation, List.rev current_group) :: previous_groups)
      | head :: tail ->
          if head.annotation = current_annotation then
            group previous_groups current_annotation (head :: current_group) tail
          else
            group ((current_annotation, List.rev current_group) :: previous_groups)
              head.annotation [ head ] tail
  in
  group [] None [] items
  |> List.filter (fun (_, l) -> l <> [])

let output_group today out i (annotation, items) =
  if i <> 0 then out "\n";
  (
    match annotation with
      | None ->
          ()
      | Some annotation ->
          output_annotation ~with_comment: true today out annotation;
          out "\n"
  );
  List.iter (output_item ~with_annotation: false today out) items

let main () =
  let filename =
    if Array.length Sys.argv <> 2 then (
      prerr_endline "Usage: toudou <FILE>";
      exit 0
    );
    Sys.argv.(1)
  in
  let bak = filename ^ ".bak" in
  copy_file filename bak;
  let today = Date.today () in
  let groups =
    read_lines filename
    |> List.mapi parse_line
    |> List.filter_map Fun.id
    |> List.map (resolve_dates today)
    |> apply_sections
    |> List.concat_map (instantiate_recurring_item today)
    |> List.map (update_date today)
    |> List.sort (by_date_and_checked today)
    |> group_by_annotation
  in
  let ch = open_out filename in
  try
    Fun.protect ~finally: (fun () -> close_out ch) @@ fun () ->
    List.iteri (output_group today (output_string ch)) groups
  with exn ->
    Sys.rename bak filename;
    raise exn

let () =
  try
    main ()
  with exn ->
    error "uncaught exception: %s" (Printexc.to_string exn)
