CC = valac
CFLAGS = --pkg gtk+-3.0 --pkg webkit2gtk-4.0 --pkg glib-2.0 --pkg gio-2.0 --Xcc=-O0 --vapidir . --pkg libcmark
TARGET = rdr
SRC = rdr.vala
RESOURCES = /com/koyu/rdr/style.css
RESOURCE_FILE = resources.xml
GRESOURCE_FILE = resources.gresource

$(TARGET): $(SRC)
	glib-compile-resources $(RESOURCE_FILE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC)

clean:
	rm -f $(TARGET) $(GRESOURCE_FILE)

install:
	mkdir -p /usr/share/rdr/
	cp $(GRESOURCE_FILE) /usr/share/rdr/
	cp $(TARGET) /usr/bin

uninstall:
	rm -rf /usr/share/rdr
	rm /usr/bin/rdr

all:
	$(TARGET)