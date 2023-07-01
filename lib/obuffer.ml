type buffer_ty = {
  byte_array :
    (int, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t;
  mutable index : int;
}

let fmt_string_as_hex_bytes str =
  let chars = List.init (String.length str) (String.get str) in
  let aux x = Printf.sprintf "%02x" (Char.code x) in
  String.concat " " (List.map aux chars)

module PlatformAgnosticReader = struct
  let seek t pos = t.index <- pos
  let advance t count = t.index <- t.index + count

  let validate_read buffer bytes =
    let size = Bigarray.Array1.dim buffer.byte_array in
    if buffer.index <= size - bytes then Ok buffer
    else
      let msg =
        Printf.sprintf
          "attempting to read %d byte(s) at index %d when buffer size is %d"
          bytes buffer.index size
      in
      Error msg

  let u8 t =
    let open Base.Result.Monad_infix in
    validate_read t 1 >>= fun t ->
    let result = t.byte_array.{t.index} in
    advance t 1;
    Ok (Stdint.Uint8.of_int result)

  let fixed_length_string t length =
    let open Base.Result.Monad_infix in
    validate_read t length >>= fun t ->
    let result = Bytes.create length in
    for i = 0 to length - 1 do
      Bytes.set result i (Char.chr t.byte_array.{t.index + i})
    done;
    advance t length;
    Ok (Bytes.unsafe_to_string result)
end

(* Module signature for little- and big-endian readers *)
module type Reader = sig
  val seek : buffer_ty -> int -> unit
  val advance : buffer_ty -> int -> unit
  val u8 : buffer_ty -> (Stdint.Uint8.t, string) result
  val u16 : buffer_ty -> (Stdint.Uint16.t, string) result
  val u32 : buffer_ty -> (Stdint.Uint32.t, string) result
  val u64 : buffer_ty -> (Stdint.Uint64.t, string) result
end

module LittleEndianReader : Reader = struct
  let seek t pos = PlatformAgnosticReader.seek t pos
  let advance t count = PlatformAgnosticReader.advance t count
  let u8 t = PlatformAgnosticReader.u8 t

  let u16 t =
    let open Base.Result.Monad_infix in
    PlatformAgnosticReader.validate_read t 2 >>= fun t ->
    u8 t >>= fun lo_val ->
    u8 t >>= fun hi_val ->
    let open Stdint.Uint16 in
    let lo_u16 = of_uint8 lo_val and hi_u16 = of_uint8 hi_val in
    Ok (logor (shift_left hi_u16 8) lo_u16)

  let u32 t =
    let open Base.Result.Monad_infix in
    PlatformAgnosticReader.validate_read t 4 >>= fun t ->
    u16 t >>= fun lo_val ->
    u16 t >>= fun hi_val ->
    let open Stdint.Uint32 in
    let lo_u32 = of_uint16 lo_val and hi_u32 = of_uint16 hi_val in
    Ok (logor (shift_left hi_u32 16) lo_u32)

  let u64 t =
    let open Base.Result.Monad_infix in
    PlatformAgnosticReader.validate_read t 8 >>= fun t ->
    u32 t >>= fun lo_val ->
    u32 t >>= fun hi_val ->
    let open Stdint.Uint64 in
    let lo_u64 = of_uint32 lo_val and hi_u64 = of_uint32 hi_val in
    Ok (logor (shift_left hi_u64 16) lo_u64)
end

module BigEndianReader : Reader = struct
  let seek t pos = PlatformAgnosticReader.seek t pos
  let advance t count = PlatformAgnosticReader.advance t count
  let u8 t = PlatformAgnosticReader.u8 t

  let u16 t =
    let open Base.Result.Monad_infix in
    PlatformAgnosticReader.validate_read t 2 >>= fun t ->
    u8 t >>= fun hi_val ->
    u8 t >>= fun lo_val ->
    let open Stdint.Uint16 in
    let lo_u16 = of_uint8 lo_val and hi_u16 = of_uint8 hi_val in
    Ok (logor (shift_left hi_u16 8) lo_u16)

  let u32 t =
    let open Base.Result.Monad_infix in
    PlatformAgnosticReader.validate_read t 4 >>= fun t ->
    u16 t >>= fun hi_val ->
    u16 t >>= fun lo_val ->
    let open Stdint.Uint32 in
    let lo_u32 = of_uint16 lo_val and hi_u32 = of_uint16 hi_val in
    Ok (logor (shift_left hi_u32 16) lo_u32)

  let u64 t =
    let open Base.Result.Monad_infix in
    PlatformAgnosticReader.validate_read t 8 >>= fun t ->
    u32 t >>= fun hi_val ->
    u32 t >>= fun lo_val ->
    let open Stdint.Uint64 in
    let lo_u64 = of_uint32 lo_val and hi_u64 = of_uint32 hi_val in
    Ok (logor (shift_left hi_u64 16) lo_u64)
end
