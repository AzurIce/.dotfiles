import XMonad

import XMonad.Util.SpawnOnce

import XMonad.Hooks.EwmhDesktops

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP

myStartupHook = do
  spawnOnce "feh --bg-fill /home/azurice/files/坚果云Sync/wallpapers/wallpaper-lumine.jpg"
  spawnOnce "picom"
  spawnOnce "xmobar"

-- reload = do
--   spawn "xmonad --recompile"
--   spawn "xmonad --restart"

-- myStatusBar = statusBarProp "xmobar" (pure xmobarPP)

myWorkSpaces = [ " dev ", " www ", " doc ", " 4 ", " 5 ", " 6 ", " 7 ", " 8 ", " sys "]

myConfig = def {
        normalBorderColor = "#222222",
        focusedBorderColor = "#36A8FF",
        terminal = "alacritty",
        workspaces = myWorkSpaces,
        -- modMask = mod4Mask,
        startupHook = myStartupHook
    }

main :: IO ()
main = xmonad $ ewmhFullscreen $ ewmh $ xmobarProp $ myConfig
--main = xmonad $ myConfig

