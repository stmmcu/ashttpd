.SUFFIXES:
CONFIG_MAK := Config.mak
-include Config.mak

ifdef USE_CUSTOM_LIBAIO
LIBAIO := ../libaio/libaio.a
AIO_SENDFILE_OBJ := io_async_sendfile.o
EXTRA_DEFS := -I../libaio/src -DHAVE_AIO_SENDFILE
else
LIBAIO := -laio
AIO_SENDFILE_OBJ := 
endif

CC := $(CROSS_COMPILE)gcc
LD := $(CROSS_COMPILE)ld
AR := $(CROSS_COMPILE)ar

EXTRA_DEFS := -D_FILE_OFFSET_BITS=64 -DHAVE_ACCEPT4=1
CFLAGS := -g -pipe -O2 -Wall \
	-Wsign-compare -Wcast-align \
	-Waggregate-return \
	-Wstrict-prototypes \
	-Wmissing-prototypes \
	-Wmissing-declarations \
	-Wmissing-noreturn \
	-finline-functions \
	-Wmissing-format-attribute \
	-Wno-cast-align \
	-fwrapv \
	-Iinclude \
	$(EXTRA_DEFS) 

HTTPD_BIN := httpd
HTTPD_LIBS := $(LIBAIO)
HTTPD_OBJ = httpd.o \
		http_conn.o \
		http_parse.o \
		http_req.o \
		http_buf.o \
		normalize.o \
		webroot.o \
		io_sync.o \
		io_sendfile.o \
		io_async.o \
		$(AIO_SENDFILE_OBJ) \
		nbio.o \
		nbio-epoll.o \
		nbio-poll.o \
		nbio-listener.o \
		nbio-eventfd.o \
		nbio-inotify.o \
		critbit.o \
		vhosts.o \
		hgang.o \
		vec.o \
		os.o

HTTPRAPE_BIN := httprape
HTTPRAPE_LIBS := 
HTTPRAPE_OBJ := httprape.o \
		markov.o \
		http_parse.o \
		http_resp.o \
		http_buf.o \
		nbio.o \
		nbio-epoll.o \
		nbio-poll.o \
		nbio-connecter.o \
		hgang.o \
		vec.o \
		os.o

MKROOT_BIN := mkroot
MKROOT_LIBS := -lmagic
MKROOT_OBJ := hgang.o \
		strpool.o \
		fobuf.o \
		sha1.o \
		trie.o \
		os.o \
		mkroot.o

FSCK_BIN := fsckroot
FSCK_LIBS :=
FSCK_OBJ = fsck.o \
	webroot.o \
	os.o

ALL_BIN := $(HTTPD_BIN) $(HTTPRAPE_BIN) $(MKROOT_BIN) $(FSCK_BIN)
ALL_OBJ := $(HTTPD_OBJ) $(HTTPRAPE_OBJ) $(MKROOT_OBJ) $(FSCK_OBJ)
ALL_DEP := $(patsubst %.o, .%.d, $(ALL_OBJ))
ALL_TARGETS := $(ALL_BIN)

TARGET: all

.PHONY: all clean walk

all: $(ALL_BIN)

ifeq ($(filter clean, $(MAKECMDGOALS)),clean)
CLEAN_DEP := clean
else
CLEAN_DEP :=
endif

%.o .%.d: %.c $(CLEAN_DEP) Makefile
	@echo " [C] $<"
	@$(CC) $(CFLAGS) -MMD -MF $(patsubst %.o, .%.d, $@) \
		-MT $(patsubst .%.d, %.o, $@) \
		-c -o $(patsubst .%.d, %.o, $@) $<

$(HTTPD_BIN): $(HTTPD_OBJ)
	@echo " [LINK] $@"
	@$(CC) $(CFLAGS) -o $@ $(HTTPD_OBJ) $(HTTPD_LIBS)

$(HTTPRAPE_BIN): $(HTTPRAPE_OBJ) $(HTTPRAPE_SLIBS)
	@echo " [LINK] $@"
	@$(CC) $(CFLAGS) -o $@ $(HTTPRAPE_OBJ) $(HTTPRAPE_LIBS)

$(MKROOT_BIN): $(MKROOT_OBJ)
	@echo " [LINK] $@"
	@$(CC) $(CFLAGS) -o $@ $(MKROOT_OBJ) $(MKROOT_LIBS)

$(FSCK_BIN): $(FSCK_OBJ)
	@echo " [LINK] $@"
	@$(CC) $(CFLAGS) -o $@ $(FSCK_OBJ) $(FSCK_LIBS)

clean:
	rm -f $(ALL_TARGETS) $(ALL_OBJ) $(ALL_DEP)

markov.c: mkmarkov WALK
	./mkmarkov < WALK
walk: markov.c

ifneq ($(MAKECMDGOALS),clean)
-include $(ALL_DEP)
endif
