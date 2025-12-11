# Makefile for ca65/ld65 NES projects

# Define directories
SRC_DIR   := src/asm
BUILD_DIR := build
BIN_DIR   := bin
INC_DIR   := src/include

TARGET    := $(BIN_DIR)/main.nes
CFG_FILE  := nes.cfg

# Find all assembly source files (.s) in the source directory
SRCS      := $(wildcard $(SRC_DIR)/*.s)

# Define object files (.o) to be created in the build directory
OBJS      := $(patsubst $(SRC_DIR)/%.s,$(BUILD_DIR)/%.o,$(SRCS))

# CC65 tools
AS      := ca65
LD      := ld65
CC      := cl65 # Unified driver

# Compiler/Assembler Flags
AFLAGS  := -I $(INC_DIR)
LFLAGS  := -C $(CFG_FILE) --target nes

.PHONY: all clean

all: directories $(TARGET)

directories:
	mkdir -p $(BUILD_DIR) $(BIN_DIR)

# Rule to link the final .nes file from all object files
$(TARGET): $(OBJS)
	$(LD) $(LFLAGS) -o $@ $(OBJS)

# Rule to assemble individual .s files into .o files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s
	$(AS) $(AFLAGS) $< -o $@

clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)