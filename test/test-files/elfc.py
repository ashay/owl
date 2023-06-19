#!/usr/bin/env python3.7
#
# This script converts a textual (YAML) description of an ELF file to
# an equivalent 'binary' file.
#
# The YAML description may have the following top-level keys:
#
# 'elf_fillchar': char
#     Sets the fill character to 'char'.
# 'ehdr': EHDR-DESCRIPTOR
#     Defines an ELF Ehdr structure.
# 'phdrtab': list-of(PHDR-DESCRIPTOR)
#     Defines the contents of the ELF Program Header table.
#     Each `Phdr' descriptor represents one ELF Phdr entry.
# 'sections': list-of(SECTION-DESCRIPTOR)
#     Defines the content of each section in the file.  Each
#     `SECTION-DESCRIPTOR' contains information for the
#     section `header' and the actual data for the section.
#
# The script will compute reasonable defaults for any fields
# left unspecified in the YAML description.
#
# Descriptors EHDR-DESCRIPTOR and PHDR-DESCRIPTOR may be specified
# as a YAML key-value set.  The key names correspond to the
# field names of the corresponding ELF structures, e.g., 'e_machine'
# and 'e_ident' for the Ehdr and 'p_type' and 'p_paddr' for
# a Phdr entry.
#
# Descriptor SECTION-DESCRIPTOR contains the fields in an ELF
# Shdr structure and an additional member 'sh_data', whose
# value is the data for the section.
#
# Example:
#
# <snip>
# ehdr: !Ehdr
#   e_ident: !Ident
#     ei_class: ELFCLASS32
#     ei_data:  ELFDATA2MSB
#   e_machine:  EM_PPC
# phdrtab:
#  - !Phdr
#    ph_type: PHT_NULL
#    ... other program header fields ...
#  - !Phdr
#    ... etc. ...
# sections:
#  - !Section
#    sh_name: .dynsym
#    ... other section header fields ...
#    sh_data: # ... list of data ...
#    - !Dyn
#      d_tag: 0xdeadcode
#    - !Dyn
#      d_tag: 0xcafebabe
#  - !Section
#    sh_name: .shstrtab
#    sh_type: SHT_STRTAB
#    sh_data:
#    - string1
#    - string2
# </snip>
#
# :: Handling of strings ::
#
# Fields like 'sh_name' (in a section header) are defined to contain
# an integer index into a specified string table (in this case a
# section with name '.shstrtab').  Other ELF data structures use a
# similar convention; names in a '.dynamic' section as stored as
# indices into a '.dynstr' section.  In the YAML descriptor, such
# fields may be specified as indices, which are used as-is, or as text
# strings which are converted to the appropriate string index.
# For convenience in creating ELF objects with a large number of
# sections, a section index may be manually specified using a
# 'sh_index' pseudo field.
#
# Formatting note: comment lines containing the string '-YAPF-' serve
# as guides for the YAPF formatting utility.
#
# $Id$

version = "%prog 1.0"
usage = "usage: %prog [options] [input-file]"
description = """Create an ELF binary from a textual description in """ + \
 """'input-file' (or stdin)"""

import io, operator, optparse, re, struct, sys, types, yaml


class ElfError(Exception):
    """An exception signalled during conversion."""

    def __init__(self, node=None, msg=None):
        """Initialize an exception object.

        Arguments:
        node    -- a YAML parse tree node.
        msg    -- human readable message associated with this
               exception.
        """
        if node:
            self.ee_start = node.start_mark.line + 1
            self.ee_end = node.end_mark.line + 1
        else:
            self.ee_start = self.ee_end = -1
        self.ee_msg = msg

    def __str__(self):
        """Form a printable representation of an exception."""

        if self.ee_start != -1:
            if self.ee_start == self.ee_end:
                return "Error: line {start}: {msg}".format(
                    start=self.ee_start, end=self.ee_msg)
            else:
                return "Error: lines {start}--{end}: {msg}".format(
                    start=self.ee_start, end=self.ee_end, msg=self.ee_msg)
        else:
            return "Error: {msg}".format(msg=self.ee_msg)


#
# Mappings used by the 'encode()' function
#

elf_cap_tag = {'CA_SUNW_NULL': 0, 'CA_SUNW_HW_1': 1, 'CA_SUNW_SF_1': 2}

elf_d_flags = {
    'DF_ORIGIN': 0x0001,
    'DF_SYMBOLIC': 0x0002,
    'DF_TEXTREL': 0x0004,
    'DF_BIND_NOW': 0x0006,
    'DF_STATIC_TLS': 0x0010
}

elf_d_tag = {
    # from <sys/elf_common.h>
    'DT_NULL': 0,
    'DT_NEEDED': 1,
    'DT_PLTRELSZ': 2,
    'DT_PLTGOT': 3,
    'DT_HASH': 4,
    'DT_STRTAB': 5,
    'DT_SYMTAB': 6,
    'DT_RELA': 7,
    'DT_RELASZ': 8,
    'DT_RELAENT': 9,
    'DT_STRSZ': 10,
    'DT_SYMENT': 11,
    'DT_INIT': 12,
    'DT_FINI': 13,
    'DT_SONAME': 14,
    'DT_RPATH': 15,
    'DT_SYMBOLIC': 16,
    'DT_REL': 17,
    'DT_RELSZ': 18,
    'DT_RELENT': 19,
    'DT_PLTREL': 20,
    'DT_DEBUG': 21,
    'DT_TEXTREL': 22,
    'DT_JMPREL': 23,
    'DT_BIND_NOW': 24,
    'DT_INIT_ARRAY': 25,
    'DT_FINI_ARRAY': 26,
    'DT_INIT_ARRAYSZ': 27,
    'DT_FINI_ARRAYSZ': 28,
    'DT_RUNPATH': 29,
    'DT_FLAGS': 30,
    'DT_ENCODING': 32,
    'DT_PREINIT_ARRAY': 32,
    'DT_PREINIT_ARRAYSZ': 33,
    'DT_LOOS': 0x6000000d,
    'DT_HIOS': 0x6ffff000,
    'DT_LOPROC': 0x70000000,
    'DT_HIPROC': 0x7fffffff,
    'DT_SUNW_AUXILIARY': 0x6000000D,
    'DT_SUNW_RTLDINF': 0x6000000E,
    'DT_SUNW_FILTER': 0x6000000F,
    'DT_SUNW_CAP': 0x60000010,
    # from "usr.bin/elfdump/elfdump.c"
    'DT_GNU_PRELINKED': 0x6ffffdf5,
    'DT_GNU_CONFLICTSZ': 0x6ffffdf6,
    'DT_GNU_LIBLISTSZ': 0x6ffffdf7,
    'DT_SUNW_CHECKSUM': 0x6ffffdf78,
    'DT_PLTPADSZ': 0x6ffffdf79,
    'DT_MOVEENT': 0x6ffffdfa,
    'DT_MOVESZ': 0x6ffffdfb,
    'DT_FEATURE': 0x6ffffdfc,
    'DT_FEATURE': 0x6ffffdfd,
    'DT_POSFLAG_1': 0x6ffffdfe,
    'DT_SYMINENT': 0x6ffffdff,
    'DT_VALRNGHI': 0x6ffffdff,  # dup
    'DT_ADDRRNGLO': 0x6ffffe00,
    'DT_GNU_CONFLICT': 0x6ffffef8,
    'DT_GNU_LIBLIST': 0x6ffffef9,
    'DT_SUNW_CONFIG': 0x6ffffefa,
    'DT_SUNW_DEPAUDIT': 0x6ffffefb,
    'DT_SUNW_AUDIT': 0x6ffffefc,
    'DT_SUNW_PLTPAD': 0x6ffffefd,
    'DT_SUNW_MOVETAB': 0x6ffffefe,
    'DT_SYMINFO': 0x6ffffeff,
    'DT_ADDRRNGHI': 0x6ffffeff,  # dup
    'DT_VERSYM': 0x6ffffff0,
    'DT_GNU_VERSYM': 0x6ffffff0,  # dup
    'DT_RELACOUNT': 0x6ffffff9,
    'DT_RELCOUNT': 0x6ffffffa,
    'DT_FLAGS_1': 0x6ffffffb,
    'DT_VERDEF': 0x6ffffffc,
    'DT_VERDEFNUM': 0x6ffffffd,
    'DT_VERNEED': 0x6ffffffe,
    'DT_VERNEEDNUM': 0x6fffffff,
    'DT_IA_64_PLT_RESERVE': 0x70000000,
    'DT_SUNW_AUXILIARY': 0x7ffffffd,
    'DT_SUNW_USED': 0x7ffffffe,
    'DT_SUNW_FILTER': 0x7fffffff
}

elf_dyn_fields = ['d_tag', 'd_val', 'd_ptr']

elf_ehdr_flags = {  # no known flags
}

elf_ehdr_type = {  # e_type
    'ET_NONE': 0,
    'ET_REL': 1,
    'ET_EXEC': 2,
    'ET_DYN': 3,
    'ET_CORE': 4
}

elf_ehdr_machine = {  # e_machine
    'EM_NONE': 0,
    'EM_M32': 1,
    'EM_SPARC': 2,
    'EM_386': 3,
    'EM_68K': 4,
    'EM_88K': 5,
    'EM_486': 6,
    'EM_860': 7,
    'EM_MIPS': 8,
    'EM_S370': 9,
    'EM_MIPS_RS3_LE': 10,
    'EM_MIPS_RS4_BE': 10,
    'EM_PARISC': 15,
    'EM_VPP500': 17,
    'EM_SPARC32PLUS': 18,
    'EM_960': 19,
    'EM_PPC': 20,
    'EM_PPC64': 21,
    'EM_S390': 22,
    'EM_V800': 36,
    'EM_FR20': 37,
    'EM_RH32': 38,
    'EM_RCE': 39,
    'EM_ARM': 40,
    'EM_ALPHA_STD': 41,
    'EM_SH': 42,
    'EM_SPARCV9': 43,
    'EM_TRICORE': 44,
    'EM_ARC': 45,
    'EM_H8_300': 46,
    'EM_H8_300H': 47,
    'EM_H8S': 48,
    'EM_H8_500': 49,
    'EM_IA_64': 50,
    'EM_MIPS_X': 51,
    'EM_COLDFIRE': 52,
    'EM_68HC12': 53,
    'EM_MMA': 54,
    'EM_PCP': 55,
    'EM_NCPU': 56,
    'EM_NDR1': 57,
    'EM_STARCORE': 58,
    'EM_ME16': 59,
    'EM_ST100': 60,
    'EM_TINYJ': 61,
    'EM_X86_64': 62,
    'EM_ALPHA': 0x9026
}

elf_ei_version = {  # e_version
    'EV_NONE': 0,
    'EV_CURRENT': 1
}

elf_ei_class = {'ELFCLASSNONE': 0, 'ELFCLASS32': 1, 'ELFCLASS64': 2}

elf_ei_data = {'ELFDATANONE': 0, 'ELFDATA2LSB': 1, 'ELFDATA2MSB': 2}

elf_ei_osabi = {
    # Official values.
    'ELFOSABI_NONE': 0,
    'ELFOSABI_HPUX': 1,
    'ELFOSABI_NETBSD': 2,
    'ELFOSABI_GNU': 3,
    'ELFOSABI_HURD': 4,
    'ELFOSABI_86OPEN': 5,
    'ELFOSABI_SOLARIS': 6,
    'ELFOSABI_AIX': 7,
    'ELFOSABI_IRIX': 8,
    'ELFOSABI_FREEBSD': 9,
    'ELFOSABI_TRU64': 10,
    'ELFOSABI_MODESTO': 11,
    'ELFOSABI_OPENBSD': 12,
    'ELFOSABI_OPENVMS': 13,
    'ELFOSABI_NSK': 14,
    'ELFOSABI_ARM': 97,
    'ELFOSABI_STANDALONE': 255,
    # Aliases.
    'ELFOSABI_SYSV': 0,
    'ELFOSABI_LINUX': 3,
    'ELFOSABI_MONTEREY': 7
}

elf_ph_fields = [
    'p_align', 'p_filesz', 'p_flags', 'p_memsz', 'p_offset', 'p_paddr',
    'p_type', 'p_vaddr'
]

elf_ph_flags = {'PF_X': 0x1, 'PF_W': 0x2, 'PF_R': 0x4}

elf_ph_type = {
    'PT_NULL': 0,
    'PT_LOAD': 1,
    'PT_DYNAMIC': 2,
    'PT_INTERP': 3,
    'PT_NOTE': 4,
    'PT_SHLIB': 5,
    'PT_PHDR': 6,
    'PT_TLS': 7,
    'PT_LOOS': 0x60000000,
    'PT_HIOS': 0x6FFFFFFF,
    'PT_SUNW_UNWIND': 0x6464E550,
    'PT_GNU_EHFRAME': 0x6464E550,  # dup
    'PT_SUNWBSS': 0x6FFFFFFA,
    'PT_SUNWSTACK': 0x6FFFFFFB,
    'PT_SUNWDTRACE': 0x6FFFFFFC,
    'PT_SUNWCAP': 0x6FFFFFFD,
    'PT_LOPROC': 0x70000000,
    'PT_HIPROC': 0x7FFFFFFF
}

elf_sh_type = {
    'SHT_NULL': 0,
    'SHT_PROGBITS': 1,
    'SHT_SYMTAB': 2,
    'SHT_STRTAB': 3,
    'SHT_RELA': 4,
    'SHT_HASH': 5,
    'SHT_DYNAMIC': 6,
    'SHT_NOTE': 7,
    'SHT_NOBITS': 8,
    'SHT_REL': 9,
    'SHT_SHLIB': 10,
    'SHT_DYNSYM': 11,
    'SHT_INIT_ARRAY': 14,
    'SHT_FINI_ARRAY': 15,
    'SHT_PREINIT_ARRAY': 16,
    'SHT_GROUP': 17,
    'SHT_SYMTAB_SHNDX': 18,
    'SHT_LOOS': 0x60000000,
    'SHT_HIOS': 0x6fffffff,
    'SHT_LOPROC': 0x70000000,
    'SHT_HIPROC': 0x7fffffff,
    'SHT_LOUSER': 0x80000000,
    'SHT_HIUSER': 0xffffffff,
    # OS specific types
    'SHT_SUNW_dof': 0x6FFFFFF4,
    'SHT_SUNW_cap': 0x6FFFFFF5,
    'SHT_SUNW_SIGNATURE': 0x6FFFFFF6,
    'SHT_SUNW_ANNOTATE': 0x6FFFFFF7,
    'SHT_GNU_LIBLIST': 0x6ffffff7,  # dup
    'SHT_SUNW_DEBUGSTR': 0x6FFFFFF8,
    'SHT_SUNW_DEBUG': 0x6FFFFFF9,
    'SHT_SUNW_move': 0x6FFFFFFA,
    'SHT_SUNW_COMDAT': 0x6FFFFFFB,
    'SHT_SUNW_syminfo': 0x6FFFFFFC,
    'SHT_GNU_verdef': 0x6ffffffd,
    'SHT_SUNW_verdef': 0x6ffffffd,  # dup
    'SHT_GNU_verneed': 0x6ffffffe,
    'SHT_SUNW_verneed': 0x6ffffffe,  # dup
    'SHT_GNU_versym': 0x6fffffff,
    'SHT_SUNW_versym': 0x6fffffff,  # dup
    # Processor specific types
    'SHT_IA_64_EXT': 0x70000000,
    'SHT_IA_64_UNWIND': 0x70000001
}

elf_sh_flags = {
    'SHF_WRITE': 0x1,
    'SHF_ALLOC': 0x2,
    'SHF_EXECINSTR': 0x4,
    'SHF_MERGE': 0x10,
    'SHF_STRINGS': 0x20,
    'SHF_INFO_LINK': 0x40,
    'SHF_LINK_ORDER': 0x80,
    'SHF_OS_NONCONFORMING': 0x100,
    'SHF_GROUP': 0x200,
    'SHF_TLS': 0x400,
    'SHF_MASKOS': 0x0ff00000,
    'SHF_MASKPROC': 0xf0000000
}

elf_st_bindings = {'STB_LOCAL': 0, 'STB_GLOBAL': 1, 'STB_WEAK': 2}

elf_st_flags = {'SHF_WRITE': 1, 'SHF_ALLOC': 2, 'SHF_EXECINSTR': 4}

elf_st_types = {
    'STT_NOTYPE': 0,
    'STT_OBJECT': 1,
    'STT_FUNC': 2,
    'STT_SECTION': 3,
    'STT_FILE': 3
}

elf_syminfo_flags = {
    'SYMINFO_FLG_DIRECT': 1,
    'SYMINFO_FLG_PASSTHRU': 2,
    'SYMINFO_FLG_FILTER': 2,  # dup
    'SYMINFO_FLG_COPY': 4,
    'SYMINFO_FLG_LAZYLOAD': 8,
    'SYMINFO_FLG_DIRECTBIND': 0x10,
    'SYMINFO_FLG_NOEXTDIRECT': 0x20,
    'SYMINFO_FLG_AUXILIARY': 0x40
}

elf_syminfo_boundto_types = {
    'SYMINFO_BT_SELF': 0xFFFF,
    'SYMINFO_BT_PARENT': 0xFFFE,
    'SYMINFO_BT_NONE': 0xFFFD,
    'SYMINFO_BT_EXTERN': 0xFFFC
}

# Defaults

defaults = {
    # ElfDyn structures
    'd_tag': 'DT_NULL',
    'd_un': '0',

    # fields in an ELf Executable Header
    'e_ehsize': None,
    'e_entry': '0',
    'e_flags': ['0'],
    'e_ident': None,
    'e_machine': 'EM_NONE',
    'e_phentsize': None,
    'e_phnum': None,
    'e_phoff': None,
    'e_shentsize': None,
    'e_shnum': None,
    'e_shoff': None,
    'e_shstrndx': None,
    'e_type': 'ET_NONE',
    'e_version': 'EV_CURRENT',
    # e_ident bytes
    'ei_class': 'ELFCLASS32',
    'ei_data': 'ELFDATA2LSB',
    'ei_version': 'EV_CURRENT',
    'ei_osabi': 'ELFOSABI_NONE',
    'ei_abiversion': '0',
    # File-wide defaults
    'elf_fillchar': '0',
    # Elf Notes
    'n_namesz': None,
    'n_descsz': None,
    'n_type': '0',
    'n_data': ["", ""],
    # Phdr
    'p_align': '1',
    'p_filesz': '0',
    'p_memsz': '0',
    'p_flags': ['0'],
    'p_offset': '0',
    'p_paddr': '0',
    'p_type': 'PT_NULL',
    'p_vaddr': '0',
    # Shdr
    'sh_addr': '0',
    'sh_addralign': None,
    'sh_data': [],
    'sh_entsize': '0',
    'sh_flags': ['0'],
    'sh_info': '0',
    'sh_index': None,
    'sh_link': '0',
    'sh_name': '0',
    'sh_offset': None,
    'sh_size': None,
    'sh_type': 'SHT_NULL',
    'sh_word_size': 32,
    # Verdaux
    'vda_name': 0,
    'vda_next': 0,
    # Verdef
    'vd_version': 1,
    'vd_flags': 0,
    'vd_ndx': 0,
    'vd_cnt': 0,
    'vd_hash': 0,
    'vd_aux': 0,
    'vd_next': 0,
    # Vernaux
    'vna_hash': 0,
    'vna_flags': 0,
    'vna_other': 0,
    'vna_name': 0,
    'vna_next': 0,
    # Verneed
    'vn_version': 1,
    'vn_cnt': 0,
    'vn_file': 0,
    'vn_aux': 0,
    'vn_next': 0
}

#
# Module wide constants.
#

ELFCLASS32 = elf_ei_class['ELFCLASS32']
ELFDATA2LSB = elf_ei_data['ELFDATA2LSB']
SHT_NOBITS = elf_sh_type['SHT_NOBITS']
SHT_NULL = elf_sh_type['SHT_NULL']
SHT_STRTAB = elf_sh_type['SHT_STRTAB']
SHN_LORESERVE = 0xFF00
SHN_XINDEX = 0xFFFF

#
# Helper functions.
#


def get(d, key, default):
    """Retrieve the value of 'key' from YAML dictionary 'd'.

    The return value is guaranteed to be not 'None'.
    """
    v = d.get(key, default)
    if v is None:
        v = default
    return v


def encode(d, key, default, mapping):
    """Return the numeric value of d[key] in map 'mapping'."""

    v = get(d, key, default)
    try:
        return mapping[v]
    except KeyError:
        return int(v)


def encode_flags(flags, m):
    """Convert 'flags' to a single numeric value using mapping 'm'."""
    try:
        v = int(flags)
        return v
    except:
        pass
    v = 0
    for f in flags:
        try:
            t = int(m[f])
        except KeyError:
            t = int(f)
        v |= t
    return v


def check_dict(d, l, node=None):
    """Check a dictionary for unknown keys."""
    unknown = []
    for k in d.keys():
        if k not in l:
            unknown.append(k)
    if len(unknown) > 0:
        raise ElfError(node, "{tag} Unknown key(s) {key}".format(
            tag=node.tag, key=unknown))


def bounded_value(v, encoding):
    """Return the value of 'v' bounded to the maximum size for a type."""
    if encoding == "H":
        return (v & 0xFFFF)
    elif encoding == "I":
        return (v & 0xFFFFFFFF)
    return v


#
# Helper classes.
#


class ElfStrTab:
    """A ELF string table.

    This class manages strings in an ELF string table section.
    """

    def __init__(self, strs=None):
        """Initialize a string table from a list of strings."""
        self.offset = 1  # reserve space for initial null byte
        self.htab = {}
        if isinstance(strs, str):  # one string
            self.add(strs)
        elif isinstance(strs, list):  # list of strings
            for s in strs:
                self.add(s)

    def add(self, s: str):
        """Add a string to the string table.

        Returns the offset of the string in the ELF section."""
        try:
            return self.lookup(s)
        except KeyError:
            self.htab[s] = offset = self.offset
            self.offset += len(s) + 1  # Keep space for a NUL.
        return offset

    def bits(self):
        """Return the contents of an ELF string table."""

        # Prepare the string table, ordered by string offset.
        ls = [b""]  # initial NUL
        for (ss, oo) in sorted(self.htab.items(), key=operator.itemgetter(1)):
            ls.append(bytes(ss, 'utf-8'))
        return b"\000".join(ls) + b"\000"  # Add trailing NULs

    def lookup(self, str):
        """Return the ELF string table offset for string 'str'."""

        return self.htab[str]


class ElfType:
    """A base type for ELF type descriptors.

    Derived classes are expected to provide the following attributes:

    'fields' -- a list of 4-typles (name, fn, lsz, msz).

        'name' is the name of a field in the ELF structure.

        'fn' is a convertor function, one of the functions
        'do_{long,encode,flags}' below.

        'msz' and 'lsz' provide the appropriate sizes when
        generating a binary representation of the type.
    """

    fields = None

    def __init__(self, d, node):
        """Initialize an ELF datatype from a YAML description.

        Arguments:
        d    -- a dictionary containing name/value pairs specified
               in the text description.
        node    -- YAML parser node for this element.
        """

        keys = [t[0] for t in self.fields]
        check_dict(d, keys, node)
        for f in self.fields:
            name = f[0]
            fn = f[1]
            try:
                v = fn(d, name)
                setattr(self, f[0], v)
            except:
                raise ElfError(
                    node, "key: {key!r} value: {value!r} unrecognized.".format(
                        key=name, value=d[name]))
        self._n = node  # Save YAML node and associated value
        self._d = d  # for error reporting.

    def __getitem__(self, attrib):
        """Allow an ELF type to be treated like a dictionary."""

        return getattr(self, attrib)

    def bits(self, formatchar, elfclass):
        """Convert an ELF type to its file representation."""

        format, args = self.getfields(elfclass)
        return struct.pack(formatchar + format, *args)

    def formatstring(self, elfclass):
        """Return the format string for this type."""

        if elfclass == ELFCLASS32:
            n = 2
        else:
            n = 3
        return "".join([t[n] for t in self.fields])

    def content(self, elfclass):
        """Return a tuple containing the values for an ELF type."""

        a = []
        if elfclass == ELFCLASS32:
            n = 2
        else:
            n = 3
        for t in self.fields:
            field_encoding = t[n]
            if field_encoding != "":
                v = getattr(self, t[0])
                a.append(bounded_value(v, field_encoding))
        return tuple(a)

    def getfields(self, elfclass):
        """Describe the binary layout of the type.

        Return a tuple (formatstring, *args) describing the
        desired binary layout in the manner of the 'struct'
        python library module.
        """

        return (self.formatstring(elfclass), self.content(elfclass))

    def layout(self, offset, elf):
        """Perform any layout-time translation for an ELF type."""

        return offset

    def size(self, elfclass):
        """Return the size of the type in bytes.

        The size returned is independent of the alignment needs of
        the type.
        """

        format = self.formatstring(elfclass)
        sz = 0
        for f in format:
            if f == "B":
                sz += 1
            elif f == "H":
                sz += 2
            elif f == "I":
                sz += 4
            elif f == "Q":
                sz += 8
            elif f == "":
                pass
            else:
                raise TypeError("Invalid format char {char!r}.".format(char=f))
        return sz


#
# Translation helper functions.
#


def do_string(d, n):
    """Convert a YAML value to a Python string."""

    v = get(d, n, defaults[n])
    if v:
        return str(v)
    return v


def do_long(d, n):
    """Convert a YAML value to a Python 'long'."""

    v = get(d, n, defaults[n])
    if v:
        return int(v)
    return v


def do_copy(d, n):
    """Copy a YAML value without conversion."""

    v = get(d, n, defaults[n])
    return v


def do_encode(xlate):
    """Translate a YAML value according to mapping 'xlate'."""

    return lambda d, n, xl=xlate: encode(d, n, defaults[n], xl)


def do_flags(xlate):
    """Translate a list of flags according to mapping 'xlate'."""

    return lambda d, n, xl=xlate: encode_flags(get(d, n, defaults[n]), xl)


#
# Definitions of ELF types.
#


class ElfCap(ElfType):
    """A representation of an ELF Cap structure.

    YAML tag: !Cap
    """

    fields = [
        # -YAPF-
        ('c_tag', do_encode(elf_cap_tag), "I", "Q"),
        ('c_un', do_long, "I", "Q")
    ]

    def __init__(self, cap, node):
        ElfType.__init__(self, cap, node)


class ElfDyn(ElfType):
    """A representation of an ELF Dyn structure.

    YAML tag: !Dyn
    """

    fields = [
        # -YAPF-
        ('d_tag', do_encode(elf_d_tag), "I", "Q"),
        ('d_un', do_long, "I", "Q")
    ]

    def __init__(self, d, node):
        ElfType.__init__(self, d, node)


class ElfEhdrIdent(ElfType):
    """A representation for the 'ident' field of an ELF Ehdr.

    YAML tag: !Ident
    """

    fields = [
        # -YAPF-
        ('ei_class', do_encode(elf_ei_class), "B", "B"),
        ('ei_data', do_encode(elf_ei_data), "B", "B"),
        ('ei_version', do_encode(elf_ei_version), "B", "B"),
        ('ei_osabi', do_encode(elf_ei_osabi), "B", "B"),
        ('ei_abiversion', do_long, "B", "B")
    ]

    def __init__(self, ei, node):
        ElfType.__init__(self, ei, node)

    def bits(self, format, elfclass):
        f, args = self.getfields(elfclass)
        s = b"\x7FELF"
        s += struct.pack(f + 'xxxxxxx', *args)
        return s


class ElfEhdr(ElfType):
    """A representation of an ELF Executable Header.

    YAML tag: !Ehdr
    """

    fields = [
        # -YAPF-
        ('e_ident', do_copy, "", ""),
        ('e_type', do_encode(elf_ehdr_type), "H", "H"),
        ('e_machine', do_encode(elf_ehdr_machine), "H", "H"),
        ('e_version', do_encode(elf_ei_version), "I", "I"),
        ('e_entry', do_long, "I", "Q"),
        ('e_phoff', do_long, "I", "Q"),
        ('e_shoff', do_long, "I", "Q"),
        ('e_flags', do_flags(elf_ehdr_flags), "I", "I"),
        ('e_ehsize', do_long, "H", "H"),
        ('e_phentsize', do_long, "H", "H"),
        ('e_phnum', do_long, "H", "H"),
        ('e_shentsize', do_long, "H", "H"),
        ('e_shnum', do_long, "H", "H"),
        ('e_shstrndx', do_copy, "H", "H")
    ]

    def __init__(self, eh, node):
        """Initialize an Ehdr structure.

        If an 'ident' structure was not specified as part of
        the YAML description, initialize it explicitly.
        """

        ElfType.__init__(self, eh, node)
        if self.e_ident is None:
            self.e_ident = ElfEhdrIdent({}, node)

    def layout(self, offset, elf):
        """Layout an ELF Ehdr.

        This method will fill in defaults and/or compute
        values for fields that were not specified in the YAML
        description.
        """

        elfclass = elf.elfclass()
        if elfclass == ELFCLASS32:
            e_ehsize = 52
            e_phentsize = 32
            e_shentsize = 40
            alignment = 4
        else:  # 64 bit sizes
            e_ehsize = 64
            e_phentsize = 56
            e_shentsize = 64
            alignment = 8

        if self.e_ehsize is None:
            self.e_ehsize = e_ehsize

        # Compute e_phnum if needed.
        if self.e_phnum is None:
            self.e_phnum = len(elf.elf_phdrtab)

        # Compute a value for the e_phentsize field.
        if self.e_phentsize is None:
            if self.e_phnum:
                self.e_phentsize = e_phentsize
            else:
                self.e_phentsize = 0

        # Set the e_shentsize field.
        if self.e_shentsize is None:
            self.e_shentsize = e_shentsize

        # The program header defaults to just after the ELF header.
        if self.e_phoff is None:
            if self.e_phnum > 0:
                self.e_phoff = \
                      (self.e_ehsize + (alignment - 1)) & \
                    ~(alignment - 1)
            else:
                self.e_phoff = 0

        # compute e_shnum
        self.nsections = elf.elf_sections.get_shnum()
        if self.nsections > 0:
            if self.e_shstrndx is None:
                self.e_shstrndx = '.shstrtab'
            if isinstance(self.e_shstrndx, str):
                self.e_shstrndx = \
                  elf.elf_sections.get_index(self.e_shstrndx)
            elif isinstance(self.e_shstrndx, int):
                pass
            else:
                raise ElfError(
                    self._n,
                    "Unparseable e_shstrndx field: {v!r}".format(
                        v=self.e_shstrndx))
            if self.e_shstrndx is None:
                raise ElfError(self._n,
                        'Cannot determine section ' + \
                        'name string table index: {v!r}'.format(v=self.e_shstrndx))
        else:
            if self.e_shstrndx is None:
                self.e_shstrndx = 0

        if self.e_shnum is None:
            self.e_shnum = self.nsections

        # section data comes after the program header by default.  The
        # section header table is placed after all section data.

        if self.e_phnum > 0:
            offset = self.e_phoff + self.e_phnum * self.e_phentsize
        else:
            offset = self.e_ehsize
        offset = elf.elf_sections.layout(offset, elf)
        if self.e_shoff is None:
            if self.nsections > 0:
                self.e_shoff = (offset + (alignment-1)) & \
                       ~(alignment-1)
            else:
                self.e_shoff = 0

        if self.nsections >= SHN_LORESERVE:
            elf.elf_sections.set_extended_shnum(self.nsections)
            self.e_shnum = 0
        if self.e_shstrndx >= SHN_XINDEX:
            elf.elf_sections.set_extended_shstrndx(self.e_shstrndx)
            self.e_shstrndx = SHN_XINDEX

    def bits(self, formatchar, elfclass):
        """Return the file representation of an Elf Ehdr."""

        s = self.e_ident.bits(formatchar, elfclass)
        s += ElfType.bits(self, formatchar, elfclass)

        return s


class ElfLong:
    """Wrapper around a python Int/Long."""

    def __init__(self, v):
        self._v = int(v)

    def bits(self, formatchar, elfclass):
        """Return the file representation for this object.

        Depending on the number of bits needed to represent
        the number, the returned bits would be either 4 or
        8 bytes wide.
        """

        if self._v > 0xFFFFFFFF:
            f = formatchar + "Q"
        else:
            f = formatchar + "I"
        return struct.pack(f, self._v)


class ElfMove(ElfType):
    """A representation of an Elf Move type.

    YAML tag: !Move
    """

    fields = [
        # -YAPF-
        ('m_value', do_long, "I", "I"),
        ('m_info', do_long, "I", "Q"),
        ('m_poffset', do_long, "I", "Q"),
        ('m_repeat', do_long, "H", "H"),
        ('m_stride', do_long, "H", "H")
    ]

    def __init__(self, move, node):
        ElfType.__init__(self, move, node)


class ElfNote(ElfType):
    """A representation of an Elf Note type.

    YAML tag: !Note

    The data in the note is held in YAML node named 'n_data' which is
    a pair of strings, one for the note's name field and one for the
    description.

    If the fields 'n_namesz' and 'n_descz' aren't specified, they
    are computed from the contents of 'n_data'.
    """

    fields = [
        # -YAPF-
        ('n_namesz', do_long, "I", "I"),
        ('n_descsz', do_long, "I", "I"),
        ('n_type', do_long, "I", "I"),
        ('n_data', do_copy, "", "")
    ]

    def __init__(self, note, node):
        ElfType.__init__(self, note, node)
        self._note = note

    def layout(self, offset, elfclass):
        if len(self.n_data) != 2:
            raise ElfError(node, "Note data not a pair of strings.")

        for nd in self.n_data:
            if isinstance(nd, ElfType):
                nd.layout(offset, elfclass)

        if self.n_namesz is None:
            self.n_namesz = len(self.n_data[0])
        if self.n_descsz is None:
            self.n_descsz = len(self.n_data[1])

    def bits(self, format, elfclass):
        b = ElfType.bits(self, format, elfclass)
        nbits = str(self.n_data[0])
        dbits = str(self.n_data[1])
        return b + nbits + dbits


class ElfPhdr(ElfType):
    """A representation of an ELF Program Header Table entry.

    YAML tag: !Phdr
    """

    fields = [
        # NOTE: class-dependent field ordering
        # -YAPF-
        ('p_align', do_long),
        ('p_filesz', do_long),
        (
            'p_flags',
            do_flags(elf_ph_flags),
        ),
        ('p_memsz', do_long),
        ('p_offset', do_long),
        ('p_paddr', do_long),
        ('p_type', do_encode(elf_ph_type)),
        ('p_vaddr', do_long)
    ]

    def __init__(self, ph, node):
        ElfType.__init__(self, ph, node)

    def to_string(self):
        """Helper during debugging."""

        s = "Phdr(type:%(p_type)d,flags:%(p_flags)d," \
         "offset:%(p_offset)ld,vaddr:%(p_vaddr)ld," \
         "paddr:%(p_paddr)ld,filesz:%(p_filesz)ld," \
         "memsz:%(p_memsz)ld)" % self
        return s

    def bits(self, formatchar, elfclass):
        """Return the file representation of a Phdr."""

        f = formatchar
        # Phdr structures are laid out in a class-dependent way
        if elfclass == ELFCLASS32:
            f += "IIIIIIII"
            s = struct.pack(f, self.p_type, self.p_offset, self.p_vaddr,
                            self.p_paddr, self.p_filesz, self.p_memsz,
                            self.p_flags, self.p_align)
        else:
            f += "IIQQQQQQ"
            s = struct.pack(f, self.p_type, self.p_flags, self.p_offset,
                            self.p_vaddr, self.p_paddr, self.p_filesz,
                            self.p_memsz, self.p_align)
        return s


class ElfRel(ElfType):
    """A representation of an ELF Rel type.

    YAML tag: !Rel
    """

    fields = [
        # -YAPF-
        ('r_offset', do_long, "I", "Q"),
        ('r_info', do_long, "I", "Q")
    ]

    def __init__(self, rel, node):
        ElfType.__init__(self, rel, node)


class ElfRela(ElfType):
    """A representation of an ELF Rela type.

    YAML tag: !Rela
    """

    fields = [
        # -YAPF-
        ('r_offset', do_long, "I", "Q"),
        ('r_info', do_long, "I", "Q"),
        ('r_addend', do_long, "I", "Q")
    ]

    def __init__(self, rela, node):
        ElfType.__init__(self, rela, node)


class ElfSection(ElfType):
    """A representation of an ELF Section.

    YAML tag: !Section

    A section description consists of the fields that make up an ELF
    section header entry with the following additional fields:

    - Field 'sh_data' contains the data associated with this section.
      'sh_data' may be a YAML string, or can be a YAML list of items
      that comprise the content of the section.
    - Field 'sh_index' can be used to manually set the section's index.
    - Field 'sh_word_size' specifies the word size to use for data in
      integer literal form.  The value of this field can be 32 or 64.
    """

    fields = [
        # -YAPF-
        ('sh_name', do_string, "I", "I"),
        ('sh_type', do_encode(elf_sh_type), "I", "I"),
        ('sh_flags', do_flags(elf_sh_flags), "I", "Q"),
        ('sh_addr', do_long, "I", "Q"),
        ('sh_offset', do_long, "I", "Q"),
        ('sh_size', do_long, "I", "Q"),
        ('sh_link', do_long, "I", "I"),
        ('sh_info', do_long, "I", "I"),
        ('sh_addralign', do_copy, "I", "Q"),
        ('sh_entsize', do_long, "I", "Q"),
        ('sh_data', do_copy, "", ""),
        ('sh_index', do_long, "", ""),
        ('sh_word_size', do_long, "", ""),
    ]

    def __init__(self, shdr, node):
        """Initialize a section descriptor."""

        ElfType.__init__(self, shdr, node)
        if not isinstance(self.sh_data, list):
            self.sh_data = list(self.sh_data)
        if self.sh_addralign is None:
            if self.sh_type == SHT_NULL or self.sh_type == SHT_NOBITS:
                self.sh_addralign = 0
            else:
                self.sh_addralign = 1
        else:
            if (self.sh_addralign == 0 or \
             (self.sh_addralign & (self.sh_addralign - 1)) != 0):
                raise ElfError(node, "'sh_addralign' not a power of two.")
        if self.sh_word_size != 32 and self.sh_word_size != 64:
            raise ElfError(
                node,
                "unsupported 'sh_word_size' value: {v!r}".format(
                    v=self.sh_word_size))
        self._data = None  # 'cache' of translated data
        self._strtab = None

    def to_string(self):
        """Helper function during debugging."""

        return "Section(name:%(sh_name)s,type:%(sh_type)d," \
               "flags:%(sh_flags)x,addr:%(sh_addr)d,"\
               "offset:%(sh_offset)d,size:%(sh_size)d," \
               "link:%(sh_link)d,info:%(sh_info)d," \
               "addralign:%(sh_addralign)d,entsize:%(sh_entsize)d)" % \
               self

    def make_strtab(self):
        """Create a string table from section contents."""

        self._strtab = ElfStrTab(self.sh_data)

    def string_to_index(self, name):
        """Convert 'name' to an offset inside a string table.

        Only valid for sections of type SHT_STRTAB."""

        if self._strtab:
            return self._strtab.lookup(name)
        raise ElfError(
            None, "Cannot translate {name!r} to an index.".format(name=name))

    def bits(self, formatchar, elfclass):
        raise AssertionError("Section objects should use " \
                             "databits() or headerbits()")

    def layout(self, offset, elf):
        """Prepare an ELF section for output."""

        if isinstance(self.sh_name, str):
            # first try convert it to a long
            try:
                self.sh_name = int(self.sh_name)
            except ValueError:  # lookup in string table
                try:
                    self.sh_name = \
                        elf.section_name_index(self.sh_name)
                except KeyError:
                    raise ElfError(
                        self._n,
                        "Section name {name!r} not in string table.".format(
                            name=self.sh_name))
        # give a chance for the contents of a section to xlate strings
        for d in self.sh_data:
            if isinstance(d, ElfType):
                d.layout(offset, elf)
        # compute the space used by the section data
        self._data = self.databits(elf.formatchar(), elf.elfclass())

        align = self.sh_addralign
        if align == 0:
            align = 1
        if self.sh_type == SHT_NULL or self.sh_type == SHT_NOBITS:
            isnulltype = 1
        else:
            isnulltype = 0

        offset = (offset + (align - 1)) & ~(align - 1)
        if self.sh_size is None:
            if isnulltype:
                self.sh_size = 0
            else:
                self.sh_size = len(self._data)
        if self.sh_offset is None:
            if isnulltype:
                self.sh_offset = 0
            else:
                self.sh_offset = offset
        if isnulltype:  # ignore bits for null types
            return offset
        return offset + len(self._data)

    def databits(self, formatchar, elfclass):
        """Return the contents of a section."""

        if self._data:
            return self._data
        # special-case string table handling
        if self.sh_type == SHT_STRTAB:
            return self._strtab.bits()
        # 'normal' section
        s = b""
        for d in self.sh_data:
            if isinstance(d, ElfType):
                s += d.bits(formatchar, elfclass)
            elif isinstance(d, int):
                word_size_char = "I"
                if self.sh_word_size == 64:
                    word_size_char = "Q"
                s += struct.pack(formatchar + word_size_char, d)
            else:
                s += bytes(d, 'utf-8')
        return s

    def headerbits(self, formatchar, elfclass):
        """Return the file representation of the section header."""

        return ElfType.bits(self, formatchar, elfclass)


class ElfSym(ElfType):
    """A representation for an ELF Symbol type.

    YAML tag: !Sym
    """

    fields = [  # NOTE: class-dependent layout.
        # -YAPF-
        ('st_info', do_long, "B", "B"),
        ('st_name', do_string, "I", "I"),
        ('st_other', do_long, "B", "B"),
        ('st_shndx', do_string, "H", "H"),
        ('st_size', do_long, "I", "Q"),
        ('st_value', do_long, "I", "Q")
    ]

    def __init__(self, sym, node):
        ElfType.__init__(self, sym, node)

    def bits(self, format, elfclass):
        """Return the file representation for an ELF Sym."""

        if elfclass == ELFCLASS32:
            s = struct.pack(format + "IIIBBH", self.st_name, self.st_value,
                            self.st_size, self.st_info, self.st_other,
                            self.st_shndx)
        else:
            s = struct.pack(format + "IBBHQQ", self.st_name, self.st_info,
                            self.st_other, self.st_shndx, self.st_value,
                            self.st_size)
        return s

    def layout(self, offset, elf):
        """Perform layout-time conversions for an ELF Sym.

        String valued fields are converted to offsets into
        string tables.
        """

        if isinstance(self.st_shndx, str):
            self.st_shndx = \
                  elf.elf_sections.get_index(self.st_shndx)
            if self.st_shndx is None:
                raise ElfError(self._n, "Untranslateable 'st_shndx' " + \
                 "value {value!r}.".format(value=self.st_shndx))

        if isinstance(self.st_name, str):
            try:
                strtab = \
                       elf.elf_sections[self.st_shndx]._strtab
            except IndexError:
                raise ElfError(self._n, "'st_shndx' out of range")
            if strtab is None:
                raise ElfError(self._n, "'st_shndx' not of type STRTAB.")

            try:
                self.st_name = strtab.lookup(self.st_name)
            except KeyError:
                raise ElfError(
                    self._n,
                    "unknown string {string!r}".format(string=self.st_name))
        return offset


class ElfSyminfo(ElfType):
    """A representation of an ELF Syminfo type.

    YAML tag: !Syminfo
    """

    fields = [
        # -YAPF-
        ('si_boundto', do_encode(elf_syminfo_boundto_types), "H", "H"),
        ('si_flags', do_flags(elf_syminfo_flags), "H", "H")
    ]

    def __init__(self, syminfo, node):
        ElfType.__init__(self, syminfo, node)


class ElfVerdaux(ElfType):
    """A representation of an ELF Verdaux type."""

    fields = [
        # -YAPF-
        ('vda_name', do_long, "I", "I"),
        ('vda_next', do_long, "I", "I")
    ]

    def __init__(self, verdaux, node):
        ElfType.__init__(self, verdaux, node)


class ElfVerdef(ElfType):
    """A representation of an ELF Verdef type."""

    fields = [
        # -YAPF-
        ('vd_version', do_long, "H", "H"),
        ('vd_flags', do_long, "H", "H"),
        ('vd_ndx', do_long, "H", "H"),
        ('vd_cnt', do_long, "H", "H"),
        ('vd_hash', do_long, "I", "I"),
        ('vd_aux', do_long, "I", "I"),
        ('vd_next', do_long, "I", "I")
    ]

    def __init__(self, verdef, node):
        ElfType.__init__(self, verdef, node)


class ElfVernaux(ElfType):
    """A representation of an ELF Vernaux type."""

    fields = [
        # -YAPF-
        ('vna_hash', do_long, "I", "I"),
        ('vna_flags', do_long, "H", "H"),
        ('vna_other', do_long, "H", "H"),
        ('vna_name', do_long, "I", "I"),
        ('vna_next', do_long, "I", "I")
    ]

    def __init__(self, vernaux, node):
        ElfType.__init__(self, vernaux, node)


class ElfVerneed(ElfType):
    """A representation of an ELF Verneed type."""

    fields = [
        # -YAPF-
        ('vn_version', do_long, "H", "H"),
        ('vn_cnt', do_long, "H", "H"),
        ('vn_file', do_long, "I", "I"),
        ('vn_aux', do_long, "I", "I"),
        ('vn_next', do_long, "I", "I")
    ]

    def __init__(self, verneed, node):
        ElfType.__init__(self, verneed, node)


#
# Aggregates
#


class ElfPhdrTable:
    """A representation of an ELF Program Header Table.

    A program header table is a list of program header entry sections.
    """

    def __init__(self, phdr):
        """Initialize a program header table object.

        Argument 'phdr' is a list of parsed ElfPhdr objects.
        """

        self.pht_data = []
        for ph in phdr:
            if isinstance(ph, dict):
                ph = ElfPhdr(ph)
            elif not isinstance(ph, ElfPhdr):
                raise ElfError(ph.node, "Program Header Table "
                               "contains non header data.")
            self.pht_data.append(ph)

    def bits(self, formatchar, elfclass):
        """Return the file representation of the Phdr table."""

        s = ""
        for d in self.pht_data:
            s += d.bits(formatchar, elfclass)
        return s

    def __len__(self):
        """Return the number of program header table entries."""

        return len(self.pht_data)

    def __iter__(self):
        """Return an iterator for traversing Phdr entries."""

        return self.pht_data.__iter__()


class ElfSectionList:
    """A list of ELF sections."""

    def __init__(self, shlist):
        """Initialize an ELF section list.

        Argument 'shlist' is a list of parser ElfSection
        objects.
        """

        self.shl_sections = shlist
        self.shl_sectionnames = []
        self.shl_nentries = len(shlist)

        for sh in shlist:
            if not isinstance(sh, ElfSection):
                raise ElfError(None, """Section 'sections' contains
                           unrecognized data.""")
            if sh.sh_index is not None:
                if self.shl_nentries <= sh.sh_index:
                    self.shl_nentries = sh.sh_index + 1
            self.shl_sectionnames.append((sh.sh_name, sh.sh_index))
            if sh.sh_type == SHT_STRTAB:  # a string table
                sh.make_strtab()

    def __len__(self):
        """Return the number of ELF sections."""

        return len(self.shl_sections)

    def __iter__(self):
        """Iterate through ELF sections."""

        return self.shl_sections.__iter__()

    def __getitem__(self, ind):
        """Retrieve the ELF section at index 'ind'."""

        try:
            return self.shl_sections[ind]
        except IndexError:
            for sh in self.shl_sections:
                if sh.sh_index == ind:
                    return sh
            raise IndexError("no section at index {index}".format(index=ind))

    def layout(self, offset, elf):
        """Compute the layout for section."""

        if len(self.shl_sections) == 0:
            return 0
        for sh in self.shl_sections:  # layout sections
            offset = sh.layout(offset, elf)
        return offset

    def get_index(self, name):
        """Return the section index for section 'name', or 'None'."""

        c = 0
        for (n, i) in self.shl_sectionnames:
            if n == name:
                if i is None:
                    return c
                else:
                    return i
            c += 1
        return None

    def get_shnum(self):
        """Retrieve the number of sections in this container."""

        return self.shl_nentries

    def set_extended_shnum(self, shnum):
        """Set the extended section number."""

        sh = self.shl_sections[0]
        sh.sh_size = shnum

    def set_extended_shstrndx(self, strndx):
        """Set the extended string table index."""

        sh = self.shl_sections[0]
        sh.sh_link = strndx


class Elf:
    """A representation of an ELF object."""

    def __init__(self, yamldict, ehdr, phdrtab, sections):
        self._d = yamldict
        self._n = None
        self.elf_ehdr = ehdr
        self.elf_phdrtab = phdrtab
        self.elf_sections = sections
        self.elf_fillchar = int(
            get(yamldict, 'elf_fillchar', defaults['elf_fillchar']))

    def byteorder(self):
        """Return the byteorder for this ELF object."""
        return self.elf_ehdr.e_ident.ei_data

    def elfclass(self):
        """Return the ELF class for this ELF object."""
        return self.elf_ehdr.e_ident.ei_class

    def formatchar(self):
        """Return the format character corresponding to the ELF
        byteorder."""

        if self.byteorder() == ELFCLASS32:
            return "<"
        else:
            return ">"

    def layout(self):
        """Compute a file layout for this ELF object and update
        internal data structures."""

        self.elf_ehdr.layout(0, self)

    def section_name_index(self, name):
        """Compute index of section 'name' in the section name string table."""

        strndx = self.elf_ehdr.e_shstrndx
        if strndx is None:
            return None
        return self.elf_sections[strndx].string_to_index(name)

    def write(self, fn):
        """Write out the file representation of an ELF object.

        Argument 'fn' denotes the destination."""

        of = io.open(fn, 'wb')

        formatchar = self.formatchar()
        elfclass = self.elfclass()

        # Write out the header
        of.write(self.elf_ehdr.bits(formatchar, elfclass))

        # Write out the program header table if present
        if self.elf_phdrtab:
            self.reposition(of, self.elf_ehdr.e_phoff)
            for ph in self.elf_phdrtab:
                of.write(ph.bits(formatchar, elfclass))
        # Write out the sections
        if self.elf_sections:
            # First the contents of the sections
            for sh in self.elf_sections:
                if sh.sh_type == SHT_NULL or sh.sh_type == SHT_NOBITS:
                    continue
                self.reposition(of, sh.sh_offset)
                of.write(sh.databits(formatchar, elfclass))
            # Then the header table
            self.reposition(of, self.elf_ehdr.e_shoff)
            for sh in self.elf_sections:
                if sh.sh_index:
                    new_offset = sh.sh_index * self.elf_ehdr.e_shentsize + \
                     self.elf_ehdr.e_shoff
                    self.reposition(of, new_offset)
                of.write(sh.headerbits(formatchar, elfclass))
        of.close()

    def reposition(self, f, offset):
        """Reposition file `f' to offset `offset', filling gaps with
        the configured fill character as needed."""

        pos = f.tell()
        if offset == pos:
            return
        if offset < pos or (offset > pos and self.elf_fillchar == 0):
            f.seek(offset, 0)
            return
        s = ("{fillchar}".format(fillchar=self.elf_fillchar) * (offset - pos))
        f.write(s)


#
# YAML Parser configuration and helpers.
#

yaml_tags = [
    # -YAPF-
    ('!Cap', ElfCap),
    ('!Dyn', ElfDyn),
    ('!Ehdr', ElfEhdr),
    ('!Ident', ElfEhdrIdent),
    ('!Move', ElfMove),
    ('!Note', ElfNote),
    ('!Phdr', ElfPhdr),
    ('!Rel', ElfRel),
    ('!Rela', ElfRela),
    ('!Section', ElfSection),
    ('!Sym', ElfSym),
    ('!Syminfo', ElfSyminfo),
    ('!Verdaux', ElfVerdaux),
    ('!Verdef', ElfVerdef),
    ('!Vernaux', ElfVernaux),
    ('!Verneed', ElfVerneed)
]


def init_parser():
    for t in yaml_tags:
        yaml.add_constructor(t[0], # lamdba: loader, node, class
         lambda l, n, c=t[1]: \
          c(l.construct_mapping(n, deep=True), n))


def make_elf(yd):
    """Convert a YAML description `yd' of an ELF file into an
    ELF object."""

    try:
        eh = yd['ehdr']
    except KeyError:
        eh = ElfEhdr({}, None)

    phdrtab = ElfPhdrTable(get(yd, 'phdrtab', {}))
    sectionlist = ElfSectionList(get(yd, 'sections', {}))

    return Elf(yd, eh, phdrtab, sectionlist)


#
# MAIN
#

if __name__ == '__main__':
    parser = optparse.OptionParser(
        usage=usage, version=version, description=description)
    parser.add_option(
        "-o",
        "--output",
        dest="output",
        help="write output to FILE [default: %default]",
        metavar="FILE",
        default="a.out")
    parser.add_option(
        "-N",
        "--no-shstrtab",
        dest="do_shstrtab",
        help="do not create a string table section for "
        "section names if missing",
        action="store_false",
        metavar="BOOLEAN",
        default=True)
    parser.add_option(
        "-U",
        "--no-shnundef",
        dest="do_shnundef",
        help="do not create a section header for index "
        "SHN_UNDEF if missing",
        action="store_false",
        metavar="BOOLEAN",
        default=True)

    (options, args) = parser.parse_args()

    if len(args) > 1:
        parser.error("only one input-file must be specified")

    try:
        if args:
            stream = io.open(args[0], 'r')
        else:
            stream = sys.stdin
    except IOError as err:
        parser.error("cannot open stream: {err}".format(err=err))

    init_parser()

    try:
        elf = make_elf(yaml.load(stream, Loader=yaml.Loader))
        elf.layout()
        elf.write(options.output)
    except yaml.YAMLError as err:
        parser.error("cannot parse stream: {err}".format(err=err))
    except ElfError as msg:
        print(msg)
        sys.exit(1)

# Local Variables:
# mode: python
# tab-width: 4
# py-indent-offset: 4
# End:
