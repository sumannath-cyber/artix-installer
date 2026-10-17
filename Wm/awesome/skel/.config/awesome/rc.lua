-- awesome config - minimal dotfile

local awful = require("awful")
local beautiful = require("beautiful")
local menubar = require("menubar")
local gears = require("gears")

beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

terminal = "kitty"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor
modkey = "Mod4"

awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    awful.layout.suit.max,
}

myawesomemenu = {
    { "hotkeys", function() return false, hotkeys_popup.show_help end },
    { "manual", terminal .. " -e man awesome" },
    { "edit config", editor_cmd .. " " .. awesome.conffile },
    { "restart", awesome.restart },
    { "quit", function() awesome.quit() end },
}

mymainmenu = awful.menu({
    items = {
        { "awesome", myawesomemenu, beautiful.awesome_icon },
        { "open terminal", terminal },
    }
})

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon, menu = mymainmenu })

mytextclock = awful.widget.textclock()

local taglist_buttons = gears.table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = gears.table.join(
    awful.button({ }, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c.minimized = false
            if not c:isvisible() and c.first_tag then
                c.first_tag:view_only()
            end
            client.focus = c
            c:raise()
        end
    end),
    awful.button({ }, 3, function()
        awful.menu.client_list({ theme = { width = 250 } })
    end),
    awful.button({ }, 4, function() awful.client.focus.byidx(1) end),
    awful.button({ }, 5, function() awful.client.focus.byidx(-1) end)
)

awful.screen.connect_for_each_screen(function(s)
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    s.mypromptbox = awful.widget.prompt()
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        awful.button({ }, 1, function() awful.layout.inc(1) end),
        awful.button({ }, 3, function() awful.layout.inc(-1) end),
        awful.button({ }, 4, function() awful.layout.inc(1) end),
        awful.button({ }, 5, function() awful.layout.inc(-1) end)
    ))
    s.mytaglist = awful.widget.taglist({
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons,
    })
    s.mytasklist = awful.widget.tasklist({
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
    })
    s.mywibox = awful.wibar({ position = "top", screen = s })
    s.mywibox:setup({
        layout = wibox.layout.align.horizontal,
        { layout = wibox.layout.fixed.horizontal, s.mytaglist, s.mypromptbox, s.mytasklist },
        s.mytextclock,
        { layout = wibox.layout.fixed.horizontal, mylauncher, s.mylayoutbox },
    })
end)

root.buttons(gears.table.join(
    awful.button({ }, 3, function() mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

globalkeys = gears.table.join(
    awful.key({ modkey, }, "s", hotkeys_popup.show_help, { description = "show help", group = "awesome" }),
    awful.key({ modkey, }, "Left", awful.tag.viewprev, { description = "view previous", group = "tag" }),
    awful.key({ modkey, }, "Right", awful.tag.viewnext, { description = "view next", group = "tag" }),
    awful.key({ modkey, }, "Escape", awful.tag.history.restore, { description = "go back", group = "tag" }),
    awful.key({ modkey, }, "j", function() awful.client.focus.byidx(1) end, { description = "focus next by index", group = "client" }),
    awful.key({ modkey, }, "k", function() awful.client.focus.byidx(-1) end, { description = "focus previous by index", group = "client" }),
    awful.key({ modkey, }, "w", function() mymainmenu:show() end, { description = "show main menu", group = "awesome" }),
    awful.key({ modkey, "Shift" }, "j", function() awful.client.swap.byidx(1) end, { description = "swap with next client by index", group = "client" }),
    awful.key({ modkey, "Shift" }, "k", function() awful.client.swap.byidx(-1) end, { description = "swap with previous client by index", group = "client" }),
    awful.key({ modkey, "Control" }, "j", function() awful.screen.focus_relative(1) end, { description = "focus the next screen", group = "screen" }),
    awful.key({ modkey, "Control" }, "k", function() awful.screen.focus_relative(-1) end, { description = "focus the previous screen", group = "screen" }),
    awful.key({ modkey, }, "u", awful.client.urgent.jumpto, { description = "jump to urgent client", group = "client" }),
    awful.key({ modkey, }, "Tab", function() awful.client.focus.history.previous(); if client.focus then client.focus:raise() end end, { description = "go back", group = "client" }),
    awful.key({ modkey, }, "Return", function() awful.spawn(terminal) end, { description = "open a terminal", group = "launcher" }),
    awful.key({ modkey, "Control" }, "r", awesome.restart, { description = "reload awesome", group = "awesome" }),
    awful.key({ modkey, "Shift" }, "q", awesome.quit, { description = "quit awesome", group = "awesome" }),
    awful.key({ modkey, }, "l", function() awful.tag.incmwfact(0.05) end, { description = "increase master width factor", group = "layout" }),
    awful.key({ modkey, }, "h", function() awful.tag.incmwfact(-0.05) end, { description = "decrease master width factor", group = "layout" }),
    awful.key({ modkey, "Shift" }, "h", function() awful.tag.incnmaster(1, nil, true) end, { description = "increase the number of master clients", group = "layout" }),
    awful.key({ modkey, "Shift" }, "l", function() awful.tag.incnmaster(-1, nil, true) end, { description = "decrease the number of master clients", group = "layout" }),
    awful.key({ modkey, "Control" }, "h", function() awful.tag.incncol(1, nil, true) end, { description = "increase the number of columns", group = "layout" }),
    awful.key({ modkey, "Control" }, "l", function() awful.tag.incncol(-1, nil, true) end, { description = "decrease the number of columns", group = "layout" }),
    awful.key({ modkey, }, "space", function() awful.layout.inc(1) end, { description = "select next", group = "layout" }),
    awful.key({ modkey, "Shift" }, "space", function() awful.layout.inc(-1) end, { description = "select previous", group = "layout" }),
    awful.key({ modkey, "Control" }, "n", function() local c = awful.client.restore(); if c then client.focus = c; c:raise() end end, { description = "restore minimized", group = "client" }),
    awful.key({ modkey, }, "r", function() awful.screen.focused().mypromptbox:run() end, { description = "run prompt", group = "launcher" }),
    awful.key({ modkey, }, "x", function() awful.spawn("rofi -show drun") end, { description = "run launcher", group = "launcher" }),
    awful.key({ modkey, }, "p", function() menubar.show() end, { description = "show the menubar", group = "launcher" })
)

clientkeys = gears.table.join(
    awful.key({ modkey, }, "f", function(c) c.fullscreen = not c.fullscreen; c:raise() end, { description = "toggle fullscreen", group = "client" }),
    awful.key({ modkey, "Shift" }, "c", function(c) c:kill() end, { description = "close", group = "client" }),
    awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle, { description = "toggle floating", group = "client" }),
    awful.key({ modkey, "Control" }, "Return", function(c) c:swap(awful.client.getmaster()) end, { description = "move to master", group = "client" }),
    awful.key({ modkey, }, "o", function(c) c:move_to_screen() end, { description = "move to screen", group = "client" }),
    awful.key({ modkey, }, "t", function(c) c.ontop = not c.ontop end, { description = "toggle keep on top", group = "client" }),
    awful.key({ modkey, }, "n", function(c) c.minimized = true end, { description = "minimize", group = "client" }),
    awful.key({ modkey, }, "m", function(c) c.maximized = not c.maximized; c:raise() end, { description = "(un)maximize", group = "client" }),
    awful.key({ modkey, "Control" }, "m", function(c) c.maximized_vertical = not c.maximized_vertical; c:raise() end, { description = "(un)maximize vertically", group = "client" }),
    awful.key({ modkey, "Shift" }, "m", function(c) c.maximized_horizontal = not c.maximized_horizontal; c:raise() end, { description = "(un)maximize horizontally", group = "client" })
)

for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9, function() local screen = awful.screen.focused(); local tag = screen.tags[i]; if tag then tag:view_only() end end, { description = "view tag #" .. i, group = "tag" }),
        awful.key({ modkey, "Control" }, "#" .. i + 9, function() local screen = awful.screen.focused(); local tag = screen.tags[i]; if tag then awful.tag.viewtoggle(tag) end end, { description = "toggle tag #" .. i, group = "tag" }),
        awful.key({ modkey, "Shift" }, "#" .. i + 9, function() if client.focus then local tag = client.focus.screen.tags[i]; if tag then client.focus:move_to_tag(tag) end end end, { description = "move focused client to tag #" .. i, group = "tag" }),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function() if client.focus then local tag = client.focus.screen.tags[i]; if tag then client.focus:toggle_tag(tag) end end end, { description = "toggle focused client on tag #" .. i, group = "tag" })
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function(c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize)
)

root.keys(globalkeys)

awful.rules.rules = {
    { rule = { }, properties = { border_width = beautiful.border_width, border_color = beautiful.border_normal, focus = awful.client.focus.filter, raise = true, keys = clientkeys, buttons = clientbuttons, screen = awful.screen.preferred, placement = awful.placement.no_overlap + awful.placement.no_offscreen } },
    { rule = { class = "MPlayer" }, properties = { floating = true } },
    { rule = { class = "pinentry" }, properties = { floating = true } },
    { rule = { class = "gimp" }, properties = { floating = true } },
    { rule = { class = "Firefox" }, properties = { maximized = true } },
}

client.connect_signal("manage", function(c)
    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end
end)

client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
