(lang dune 3.7)

(name owl)

(generate_opam_files true)

(source
 (github ashay/owl))

(authors "Ashay Rane")

(maintainers "Ashay Rane")

(license CC0-1.0)

(package
 (name owl)
 (synopsis "An ELF parser in OCaml")
 (depends ocaml base dune stdint)
 (tags
  (topics elf dwarf owl)))
