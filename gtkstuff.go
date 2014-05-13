package main

import (
	"fmt"
	"github.com/mattn/go-gtk/gtk"
	"github.com/mattn/go-gtk/gdkpixbuf"
	"os"
	"strconv"
)

func entrychanged( out  *gtk.Label,
                   opts [][2]string,
                   n    uint,
                   e    *gtk.Entry,
                   im   *gtk.Image ) func() {
	return func() {
		opts[n][1] = e.GetText()
		if n == 0 || n == 1 || n == 4 || n == 5 {
			updateimage(im, out, opts)
		}
	}
}

func updateimage( im   *gtk.Image,
                  out  *gtk.Label,
                  opts [][2]string ) {
	url := out.GetLabel()+"/"+opts[0][1]+opts[1][1]+opts[4][1]
	pixbuf, err := gdkpixbuf.NewFromFile(url)
	if err != nil {
		return
	}
	ms, cerr := strconv.Atoi(opts[5][1])
	if cerr == nil && ms > 0 {
		ow := pixbuf.GetWidth()
		oh := pixbuf.GetHeight()
		if ow == 0 || oh == 0 {
			return
		}
		w, h := ow, oh
		s := float32(oh)/float32(ow)
		if ow > oh {
			if ow > ms {
				w = ms
				h = int(float32(w)*s)
			}
		} else if oh > ms {
			h = ms
			w = int(float32(h)/s)
		}
		pixbuf = gdkpixbuf.ScaleSimple(pixbuf, w, h,
			gdkpixbuf.INTERP_BILINEAR)
	}
	im.SetFromPixbuf(pixbuf)
}

func main() {
	gtk.Init(&os.Args)
	window := gtk.NewWindow(gtk.WINDOW_TOPLEVEL)
	window.Connect("destroy", gtk.MainQuit)
	window.SetBorderWidth(10)
	table := gtk.NewTable(4, 17, false)
	titlelabel := gtk.NewLabel("gif-go")
	titlelabel.SetPadding(5, 5)
	table.AttachDefaults(titlelabel, 0, 2, 0, 1)
	table.Attach(gtk.NewHSeparator(), 0, 2, 1, 2,
		gtk.FILL, gtk.FILL, 5, 5)
	table.Attach(gtk.NewVSeparator(), 2, 3, 0, 17,
		gtk.FILL, gtk.FILL, 5, 5)
	image := gtk.NewImage()
	table.AttachDefaults(image, 3, 4, 0, 17)
	filebut := gtk.NewButtonWithLabel("select folder")
	out := gtk.NewLabel("")
	filebut.Connect("clicked", func () {
		chooser := gtk.NewFileChooserDialog(
			"select folder", window,
			gtk.FILE_CHOOSER_ACTION_SELECT_FOLDER,
			gtk.STOCK_OK, gtk.RESPONSE_ACCEPT)
		chooser.Response(func() {
			out.SetLabel(chooser.GetFilename())
			chooser.Destroy()
		})
		chooser.Run()
	})
	table.AttachDefaults(filebut, 0, 2, 2, 3)
	table.AttachDefaults(out, 0, 2, 3, 4)
	opts := make([][2]string, 9, 9)
	opts[0] = [2]string{"prefix", ""}
	opts[1] = [2]string{"first", "1"}
	opts[2] = [2]string{"last", ""}
	opts[3] = [2]string{"step", "1"}
	opts[4] = [2]string{"suffix", ".png"}
	opts[5] = [2]string{"maxsize", "400"}
	opts[6] = [2]string{"colors", "60"}
	opts[7] = [2]string{"title", ""}
	opts[8] = [2]string{"output file", "out.gif"}
	for n := uint(0); n < uint(len(opts)); n++ {
		entry := gtk.NewEntry()
		entry.SetText(opts[n][1])
		entry.Connect("changed", entrychanged(
			out, opts, n, entry, image))
		table.AttachDefaults(entry, 0, 1, n+4, n+5)
		table.AttachDefaults(gtk.NewLabel(opts[n][0]),
			1, 2, n+4, n+5)
	}
	run := gtk.NewButtonWithLabel("run")
	run.Clicked(func() {
		for n := 0; n < len(opts); n++ {
			fmt.Println(opts[n][0], opts[n][1])
		}
	})
	table.AttachDefaults(run, 0, 2, 15, 16)
	window.Add(table)
	window.SetResizable(false)
	window.ShowAll()
	gtk.Main()
}
