type negative_test_desc = { yaml_path : string; error_message : string }

let negative_tests =
  [
    {
      yaml_path =
        "test-files/invalid-elf-descriptions/invalid-byte-ordering-0.yaml";
      error_message = "invalid ELF data encoding: ELFDATANONE";
    };
    {
      yaml_path =
        "test-files/invalid-elf-descriptions/invalid-byte-ordering-1.yaml";
      error_message = "unknown ELF data encoding: 0x03";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-class-0.yaml";
      error_message = "invalid ELF class: ELFCLASSNONE";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-class-1.yaml";
      error_message = "unknown ELF class: 0x03";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-phdr-type.yaml";
      error_message = "unknown program header type: 0x0008";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-phentsize-0.yaml";
      error_message = "invalid e_phentsize: 31";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-phentsize-1.yaml";
      error_message = "invalid e_phentsize: 55";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-shdr-type.yaml";
      error_message = "unknown section header type: 0x0013";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-shentsize-0.yaml";
      error_message = "invalid e_shentsize: 39";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-shentsize-1.yaml";
      error_message = "invalid e_shentsize: 63";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-shentsize-2.yaml";
      error_message = "invalid e_shentsize: 39";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-shentsize-3.yaml";
      error_message = "invalid e_shentsize: 63";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-shnum-0.yaml";
      error_message = "invalid e_shnum 3598 for e_shoff=0";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-shnum-1.yaml";
      error_message = "invalid type of the initial section: SHT_PROGBITS";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-shstrndx.yaml";
      error_message = "invalid e_shstrndx 61680 since e_shnum is 3598";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-type-0.yaml";
      error_message = "invalid ELF type: ET_NONE";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-type-1.yaml";
      error_message = "invalid ELF type: ET_NONE";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-type-2.yaml";
      error_message = "unknown ELF type: 0x0005";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-version-0.yaml";
      error_message = "invalid ELF version: EV_NONE";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-version-1.yaml";
      error_message = "invalid ELF version: EV_NONE";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-version-2.yaml";
      error_message = "invalid ELF version: EV_NONE";
    };
    {
      yaml_path = "test-files/invalid-elf-descriptions/invalid-version-3.yaml";
      error_message = "unknown ELF version: 0x02";
    };
  ]

(* Run command after redirecting stdout and stderr to specified files *)
let run_cmd_with_redirects cmd_array stdout_path stderr_path =
  let new_stdout = Unix.descr_of_out_channel (open_out stdout_path)
  and new_stderr = Unix.descr_of_out_channel (open_out stderr_path) in
  Unix.dup2 new_stdout Unix.stdout;
  Unix.dup2 new_stderr Unix.stderr;
  try Unix.execvp cmd_array.(0) cmd_array with Unix.Unix_error _ -> exit 255

let exec_command cmd_array =
  let stdout_path = Filename.temp_file "owl-" "out"
  and stderr_path = Filename.temp_file "owl-" "err" in

  let read_whole_file filename =
    try
      let ch = open_in_bin filename in
      let contents = really_input_string ch (in_channel_length ch) in
      close_in ch;
      contents
    with Sys_error _ -> ""
  in

  let wait_for_child pid =
    let this_stderr = read_whole_file stderr_path in
    match Unix.waitpid [] pid with
    | _, Unix.WEXITED 0 -> Ok ()
    | _ -> Error this_stderr
  in

  match Unix.fork () with
  | 0 -> run_cmd_with_redirects cmd_array stdout_path stderr_path
  | pid -> wait_for_child pid

let run_elf_spec_pipeline spec_path =
  let elf_path = Filename.temp_file "owl-" "elf" in
  let cmd = [| "python3"; "test-files/elfc.py"; spec_path; "-o"; elf_path |] in
  let open Base.Result.Monad_infix in
  exec_command cmd >>= fun _ -> Owl.Ofile.new_file elf_path

let expand_string nchars filler str =
  let rec repeat n s = if n <= 0 then "" else s ^ repeat (n - 1) s in
  let diff = nchars - String.length str in
  let groups = diff / String.length filler in
  str ^ repeat groups filler

let fmt_test_name spec_path =
  let test_name = spec_path |> Filename.basename |> Filename.remove_extension in
  let pad_length = String.length test_name mod String.length ". " in
  test_name
  |> expand_string (String.length test_name + pad_length) " "
  |> expand_string 40 ". "

let succ () =
  Printf.printf "passed\n";
  flush stdout;
  Some ()

let fail () =
  Printf.printf "failed\n";
  flush stdout;
  None

(* Ensure that Owl runs successfully on the given ELF spec *)
let test_positive_elf_spec spec_path =
  Printf.printf "%s" (fmt_test_name spec_path);
  match run_elf_spec_pipeline spec_path with
  | Ok _ -> succ ()
  | Error _ -> fail ()

let yaml_files dir =
  let check_extension filename =
    match Filename.extension filename with
    (* Add directory name so that the returned filenames are well-formed *)
    | ".yaml" -> Some (dir ^ "/" ^ filename)
    | _ -> None
  in
  Sys.readdir dir |> Array.to_list |> List.filter_map check_extension

let run_tests test_fn elf_spec_dir =
  let specs = yaml_files elf_spec_dir in
  let total = List.length specs in
  let succ = specs |> List.filter_map test_fn |> List.length in
  (total, total - succ)

(* Ensure that Owl fails on the given ELF spec *)
let run_negative_tests () =
  let total = List.length negative_tests
  and aux test_desc =
    Printf.printf "%s" (fmt_test_name test_desc.yaml_path);
    match run_elf_spec_pipeline test_desc.yaml_path with
    | Error msg ->
        if String.equal msg test_desc.error_message then succ () else fail ()
    | Ok _ -> fail ()
  in
  let succ = negative_tests |> List.filter_map aux |> List.length in
  (total, total - succ)

let () =
  Printf.printf "Running positive tests ...\n";
  let ptotal, pfail =
    run_tests test_positive_elf_spec "test-files/valid-elf-descriptions"
  in

  Printf.printf "\nRunning negative tests ...\n";
  let ntotal, nfail = run_negative_tests () in

  Printf.printf "\nSummary (%d positive tests):\n" ptotal;
  Printf.printf " - failed: %u\n" pfail;

  Printf.printf "\nSummary (%d negative tests):\n" ntotal;
  Printf.printf " - failed: %u\n" nfail;

  if pfail > 0 || nfail > 0 then exit 1
