# Qtile config - minimal dotfile

from libqtile import bar, layout, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
import os
import subprocess

mod = "mod4"
terminal = "kitty"

keys = [
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod, "control"], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    Key([mod, "shift"], "Return", lazy.layout.toggle_split(), desc="Toggle between split and unsplit sides of stack"),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
    Key([mod], "d", lazy.spawn("rofi -show drun"), desc="Spawn rofi"),
    Key([mod], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen"),
    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating"),
    Key([mod], "m", lazy.window.toggle_maximize(), desc="Toggle maximize"),
    Key([mod], "n", lazy.window.toggle_minimize(), desc="Toggle minimize"),
    Key([mod], "Left", lazy.screen.prev_group(), desc="Move to previous group"),
    Key([mod], "Right", lazy.screen.next_group(), desc="Move to next group"),
    Key([mod, "shift"], "Left", lazy.window.togroup(prev_group), desc="Move window to previous group"),
    Key([mod, "shift"], "Right", lazy.window.togroup(next_group), desc="Move window to next group"),
    Key([], "XF86AudioRaiseVolume", lazy.spawn("pamixer -i 5"), desc="Volume up"),
    Key([], "XF86AudioLowerVolume", lazy.spawn("pamixer -u -d 5"), desc="Volume down"),
    Key([], "XF86AudioMute", lazy.spawn("pamixer -t"), desc="Volume mute"),
    Key([], "XF86MonBrightnessUp", lazy.spawn("brightnessctl set +5%"), desc="Brightness up"),
    Key([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl set 5%-"), desc="Brightness down"),
    Key([], "XF86AudioPlay", lazy.spawn("playerctl play-pause"), desc="Play/pause"),
    Key([], "XF86AudioStop", lazy.spawn("playerctl stop"), desc="Stop"),
    Key([], "XF86AudioPrev", lazy.spawn("playerctl previous"), desc="Previous track"),
    Key([], "XF86AudioNext", lazy.spawn("playerctl next"), desc="Next track"),
    Key([], "Print", lazy.spawn("scrot ~/Pictures/screenshots/$(date +%Y%m%d_%H%M%S.png"), desc="Screenshot"),
]

groups = [Group(i) for i in "1234567890"]

for i in groups:
    keys.extend([
        Key([mod], i.name, lazy.group[i.name].toscreen(), desc=f"Switch to group {i.name}"),
        Key([mod, "shift"], i.name, lazy.window.togroup(i.name, switch_group=True), desc=f"Switch to & move focused window to group {i.name}"),
    ])

layouts = [
    layout.Columns(border_focus="#88c0d0", border_normal="#3b4252", border_width=2, margin=5),
    layout.Max(),
    layout.Stack(num_stacks=2),
    layout.Bsp(),
    layout.Matrix(),
    layout.MonadTall(),
    layout.MonadWide(),
    layout.RatioTile(),
    layout.Tile(),
    layout.TreeTab(),
    layout.VerticalTile(),
    layout.Zoomy(),
]

widget_defaults = dict(
    font="monospace",
    fontsize=10,
    padding=3,
)
extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.CurrentLayout(),
                widget.GroupBox(),
                widget.Prompt(),
                widget.WindowName(),
                widget.Chord(
                    chords_colors={
                        "launch": ("#ff0000", "#ffffff"),
                    },
                    name_transform=lambda name: name.upper(),
                ),
                widget.Systray(),
                widget.Clock(format="%Y-%m-%d %H:%M"),
                widget.QuickExit(),
            ],
            24,
            background="#2e3440",
            foreground="#d8dee9",
        ),
    ),
]

mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),
        Match(wm_class="makebranch"),
        Match(wm_class="maketag"),
        Match(wm_class="ssh-askpass"),
        Match(title="branchdialog"),
        Match(title="pinentry"),
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
auto_minimize = True
wl_input_rules = None
wmname = "LG3D"

@hook.subscribe.startup_once
def autostart():
    home = os.path.expanduser("~/.config/qtile/autostart.sh")
    subprocess.Popen([home])
