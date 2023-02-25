CC=gcc # gcc || clang
PROG = wifimngr
OBJS = wifimngr.o wps.o wifimngr_event.o main.o

BINDIR ?= /usr/sbin

PROG_CFLAGS = $(CFLAGS) -Wall -Werror -fstrict-aliasing -ggdb
CFLAGS += -Wno-address-of-packed-member
PROG_LDFLAGS = $(LDFLAGS)
PROG_LIBS = -lwifi-7
PROG_LIBS += -luci -lubus -lubox -ljson-c -lblobmsg_json -lnl-genl-3 -lnl-3 -lgcov -leasy
GCOV = gcov
CODECOVERAGE_SRC = wifimngr.c

BUILDCOLOR=@printf "\e[1;32mBuilding $< \e[0m\n"


$(shell chmod a+x ./verifysum.sh)

%.o: %.c
	$(BUILDCOLOR)
	$(CC) $(PROG_CFLAGS) $(FPIC) -c -o $@ $<

.PHONY: version clean install

all: version wifimngr

version: version.h files.md5

version.h:
	@(dirty=$(shell ./verifysum.sh); \
	[ -f version.h ] || { \
		[ -f VERSION ] && basever=$(shell cat VERSION) || \
			basever=Unknown; \
		xver=$(shell date +'%y%V%u-%H%M'); \
		echo "const char *wifimngr_base_version = \"$$basever\";" > $@; \
	}; \
	echo "const char *wifimngr_xtra_version = \"$$xver$$dirty\";" >> $@; \
	)

files.md5:
	@md5sum *.c > $@

wifimngr: $(OBJS)
	$(CC) $(PROG_LDFLAGS) -o $@ $^ $(PROG_LIBS)


test: CFLAGS += -fPIC
test: ${OBJS}
	${CC} ${LDFLAGS} -shared -o libwifimngr.so ${OBJS} ${LIBS}

unit-test: coverage
	make -C test/cmocka unit-test WIFIMNGR_LIB_DIR=$(PWD)

functional-test: coverage
	make -C test/cmocka functional-test WIFIMNGR_LIB_DIR=$(PWD)

coverage: CFLAGS  += -g -O0 -fprofile-arcs -ftest-coverage -fPIC
coverage: LDFLAGS += --coverage
coverage: test wifimngr
	$(foreach testprog, $(CODECOVERAGE_SRC), $(GCOV) $(testprog);)

$(DESTDIR)/$(BINDIR)/%: %
	install -D $< $@

install: $(addprefix $(DESTDIR)/$(BINDIR)/,wifimngr)

clean:
	rm -f *.o libwifimngr.so $(PROG)
	rm -f *.xml *.html
	rm -rf coverage
	find -name '*.gcda' -exec rm {} -fv \;
	find -name '*.gcno' -exec rm {} -fv \;
	find -name '*.gcov' -exec rm {} -fv \;
	make -C test/cmocka clean
