######################################################################
#  Project
######################################################################

BINARY		= braverats
SRCFILES	= \
	main.c \
	core.c \
	ui.c \
	ai.c \

HDRFILES	= \
	config.h \
	core.h \
	ui.h \
	ai.h \

$(BINARY): $(SRCFILES) $(HDRFILES)
	gcc -Wextra -Wall -std=c99 -O0 -g -o $(BINARY) $(SRCFILES)

$(BINARY).bin: $(SRCFILES) $(HDRFILES)
	zcc +zx -lndos $(SRCFILES) -create-app -o $(BINARY).bin -startup=1

run: $(BINARY)
	./$(BINARY)

spectrum: $(BINARY).bin

clean:
	rm -rf $(BINARY) $(BINARY).bin $(BINARY).tap

.PHONY: run spectrum clean
