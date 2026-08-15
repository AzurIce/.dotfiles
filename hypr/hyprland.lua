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
    scale    = 1.07,
})

hl.monitor({
    output   = "desc:Dell Inc. DELL P2314H HMJ1V739CH9B",
    mode     = "1920x1080@60",
    position = "auto-center-up",
    scale    = 1.2,
})


---------------------
---- ENVIRONMENT ----
---------------------

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
-- hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("no_proxy", "localhost,127.0.0.1")
hl.env("NIXOS_OZONE_WL", "1")
-- unset on Wayland; Fcitx uses input-method-v2 frontend instead
-- hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")


------------------
---- AUTOSTART ----
------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("wl-paste --watch clipvault store")
    hl.exec_cmd("noctalia")
    -- hl.exec_cmd("hyprpaper")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("fcitx5")
    hl.exec_cmd("clash-verge")
    -- hl.exec_cmd("syncthingtray --wait")
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

-- https://github.com/hyprwm/Hyprland/discussions/13464
hl.config({
    cursor = {
        no_hardware_cursors = 0,
    }
})

-- Render XWayland apps (e.g. Steam) at scale 1 instead of the fractional
-- monitor scale, otherwise their text gets upscaled and looks blurry.
hl.config({
    xwayland = {
        force_zero_scaling = true,
    }
})


------------------
---- GENERAL ----
------------------

hl.config({
    general = {
        gaps_in  = 8,
        gaps_out = 32,

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
hl.bind(mainMod .. "+ SHIFT + V", hl.dsp.exec_cmd("clipvault list | rofi -dmenu -display-columns 2 | clipvault get | wl-copy"))
-- hl.bind("CTRL + SHIFT + S",     hl.dsp.exec_cmd("wayshot - -g | satty --filename - --fullscreen"))
hl.bind("CTRL + SHIFT + S",     hl.dsp.exec_cmd("wayshot - -g | wl-copy"))
hl.bind("CTRL + SHIFT + A",     hl.dsp.exec_cmd("wl-paste | satty --filename -"))
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

-- hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
-- hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

local function onlyOnScrolling(dsp)
    return function()
        local ws = hl.get_active_workspace()
        if ws and ws.tiled_layout == "scrolling" then
            hl.dispatch(dsp)
        end
    end
end

hl.bind(mainMod .. " + mouse_down", onlyOnScrolling(hl.dsp.layout("move +col")))
hl.bind(mainMod .. " + mouse_up",   onlyOnScrolling(hl.dsp.layout("move -col")))
hl.bind(mainMod .. " + SHIFT + mouse_down", onlyOnScrolling(hl.dsp.layout("colresize -0.25")))
hl.bind(mainMod .. " + SHIFT + mouse_up",   onlyOnScrolling(hl.dsp.layout("colresize +0.25")))

-- Mouse binds
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"),     { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"),     { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("noctalia msg volume-mute"),    { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("noctalia msg mic-mute"),  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("light -A 5"),                              { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("light -U 5"),                             { locked = true, repeating = true })
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
        persistent = true, -- Noctalia 工作区指示器：空工作区也保持可见
    })
end

hl.workspace_rule({
    workspace = "9",
    monitor   = dell,
    default   = true,
    persistent = true,
    layout = "scrolling"
})

hl.workspace_rule({
    workspace = "10",
    monitor   = philips,
    default   = false,
    persistent = true,
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
    workspace = "10",
})

hl.window_rule({
    name  = "steam-app",
    match = { class = "steam_app_" },
    confine_pointer = true
})

----------------------
---- NOCTALIA ----
----------------------

-- Noctalia 设置窗口浮窗显示
hl.window_rule({
    match = { class = "dev.noctalia.Noctalia" },
    float = true,
    size  = { 1080, 920 },
})

-- 给 Noctalia 的 bar/面板/通知/OSD 等 surface 开启模糊，
-- 并关闭 Hyprland 自带的 layer 动画以免与 Noctalia 动画冲突
hl.layer_rule({
    name = "noctalia",
    match = {
        namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
    },
    no_anim      = true,
    ignore_alpha = 0.5,
    blur         = true,
    blur_popups  = true,
})
