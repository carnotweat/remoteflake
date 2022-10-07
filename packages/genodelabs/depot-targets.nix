# This file contains overrides necessary to build some Make and Depot targets.
# Many targets can be built with the default attributes, and are not listed here.
# However, any package listed here with empty overrides ({ }) will be added to
# the package attributes of this flake.

{ buildPackages, genodePackages, ports }:

let
  self = genodePackages;

  includeDir = pkg: buildPackages.lib.getDev pkg + "/include";

  hostLibcInc = includeDir buildPackages.glibc;
  # TODO: does this need to be glibc?

in {
  acpi_drv = { };
  acpica = { };
  ahci_drv.patches = [ ./patches/config-update.patch ];
  backdrop = { depotInputs = with self; [ libpng ]; };
  bash-minimal = {
    enableParallelBuilding = false;
    nativeBuildInputs = with buildPackages; [ autoconf ];
    portInputs = with ports; [ bash libc ];
    postInstall = ''
      find depot/genodelabs/bin/ -name '*.tar' -exec tar xf {} -C $out \;
      rm "''${!outputBin}/bin/bashbug"
    '';
  };
  binutils_x86 = { };
  block_cache = { };
  block_tester = { };
  boot_fb_drv.patches = [ ./patches/boot_fb_drv.patch ];
  bsd_audio_drv.portInputs = with ports; [ dde_bsd ];
  cached_fs_rom.patches = [ ./patches/cached_fs_rom.patch ];
  chroot = { };
  clipboard = { };
  coreutils-minimal = {
    enableParallelBuilding = false;
    depotInputs = with self; [ libc ];
    portInputs = with ports; [ coreutils ];
    postInstall = ''
      find depot/genodelabs/bin/ -name '*.tar' -exec tar xf {} -C $out \;
    '';
  };
  cpu_burner = { };
  cpu_load_display = { };
  curl = {
    depotInputs = with self; [ libcrypto libssh libssl zlib ];
    portInputs = with ports; [ curl ];
  };
  decorator = { };
  demo = { };
  depot_deploy = { };
  depot_download_manager = { };
  depot_query = { };
  driver_manager = { };
  drm = { };
  dummy = { };
  dynamic_rom = { };
  e2fsprogs = { };
  e2fsprogs-minimal = { };
  event_filter.patches = [ ./patches/event_filter.patch ];
  exec_terminal = { };
  expat = { };
  extract = { };
  fb_sdl = with buildPackages; {
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ SDL ];
    HOST_INC_DIR = [ hostLibcInc (includeDir SDL) ];
  };
  fec_nic_drv = { };
  fetchurl = { };
  file_terminal = { };
  findutils = { };
  freetype = { };
  fs_log = { };
  fs_query = { };
  fs_report = { };
  fs_rom = { };
  fs_tool = { };
  fs_utils = { };
  gcc_x86 = { };
  gcov = { };
  global_keys_handler = { };
  gmp = { };
  gnumake = { };
  gpt_write.portInputs = with ports; [ jitterentropy ];
  grep = { };
  gui_fader = { };
  gui_fb.patches = [ ./patches/gui_fb.patch ];
  icu = { };
  imx53_qsb_drivers = { };
  imx8_fb_drv = { };
  imx8q_evk_drivers = { };
  init = { };
  input_event_bridge = { };
  intel_fb_drv = {
    BOARD = "pc";
    portInputs = with ports; [ dde_linux ];
  };
  ipxe_nic_drv.portInputs = with ports; [ dde_ipxe ];
  jbig2dec = { };
  jitter_sponge = {
    portInputs = with ports; [ jitterentropy xkcp ];
    preConfigure = "cp -r ${self.worldSources} repos/world";
  };
  jpeg = { };
  lan9118_nic_drv = { };
  libarchive = { };
  libc = {
    depotInputs = with self; [ vfs ];
    portInputs = with ports; [ libc ];
  };
  libcrypto = {
    depotInputs = with self; [ libc ];
    portInputs = with ports; [ openssl ];
  };
  libiconv = {
    depotInputs = with self; [ libc ];
    portInputs = with ports; [ libiconv ];
  };
  liblzma = { };
  libpng = {
    depotInputs = with self; [ zlib ];
    portInputs = with ports; [ libpng ];
  };
  libqgenodeviewwidget = { };
  libqpluginwidget = { };
  libsparkcrypto = { };
  libssh = {
    depotInputs = with self; [ libcrypto zlib ];
    portInputs = with ports; [ libssh ];
  };
  libssl = {
    depotInputs = with self; [ libcrypto ];
    portInputs = with ports; [ openssl ];
  };
  lighttpd = { };
  linux_nic_drv.HOST_INC_DIR = [ hostLibcInc ];
  linux_rtc_drv = { };
  loader = { };
  log_core = { };
  log_terminal = { };
  lx_block.HOST_INC_DIR = [ hostLibcInc ];
  lx_fs = { };
  menu_view = { };
  mesa = { };
  mixer = { };
  mixer_gui_qt = { };
  mpc = { };
  mpfr = { };
  mupdf = { };
  nano3d = { };
  ncurses = {
    depotInputs = with self; [ libc ];
    portInputs = with ports; [ ncurses ];
  };
  nic_bridge = { };
  nic_loopback = { };
  nic_router = { };
  nit_focus = { };
  nitpicker.patches = [ ./patches/nitpicker.patch ];
  nvme_drv = { };
  openjpeg = { };
  part_block.patches = [ ./patches/config-update.patch ];
  pbxa9_drivers = { };
  pcre = { };
  pcre16 = { };
  pdf_view = { };
  platform_drv = { }; # .patches = [ ./patches/platform_drv.patch ];
  posix.depotInputs = with self; [ libc ];
  ps2_drv = { };
  qt5_base = { };
  qt5_calculatorform = { };
  qt5_component = { };
  qt5_declarative = { };
  qt5_launchpad = { };
  qt5_openglwindow = { };
  qt5_quickcontrols = { };
  qt5_quickcontrols2 = { };
  qt5_samegame = { };
  qt5_svg = { };
  qt5_testqstring = { };
  qt5_tetrix = { };
  qt5_textedit = { };
  qt5_virtualkeyboard = { };
  qt5_virtualkeyboard_example = { };
  report_rom = { };
  rom_filter = { };
  rom_logger = { };
  rom_reporter = { };
  rom_to_file = { };
  rpi_fb_drv = { };
  rtc_drv = { };
  rump = {
    portInputs = with ports; [ dde_rump ];
    buildInputs = with buildPackages; [ zlib ];
    patches = [ ./patches/rump-libs.patch ];
  };
  sandbox = { };
  sanitizer = { };
  sculpt_manager = { };
  sed = { };
  seoul.portInputs = with ports; [ libc seoul ];
  sequence = { };
  spark = { };
  ssh_terminal = { depotInputs = with self; [ libssh ]; };
  stdcxx = {
    depotInputs = with self; [ libc ];
    portInputs = with ports; [ stdcxx ];
  };
  stdin2out = { };
  system_rtc = { };
  tar = { };
  tclsh = { };
  terminal.depotInputs = with self; [ vfs ];
  terminal_crosslink = { };
  terminal_log.patches = [ ./patches/terminal_log.patch ];
  test-block = { };
  test-bomb = { };
  test-clipboard = { };
  test-ds_ownership = { };
  test-dynamic_config = { };
  test-entrypoint = { };
  test-expat = { };
  test-fault_detection = { };
  test-fs_packet = { };
  test-fs_report = { };
  test-immutable_rom = { };
  test-init = { };
  test-init_loop = { };
  test-ldso = { };
  test-libc = { };
  test-libc_connect = { };
  test-libc_counter = { };
  test-libc_execve = { };
  test-libc_fork = { };
  test-libc_getenv = { };
  test-libc_pipe = { };
  test-libc_vfs = { };
  test-libc_vfs_block = { };
  test-log.patches = [ ./patches/test-log.patch ];
  test-magic_ring_buffer = { };
  test-mmio = { };
  test-netty = { };
  test-new_delete = { };
  test-nic_loopback = { };
  test-pthread = { };
  test-qpluginwidget = { };
  test-qt_core = { };
  test-qt_quick = { };
  test-ram_fs_chunk = { };
  test-reconstructible = { };
  test-registry = { };
  test-report_rom = { };
  test-resource_request = { };
  test-resource_yield = { };
  test-rm_fault = { };
  test-rm_nested = { };
  test-rm_stress = { };
  test-rtc = { };
  test-sanitizer = { };
  test-segfault = { };
  test-signal.patches = [ ./patches/test-signal.patch ];
  test-slab = { };
  test-spark = { };
  test-spark_exception = { };
  test-spark_secondary_stack = { };
  test-stack_smash = { };
  test-stdcxx = { };
  test-synced_interface = { };
  test-tcp = { };
  test-terminal_crosslink = { };
  test-tiled_wm = { };
  test-timer = { };
  test-tls = { };
  test-token = { };
  test-trace = { };
  test-trace_logger = { };
  test-utf8 = { };
  test-vfs_stress = { };
  test-weak_ptr = { };
  test-xml_generator = { };
  test-xml_node = { };
  text_area = { };
  themed_decorator = { };
  top = { };
  trace_logger = { };
  trace_policy = { };
  trace_subject_reporter = { };
  usb_block_drv = { };
  usb_drv = {
    portInputs = with ports; [ dde_linux ];
    meta.broken = builtins.trace "usb_drv is broken! Use usb_host_drv!" false;
  };
  usb_hid_drv.portInputs = with ports; [ dde_linux ];
  usb_host_drv = {
    patches = [ ./patches/usb_host_drv.patch ];
    portInputs = with ports; [ dde_linux ];
  };
  verify = { };
  vesa_drv = {
    patches = [ ./patches/vesa_drv.patch ];
    portInputs = with ports; [ libc x86emu ];
  };
  vfs = { };
  vfs_audit = { };
  vfs_block = { };
  vfs_fatfs = { };
  vfs_import.patches = [ ./patches/vfs_import.patch ];
  vfs_jitterentropy.portInputs = with ports; [ jitterentropy libc ];
  vfs_lwip = {
    patches = [ ./patches/lwip.patch ];
    portInputs = with ports; [ lwip ];
  };
  vfs_lxip.portInputs = with ports; [ dde_linux ];
  vfs_oss = { };
  vfs_pipe = { };
  vfs_trace = { };
  vfs_ttf = {
    depotInputs = with self; [ libc ];
    portInputs = with ports; [ stb ];
  };
  vim = { };
  vim-minimal = { };
  virtdev_rom = { };
  virtio_nic_drv = {
    patches = [ ./patches/virtio_net.patch ];
    postInstall = "mv $out/bin/virtio_*_nic $out/bin/$pname";
  };
  which = { };
  wifi_drv = {
    depotInputs = with self; [ libcrypto ];
    portInputs = with ports; [ dde_linux ];
  };
  window_layouter = { };
  wm = { };
  zlib = {
    depotInputs = with self; [ libc ];
    portInputs = with ports; [ zlib ];
  };
  zynq_nic_drv = { };
}
