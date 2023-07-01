type elf_class_ty = ELFCLASS32 | ELFCLASS64
type byte_order_ty = LITTLE_ENDIAN | BIG_ENDIAN
type elf_version_ty = EV_CURRENT

type elf_os_abi_ty =
  | ELFOSABI_NONE
  | ELFOSABI_HPUX
  | ELFOSABI_NETBSD
  | ELFOSABI_LINUX
  | ELFOSABI_HURD
  | ELFOSABI_86OPEN
  | ELFOSABI_SOLARIS
  | ELFOSABI_AIX
  | ELFOSABI_IRIX
  | ELFOSABI_FREEBSD
  | ELFOSABI_TRU64
  | ELFOSABI_MODESTO
  | ELFOSABI_OPENBSD
  | ELFOSABI_OPENVMS
  | ELFOSABI_NSK
  | ELFOSABI_AROS
  | ELFOSABI_FENIXOS
  | ELFOSABI_CLOUDABI
  | ELFOSABI_ARM
  | ELFOSABI_STANDALONE

type elf_type_ty = ET_REL | ET_EXEC | ET_DYN | ET_CORE | ET_OS | ET_PROC

type machine_ty =
  | EM_NONE
  | EM_M32
  | EM_SPARC
  | EM_386
  | EM_68K
  | EM_88K
  | EM_860
  | EM_MIPS
  | EM_S370
  | EM_MIPS_RS3_LE
  | EM_PARISC
  | EM_VPP500
  | EM_SPARC32PLUS
  | EM_960
  | EM_PPC
  | EM_PPC64
  | EM_S390
  | EM_V800
  | EM_FR20
  | EM_RH32
  | EM_RCE
  | EM_ARM
  | EM_SH
  | EM_SPARCV9
  | EM_TRICORE
  | EM_ARC
  | EM_H8_300
  | EM_H8_300H
  | EM_H8S
  | EM_H8_500
  | EM_IA_64
  | EM_MIPS_X
  | EM_COLDFIRE
  | EM_68HC12
  | EM_MMA
  | EM_PCP
  | EM_NCPU
  | EM_NDR1
  | EM_STARCORE
  | EM_ME16
  | EM_ST100
  | EM_TINYJ
  | EM_X86_64
  | EM_PDSP
  | EM_PDP10
  | EM_PDP11
  | EM_FX66
  | EM_ST9PLUS
  | EM_ST7
  | EM_68HC16
  | EM_68HC11
  | EM_68HC08
  | EM_68HC05
  | EM_SVX
  | EM_ST19
  | EM_VAX
  | EM_CRIS
  | EM_JAVELIN
  | EM_FIREPATH
  | EM_ZSP
  | EM_MMIX
  | EM_HUANY
  | EM_PRISM
  | EM_AVR
  | EM_FR30
  | EM_D10V
  | EM_D30V
  | EM_V850
  | EM_M32R
  | EM_MN10300
  | EM_MN10200
  | EM_PJ
  | EM_OPENRISC
  | EM_ARC_COMPACT
  | EM_XTENSA
  | EM_VIDEOCORE
  | EM_TMM_GPP
  | EM_NS32K
  | EM_TPC
  | EM_SNP1K
  | EM_ST200
  | EM_IP2K
  | EM_MAX
  | EM_CR
  | EM_F2MC16
  | EM_MSP430
  | EM_BLACKFIN
  | EM_SE_C33
  | EM_SEP
  | EM_ARCA
  | EM_UNICORE
  | EM_EXCESS
  | EM_DXP
  | EM_ALTERA_NIOS2
  | EM_CRX
  | EM_XGATE
  | EM_C166
  | EM_M16C
  | EM_DSPIC30F
  | EM_CE
  | EM_M32C
  | EM_TSK3000
  | EM_RS08
  | EM_SHARC
  | EM_ECOG2
  | EM_SCORE7
  | EM_DSP24
  | EM_VIDEOCORE3
  | EM_LATTICEMICO32
  | EM_SE_C17
  | EM_TI_C6000
  | EM_TI_C2000
  | EM_TI_C5500
  | EM_TI_ARP32
  | EM_TI_PRU
  | EM_MMDSP_PLUS
  | EM_CYPRESS_M8C
  | EM_R32C
  | EM_TRIMEDIA
  | EM_QDSP6
  | EM_8051
  | EM_STXP7X
  | EM_NDS32
  | EM_ECOG1
  | EM_MAXQ30
  | EM_XIMO16
  | EM_MANIK
  | EM_CRAYNV2
  | EM_RX
  | EM_METAG
  | EM_MCST_ELBRUS
  | EM_ECOG16
  | EM_CR16
  | EM_ETPU
  | EM_SLE9X
  | EM_L10M
  | EM_K10M
  | EM_AARCH64
  | EM_AVR32
  | EM_STM8
  | EM_TILE64
  | EM_TILEPRO
  | EM_MICROBLAZE
  | EM_CUDA
  | EM_TILEGX
  | EM_CLOUDSHIELD
  | EM_COREA_1ST
  | EM_COREA_2ND
  | EM_ARC_COMPACT2
  | EM_OPEN8
  | EM_RL78
  | EM_VIDEOCORE5
  | EM_78KOR
  | EM_56800EX
  | EM_BA1
  | EM_BA2
  | EM_XCORE
  | EM_MCHP_PIC
  | EM_INTEL205
  | EM_INTEL206
  | EM_INTEL207
  | EM_INTEL208
  | EM_INTEL209
  | EM_KM32
  | EM_KMX32
  | EM_KMX16
  | EM_KMX8
  | EM_KVARC
  | EM_CDP
  | EM_COGE
  | EM_COOL
  | EM_NORC
  | EM_CSR_KALIMBA
  | EM_Z80
  | EM_VISIUM
  | EM_FT32
  | EM_MOXIE
  | EM_AMDGPU
  | EM_RISCV
  | EM_LANAI
  | EM_BPF
  | EM_LOONGARCH
  | EM_486
  | EM_ALPHA_STD
  | EM_ALPHA

type elf_info_ty = {
  ei_class : elf_class_ty;
  ei_data : byte_order_ty;
  ei_version : elf_version_ty;
  ei_os_abi : elf_os_abi_ty;
  ei_os_abi_version : Stdint.uint8;
}

type elf_header_ty = {
  e_type : elf_type_ty;
  e_machine : machine_ty;
  e_version : elf_version_ty;
  e_entry : Stdint.uint64;
  e_phoff : Stdint.uint64;
  e_shoff : Stdint.uint64;
  e_flags : Stdint.uint32;
  e_ehsize : Stdint.uint16;
  e_phentsize : Stdint.uint16;
  e_phnum : Stdint.uint16;
  e_shentsize : Stdint.uint16;
  e_shnum : Stdint.uint16;
  e_shstrndx : Stdint.uint16;
}

val os_abi_ty_to_string : elf_os_abi_ty -> string
val elf_type_ty_to_string : elf_type_ty -> string

type phdr_type_ty =
  | PT_NULL
  | PT_LOAD
  | PT_DYNAMIC
  | PT_INTERP
  | PT_NOTE
  | PT_SHLIB
  | PT_PHDR
  | PT_PROC

type phdr_ty = {
  p_type : phdr_type_ty;
  p_offset : Stdint.uint64;
  p_vaddr : Stdint.uint64;
  p_paddr : Stdint.uint64;
  p_filesz : Stdint.uint64;
  p_memsz : Stdint.uint64;
  p_flags : Stdint.uint32;
  p_align : Stdint.uint64;
}

val new_file : string -> (phdr_ty list * elf_header_ty, string) result
