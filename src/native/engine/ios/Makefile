# src/native/engine/ios/Makefile

TARGET = aarch64-apple-ios
SDK = $(shell xcrun --sdk iphoneos --show-sdk-path)
CC = clang -arch arm64 -isysroot $(SDK)
METAL = xcrun metal
METALLIB = xcrun metallib
AR = ar rcs

CRYSTAL_SRC = bridge.cr
CRYSTAL_LIB = libnative_cr_ios.a

OBJC_SRC = AppDelegate.m ViewController.m Renderer.m
OBJC_OBJ = $(OBJC_SRC:.m=.o)
OBJC_LIB = libnative_cr_engine.a

METAL_SRC = Shaders.metal
METAL_AIR = Shaders.air
METAL_LIB = default.metallib

CFLAGS = -fobjc-arc -framework UIKit -framework Metal -framework QuartzCore -framework Foundation

.PHONY: all clean crystal objc metal

all: crystal objc metal
	@echo "[native.cr] iOS engine build complete"
	@echo "  - $(CRYSTAL_LIB)"
	@echo "  - $(OBJC_LIB)"
	@echo "  - $(METAL_LIB)"

crystal: $(CRYSTAL_LIB)

$(CRYSTAL_LIB): $(CRYSTAL_SRC)
	@echo "[native.cr] Compiling Crystal..."
	crystal build $< --target $(TARGET) --release --link-flags="-static" -o $@

objc: $(OBJC_LIB)

$(OBJC_LIB): $(OBJC_OBJ)
	@echo "[native.cr] Archiving Objective-C..."
	$(AR) $@ $^

%.o: %.m
	@echo "[native.cr] Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

metal: $(METAL_LIB)

$(METAL_AIR): $(METAL_SRC)
	@echo "[native.cr] Compiling Metal shader..."
	$(METAL) -c $< -o $@

$(METAL_LIB): $(METAL_AIR)
	@echo "[native.cr] Linking Metal library..."
	$(METALLIB) $< -o $@

clean:
	@echo "[native.cr] Cleaning..."
	rm -f $(CRYSTAL_LIB) $(OBJC_OBJ) $(OBJC_LIB) $(METAL_AIR) $(METAL_LIB)
