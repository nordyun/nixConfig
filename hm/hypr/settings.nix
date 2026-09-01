{ osConfig, ... }:
{
  wayland.windowManager.hyprland.settings = {
    input = {
      kb_layout = osConfig.hostVars.keyboardLayout;
      kb_options = [
        "grp:alt_caps_toggle"
        "caps:super"
      ];
      numlock_by_default = true;
      repeat_delay = 300;
      follow_mouse = 1;
      sensitivity = 0;
      touchpad = {
        natural_scroll = true;
        disable_while_typing = true;
        scroll_factor = 0.8;
      };
    };

    general = {
      "$modifier" = "SUPER";
      layout = "dwindle";
      gaps_in = 6;
      gaps_out = 8;
      border_size = 2;
      resize_on_border = true;
      "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
      "col.inactive_border" = "rgba(595959aa)";
    };

    misc = {
      layers_hog_keyboard_focus = true;
      initial_workspace_tracking = 0;
      mouse_move_enables_dpms = false;
      key_press_enables_dpms = false;
    };

    dwindle = {
      pseudotile = true;
      preserve_split = true;
    };

    plugin = {
      hyprtasking = {
        layout = "grid";
        gap_size = 5;
        bg_color = "0xff111111";
        grid = {
          rows = 3;
          cols = 3;
        };
      };
    };
  };
}
