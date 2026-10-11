{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  patchelf,
  ffmpeg-headless,
  unzip,
  zip,
  p7zip,
  withFFmpeg ? true,
  ffmpeg ? ffmpeg-headless,
  extraPackages ? [
    unzip
    zip
    p7zip
  ],
}:

let
  sources = lib.importJSON ./sources.json;
  system = stdenv.hostPlatform.system;
  arch = stdenv.hostPlatform.parsed.cpu.name;
in
stdenv.mkDerivation {
  pname = "tfm";
  inherit (sources) version;

  src = fetchurl {
    url = "https://github.com/clarkarch/tfm-tui/releases/download/v${sources.version}/tfm-${arch}-linux.gz";
    hash = sources.hashes.${system} or (throw "tfm: unsupported system ${system}");
  };

  nativeBuildInputs = [
    makeWrapper
    patchelf
  ];

  dontUnpack = true;
  # The app is a payload in the ELF .bun section; strip would drop it.
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/libexec $out/bin
    gunzip -c $src > $out/libexec/tfm
    chmod +x $out/libexec/tfm
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/libexec/tfm
    makeWrapper $out/libexec/tfm $out/bin/tfm \
      ${lib.optionalString withFFmpeg "--set-default TFM_FFMPEG ${lib.getExe ffmpeg}"} \
      --suffix PATH : ${lib.makeBinPath extraPackages}
    runHook postInstall
  '';

  meta = {
    description = "Mouse-first terminal file manager";
    homepage = "https://github.com/clarkarch/tfm-tui";
    license = lib.licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "tfm";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
