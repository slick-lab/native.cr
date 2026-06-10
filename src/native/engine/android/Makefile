# src/native/engine/android/Makefile

NDK_PATH ?= $(ANDROID_NDK)
TOOLCHAIN = $(NDK_PATH)/toolchains/llvm/prebuilt/linux-x86_64
CC = $(TOOLCHAIN)/bin/aarch64-linux-android24-clang
JAVAC = javac
JAR = jar

GLUE_DIR = $(NDK_PATH)/sources/android/native_app_glue
GLUE_SRC = $(GLUE_DIR)/android_native_app_glue.c

CFLAGS = -fPIC -O2 -I$(GLUE_DIR)
LDFLAGS = -shared -landroid -llog -ljnigraphics

TARGET_SO = libnative_cr_engine.so
TARGET_JAR = libnative_cr_android.jar
SOURCES = native.c $(GLUE_SRC)
JAVA_SOURCES = $(wildcard java/com/nativecr/*.java)

all: $(TARGET_SO) $(TARGET_JAR)

$(TARGET_SO): $(SOURCES)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

$(TARGET_JAR): $(JAVA_SOURCES)
	mkdir -p build/classes
	$(JAVAC) -source 1.8 -target 1.8 -d build/classes $(JAVA_SOURCES)
	$(JAR) cf $@ -C build/classes .

clean:
	rm -f $(TARGET_SO) $(TARGET_JAR)
	rm -rf build

.PHONY: all clean
