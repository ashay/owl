let () =
  if Array.length Sys.argv <> 2 then Printf.printf "USAGE: owl elf-file\n"
  else
    match Owl.Ofile.new_file Sys.argv.(1) with
    | Ok _ -> Printf.printf "success\n"
    | Error msg ->
        Printf.printf "error: %s\n" msg;
        exit 1
