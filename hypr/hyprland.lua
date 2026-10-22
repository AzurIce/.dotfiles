-- Migrated from hyprland.conf for Hyprland 0.55+ (Lua config)
-- Original hyprland.conf is kept as a backup.

------------------
---- VARIABLES ----
------------------

local mainMod = "SUPER"

------------------
---- MONITORS ----
------------------

-- Use desc: prefix with output description (without trailing port name) for stability.

local philips = "desc:Philips Consumer Electronics Company PHL 345M1CR UK02107000363"
local dell    = "desc:Dell Inc. DELL P2314H HMJ1V739CH9B"
local ktc     = "desc:Shenzhen KTC Technology Group H24T7 0x00000001"

hl.monitor({
  output   = philips,
  mode     = "3440x1440@144",
  position = "0x0",
  scale    = 1.07,
})

hl.monitor({
  output   = dell,
  mode     = "1920x1080@60",
  position = "600x-900",
  scale    = 1.2,
})

hl.monitor({
  output = ktc,
  mode = "2560x1440@144.00Hz",
  position = "-1152x-200",
  scale = 1.25,
  transform = 1,
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
  -- 预启动 scratch 终端，class 需与 kitty-scratch window rule 匹配
  hl.exec_cmd("kitty --class kitty-scratch")
  -- hl.exec_cmd("hyprpaper")
  -- hl.exec_cmd("awww-daemon")
  hl.exec_cmd("fcitx5")
  hl.exec_cmd("clash-verge")
  -- hl.exec_cmd("syncthingtray --wait")
  hl.exec_cmd(
  "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_IM_MODULE XMODIFIERS SDL_IM_MODULE")
  -- XWayland 按显示器 ID 排序主屏，会把 DP-3(1080p) 当主屏；显式指定带鱼屏为 X11 主屏，游戏才能枚举到 3440x1440
  hl.exec_cmd("sh -c 'sleep 2 && DISPLAY=:0 xrandr --output DP-4 --primary'")

  applyWorkspaceLabels()
end)

-- 工作区显示标签向左平移：ws1 显示 "~"，ws2..10 显示 1..9。
-- id 保持 1..10 不变（rules/窗口规则/脚本都按 id 工作）；bar 显示 name 时生效。
-- 1..10 均有 persistent rule，workspace 不会被销毁，rename 一次即可保持。
local function applyWorkspaceLabels()
  for i = 1, 10 do
    local label =
        (i == 1) and "~" or
        (i == 6) and "G" or
        (i == 7) and "Z" or
        (i == 8) and "X" or
        (i == 9) and "C" or
        (i == 10) and "0" or tostring(i - 1)
    hl.dispatch(hl.dsp.workspace.rename({ workspace = i, name = label }))
  end
end

-- reload 后 workspace name 会重置为 id，重新应用标签
hl.on("config.reloaded", applyWorkspaceLabels)


-- 每个普通 workspace 都有一个对应的浮动层 special:float-<id>：
--   SUPER + S         显示/隐藏当前 workspace 的浮动层
--   SUPER + SHIFT + S 将当前窗口移入浮动层，或移回对应的普通 workspace
-- follow=true 移入后跟随过去（浮动层）；false 直接藏进去（scratch）
local function stashIntoSpecial(window, name, follow)
  hl.dispatch(hl.dsp.window.float({ action = "on", window = window }))
  hl.dispatch(hl.dsp.window.move({ workspace = name, follow = follow, window = window }))
end

hl.bind(mainMod .. " + S", function()
  local ws = hl.get_active_workspace()
  if ws and ws.id and not ws.special then
    hl.dispatch(hl.dsp.workspace.toggle_special("float-" .. ws.id))
  end
end)

hl.bind(mainMod .. " + SHIFT + S", function()
  local window = hl.get_active_window()
  local ws = window and window.workspace
  if not ws then
    return
  end

  -- 在浮动层中：恢复平铺，移回层名中记录的普通 workspace
  local homeId = ws.special and ws.addressable_name:match("^special:float%-(%d+)$")
  if homeId then
    hl.dispatch(hl.dsp.window.float({ action = "off", window = window }))
    hl.dispatch(hl.dsp.window.move({ workspace = tonumber(homeId), follow = true, window = window }))
  elseif not ws.special then
    -- 不接管 scratch、wine-helper 等其他 special workspace 中的窗口
    stashIntoSpecial(window, "special:float-" .. ws.id, true)
  end
end)

-- 切换普通 workspace 时收起之前显示的浮动层，保持二者一一对应
hl.on("workspace.active", function(workspace)
  if not workspace or workspace.special or not workspace.id or workspace.monitor ~= hl.get_active_monitor() then
    return
  end

  local special = hl.get_active_special_workspace(workspace.monitor)
  local shown = special and special.addressable_name:match("^special:(float%-%d+)$")
  if shown and shown ~= "float-" .. workspace.id then
    hl.dispatch(hl.dsp.workspace.toggle_special(shown))
  end
end)

hl.bind(mainMod .. " + Space", hl.dsp.workspace.toggle_special("scratch"))

-- 把当前窗口丢进 scratch
hl.bind(mainMod .. " + SHIFT + Space", function()
  local window = hl.get_active_window()
  if window then
    stashIntoSpecial(window, "special:scratch", false)
  end
end)

local function bindWorkspace(i, key)
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- 键位向左平移：SUPER+` → workspace 1，SUPER+1 → workspace 2，…，SUPER+9 → workspace 10
-- 与 hyprland.start 中的 renameworkspace 对应：bar 上显示为 ~ 1 2 … 9
-- keys:
-- ~ 1 2 3 4
-- g
-- z x c
-- 0
local workspaceKeys = { "grave", "1", "2", "3", "4", "g", "z", "x", "c", "0" }
for i, key in ipairs(workspaceKeys) do
  bindWorkspace(i, key)
end

-------------------------
---- WORKSPACE RULES ----
-------------------------

for i = 1, 9 do
  hl.workspace_rule({
    workspace  = tostring(i),
    monitor    = philips,
    default    = (i == 1),
    persistent = true,     -- Noctalia 工作区指示器：空工作区也保持可见
  })
end

hl.workspace_rule({
  workspace  = "10",
  monitor    = dell,
  default    = true,
  persistent = true,
  layout     = "scrolling",
  gaps_out = 16,
})

hl.workspace_rule({
  workspace  = "11",
  monitor    = ktc,
  default   = true,
  persistent = true,
  -- gaps_in = 8,
  gaps_out = 16,
  -- gaps_out = 32,
})

-----------------
---- INPUT ----
-----------------

hl.config({
  input = {
    kb_layout      = "us",
    kb_variant     = "",
    kb_model       = "",
    kb_options     = "",
    kb_rules       = "",

    follow_mouse   = 1,

    touchpad       = {
      natural_scroll = true,
    },

    sensitivity    = 0,
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
    gaps_in     = 8,
    gaps_out    = 32,

    border_size = 3,

    col         = {
      active_border   = "rgba(50bbddee)",
      inactive_border = "rgba(595959aa)",
    },

    layout      = "dwindle",
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

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "default", style = "slidevert" })
hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })


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
    workspace_swipe_distance           = 250,
    workspace_swipe_invert             = true,
    workspace_swipe_min_speed_to_force = 15,
    workspace_swipe_cancel_ratio       = 0.5,
    workspace_swipe_create_new         = false,
  }
})

--------------
---- MISC ----
--------------

hl.config({
  misc = {
    disable_hyprland_logo     = true,
    always_follow_on_dnd      = true,
    layers_hog_keyboard_focus = true,
    animate_manual_resizes    = false,
    enable_swallow            = true,
    swallow_regex             = "",
    focus_on_activate         = true,
  }
})

---------------------
---- KEYBINDINGS ----
---------------------

-- Apps / session
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT + Space", hl.dsp.exec_cmd("rofi -show drun"))

hl.bind(mainMod .. "+ SHIFT + V",
  hl.dsp.exec_cmd("clipvault list | rofi -dmenu -display-columns 2 | clipvault get | wl-copy"))
-- hl.bind("CTRL + SHIFT + S",     hl.dsp.exec_cmd("wayshot - -g | satty --filename - --fullscreen"))
hl.bind("CTRL + SHIFT + S", hl.dsp.exec_cmd("wayshot - -g | wl-copy"))
hl.bind("CTRL + SHIFT + A", hl.dsp.exec_cmd("wl-paste | satty --filename -"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

-- Groups
hl.bind(mainMod .. " + T", hl.dsp.group.toggle())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + Tab", hl.dsp.group.next())
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.group.prev())

-- Move focus
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))

-- Workspaces
-- hl.bind(mainMod .. " + bracketleft",  hl.dsp.focus({ workspace = "-1" }))
-- hl.bind(mainMod .. " + bracketright", hl.dsp.focus({ workspace = "+1" }))
-- hl.bind(mainMod .. " + SHIFT + bracketleft",  hl.dsp.window.move({ workspace = "-1" }))
-- hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }))

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
hl.bind(mainMod .. " + mouse_up", onlyOnScrolling(hl.dsp.layout("move -col")))
-- hl.bind(mainMod .. " + SHIFT + mouse_down", onlyOnScrolling(hl.dsp.layout("colresize -0.25")))
-- hl.bind(mainMod .. " + SHIFT + mouse_up",   onlyOnScrolling(hl.dsp.layout("colresize +0.25")))

-- Mouse binds
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
hl.bind("Print", hl.dsp.exec_cmd("grimblast copy area"))


----------------------
---- WINDOW RULES ----
----------------------

hl.window_rule({
  name  = "fcitx-float",
  match = { class = "org.fcitx." },
  float = true,
})

hl.window_rule({
  name      = "clash-verge-float",
  match     = { class = "clash-verge" },
  float     = true,
  workspace = "10",
})

hl.window_rule({
  name            = "steam-app",
  match           = { class = "steam_app_" },
  confine_pointer = true
})

-- Steam 非商店启动器（终末地 / 诡秘之主）：浮动显示，避免 tiling 强制 resize
-- 与启动器自绘 UI 的尺寸请求形成正反馈（一拖就膨胀）。
-- suppress_event 直接忽略 wine 客户端反改窗口大小的 X11 请求，打断膨胀循环；
-- max_size 兜底。注意：由启动器拉起、继承同一 steam_app_ class 的游戏本体
-- 也会浮动打开，进游戏后手动全屏即可。
hl.window_rule({
  name           = "steam-launcher-float",
  match          = { class = "steam_app_(2401871547|2890382219)" },
  float          = true,
  suppress_event = "x11configurerequest",
  max_size       = { 1920, 1200 },
})

-- wine 启动器的隐藏辅助窗口（标题为空的空白小窗）：藏进 special workspace。
-- title 用 negative 匹配（空标题无法被 ^$ 匹配到——实现上直接跳过）。
hl.window_rule({
  name      = "steam-launcher-helper-hide",
  match     = { class = "steam_app_(2401871547|2890382219)", title = "negative:.+" },
  workspace = "special:wine-helper silent",
})

-- Scratch 终端：藏在 special:scratch，win+Space 切换显示/收回
hl.window_rule({
  name      = "kitty-scratch",
  match     = { class = "kitty-scratch" },
  workspace = "special:scratch silent",
  float     = true,
  size      = { 2400, 1000 },
})

-- gamescope (终末地 MaaEnd 自动化)：固定 1920x1080 浮窗，防止平铺改大小破坏画面识别
hl.window_rule({
  name  = "gamescope",
  match = { class = "gamescope" },
  float = true,
  size  = { 1920, 1080 },
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
  name         = "noctalia",
  match        = {
    namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
  },
  no_anim      = true,
  ignore_alpha = 0.5,
  blur         = true,
  blur_popups  = true,
})

-- For Noctalia Color templates
require("noctalia").apply_theme()
