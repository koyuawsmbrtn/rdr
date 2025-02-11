using Gtk;
using WebKit;
using GLib;

int main(string[] args) {
    if (args.length < 2) {
        stderr.printf("Usage: %s <markdown_file>\n", args[0]);
        return 1;
    }
    
    string markdown_file = args[1];
    string tmp_dir = "/tmp/rdr";

    try {
        string markdown_content;
        size_t length;
        FileUtils.get_contents(markdown_file, out markdown_content, out length);
        string html_content = "<html><head><meta charset=\"utf-8\"><link rel=\"stylesheet\" href=\"file:///tmp/rdr/style.css\"></head><body>" + markdown_to_html(markdown_content) + "</body></html>";
        
        var dir = File.new_for_path(tmp_dir);
        if (!dir.query_exists()) {
            try {
                dir.make_directory();
            } catch (Error e) {
                stderr.printf("Error creating folder: %s\n", e.message);
            }
        }
        string tmp_file = Path.build_filename(Environment.get_current_dir(), ".rdr-preview.html");
        extract_css(tmp_dir);
        FileUtils.set_contents(tmp_file, html_content);
        
        Gtk.init(ref args);
        var window = new Gtk.Window(WindowType.TOPLEVEL);
        window.title = "rdr: "+markdown_file;
        window.set_default_size(800, 600);
        
        var webview = new WebKit.WebView();
        webview.load_uri("file://" + tmp_file);
        
        window.add(webview);
        window.show_all();

        window.destroy.connect(() => {
            delete_folder_recursively(tmp_dir);
            FileUtils.remove(tmp_file);
            Gtk.main_quit();
        });

        window.key_press_event.connect((sender, event) => {
            if (event.keyval == 113) {
                window.destroy();
            }
            return false;
        });

        Gtk.main();
    } catch (Error e) {
        stderr.printf("Error: %s\n", e.message);
        return 1;
    }
    
    return 0;
}

void delete_folder_recursively(string folder_path) {
    try {
        var dir = File.new_for_path(folder_path);
        var enumerator = dir.enumerate_children("standard::*", FileQueryInfoFlags.NONE, null);

        while (true) {
            try {
                var file_info = enumerator.next_file(null);
                if (file_info == null) {
                    break;
                }

                var file = enumerator.get_child(file_info);

                var file_type = file.query_file_type(FileQueryInfoFlags.NONE);

                if (file_type == FileType.DIRECTORY) {
                    delete_folder_recursively(file.get_path());
                } else {
                    file.delete(null);
                }
            } catch (Error e) {
                stderr.printf("Error: %s\n", e.message);
            }
        }
        enumerator.close();
        dir.delete(null);
    } catch (Error e) {
        stderr.printf("Error: %s\n", e.message);
    }
}

string markdown_to_html(string markdown) {
    uint8[] markdown_bytes = (uint8[])markdown.to_utf8();
    return CMark.to_html(markdown_bytes, CMark.OPT.UNSAFE);
}

void extract_css(string output_filename) {
    try {
        var resource = GLib.Resource.load("/usr/share/rdr/resources.gresource");
        if (resource == null) {
            stderr.printf("Failed to load resource.\n");
            return;
        }

        var input_stream = resource.open_stream("/com/koyu/rdr/style.css", ResourceLookupFlags.NONE);
        if (input_stream == null) {
            stderr.printf("Failed to open stream for /com/koyu/rdr/style.css.\n");
            return;
        }

        string tmp_file = Path.build_filename(output_filename, "style.css");
        var output_stream = File.new_for_path(tmp_file).create(FileCreateFlags.REPLACE_DESTINATION, null);

        uint8[] buffer = new uint8[1024];
        size_t bytes_read;

        while ((bytes_read = input_stream.read(buffer)) > 0) {
            uint8[] valid_data = new uint8[(int)bytes_read];
            for (int i = 0; i < bytes_read; i++) {
                valid_data[i] = buffer[i];
            }

            output_stream.write_all(valid_data, null);
        }
    } catch (Error e) {
        stderr.printf("Error extracting and writing the CSS file: %s\n", e.message);
    }
}
