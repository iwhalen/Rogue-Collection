SHELL       := /bin/bash
BUILD_DIR   := build/release
QML_DIR     := build/qml
SRC_DIR     := src

ROGUE_BIN    := $(BUILD_DIR)/rogue-collection
RETRO_BIN    := $(BUILD_DIR)/retro-rogue-collection
HEADLESS_BIN := $(BUILD_DIR)/rogue-collection-headless
DEFAULT_VER  := Unix Rogue 5.4.2

LIB_SUBDIRS := \
	MyCurses \
	RogueVersions/Rogue_PC_Core \
	RogueVersions/Rogue_PC_1_48 \
	RogueVersions/Rogue_3_6_3 \
	RogueVersions/Rogue_5_2_1 \
	RogueVersions/Rogue_5_3 \
	RogueVersions/Rogue_5_4_2 \
	Rogomatic \
	Shared/Frontend

.PHONY: all build libs qml headless resources run run-retro clean distclean help

all: build

help:
	@echo "Rogue Collection build targets:"
	@echo "  build       - Full build (libraries + QML apps + headless + resources)"
	@echo "  libs        - Build only native libraries"
	@echo "  qml         - Build only QML applications"
	@echo "  headless    - Build headless binary (no GUI, pipe I/O only)"
	@echo "  resources   - Copy resources/data to build directory"
	@echo "  run         - Run rogue-collection (QML frontend)"
	@echo "  run-retro   - Run retro-rogue-collection (QML frontend)"
	@echo "  clean       - Remove object files, keep build artifacts"
	@echo "  distclean   - Remove entire build directory"

build: resources libs qml headless

resources: | $(BUILD_DIR)/res $(BUILD_DIR)/data $(BUILD_DIR)/rlog
	cp -Ru res/* $(BUILD_DIR)/res/
	cp -Ru data/* $(BUILD_DIR)/data/
	cp -u rogue.opt $(BUILD_DIR)/
	cp -u docs/readme.md $(BUILD_DIR)/

$(BUILD_DIR) $(BUILD_DIR)/res $(BUILD_DIR)/data $(BUILD_DIR)/rlog:
	mkdir -p $@

libs: | $(BUILD_DIR)
	@for dir in $(LIB_SUBDIRS); do \
		echo "=== Building $$dir ==="; \
		$(MAKE) -C $(SRC_DIR)/$$dir || exit 1; \
	done

qml: $(ROGUE_BIN) $(RETRO_BIN)
	mkdir -p $(BUILD_DIR)/RoguePlugin
	cp $(QML_DIR)/RetroRogueCollection/RoguePlugin/qmldir $(BUILD_DIR)/RoguePlugin/
	cp $(QML_DIR)/RetroRogueCollection/RoguePlugin/librogueplugin.so $(BUILD_DIR)/RoguePlugin/

$(ROGUE_BIN): libs | $(QML_DIR)/RogueCollection
	cd $(QML_DIR)/RogueCollection && \
		qmake ../../../$(SRC_DIR)/RogueCollectionQml/RogueCollection.pro -spec linux-g++ && \
		$(MAKE) qmake_all && $(MAKE) -j$$(nproc)
	cp $(QML_DIR)/RogueCollection/rogue-collection $(BUILD_DIR)/

$(RETRO_BIN): libs | $(QML_DIR)/RetroRogueCollection
	cd $(QML_DIR)/RetroRogueCollection && \
		qmake ../../../$(SRC_DIR)/RogueCollectionQml/RetroRogueCollection.pro -spec linux-g++ && \
		$(MAKE) qmake_all && $(MAKE) -j$$(nproc)
	cp $(QML_DIR)/RetroRogueCollection/retro-rogue-collection $(BUILD_DIR)/

$(QML_DIR)/RogueCollection $(QML_DIR)/RetroRogueCollection:
	mkdir -p $@

headless: libs
	$(MAKE) -C $(SRC_DIR)/RogueCollectionHeadless

run: build
	cd $(BUILD_DIR) && LD_LIBRARY_PATH=. ./rogue-collection "$(DEFAULT_VER)"

run-retro: build
	cd $(BUILD_DIR) && LD_LIBRARY_PATH=. ./retro-rogue-collection "$(DEFAULT_VER)"

clean:
	@for dir in $(LIB_SUBDIRS); do \
		$(MAKE) -C $(SRC_DIR)/$$dir clean 2>/dev/null || true; \
	done
	@if [ -d "$(QML_DIR)/RogueCollection" ] && [ -f "$(QML_DIR)/RogueCollection/Makefile" ]; then \
		$(MAKE) -C $(QML_DIR)/RogueCollection clean; \
	fi
	@if [ -d "$(QML_DIR)/RetroRogueCollection" ] && [ -f "$(QML_DIR)/RetroRogueCollection/Makefile" ]; then \
		$(MAKE) -C $(QML_DIR)/RetroRogueCollection clean; \
	fi
	$(MAKE) -C $(SRC_DIR)/RogueCollectionHeadless clean 2>/dev/null || true

distclean:
	rm -rf build/
