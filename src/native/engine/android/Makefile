# src/native/engine/android/Makefile

NDK_PATH ?= $(ANDROID_NDK)
TOOLCHAIN = $(NDK_PATH)/toolchains/llvm/prebuilt/linux-x86_64
CC = $(TOOLCHAIN)/bin/aarch64-linux-android24-clang
AR = $(TOOLCHAIN)/bin/llvm-ar
CFLAGS = -fPIC -O2 -I$(NDK_PATH)/sources/android/native_app_glue
LDFLAGS = -shared -landroid -llog -lEGL -lGLESv2 -lc

TARGET = libnative_cr_engine.so
SOURCES = native.c android_native_app_glue.c

all: $(TARGET)

$(TARGET): $(SOURCES)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

clean:
	rm -f $(TARGET)
