NDK_PATH ?= $(ANDROID_NDK)
SDK_PATH ?= $(ANDROID_HOME)

TOOLCHAIN = $(NDK_PATH)/toolchains/llvm/prebuilt/linux-x86_64
CC = $(TOOLCHAIN)/bin/aarch64-linux-android24-clang
JAVAC = javac
JAR = jar

GLUE_DIR = $(NDK_PATH)/sources/android/native_app_glue
GLUE_SRC = $(GLUE_DIR)/android_native_app_glue.c

ANDROID_JAR = $(SDK_PATH)/platforms/android-34/android.jar

# Target path relative to /home/zendrx/projects/native.cr/src/native/engine/android
LIBS_DIR = ../../../../../libs
DEP_JARS = $(LIBS_DIR)/androidx-core.jar:$(LIBS_DIR)/androidx-recyclerview.jar:$(LIBS_DIR)/androidx-biometric.jar:$(LIBS_DIR)/androidx-appcompat.jar:$(LIBS_DIR)/google-billing.jar:$(LIBS_DIR)/androidx-fragment.jar
CLASSPATH = $(ANDROID_JAR):$(DEP_JARS)

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
	$(JAVAC) -source 1.8 -target 1.8 -Xbootclasspath/p:"$(ANDROID_JAR)" -cp "$(CLASSPATH)" -d build/classes $(JAVA_SOURCES)
	$(JAR) cf $@ -C build/classes .

clean:
	rm -f $(TARGET_SO) $(TARGET_JAR)
	rm -rf build

.PHONY: all clean