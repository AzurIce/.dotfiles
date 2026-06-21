-- Migrated from hyprland.conf for Hyprland 0.55+ (Lua config)
-- Original hyprland.conf is kept as a backup.

------------------
---- MONITORS ----
------------------

-- Use desc: prefix with output description (without trailing port name) for stability.

hl.monitor({
    output   = "desc:Philips Consumer Electronics Company PHL 345M1CR UK02107000363",
    mode     = "3440x1440@144",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output   = "desc:Dell Inc. DELL P2314H HMJ1V739CH9B",
    mode     = "1920x1080@60",
    position = "760x-1080",
    scale    = 1,
})


---------------------
---- ENVIRONMENT ----
---------------------

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("no_proxy", "localhost,127.0.0.1")


------------------
---- AUTOSTART ----
------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("eww open topbar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("fcitx5")
    hl.exec_cmd("clash-verge")
    hl.exec_cmd("syncthingtray --wait")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
end)


-----------------
---- INPUT ----
-----------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        touchpad = {
            natural_scroll = true,
        },

        sensitivity = 0,
        force_no_accel = true,
    }
})


------------------
---- GENERAL ----
------------------

hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 5,

        border_size = 3,

        col = {
            active_border   = "rgba(50bbddee)",
            inactive_border = "rgba(595959aa)",
        },

        layout = "dwindle",
    }
})


--------------------
---- DECORATION ----
--------------------

hl.config({
    decoration = {
        rounding = 4,

        blur = {
            enabled           = true,
            size              = 3,
            passes            = 1,
            new_optimizations = true,
        },
    }
})


---------------------
---- ANIMATIONS ----
---------------------

hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

hl.animation({ leaf = "windows",    enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",     enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6,  bezier = "default" })


-----------------
---- LAYOUTS ----
-----------------

hl.config({
    dwindle = {
        preserve_split = false,
    }
})


------------------
---- GESTURES ----
------------------

hl.config({
    gestures = {
        workspace_swipe_distance         = 250,
        workspace_swipe_invert           = true,
        workspace_swipe_min_speed_to_force = 15,
        workspace_swipe_cancel_ratio     = 0.5,
        workspace_swipe_create_new       = false,
    }
})


--------------
---- MISC ----
--------------

hl.config({
    misc = {
        disable_hyprland_logo      = true,
        always_follow_on_dnd       = true,
        layers_hog_keyboard_focus  = true,
        animate_manual_resizes     = false,
        enable_swallow             = true,
        swallow_regex              = "",
        focus_on_activate          = true,
    }
})


------------------
---- VARIABLES ----
------------------

local mainMod = "SUPER"


---------------------
---- KEYBINDINGS ----
---------------------

-- Apps / session
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + M",      hl.dsp.exit())
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT + Space",          hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen())

-- Groups
hl.bind(mainMod .. " + G",           hl.dsp.group.toggle())
hl.bind(mainMod .. " + P",           hl.dsp.window.pseudo())
hl.bind(mainMod .. " + Tab",         hl.dsp.group.next())
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.group.prev())

-- Move focus
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))

-- Workspaces
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + bracketleft",  hl.dsp.focus({ workspace = "-1" }))
hl.bind(mainMod .. " + bracketright", hl.dsp.focus({ workspace = "+1" }))
hl.bind(mainMod .. " + SHIFT + bracketleft",  hl.dsp.window.move({ workspace = "-1" }))
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Mouse binds
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("amixer -q sset Master unmute && amixer -q sset Master 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("amixer -q sset Master unmute && amixer -q sset Master 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("amixer -q sset Master toggle"),                                 { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("light -A 5"),                                                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("light -U 5"),                                                  { locked = true, repeating = true })
hl.bind("Print",                hl.dsp.exec_cmd("grimblast copy area"))


-------------------------
---- WORKSPACE RULES ----
-------------------------

local philips = "desc:Philips Consumer Electronics Company PHL 345M1CR UK02107000363"
local dell    = "desc:Dell Inc. DELL P2314H HMJ1V739CH9B"

for i = 1, 8 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor   = philips,
        default   = (i == 1),
    })
end

hl.workspace_rule({
    workspace = "9",
    monitor   = dell,
    default   = true,
})

hl.workspace_rule({
    workspace = "10",
    monitor   = philips,
    default   = false,
})


----------------------
---- WINDOW RULES ----
----------------------

hl.window_rule({
    name  = "fcitx-float",
    match = { class = "org.fcitx." },
    float = true,
})

hl.window_rule({
    name  = "clash-verge-float",
    match = { class = "clash-verge" },
    float = true,
})
