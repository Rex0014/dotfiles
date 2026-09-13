local vars = require("variables")
local fn   = require("utils.functions")

hl.on("hyprland.start", function()
    -- Keyring and auth
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Auto delete trash 30 days old
    hl.exec_cmd("trash-empty 30")

    -- Cursors
    hl.exec_cmd("hyprctl setcursor " .. vars.cursorTheme .. " " .. vars.cursorSize)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme " .. vars.cursorTheme)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size " .. vars.cursorSize)

    -- Location provider and night light
    hl.exec_cmd("/usr/lib/geoclue-2.0/demos/agent")
    hl.exec_cmd("sleep 1 && gammastep")

    -- Forward bluetooth media commands to MPRIS
    hl.exec_cmd("mpris-proxy")

    -- Start shell
    hl.exec_cmd("caelestia shell -d")

    -- Start wallpaper picker
    hl.exec_cmd("qs -p /home/rex/.config/quickshell/wallpaper -d")
end)

-- Resizer listeners
local function apply_resizer_rules(win)
    local float_center = {
        hl.dsp.window.float({ action = "on", window = win }),
        hl.dsp.window.center({ window = win }),
    }
    local pip_actions = fn.move_actions(win) or {}

    -- Bitwarden
    fn.resizer(win, "Bitwarden", 20, 54, float_center, true, "class")                                       -- Native app
    fn.resizer(win, "^Extension: %(Bitwarden Password Manager%) %- Bitwarden", 20, 54, float_center, false) -- Firefox
    fn.resizer(win, "nngceckbapebfimnlniiiahkandclblb", 20, 54, float_center, true, "class")                -- Chromium

    -- Picture in picture
    fn.resizer(win, "Picture[- ]in[- ][Pp]icture", 0, 0, pip_actions, false)
end

hl.on("window.title", apply_resizer_rules)
hl.on("window.open", apply_resizer_rules)

-- Game window workspace persistence
--
-- Games (Steam/Lutris via steam_app_*, gamescope) take a few seconds to open
-- their window, and by then focus has usually moved to whatever workspace
-- we're working in. Instead of spawning there, remember the workspace that
-- was focused when a game launcher last became active (i.e. the workspace we
-- were on when we clicked "play") and silently move the game there once its
-- window appears, without stealing focus from wherever we've moved on to.
local game_launcher_classes = {
    "steam",                        -- Steam client
    "net.lutris.Lutris",            -- Lutris
    "com.usebottles.bottles",       -- Bottles
    "com.heroicgameslauncher.hgl",  -- Heroic
}

local function is_game_launcher(class)
    if not class then return false end
    for _, launcher_class in ipairs(game_launcher_classes) do
        if class == launcher_class then return true end
    end
    return false
end

local function is_game_window(class)
    return class ~= nil and (class:match("^steam_app_%d+$") ~= nil or class == "steam_app_default" or class == "gamescope")
end

local pending_launch_workspace = nil
local pending_launch_time = nil
local LAUNCH_TIMEOUT_SECS = 180 -- how long a remembered workspace stays valid

hl.on("window.active", function(win)
    if win and is_game_launcher(win.class) then
        local ws = hl.get_active_workspace()
        if ws then
            pending_launch_workspace = ws.id
            pending_launch_time = os.time()
        end
    end
end)

-- Deliberately NOT cleared after one match: many Steam/Proton games (e.g.
-- World of Tanks' Game Center) open a launcher/updater window first and the
-- real game window later, both sharing the same steam_app_<id> class. Clearing
-- on the first match would leave the actual game window unmoved. It instead
-- expires after LAUNCH_TIMEOUT_SECS so a stale workspace can't hijack an
-- unrelated later launch.
local function move_game_to_launch_workspace(win)
    if pending_launch_time and os.time() - pending_launch_time > LAUNCH_TIMEOUT_SECS then
        pending_launch_workspace = nil
        pending_launch_time = nil
    end

    if win and pending_launch_workspace and is_game_window(win.class) then
        hl.dispatch(hl.dsp.window.move({ window = win, workspace = pending_launch_workspace, follow = false }))
    end
end

hl.on("window.open", move_game_to_launch_workspace)
hl.on("window.class", move_game_to_launch_workspace) -- some games set their class after opening
