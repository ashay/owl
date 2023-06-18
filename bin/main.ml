let run_pipeline () =
  let open Base.Result.Monad_infix in
  Ofile.read_elf "/tmp/x.o" >>= fun buffer ->
  Ofile.parse_elf_info buffer >>= fun elf_info ->
  Ofile.parse_elf_header elf_info buffer >>= fun elf_header -> Ok elf_header

let () =
  match run_pipeline () with
  | Ok _ -> Printf.printf "success\n"
  | Error msg -> Printf.printf "error: %s\n" msg
