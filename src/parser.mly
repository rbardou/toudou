/**********************************************************************************/
/* MIT License                                                                    */
/*                                                                                */
/* Copyright (c) 2023 Romain Bardou                                               */
/*                                                                                */
/* Permission is hereby granted, free of charge, to any person obtaining a copy   */
/* of this software and associated documentation files (the "Software"), to deal  */
/* in the Software without restriction, including without limitation the rights   */
/* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      */
/* copies of the Software, and to permit persons to whom the Software is          */
/* furnished to do so, subject to the following conditions:                       */
/*                                                                                */
/* The above copyright notice and this permission notice shall be included in all */
/* copies or substantial portions of the Software.                                */
/*                                                                                */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     */
/* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       */
/* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    */
/* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         */
/* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  */
/* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  */
/* SOFTWARE.                                                                      */
/**********************************************************************************/

%{
  open AST
%}

%token <int> INT
%token DASH
%token LPAR RPAR
%token EOF

%token TODAY
%token TOMORROW
%token NEXT
%token WEEK
%token MONTH
%token YEAR
%token LATER
%token DAILY
%token EVERY
%token FROM
%token <Date.dow> DOW

%type <AST.date AST.annotation> annotation
%start annotation
%%

annotation:
| date
  { Date $1 }
| frequency
  { Frequency ($1, None) }
| frequency FROM date
  { Frequency ($1, Some $3) }
| LATER
  { Later }

date:
| INT
  { Day_of_month $1 }
| INT DASH INT
  { Day_of_year { m = $1; d = $3 } }
| INT DASH INT DASH INT
  { Day { y = $1; m = $3; d = $5 } }
| TODAY
  { Today }
| TOMORROW
  { Tomorrow }
| DOW
  { Dow $1 }
| NEXT WEEK
  { Next_week }
| NEXT MONTH
  { Next_month }
| NEXT YEAR
  { Next_year }

frequency:
| DAILY
  { Daily }
| EVERY DOW
  { Weekly $2 }
| EVERY INT
  { Monthly $2 }
| EVERY INT DASH INT
  { Yearly { m = $2; d = $4 } }
