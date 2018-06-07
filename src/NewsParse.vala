struct FeedItem {
    string? title;
    string? about;
    string? link;
    string? pubDate;
    string? content;
}

abstract class Feed {
    [Description(nick = "Feed items", blurb = "This is the list of feed entries.")]
    public abstract FeedItem[] items { get; protected set; }
    [Description(nick = "Feed title", blurb = "This is the title of the feed.")]
    public abstract string? title { get; protected set; }
    [Description(nick = "Feed source", blurb = "This is the source of the feed.")]
    public abstract string? link { get; protected set; }
}

class RssFeed : Feed {
    public string? about { get; protected set; default = null; }
    public override string? title { get; protected set; default = null; }
    public override string? link { get; protected set; default = null; }
    public override FeedItem[] items { get; protected set; default = new FeedItem[0]; }

    private RssFeed() {}

    /* Creates feed from xml */
    public RssFeed.from_xml(string str) {
        var doc = Xml.Parser.parse_doc(str);
    
        Xml.Node* root = doc->get_root_element();
        if(root == null) {
            stderr.puts("Error parsing Xml.Doc: doc->get_root_element() is null");
        }

        // find channel element
        var channel = root->children;
        for(; channel->name != "channel"; channel = channel->next);

        FeedItem[] items = this.items;

        // loop through elements
        for(var child = channel->children; child != null; child = child->next) {
            switch(child->name) {
            case "title":
                this.title = child->get_content();
                break;
            case "description":
                this.about = child->get_content();
                break;
            case "link":
                this.link = child->get_content();
                break;
            case "item":
                FeedItem item = FeedItem();
                for(var childitem = child->children; childitem != null; childitem = childitem->next) {
                    switch(childitem->name) {
                    case "title":
                        item.title = childitem->get_content().replace("&", "&amp;");
                        break;
                    case "link":
                        item.link = childitem->get_content();
                        break;
                    case "description":
                        item.about = childitem->get_content();
                        break;
                    case "encoded":
                        item.content = childitem->get_content();
                        break;
                    case "pubDate":
                        item.pubDate = childitem->get_content();
                        break;
                    }
                }

                items += item;
                break;
            }
        }
        this.items = items;
    }

    /* Creates feed from uri */
    public RssFeed.from_uri(string uri) throws Error {
        var news_page = File.new_for_uri(uri);
    
        DataInputStream data_stream = null;
        try {
            data_stream = new DataInputStream(news_page.read());
        } catch(Error err) {
            stdout.puts(err.message);
            stdout.putc('\n');
            throw err;
        }
        data_stream.set_byte_order(DataStreamByteOrder.LITTLE_ENDIAN);

        string line = null;
        var text = new StringBuilder();
        while((line = data_stream.read_line()) != null) {
            text.append(line);
            text.append_c('\n');
        }

        this.from_xml(text.str);
    }

/*    // special exceptions (has a lot)
    private static string? parse_rules(owned string url, owned string? about) {
        if(url != null) url = url.ascii_down();

        if(url == null); // make url null
        else if(url.index_of("news.google.com") != -1) {                    
            about = null;
        } else if(url.index_of("rss.cnn.com") != -1) {
            var endIndex = about.index_of("<div");
            about = about[0:endIndex].replace("&", "&amp;");
            if(about == "") // if description is empty (sometimes is)
                about = null;
        } else if(url.index_of("news.ycombinator.com") != -1 || about == "") {
            about = null;
        } else if(url.index_of("feeds.kinja.com/lifehacker") != -1) {
            about = about.slice(about.index_of("<p>"), about.index_of("</p>"));
        }
        return about;
    }
*/
}

class GoogleNewsFeed : RssFeed {
    public GoogleNewsFeed() throws Error {
        base.from_uri("https://news.google.com/news/rss/?ned=us&gl=US&hl=e");
    }
    public override string? title {
        get { return "Google News"; }
        protected set {}
    }
}

