CC       = g++
SHELL    = /bin/sh
SRCROOT  = ../..

INCLUDES = -I$(SRCROOT)/src/Shared \
           -I$(SRCROOT)/src/Shared/Frontend \
           -I$(SRCROOT)/src/MyCurses
CFLAGS   = -std=gnu++11 -Wall -Wno-error -pedantic

TARGET   = rogue-collection-headless

BUILDROOT= $(SRCROOT)/build/release

LIBS     = $(BUILDROOT)/lib-shared-frontend.a \
           -ldl -lpthread

OBJECTS  = main.o game_config.o

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $(BUILDROOT)/$(TARGET) $(OBJECTS) $(LIBS)

main.o: main.cpp
	$(CC) -c -o $@ $< $(CFLAGS) $(INCLUDES)

game_config.o: $(SRCROOT)/src/RogueCollectionQml/RoguePlugin/game_config.cpp
	$(CC) -c -o $@ $< $(CFLAGS) $(INCLUDES)

clean:
	rm -f $(OBJECTS) $(BUILDROOT)/$(TARGET)
