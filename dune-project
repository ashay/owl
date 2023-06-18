(lang dune 3.7)

(name owl)

(generate_opam_files true)

(source
 (github ashay/owl))

(authors "Ashay Rane")

(maintainers "Ashay Rane")

(license LICENSE)

(package
 (name owl)
 (synopsis "An ELF parser in OCaml")
 (depends ocaml dune)
 (tags
  (topics elf dwarf owl)))
