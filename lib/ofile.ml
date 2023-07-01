type elf_class_ty = ELFCLASS32 | ELFCLASS64
type byte_order_ty = LITTLE_ENDIAN | BIG_ENDIAN
type elf_version_ty = EV_CURRENT

type elf_os_abi_ty =
  | ELFOSABI_NONE (* UNIX System V ABI *)
  | ELFOSABI_HPUX (* HP-UX operating system *)
  | ELFOSABI_NETBSD (* NetBSD *)
  | ELFOSABI_LINUX (* Linux *)
  | ELFOSABI_HURD (* Hurd *)
  | ELFOSABI_86OPEN (* 86Open common IA32 ABI *)
  | ELFOSABI_SOLARIS (* Solaris *)
  | ELFOSABI_AIX (* AIX *)
  | ELFOSABI_IRIX (* IRIX *)
  | ELFOSABI_FREEBSD (* FreeBSD *)
  | ELFOSABI_TRU64 (* TRU64 UNIX *)
  | ELFOSABI_MODESTO (* Novell Modesto *)
  | ELFOSABI_OPENBSD (* OpenBSD *)
  | ELFOSABI_OPENVMS (* Open VMS *)
  | ELFOSABI_NSK (* HP Non-Stop Kernel *)
  | ELFOSABI_AROS (* Amiga Research OS *)
  | ELFOSABI_FENIXOS (* The FenixOS highly scalable multi-core OS *)
  | ELFOSABI_CLOUDABI (* Nuxi CloudABI *)
  | ELFOSABI_ARM (* ARM *)
  | ELFOSABI_STANDALONE (* Standalone (embedded) application *)

let os_abi_ty_to_string os_abi =
  match os_abi with
  | ELFOSABI_NONE -> "UNIX System V ABI"
  | ELFOSABI_HPUX -> "HP-UX operating system"
  | ELFOSABI_NETBSD -> "NetBSD"
  | ELFOSABI_LINUX -> "Linux"
  | ELFOSABI_HURD -> "Hurd"
  | ELFOSABI_86OPEN -> "86Open common IA32 ABI"
  | ELFOSABI_SOLARIS -> "Solaris"
  | ELFOSABI_AIX -> "AIX"
  | ELFOSABI_IRIX -> "IRIX"
  | ELFOSABI_FREEBSD -> "FreeBSD"
  | ELFOSABI_TRU64 -> "TRU64 UNIX"
  | ELFOSABI_MODESTO -> "Novell Modesto"
  | ELFOSABI_OPENBSD -> "OpenBSD"
  | ELFOSABI_OPENVMS -> "Open VMS"
  | ELFOSABI_NSK -> "HP Non-Stop Kernel"
  | ELFOSABI_AROS -> "Amiga Research OS"
  | ELFOSABI_FENIXOS -> "The FenixOS highly scalable multi-core OS"
  | ELFOSABI_CLOUDABI -> "Nuxi CloudABI"
  | ELFOSABI_ARM -> "ARM"
  | ELFOSABI_STANDALONE -> "Standalone (embedded) application"

type elf_info_ty = {
  ei_class : elf_class_ty;
  ei_data : byte_order_ty;
  ei_version : elf_version_ty;
  ei_os_abi : elf_os_abi_ty;
  ei_os_abi_version : Stdint.uint8;
}

type elf_type_ty =
  | ET_REL (* Relocatable *)
  | ET_EXEC (* Executable *)
  | ET_DYN (* Shared object *)
  | ET_CORE (* Core file *)
  | ET_OS (* Operating system specific *)
  | ET_PROC (* Processor-specific *)

let elf_type_ty_to_string elf_type =
  match elf_type with
  | ET_REL -> "Relocatable"
  | ET_EXEC -> "Executable"
  | ET_DYN -> "Shared object"
  | ET_CORE -> "Core file"
  | ET_OS -> "Operating system specific"
  | ET_PROC -> "Processor-specific"

type machine_ty =
  | EM_NONE (* Unknown machine *)
  | EM_M32 (* AT&T WE32100 *)
  | EM_SPARC (* Sun SPARC *)
  | EM_386 (* Intel i386 *)
  | EM_68K (* Motorola 68000 *)
  | EM_88K (* Motorola 88000 *)
  | EM_860 (* Intel i860 *)
  | EM_MIPS (* MIPS R3000 Big-Endian only *)
  | EM_S370 (* IBM System/370 *)
  | EM_MIPS_RS3_LE (* MIPS R3000 Little-Endian *)
  | EM_PARISC (* HP PA-RISC *)
  | EM_VPP500 (* Fujitsu VPP500 *)
  | EM_SPARC32PLUS (* SPARC v8plus *)
  | EM_960 (* Intel 80960 *)
  | EM_PPC (* PowerPC 32-bit *)
  | EM_PPC64 (* PowerPC 64-bit *)
  | EM_S390 (* IBM System/390 *)
  | EM_V800 (* NEC V800 *)
  | EM_FR20 (* Fujitsu FR20 *)
  | EM_RH32 (* TRW RH-32 *)
  | EM_RCE (* Motorola RCE *)
  | EM_ARM (* ARM *)
  | EM_SH (* Hitachi SH *)
  | EM_SPARCV9 (* SPARC v9 64-bit *)
  | EM_TRICORE (* Siemens TriCore embedded processor *)
  | EM_ARC (* Argonaut RISC Core *)
  | EM_H8_300 (* Hitachi H8/300 *)
  | EM_H8_300H (* Hitachi H8/300H *)
  | EM_H8S (* Hitachi H8S *)
  | EM_H8_500 (* Hitachi H8/500 *)
  | EM_IA_64 (* Intel IA-64 Processor *)
  | EM_MIPS_X (* Stanford MIPS-X *)
  | EM_COLDFIRE (* Motorola ColdFire *)
  | EM_68HC12 (* Motorola M68HC12 *)
  | EM_MMA (* Fujitsu MMA *)
  | EM_PCP (* Siemens PCP *)
  | EM_NCPU (* Sony nCPU *)
  | EM_NDR1 (* Denso NDR1 microprocessor *)
  | EM_STARCORE (* Motorola Star*Core processor *)
  | EM_ME16 (* Toyota ME16 processor *)
  | EM_ST100 (* STMicroelectronics ST100 processor *)
  | EM_TINYJ (* Advanced Logic Corp. TinyJ processor *)
  | EM_X86_64 (* Advanced Micro Devices x86-6 *)
  | EM_PDSP (* Sony DSP Processo *)
  | EM_PDP10 (* Digital Equipment Corp. PDP-1 *)
  | EM_PDP11 (* Digital Equipment Corp. PDP-1 *)
  | EM_FX66 (* Siemens FX66 microcontrolle *)
  | EM_ST9PLUS (* STMicroelectronics ST9+ 8/16 bit microcontrolle *)
  | EM_ST7 (* STMicroelectronics ST7 8-bit microcontrolle *)
  | EM_68HC16 (* Motorola MC68HC16 Microcontrolle *)
  | EM_68HC11 (* Motorola MC68HC11 Microcontrolle *)
  | EM_68HC08 (* Motorola MC68HC08 Microcontrolle *)
  | EM_68HC05 (* Motorola MC68HC05 Microcontrolle *)
  | EM_SVX (* Silicon Graphics SV *)
  | EM_ST19 (* STMicroelectronics ST19 8-bit microcontrolle *)
  | EM_VAX (* Digital VA *)
  | EM_CRIS (* Axis Communications 32-bit embedded processo *)
  | EM_JAVELIN (* Infineon Technologies 32-bit embedded processo *)
  | EM_FIREPATH (* Element 14 64-bit DSP Processo *)
  | EM_ZSP (* LSI Logic 16-bit DSP Processo *)
  | EM_MMIX (* Donald Knuth's educational 64-bit processo *)
  | EM_HUANY (* Harvard University machine-independent object file *)
  | EM_PRISM (* SiTera Pris *)
  | EM_AVR (* Atmel AVR 8-bit microcontrolle *)
  | EM_FR30 (* Fujitsu FR3 *)
  | EM_D10V (* Mitsubishi D10 *)
  | EM_D30V (* Mitsubishi D30 *)
  | EM_V850 (* NEC v85 *)
  | EM_M32R (* Mitsubishi M32 *)
  | EM_MN10300 (* Matsushita MN1030 *)
  | EM_MN10200 (* Matsushita MN1020 *)
  | EM_PJ (* picoJav *)
  | EM_OPENRISC (* OpenRISC 32-bit embedded processo *)
  | EM_ARC_COMPACT
    (* ARC International ARCompact processor (old spelling/synonym: EM_ARC_A5 *)
  | EM_XTENSA (* Tensilica Xtensa Architectur *)
  | EM_VIDEOCORE (* Alphamosaic VideoCore processo *)
  | EM_TMM_GPP (* Thompson Multimedia General Purpose Processo *)
  | EM_NS32K (* National Semiconductor 32000 serie *)
  | EM_TPC (* Tenor Network TPC processo *)
  | EM_SNP1K (* Trebia SNP 1000 processo *)
  | EM_ST200 (* STMicroelectronics (www.st.com) ST200 microcontrolle *)
  | EM_IP2K (* Ubicom IP2xxx microcontroller famil *)
  | EM_MAX (* MAX Processo *)
  | EM_CR (* National Semiconductor CompactRISC microprocesso *)
  | EM_F2MC16 (* Fujitsu F2MC1 *)
  | EM_MSP430 (* Texas Instruments embedded microcontroller msp43 *)
  | EM_BLACKFIN (* Analog Devices Blackfin (DSP) processo *)
  | EM_SE_C33 (* S1C33 Family of Seiko Epson processor *)
  | EM_SEP (* Sharp embedded microprocesso *)
  | EM_ARCA (* Arca RISC Microprocesso *)
  | EM_UNICORE
    (* Microprocessor series from PKU-Unity Ltd. and MPRC of Peking Universit *)
  | EM_EXCESS (* eXcess: 16/32/64-bit configurable embedded CP *)
  | EM_DXP (* Icera Semiconductor Inc. Deep Execution Processo *)
  | EM_ALTERA_NIOS2 (* Altera Nios II soft-core processo *)
  | EM_CRX (* National Semiconductor CompactRISC CRX microprocesso *)
  | EM_XGATE (* Motorola XGATE embedded processo *)
  | EM_C166 (* Infineon C16x/XC16x processo *)
  | EM_M16C (* Renesas M16C series microprocessor *)
  | EM_DSPIC30F (* Microchip Technology dsPIC30F Digital Signal Controlle *)
  | EM_CE (* Freescale Communication Engine RISC cor *)
  | EM_M32C (* Renesas M32C series microprocessor *)
  | EM_TSK3000 (* Altium TSK3000 cor *)
  | EM_RS08 (* Freescale RS08 embedded processo *)
  | EM_SHARC (* Analog Devices SHARC family of 32-bit DSP processor *)
  | EM_ECOG2 (* Cyan Technology eCOG2 microprocesso *)
  | EM_SCORE7 (* Sunplus S+core7 RISC processo *)
  | EM_DSP24 (* New Japan Radio (NJR) 24-bit DSP Processo *)
  | EM_VIDEOCORE3 (* Broadcom VideoCore III processo *)
  | EM_LATTICEMICO32 (* RISC processor for Lattice FPGA architectur *)
  | EM_SE_C17 (* Seiko Epson C17 famil *)
  | EM_TI_C6000 (* The Texas Instruments TMS320C6000 DSP famil *)
  | EM_TI_C2000 (* The Texas Instruments TMS320C2000 DSP famil *)
  | EM_TI_C5500 (* The Texas Instruments TMS320C55x DSP famil *)
  | EM_TI_ARP32
    (* Texas Instruments Application Specific RISC Processor, 32bit fetc *)
  | EM_TI_PRU (* Texas Instruments Programmable Realtime Uni *)
  | EM_MMDSP_PLUS (* STMicroelectronics 64bit VLIW Data Signal Processo *)
  | EM_CYPRESS_M8C (* Cypress M8C microprocesso *)
  | EM_R32C (* Renesas R32C series microprocessor *)
  | EM_TRIMEDIA (* NXP Semiconductors TriMedia architecture famil *)
  | EM_QDSP6 (* QUALCOMM DSP6 Processo *)
  | EM_8051 (* Intel 8051 and variant *)
  | EM_STXP7X
    (* STMicroelectronics STxP7x family of configurable and extensible RISC processor *)
  | EM_NDS32
    (* Andes Technology compact code size embedded RISC processor famil *)
  | EM_ECOG1 (* Cyan Technology eCOG1X famil *)
  | EM_MAXQ30 (* Dallas Semiconductor MAXQ30 Core Micro-controller *)
  | EM_XIMO16 (* New Japan Radio (NJR) 16-bit DSP Processo *)
  | EM_MANIK (* M2000 Reconfigurable RISC Microprocesso *)
  | EM_CRAYNV2 (* Cray Inc. NV2 vector architectur *)
  | EM_RX (* Renesas RX famil *)
  | EM_METAG (* Imagination Technologies META processor architectur *)
  | EM_MCST_ELBRUS (* MCST Elbrus general purpose hardware architectur *)
  | EM_ECOG16 (* Cyan Technology eCOG16 famil *)
  | EM_CR16 (* National Semiconductor CompactRISC CR16 16-bit microprocesso *)
  | EM_ETPU (* Freescale Extended Time Processing Uni *)
  | EM_SLE9X (* Infineon Technologies SLE9X cor *)
  | EM_L10M (* Intel L10 *)
  | EM_K10M (* Intel K10 *)
  | EM_AARCH64 (* ARM 64-bit Architecture (AArch64 *)
  | EM_AVR32 (* Atmel Corporation 32-bit microprocessor famil *)
  | EM_STM8 (* STMicroeletronics STM8 8-bit microcontrolle *)
  | EM_TILE64 (* Tilera TILE64 multicore architecture famil *)
  | EM_TILEPRO (* Tilera TILEPro multicore architecture famil *)
  | EM_MICROBLAZE (* Xilinx MicroBlaze 32-bit RISC soft processor cor *)
  | EM_CUDA (* NVIDIA CUDA architectur *)
  | EM_TILEGX (* Tilera TILE-Gx multicore architecture famil *)
  | EM_CLOUDSHIELD (* CloudShield architecture famil *)
  | EM_COREA_1ST (* KIPO-KAIST Core-A 1st generation processor famil *)
  | EM_COREA_2ND (* KIPO-KAIST Core-A 2nd generation processor famil *)
  | EM_ARC_COMPACT2 (* Synopsys ARCompact V *)
  | EM_OPEN8 (* Open8 8-bit RISC soft processor cor *)
  | EM_RL78 (* Renesas RL78 famil *)
  | EM_VIDEOCORE5 (* Broadcom VideoCore V processo *)
  | EM_78KOR (* Renesas 78KOR famil *)
  | EM_56800EX (* Freescale 56800EX Digital Signal Controller (DSC *)
  | EM_BA1 (* Beyond BA1 CPU architectur *)
  | EM_BA2 (* Beyond BA2 CPU architectur *)
  | EM_XCORE (* XMOS xCORE processor famil *)
  | EM_MCHP_PIC (* Microchip 8-bit PIC(r) famil *)
  | EM_INTEL205 (* Reserved by Inte *)
  | EM_INTEL206 (* Reserved by Inte *)
  | EM_INTEL207 (* Reserved by Inte *)
  | EM_INTEL208 (* Reserved by Inte *)
  | EM_INTEL209 (* Reserved by Inte *)
  | EM_KM32 (* KM211 KM32 32-bit processo *)
  | EM_KMX32 (* KM211 KMX32 32-bit processo *)
  | EM_KMX16 (* KM211 KMX16 16-bit processo *)
  | EM_KMX8 (* KM211 KMX8 8-bit processo *)
  | EM_KVARC (* KM211 KVARC processo *)
  | EM_CDP (* Paneve CDP architecture famil *)
  | EM_COGE (* Cognitive Smart Memory Processo *)
  | EM_COOL (* Bluechip Systems CoolEngin *)
  | EM_NORC (* Nanoradio Optimized RIS *)
  | EM_CSR_KALIMBA (* CSR Kalimba architecture famil *)
  | EM_Z80 (* Zilog Z8 *)
  | EM_VISIUM (* Controls and Data Services VISIUMcore processo *)
  | EM_FT32 (* FTDI Chip FT32 high performance 32-bit RISC architectur *)
  | EM_MOXIE (* Moxie processor famil *)
  | EM_AMDGPU (* AMD GPU architectur *)
  | EM_RISCV (* RISC- *)
  | EM_LANAI (* Lanai 32-bit processo *)
  | EM_BPF (* Linux BPF – in-kernel virtual machin *)
  | EM_LOONGARCH (* LoongArc *)
  | EM_486 (* Intel i486 *)
  | EM_ALPHA_STD (* Digital Alpha (standard value) *)
  | EM_ALPHA (* Alpha (written in the absence of an ABI) *)

let parse_class buffer =
  let open Base.Result.Monad_infix in
  Obuffer.PlatformAgnosticReader.u8 buffer >>= fun value ->
  match Stdint.Uint8.to_int value with
  | 1 -> Ok ELFCLASS32
  | 2 -> Ok ELFCLASS64
  | 0 -> Error (Printf.sprintf "invalid ELF class: ELFCLASSNONE")
  | x -> Error (Printf.sprintf "unknown ELF class: %02x" x)

let parse_byte_order buffer =
  let open Base.Result.Monad_infix in
  Obuffer.PlatformAgnosticReader.u8 buffer >>= fun value ->
  match Stdint.Uint8.to_int value with
  | 1 -> Ok LITTLE_ENDIAN
  | 2 -> Ok BIG_ENDIAN
  | 0 -> Error (Printf.sprintf "invalid ELF data encoding: ELFDATANONE")
  | x -> Error (Printf.sprintf "unknown ELF data encoding: %02x" x)

let parse_version_in_identifier buffer =
  let open Base.Result.Monad_infix in
  Obuffer.PlatformAgnosticReader.u8 buffer >>= fun value ->
  match Stdint.Uint8.to_int value with
  | 1 -> Ok EV_CURRENT
  | 0 -> Error (Printf.sprintf "invalid ELF version: EV_NONE")
  | x -> Error (Printf.sprintf "unknown ELF version: %02x" x)

let parse_os_abi buffer =
  let open Base.Result.Monad_infix in
  Obuffer.PlatformAgnosticReader.u8 buffer >>= fun value ->
  match Stdint.Uint8.to_int value with
  | 0 -> Ok ELFOSABI_NONE
  | 1 -> Ok ELFOSABI_HPUX
  | 2 -> Ok ELFOSABI_NETBSD
  | 3 -> Ok ELFOSABI_LINUX
  | 4 -> Ok ELFOSABI_HURD
  | 5 -> Ok ELFOSABI_86OPEN
  | 6 -> Ok ELFOSABI_SOLARIS
  | 7 -> Ok ELFOSABI_AIX
  | 8 -> Ok ELFOSABI_IRIX
  | 9 -> Ok ELFOSABI_FREEBSD
  | 10 -> Ok ELFOSABI_TRU64
  | 11 -> Ok ELFOSABI_MODESTO
  | 12 -> Ok ELFOSABI_OPENBSD
  | 13 -> Ok ELFOSABI_OPENVMS
  | 14 -> Ok ELFOSABI_NSK
  | 15 -> Ok ELFOSABI_AROS
  | 16 -> Ok ELFOSABI_FENIXOS
  | 17 -> Ok ELFOSABI_CLOUDABI
  | 97 -> Ok ELFOSABI_ARM
  | 255 -> Ok ELFOSABI_STANDALONE
  | x -> Error (Printf.sprintf "unknown OS ABI: %02x" x)

let parse_info buffer =
  let open Base.Result.Monad_infix in
  parse_class buffer >>= fun ei_class ->
  parse_byte_order buffer >>= fun ei_data ->
  parse_version_in_identifier buffer >>= fun ei_version ->
  parse_os_abi buffer >>= fun ei_os_abi ->
  Obuffer.PlatformAgnosticReader.u8 buffer >>= fun ei_os_abi_version ->
  Ok { ei_class; ei_data; ei_version; ei_os_abi; ei_os_abi_version }

let parse_type reader_module buffer =
  let open Base.Result.Monad_infix in
  let module M = (val reader_module : Obuffer.Reader) in
  M.u16 buffer >>= fun value ->
  match Stdint.Uint16.to_int value with
  | 1 -> Ok ET_REL
  | 2 -> Ok ET_EXEC
  | 3 -> Ok ET_DYN
  | 4 -> Ok ET_CORE
  | 0 -> Error (Printf.sprintf "invalid ELF type: ET_NONE")
  | x ->
      if x >= 0xfe00 && x <= 0xfeff then Ok ET_OS
      else if x >= 0xff00 && x <= 0xffff then Ok ET_PROC
      else Error (Printf.sprintf "unknown ELF type: %04x" x)

let parse_machine reader_module buffer =
  let open Base.Result.Monad_infix in
  let module M = (val reader_module : Obuffer.Reader) in
  M.u16 buffer >>= fun value ->
  match Stdint.Uint16.to_int value with
  | 0 -> Ok EM_NONE
  | 1 -> Ok EM_M32
  | 2 -> Ok EM_SPARC
  | 3 -> Ok EM_386
  | 4 -> Ok EM_68K
  | 5 -> Ok EM_88K
  | 7 -> Ok EM_860
  | 8 -> Ok EM_MIPS
  | 9 -> Ok EM_S370
  | 10 -> Ok EM_MIPS_RS3_LE
  | 15 -> Ok EM_PARISC
  | 17 -> Ok EM_VPP500
  | 18 -> Ok EM_SPARC32PLUS
  | 19 -> Ok EM_960
  | 20 -> Ok EM_PPC
  | 21 -> Ok EM_PPC64
  | 22 -> Ok EM_S390
  | 36 -> Ok EM_V800
  | 37 -> Ok EM_FR20
  | 38 -> Ok EM_RH32
  | 39 -> Ok EM_RCE
  | 40 -> Ok EM_ARM
  | 42 -> Ok EM_SH
  | 43 -> Ok EM_SPARCV9
  | 44 -> Ok EM_TRICORE
  | 45 -> Ok EM_ARC
  | 46 -> Ok EM_H8_300
  | 47 -> Ok EM_H8_300H
  | 48 -> Ok EM_H8S
  | 49 -> Ok EM_H8_500
  | 50 -> Ok EM_IA_64
  | 51 -> Ok EM_MIPS_X
  | 52 -> Ok EM_COLDFIRE
  | 53 -> Ok EM_68HC12
  | 54 -> Ok EM_MMA
  | 55 -> Ok EM_PCP
  | 56 -> Ok EM_NCPU
  | 57 -> Ok EM_NDR1
  | 58 -> Ok EM_STARCORE
  | 59 -> Ok EM_ME16
  | 60 -> Ok EM_ST100
  | 61 -> Ok EM_TINYJ
  | 62 -> Ok EM_X86_64
  | 63 -> Ok EM_PDSP
  | 64 -> Ok EM_PDP10
  | 65 -> Ok EM_PDP11
  | 66 -> Ok EM_FX66
  | 67 -> Ok EM_ST9PLUS
  | 68 -> Ok EM_ST7
  | 69 -> Ok EM_68HC16
  | 70 -> Ok EM_68HC11
  | 71 -> Ok EM_68HC08
  | 72 -> Ok EM_68HC05
  | 73 -> Ok EM_SVX
  | 74 -> Ok EM_ST19
  | 75 -> Ok EM_VAX
  | 76 -> Ok EM_CRIS
  | 77 -> Ok EM_JAVELIN
  | 78 -> Ok EM_FIREPATH
  | 79 -> Ok EM_ZSP
  | 80 -> Ok EM_MMIX
  | 81 -> Ok EM_HUANY
  | 82 -> Ok EM_PRISM
  | 83 -> Ok EM_AVR
  | 84 -> Ok EM_FR30
  | 85 -> Ok EM_D10V
  | 86 -> Ok EM_D30V
  | 87 -> Ok EM_V850
  | 88 -> Ok EM_M32R
  | 89 -> Ok EM_MN10300
  | 90 -> Ok EM_MN10200
  | 91 -> Ok EM_PJ
  | 92 -> Ok EM_OPENRISC
  | 93 -> Ok EM_ARC_COMPACT
  | 94 -> Ok EM_XTENSA
  | 95 -> Ok EM_VIDEOCORE
  | 96 -> Ok EM_TMM_GPP
  | 97 -> Ok EM_NS32K
  | 98 -> Ok EM_TPC
  | 99 -> Ok EM_SNP1K
  | 100 -> Ok EM_ST200
  | 101 -> Ok EM_IP2K
  | 102 -> Ok EM_MAX
  | 103 -> Ok EM_CR
  | 104 -> Ok EM_F2MC16
  | 105 -> Ok EM_MSP430
  | 106 -> Ok EM_BLACKFIN
  | 107 -> Ok EM_SE_C33
  | 108 -> Ok EM_SEP
  | 109 -> Ok EM_ARCA
  | 110 -> Ok EM_UNICORE
  | 111 -> Ok EM_EXCESS
  | 112 -> Ok EM_DXP
  | 113 -> Ok EM_ALTERA_NIOS2
  | 114 -> Ok EM_CRX
  | 115 -> Ok EM_XGATE
  | 116 -> Ok EM_C166
  | 117 -> Ok EM_M16C
  | 118 -> Ok EM_DSPIC30F
  | 119 -> Ok EM_CE
  | 120 -> Ok EM_M32C
  | 131 -> Ok EM_TSK3000
  | 132 -> Ok EM_RS08
  | 133 -> Ok EM_SHARC
  | 134 -> Ok EM_ECOG2
  | 135 -> Ok EM_SCORE7
  | 136 -> Ok EM_DSP24
  | 137 -> Ok EM_VIDEOCORE3
  | 138 -> Ok EM_LATTICEMICO32
  | 139 -> Ok EM_SE_C17
  | 140 -> Ok EM_TI_C6000
  | 141 -> Ok EM_TI_C2000
  | 142 -> Ok EM_TI_C5500
  | 143 -> Ok EM_TI_ARP32
  | 144 -> Ok EM_TI_PRU
  | 160 -> Ok EM_MMDSP_PLUS
  | 161 -> Ok EM_CYPRESS_M8C
  | 162 -> Ok EM_R32C
  | 163 -> Ok EM_TRIMEDIA
  | 164 -> Ok EM_QDSP6
  | 165 -> Ok EM_8051
  | 166 -> Ok EM_STXP7X
  | 167 -> Ok EM_NDS32
  | 168 -> Ok EM_ECOG1
  | 169 -> Ok EM_MAXQ30
  | 170 -> Ok EM_XIMO16
  | 171 -> Ok EM_MANIK
  | 172 -> Ok EM_CRAYNV2
  | 173 -> Ok EM_RX
  | 174 -> Ok EM_METAG
  | 175 -> Ok EM_MCST_ELBRUS
  | 176 -> Ok EM_ECOG16
  | 177 -> Ok EM_CR16
  | 178 -> Ok EM_ETPU
  | 179 -> Ok EM_SLE9X
  | 180 -> Ok EM_L10M
  | 181 -> Ok EM_K10M
  | 183 -> Ok EM_AARCH64
  | 185 -> Ok EM_AVR32
  | 186 -> Ok EM_STM8
  | 187 -> Ok EM_TILE64
  | 188 -> Ok EM_TILEPRO
  | 189 -> Ok EM_MICROBLAZE
  | 190 -> Ok EM_CUDA
  | 191 -> Ok EM_TILEGX
  | 192 -> Ok EM_CLOUDSHIELD
  | 193 -> Ok EM_COREA_1ST
  | 194 -> Ok EM_COREA_2ND
  | 195 -> Ok EM_ARC_COMPACT2
  | 196 -> Ok EM_OPEN8
  | 197 -> Ok EM_RL78
  | 198 -> Ok EM_VIDEOCORE5
  | 199 -> Ok EM_78KOR
  | 200 -> Ok EM_56800EX
  | 201 -> Ok EM_BA1
  | 202 -> Ok EM_BA2
  | 203 -> Ok EM_XCORE
  | 204 -> Ok EM_MCHP_PIC
  | 205 -> Ok EM_INTEL205
  | 206 -> Ok EM_INTEL206
  | 207 -> Ok EM_INTEL207
  | 208 -> Ok EM_INTEL208
  | 209 -> Ok EM_INTEL209
  | 210 -> Ok EM_KM32
  | 211 -> Ok EM_KMX32
  | 212 -> Ok EM_KMX16
  | 213 -> Ok EM_KMX8
  | 214 -> Ok EM_KVARC
  | 215 -> Ok EM_CDP
  | 216 -> Ok EM_COGE
  | 217 -> Ok EM_COOL
  | 218 -> Ok EM_NORC
  | 219 -> Ok EM_CSR_KALIMBA
  | 220 -> Ok EM_Z80
  | 221 -> Ok EM_VISIUM
  | 222 -> Ok EM_FT32
  | 223 -> Ok EM_MOXIE
  | 224 -> Ok EM_AMDGPU
  | 243 -> Ok EM_RISCV
  | 244 -> Ok EM_LANAI
  | 247 -> Ok EM_BPF
  | 258 -> Ok EM_LOONGARCH
  | 6 -> Ok EM_486
  | 41 -> Ok EM_ALPHA_STD
  | 0x9026 -> Ok EM_ALPHA
  | x -> Error (Printf.sprintf "unknown machine type: %04x" x)

let parse_version reader_module buffer =
  let open Base.Result.Monad_infix in
  let module M = (val reader_module : Obuffer.Reader) in
  M.u32 buffer >>= fun value ->
  match Stdint.Uint32.to_int value with
  | 1 -> Ok EV_CURRENT
  | 0 -> Error (Printf.sprintf "invalid ELF version: EV_NONE")
  | x -> Error (Printf.sprintf "unknown ELF version: %02x" x)

let parse_header_field reader_module elf_class buffer =
  let module M = (val reader_module : Obuffer.Reader) in
  match elf_class with
  | ELFCLASS32 -> Result.map Stdint.Uint64.of_uint32 (M.u32 buffer)
  | ELFCLASS64 -> M.u64 buffer

let parse_shnum reader_module buffer e_class e_shoff e_shentsize =
  let open Base.Result.Monad_infix in
  let module M = (val reader_module : Obuffer.Reader) in
  M.u16 buffer >>= fun e_shnum ->
  let int_shnum = Stdint.Uint16.to_int e_shnum
  and int_shentsize = Stdint.Uint16.to_int e_shentsize
  and min_shentsize =
    match e_class with ELFCLASS32 -> 10 * 4 | ELFCLASS64 -> (4 * 4) + (6 * 8)
  in
  (* We use Stdint.Uint64.compare since we can't safely convert it to int for comparison with zero *)
  if Stdint.Uint64.compare e_shoff Stdint.Uint64.zero = 0 && int_shnum <> 0 then
    Error (Printf.sprintf "invalid e_shnum %d for e_shoff=0" int_shnum)
  else if int_shentsize < min_shentsize then
    Error (Printf.sprintf "invalid e_shentsize: %d" int_shentsize)
  else Ok e_shnum

let parse_shstrndx reader_module buffer e_shnum =
  let open Base.Result.Monad_infix in
  let module M = (val reader_module : Obuffer.Reader) in
  M.u16 buffer >>= fun e_shstrndx ->
  (* It is fine to convert to int here since the width of int is greater than width of Stdint.uint16 *)
  let int_shnum = Stdint.Uint16.to_int e_shnum
  and int_shstrndx = Stdint.Uint16.to_int e_shstrndx in
  if int_shnum > 0 && int_shstrndx >= int_shnum then
    Error
      (Printf.sprintf "invalid e_shstrndx %d since e_shnum is %d" int_shstrndx
         int_shnum)
  else Ok e_shstrndx

let parse_phnum reader_module elf_class buffer e_phentsize =
  let open Base.Result.Monad_infix in
  let module M = (val reader_module : Obuffer.Reader) in
  M.u16 buffer >>= fun e_phnum ->
  (* It is fine to convert to int here since the width of int is greater than width of Stdint.uint16 *)
  let int_phnum = Stdint.Uint16.to_int e_phnum
  and int_phentsize = Stdint.Uint16.to_int e_phentsize
  and min_phentsize =
    match elf_class with ELFCLASS32 -> 8 * 4 | ELFCLASS64 -> (2 * 4) + (6 * 8)
  in
  if int_phnum > 0 && int_phentsize < min_phentsize then
    Error (Printf.sprintf "invalid e_phentsize: %d" int_phentsize)
  else Ok e_phnum

type elf_header_ty = {
  e_type : elf_type_ty;
  e_machine : machine_ty;
  e_version : elf_version_ty;
  (* The follow three fields are 32-bits long for ELFCLASS32 and 64-bits long
     for ELFCLASS64, but for simplicity, we cast the values to 64 bits *)
  e_entry : Stdint.uint64;
  e_phoff : Stdint.uint64;
  e_shoff : Stdint.uint64;
  (* The remaining fields have the same size between ELFCLASS32 and ELFCLASS64 *)
  e_flags : Stdint.uint32;
  e_ehsize : Stdint.uint16;
  e_phentsize : Stdint.uint16;
  e_phnum : Stdint.uint16;
  e_shentsize : Stdint.uint16;
  e_shnum : Stdint.uint16;
  e_shstrndx : Stdint.uint16;
}

(* Select between BigEndian or LittleEndian reader *)
let fetch_reader_module byte_order =
  match byte_order with
  | BIG_ENDIAN -> (module Obuffer.BigEndianReader : Obuffer.Reader)
  | LITTLE_ENDIAN -> (module Obuffer.LittleEndianReader : Obuffer.Reader)

let parse_header info buffer =
  let reader = fetch_reader_module info.ei_data in
  let module M = (val reader : Obuffer.Reader) in
  (* Skip the padding bytes *)
  M.advance buffer 7;

  let e_class = info.ei_class in
  let open Base.Result.Monad_infix in
  parse_type reader buffer >>= fun e_type ->
  parse_machine reader buffer >>= fun e_machine ->
  parse_version reader buffer >>= fun e_version ->
  parse_header_field reader e_class buffer >>= fun e_entry ->
  parse_header_field reader e_class buffer >>= fun e_phoff ->
  parse_header_field reader e_class buffer >>= fun e_shoff ->
  M.u32 buffer >>= fun e_flags ->
  M.u16 buffer >>= fun e_ehsize ->
  M.u16 buffer >>= fun e_phentsize ->
  parse_phnum reader e_class buffer e_phentsize >>= fun e_phnum ->
  M.u16 buffer >>= fun e_shentsize ->
  parse_shnum reader buffer e_class e_shoff e_shentsize >>= fun e_shnum ->
  parse_shstrndx reader buffer e_shnum >>= fun e_shstrndx ->
  if e_version = info.ei_version then
    Ok
      {
        e_type;
        e_machine;
        e_version;
        e_entry;
        e_phoff;
        e_shoff;
        e_flags;
        e_ehsize;
        e_phentsize;
        e_phnum;
        e_shentsize;
        e_shnum;
        e_shstrndx;
      }
  else Error "ELF version mismatch"

let validate_magic_number buffer =
  let open Base.Result.Monad_infix in
  Obuffer.PlatformAgnosticReader.fixed_length_string buffer 4 >>= fun value ->
  match value with
  | "\x7FELF" -> Ok buffer
  | _ ->
      let hexes = Obuffer.fmt_string_as_hex_bytes value in
      Error (Printf.sprintf "bad magic number: %s" hexes)

let read path =
  try
    let fd = Unix.openfile path [ Unix.O_RDONLY ] 0 in
    let len = Unix.lseek fd 0 Unix.SEEK_END in
    let byte_array =
      Bigarray.array1_of_genarray
        (Unix.map_file fd Bigarray.int8_unsigned Bigarray.c_layout false
           [| len |])
    in
    Unix.close fd;
    validate_magic_number { byte_array; index = 0 }
  with Unix.Unix_error (err_code, fn_name, arg) ->
    let err_description = Unix.error_message err_code in
    Error (Printf.sprintf "%s: %s %s" fn_name arg err_description)

type phdr_type_ty =
  | PT_NULL
  | PT_LOAD
  | PT_DYNAMIC
  | PT_INTERP
  | PT_NOTE
  | PT_SHLIB
  | PT_PHDR
  | PT_PROC

type phdr_ty = { p_type : phdr_type_ty }

let parse_phdr_type reader buffer =
  let module M = (val reader : Obuffer.Reader) in
  let open Base.Result.Monad_infix in
  M.u32 buffer >>= fun value ->
  match Stdint.Uint32.to_int value with
  | 0 -> Ok PT_NULL
  | 1 -> Ok PT_LOAD
  | 2 -> Ok PT_DYNAMIC
  | 3 -> Ok PT_INTERP
  | 4 -> Ok PT_NOTE
  | 5 -> Ok PT_SHLIB
  | 6 -> Ok PT_PHDR
  | x ->
      if x >= 0x70000000 && x <= 0x7fffffff then Ok PT_PROC
      else Error (Printf.sprintf "unknown program header type: %04x" x)

let parse_phdrs info header buffer idx =
  let reader = fetch_reader_module info.ei_data in
  let module M = (val reader : Obuffer.Reader) in
  let index = Stdint.Uint64.of_int idx in
  let phentsize = Stdint.Uint16.to_uint64 header.e_phentsize in
  let mul = Stdint.Uint64.( * ) index phentsize in
  let offset = Stdint.Uint64.( + ) header.e_phoff mul in
  (* We convert the offset from uint64 to int, since the underlying BigArray
     operates on int values *)
  Obuffer.PlatformAgnosticReader.seek buffer (Stdint.Uint64.to_int offset);
  let open Base.Result.Monad_infix in
  parse_phdr_type reader buffer >>= fun p_type -> Ok { p_type }

(* XXX: Can this be replaced with a tail-recursive library function? *)
let rec list_init n f =
  if n = 0 then Ok []
  else
    match (f (n - 1), list_init (n - 1) f) with
    | Ok v, Ok l -> Ok (v :: l)
    | _, Error e -> Error e
    | Error e, _ -> Error e

let new_file filepath =
  let open Base.Result.Monad_infix in
  read filepath >>= fun buffer ->
  parse_info buffer >>= fun info ->
  parse_header info buffer >>= fun header ->
  let header_count = Stdint.Uint16.to_int header.e_phnum in
  list_init header_count (parse_phdrs info header buffer) >>= fun phdrs ->
  Ok (phdrs, header)
