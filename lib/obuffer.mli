type buffer_ty = {
  byte_array :
    (int, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t;
  mutable index : int;
}

val fmt_string_as_hex_bytes : string -> string

(* Generic reader that can read unsigned bytes and fixed-length strings *)
module PlatformAgnosticReader : sig
  val seek : buffer_ty -> int -> unit
  val advance : buffer_ty -> int -> unit
  val validate_read : buffer_ty -> int -> (buffer_ty, string) result
  val u8 : buffer_ty -> (Stdint.uint8, string) result
  val fixed_length_string : buffer_ty -> int -> (string, string) result
  val null_terminated_string : buffer_ty -> int -> (string, string) result
end

(* Module signature for little- and big-endian readers *)
module type Reader = sig
  val seek : buffer_ty -> int -> unit
  val advance : buffer_ty -> int -> unit
  val u8 : buffer_ty -> (Stdint.uint8, string) result
  val u16 : buffer_ty -> (Stdint.uint16, string) result
  val u32 : buffer_ty -> (Stdint.uint32, string) result
  val u64 : buffer_ty -> (Stdint.uint64, string) result
end

module LittleEndianReader : Reader
module BigEndianReader : Reader
