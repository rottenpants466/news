class MainWindow : Gtk.ApplicationWindow {
	private Granite.Widgets.Toast errortoast;
	private News.Widgets.SourceList newssourcelist;

	public signal void source_add(string source);
	public signal void source_remove(string source);

	public MainWindow(Gtk.Application app) {
		Object (application: app,
			title: _("News"));
	}

	public void show_error(string msg = _("Something went wrong")) {
		this.errortoast.title = msg;
		this.errortoast.send_notification();
	}

	construct {
		this.default_width = 1100;
		this.default_height = 700;

		var headerbar = new NewsHeaderBar();
		this.set_titlebar(headerbar);

		var box = new Gtk.Overlay();
		this.add(box);

		this.errortoast = new Granite.Widgets.Toast(_("Something went wrong"));
		box.add_overlay(errortoast);

		this.newssourcelist = new News.Widgets.SourceList();
		var newspanel = new NewsPanel();
		var paned = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
		paned.pack1(this.newssourcelist, false, false);
		paned.add2(newspanel);
		box.add(paned);

		headerbar.search.connect((query) => {
			try {
				var langs = Intl.get_language_names();
				string lang = langs.length > 0 ? langs[0] : "en_US";

				// Spanish site is down
				if (lang == "es_ES") {
					lang = "es_MX";
				}

				var feed = new XmlFeed("https://news.google.com/rss/search?hl=" + lang.replace("_", "-") + "&q=" + query);
				this.add_feed(feed);
				this.source_add(feed.source);
			} catch (Error err) {
				warning(err.message);
				this.show_error("Couldn't reach Google News");
			}
		});

		this.newssourcelist.feed_selected.connect((feed) => {
			newspanel.feed = feed;
		});
		this.newssourcelist.feed_removed.connect((feed) => {
			this.source_remove(feed.source);
		});
		this.newssourcelist.feed_added.connect((feed) => {
			this.source_add(feed.source);
		});

		var provider = new Gtk.CssProvider();
		provider.load_from_data("""
		@define-color colorPrimary #f20050;
		@define-color textColorPrimary #fafafa;
		@define-color colorAccent #68b723;""", -1);
		Gtk.StyleContext.add_provider_for_screen(this.get_screen(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

		// Ctrl+F shortcut
		var accel_group = new Gtk.AccelGroup();
		accel_group.connect(Gdk.Key.f,  Gdk.ModifierType.CONTROL_MASK,  Gtk.AccelFlags.VISIBLE,  () => {
			headerbar.focus_search();
			return true;
		});
		this.add_accel_group(accel_group);
	}

	public void add_feed(Feed feed) {
		this.newssourcelist.add_feed(feed);
   }
}
