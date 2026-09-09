{ pkgs, ... }:
{
  # Intel Quick Sync / iGPU video acceleration for Jellyfin.
  # CPU: i5-13500T, UHD 770 (Gen12 / Raptor Lake) - HEVC 8/10-bit, AV1 decode,
  # VP9, H.264, VPP HDR tone-mapping. No discrete GPU for now.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # iHD VAAPI driver
      vpl-gpu-rt # oneVPL runtime - jellyfin-ffmpeg's QSV path
      intel-compute-runtime # OpenCL (OpenCL HDR tone-mapping)
    ];
  };

  environment.variables.LIBVA_DRIVER_NAME = "iHD";

  # services.jellyfin runs as its own system user; needs GPU device access.
  users.users.jellyfin.extraGroups = [
    "video"
    "render"
  ];

  # ECC error logging for the DDR4 ECC UDIMMs (ie31200_edac on W680).
  # Inspect with: ras-mc-ctl --summary  /  ras-mc-ctl --errors
  hardware.rasdaemon.enable = true;
}
