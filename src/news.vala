struct Article {
    public string title;
    public string text;
    public string link;
}

Article[] fetch_news() {
    var youtube_page = File.new_for_uri("https://news.google.com/news/?ned=us&hl=en&output=rss");
    
    DataInputStream data_stream = null;
    try {
        data_stream = new DataInputStream(youtube_page.read());
    } catch(GLib.Error err) {
        stdout.puts(err.message);
        stdout.putc('\n');
        return null;
    }
    data_stream.set_byte_order(DataStreamByteOrder.LITTLE_ENDIAN);

    string line = null;
    var text = new StringBuilder();
    try {
        while((line = data_stream.read_line()) != null) {
            text.append(line);
            text.append_c('\n');
        }
    } catch(GLib.IOError err) {
        return null;
    }
    
    var str = text.str;

    int itemIndex = 0;
    Article[] articles = new Article[0];
    while((itemIndex = (int)str.index_of("<item>", itemIndex + 1)) != -1) {
        var startIndex = str.index_of("<title>", itemIndex) + "<title>".length;
        var endIndex = str.index_of("</", startIndex);
        var s = str[startIndex:endIndex];
        
        // Find link;
        var uStartIndex = str.index_of("<link>", itemIndex) + "<link>".length;
        uStartIndex = str.index_of("url=", uStartIndex) + 4;
        var uEndIndex = str.index_of("</", uStartIndex);
        var uS = str[uStartIndex:uEndIndex];

        // Scrape description
        var dStartIndex = str.index_of("<description>", itemIndex) + "<description>".length;
        var dEndIndex = str.index_of("</", dStartIndex);
        var dS = str.slice(dStartIndex, dEndIndex).replace("&quot;", "\"").replace("&#39;", "'").replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&");
        
        // Find description inside of the html table inside of the description: look at the rss feed for yourself
        var eStartIndex = dS.index_of("</font><br><font size=\"-1\">") + "</font><br><font size=\"-1\">".length;
        var eEndIndex = dS.index_of("</", eStartIndex);
        var desc = dS.slice(eStartIndex, eEndIndex).replace("&nbsp;", " ").replace("<b>", "").replace("&#39;", "'");  
        desc = desc.replace("&quot;", "\"").replace("&middot;", ".");
        Article article = new Article() {
            title = s,
            text = desc,
            link = uS
        };
        articles += article;
    }
    return articles;
}

int main (string args[]) {
    Gtk.init(ref args);

    Article[] s = fetch_news();

    var window = new Gtk.Window();
    window.title = "News";
    window.set_position(Gtk.WindowPosition.CENTER);
    window.set_default_size(950, 950);
    window.destroy.connect(Gtk.main_quit);

    Gtk.ListBox list = null;
    
    if(s == null) {
        window.add(new Gtk.Label("An error occured"));
    } else { 
        list = new Gtk.ListBox();
        foreach (Article article in s) {
            // TODO: Add hbox for arrow
//			var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box.margin = 12;
//			hbox.add(box);
//          hbox.margin = 12;

            // Title
            var label = new Gtk.Label(null);
            label.set_markup("<b>" + article.title + "</b>");
            label.set_line_wrap(true);
            box.add(label);

            // Description
            var desc = new Gtk.TextView();
            desc.set_wrap_mode (Gtk.WrapMode.WORD);
            desc.buffer.text = article.text;
            desc.override_background_color(Gtk.StateFlags.NORMAL, {0,0,0,0});
            desc.editable = false;
            //desc.set_line_wrap(true);
            box.add(desc);

			//hbox.add(new Gtk.Label(">"));

            var row = new Gtk.ListBoxRow();            
            row.add(box);
            row.button_press_event.connect((e) => {
	            Pid child_pid = 0;

                if(e.type == Gdk.EventType.DOUBLE_BUTTON_PRESS)
                    Process.spawn_async("/",
                        {"xdg-open", article.link},
                        Environ.get(),
                        SpawnFlags.SEARCH_PATH,
                        null,
                        out child_pid
                    );              

                return false;
            });

            list.add(row);
        }
        window.add(list);
    }
    window.show_all();

    window.resize(950, 950);

    Gtk.main();
    return 0;
}
