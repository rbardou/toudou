(lang dune 2.7)
(generate_opam_files true)

(source (github rbardou/toudou))
(license MIT)
(authors "Romain Bardou")
(maintainers "Romain Bardou")

(package
 (name toudou)
 (synopsis "A todo-list manager")
 (description "Toudou takes your todo-list, cleans it up and fills today's list with items from the past that were not done and with recurring items (e.g. every Monday). Comes with an Emacs mode.")
 (depends (ocaml (>= 4.07))))
