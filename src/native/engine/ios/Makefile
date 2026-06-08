SDK = $(shell xcrun --sdk iphoneos --show-sdk-path)
CC = clang -arch arm64 -isysroot $(SDK) -fobjc-arc
CFLAGS = -framework UIKit -framework Metal -framework QuartzCore -framework Foundation

OBJC_SRC = AppDelegate.m ViewController.m Renderer.m
OBJC_OBJ = $(OBJC_SRC:.m=.o)
TARGET = libnative_cr_engine.a

METAL_SRC = Shaders.metal
METAL_AIR = Shaders.air
METAL_LIB = default.metallib

all: $(TARGET) $(METAL_LIB)

$(TARGET): $(OBJC_OBJ)
	ar rcs $@ $^

%.o: %.m
	$(CC) $(CFLAGS) -c $< -o $@

$(METAL_AIR): $(METAL_SRC)
	xcrun metal -c $< -o $@

$(METAL_LIB): $(METAL_AIR)
	xcrun metallib $< -o $@

clean:
	rm -f $(OBJC_OBJ) $(TARGET) $(METAL_AIR) $(METAL_LIB)

.PHONY: all clean
