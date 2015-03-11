#!/usr/bin/env lua

local lgi = require 'lgi'
local Gtk = lgi.Gtk
local GdkPixbuf = lgi.GdkPixbuf

local function gif(arg, window, outim, prog)
	local gd = require 'gd'
	function resize(frametc, maxsize)
		local sizex, sizey = frametc:sizeXY()
		if sizex > maxsize or sizey > maxsize then
			if sizex > sizey then
				local nsizey = sizey*maxsize/sizex
				local nframetc = gd.createTrueColor(maxsize, nsizey)
				nframetc:copyResampled(frametc, 0, 0, 0, 0, maxsize, nsizey, sizex, sizey)
				return nframetc
			else
				local nsizex = sizex*maxsize/sizey
				local nframetc = gd.createTrueColor(nsizex, maxsize)
				nframetc:copyResampled(frametc, 0, 0, 0, 0, nsizex, maxsize, sizex, sizey)
				return nframetc
			end
		end
	end

	for i = 1, 9 do
		if not arg[i] then
			print(
"usage: gif.lua prefix first last step suffix maxsize colors text output\
	example: gif.lua \"frame_\" 2 8 3 \".png\" 400 40 \"\" \"anim.gif\"")
			os.exit(1)
		end
	end

	local prefix = arg[1]
	local first = tonumber(arg[2])
	local last = tonumber(arg[3])
	local step = tonumber(arg[4])
	local suffix = arg[5]
	local maxsize = tonumber(arg[6]) or math.huge
	local colors = tonumber(arg[7])
	local text = arg[8]
	local output = arg[9]
	local createFromFF = gd.createFromJpeg
	if string.lower(string.sub(suffix, -3)) == "jpg" then
	elseif string.lower(string.sub(suffix, -3)) == "png" then
		createFromFF = gd.createFromPng
	else
		print("invalid file type")
		return
	end

	local url = string.format("%s%d%s", prefix, first, suffix)
	frametc = createFromFF(url)
	assert(frametc, url .. " does not exist")
	frametc = resize(frametc, maxsize)
	local framepal = frametc:createPaletteFromTrueColor(true, colors)
	--local out = string.format("%s%d%s.gif", prefix, first, string.sub(suffix, 0, -5))
	local out = output
	io.write(out, "\t")
	framepal:gifAnimBegin(out, true, 0)
	for frame = first, last, step do
		local url = string.format("%s%d%s", prefix, frame, suffix)
		frametc = createFromFF(url)
		frametc = resize(frametc, maxsize)
		if text then
			local white = frametc:colorAllocate(255, 255, 255)
			frametc:string(gd.FONT_SMALL, 2, 2, text, white)
		end
		framepal = frametc:createPaletteFromTrueColor(true, colors)
		framepal:gifAnimAdd(out, true, 0, 0, 10, gd.DISPOSAL_NONE)
		prog:set_fraction((frame-first)/(last-first/step))
		updateimage(url)
		Gtk.main_iteration()
	end
	gd.gifAnimEnd(out)
	local outpix = GdkPixbuf.PixbufAnimation.new_from_file(out)
	outim:set_from_animation(outpix)
end

local window = Gtk.Window {
	title = 'test',
	border_width = 10,
	on_destroy = Gtk.main_quit
}

local grid = Gtk.Grid()
grid:attach(Gtk.Label{label="gif.lua", margin=5}, 0, 0, 2, 1)
grid:attach(Gtk.HSeparator{margin=5}, 0, 1, 2, 1)
grid:attach(Gtk.VSeparator{margin=5}, 2, 0, 1, 17)
local outim = Gtk.Image()--{margin=10}
local outpix = GdkPixbuf.Pixbuf.new_from_file('')
grid:attach(outim, 3, 0, 1, 17)
local out = Gtk.Label()
local filebut = Gtk.Button{
	label = "select folder",
	on_clicked = function()
		local chooser = Gtk.FileChooserDialog{
			title = 'select folder',
			action = 'SELECT_FOLDER',
			buttons = {
				{Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL},
				{Gtk.STOCK_OPEN, Gtk.ResponseType.OK}}}
		chooser:run()
		out.label = chooser:get_filename()
		chooser:destroy() end
	}
grid:attach(filebut, 0, 2, 2, 1)
grid:attach(out, 0, 3, 2, 1)

local opts = {
	{"prefix", ""},
	{"first", "1"},
	{"last", ""},
	{"step", "1"},
	{"suffix", ".png"},
	{"maxsize", "400"},
	{"colors", "60"},
	{"title", ""},
	{"output file", "out.gif"}
}

function updateimage(url)
	outpix = GdkPixbuf.Pixbuf.new_from_file(url)
	if not outpix then return end
	local ms = tonumber(opts[6][2])
	if type(ms) == "number" and ms > 0 then
		local ow = outpix:get_width()
		local oh = outpix:get_height()
		if ow == 0 or oh == 0 then
			return
		end
		local w, h = ow, oh
		local s = oh/ow
		if ow > oh then
			if ow > ms then
				w = ms
				h = w*s
			end
		elseif oh > ms then
			h = ms
			w = h/s
		end
		outpix = GdkPixbuf.Pixbuf.scale_simple(outpix,
			w, h, GdkPixbuf.InterpType.BILINEAR)
	end
	outim:set_from_pixbuf(outpix)
end

for n, opt in ipairs(opts) do
	local entry = Gtk.Entry{
		text = opt[2],
		on_changed = function(e)
			opt[2] = e.text
			if n == 1 or n == 2 or n == 5 or n == 6 then
				updateimage(out.label.."/"..
					opts[1][2]..
					opts[2][2]..
					opts[5][2])
			end end}
	grid:attach(entry, 0, n+4, 1, 1)
	grid:attach(Gtk.Label{label = opt[1], margin = 3}, 1, n+4, 1, 1)
end
grid:attach(Gtk.HSeparator{margin=5}, 0, #opts+5, 2, 1)
local button = Gtk.Button{label = "run"}
grid:attach(button, 0, #opts+6, 2, 1)
local prog = Gtk.ProgressBar()
function button.on_clicked(e)
	local arg = {}
	for _, opt in ipairs(opts) do
		table.insert(arg, opt[2])
	end
	arg[1] = out.label .. "/" .. arg[1]
	gif(arg, window, outim, prog)
end
grid:attach(prog, 0, #opts+7, 2, 1)
window:add(grid)
window:set_resizable(false)

window:show_all()
Gtk.main()
