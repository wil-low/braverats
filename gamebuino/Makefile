# sudo snap install arduino-cli

ARDUINO_PATH=$(HOME)/.arduino15/packages/arduino
SIM_PATH=$(HOME)/Arduino/Simbuino4Web-patched/hex
SRC_PATH=braverats

DEPS= \
	$(SRC_PATH)/core.cpp \
	$(SRC_PATH)/core.h \
	$(SRC_PATH)/ai.cpp \
	$(SRC_PATH)/ai.h \
	$(SRC_PATH)/ui.cpp \
	$(SRC_PATH)/ui.h \
	$(SRC_PATH)/pile.cpp \
	$(SRC_PATH)/pile.h \
	$(SRC_PATH)/sprite.h \
	$(SRC_PATH)/config.h \
	$(SRC_PATH)/braverats.ino

all: bin/BRAVERAT.HEX

clean:
	rm -rf bin/BRAVERAT.HEX build/*

build/braverats.ino.hex: $(DEPS)
	clear
	mkdir -p build bin
	$(HOME)/.local/bin/arduino-cli compile \
		--fqbn arduino:avr:uno \
		--libraries "$(HOME)/Arduino/libraries" \
		--build-path build \
		$(SRC_PATH)

bin/BRAVERAT.HEX: build/braverats.ino.hex
	cp build/braverats.ino.hex bin/BRAVERAT.HEX
	cp build/braverats.ino.hex $(SIM_PATH)/

sim: bin/BRAVERAT.HEX stop_sim
	cd $(HOME)/Arduino/Simbuino4Web-patched && bash start.sh &
	xdg-open http://localhost:8000/Index.html?hex=hex/braverats.ino.hex &

stop_sim:
	fuser -k 8000/tcp || true

.PHONY: all clean sim stop_sim
