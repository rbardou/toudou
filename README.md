# Toudou — Simple Todo-List Management Tool

Toudou takes your todo-list, cleans it up and fills today's list with
items from the past that were not done and with recurring items (e.g. "every Monday").

Toudou has two components:
- a command-line tool;
- an Emacs mode for files with extension `.todo`.

The Command-Line Tool takes your todo-list file and updates it.
For instance, running `toudou work.todo` updates `work.todo`
(after creating a backup `work.todo.bak`).

The Emacs mode provides some syntax highlighting, and invokes Toudou
on your file everytime you save.

## Install

### With Opam

Toudou is not yet in the public opam repository but you can just clone the Toudou
repository and install it like this:
```
opam install .
```
Then add something like this to your `.emacs`
(replace `SWITCH` with the name of your opam switch, e.g. `4.14.0`):
```
(add-to-list 'load-path "~/.opam/SWITCH/share/emacs/site-lisp")
(require 'toudou "toudou" 'noerror)
```

### Manually

Alternatively, you can just build the program with:
```
dune build
```
Then copy `_build/default/main.exe` into a directory which is in your `$PATH`,
with the name `toudou`.

Then add something like this to your `.emacs`
(replace `PATH` with the path to the `emacs` directory of Toudou,
or to a place where you copied `emacs/toudou.el`):
```
(add-to-list 'load-path "PATH")
(require 'toudou "toudou" 'noerror)
```

## Example

Create a new file named `home.todo`:
```
- laundry
- (tomorrow) groceries
- (every saturday) find a movie for tonight
- call plumber
```

Run `toudou home.todo` (or, if using `toudou-mode` in Emacs, just save with `C-x C-s`).
Toudou updates your file as follows (assuming today's date is 2023-06-06):
```
2023-06-06
- [ ] laundry
- [ ] call plumber

2023-06-07
- groceries

every Saturday from 2023-06-10
- find a movie for tonight
```
As you can see, Toudou sorted tasks by date, added checkboxes for today's tasks,
and added the date at which the recurring task to find a movie shall first occur.

If you now check the "call plumber" task (by writing an `x`) and run Toudou,
it will put it at the top of today's list:
```
2023-06-06
- [x] call plumber
- [ ] laundry

2023-06-07
- groceries

every Saturday from 2023-06-10
- find a movie for tonight
```

Let's assume that one day passed, and we're now 2023-06-07.
Run Toudou. The file becomes:
```
2023-06-06
- [x] call plumber

2023-06-07
- [ ] laundry
- [ ] groceries

every Saturday from 2023-06-10
- find a movie for tonight
```
As you can see, the laundry task from yesterday was moved to today since it was not done,
and the "groceries" task now have a checkbox. Let's mark both tasks as done.

Let's assume that we're now Saturday (2023-06-10). Run Toudou. You get:
```
2023-06-06
- [x] call plumber

2023-06-07
- [x] laundry
- [x] groceries

2023-06-10
- [ ] find a movie for tonight

every Saturday from 2023-06-17
- find a movie for tonight
```
As you can see, the recurring task has been duplicated: it has been instantiated
into today's list, and the `from` annotation has been updated so that Toudou
knows that it should not add the task again next time it runs.

## Annotations

Annotations can be either put in parentheses at the beginning of a task title,
or they can be put as section titles for a group of items.
There are two kinds of annotations: date annotations, and frequency annotations.

Date annotations can be of the form:
- `YYYY-MM-DD`;
- `MM-DD`, denoting the day `DD` of month `MM` of the current year
  (if not in the past) or of the next year;
- `DD`, denoting the day `DD` of the current month (if not in the past)
  or of the next month;
- `today` (or `tod` for short);
- `tomorrow` (or `tom` for short);
- days of the week such as `monday` (or `mon` for short),
  which denotes the first day after today which is a Monday;
- `next week` (equivalent to `monday`);
- `next month` (equivalent to `01`);
- `next year` (equivalent to `01-01`);
- `later` (an unspecified date that is not today).

Frequency annotations are used to specify recurring items and can be:
- `daily`;
- weekly: `every monday` (or `every mon` for short), `every tuesday`, etc.;
- monthly: `every DD`, i.e. every `DD` day of the month;
- yearly: `every MM-DD`, i.e. every `MM-DD` day of the year.
