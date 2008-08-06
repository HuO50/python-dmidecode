#
#	DMI Decode
#	BIOS Decode
#
#	(C) 2000-2002 Alan Cox <alan@redhat.com>
#	(C) 2002-2007 Jean Delvare <khali@linux-fr.org>
#
#	Licensed under the GNU Public License.
#

PY      = $(shell python -V 2>&1 |sed -e 's/.\(ython\) \(2\.[0-9]\)\..*/p\1\2/')
CC      = gcc

CFLAGS  = -fno-strict-aliasing -D_XOPEN_SOURCE=600
CFLAGS += -W -Wall -Wshadow -Wstrict-prototypes -Wpointer-arith -Wcast-align -Wwrite-strings -Wmissing-prototypes -Winline -Wundef #-Wcast-qual
CFLAGS += -I/usr/include/$(PY)
#.
#CFLAGS += -DBIGENDIAN
#CFLAGS += -DALIGNMENT_WORKAROUND
#.
#. When debugging, disable -O2 and enable -g.
CFLAGS += -g -DNDEBUG
#CFLAGS += -O2

SOFLAGS = -shared -fPIC

# Pass linker flags here
LDFLAGS = -I/usr/include/$(PY) -lefence

DESTDIR =
prefix  = /usr/local
sbindir = $(prefix)/sbin
mandir  = $(prefix)/share/man
man8dir = $(mandir)/man8
docdir  = $(prefix)/share/doc/dmidecode

INSTALL         := install
INSTALL_DATA    := $(INSTALL) -m 644
INSTALL_DIR     := $(INSTALL) -m 755 -d
INSTALL_PROGRAM := $(INSTALL) -m 755
RM              := rm -f

PROGRAMS := dmidecode
PROGRAMS += $(shell test `uname -m 2>/dev/null` != ia64 && echo biosdecode ownership vpddecode)
# BSD make doesn't understand the $(shell) syntax above, it wants the !=
# syntax below. GNU make ignores the line below so in the end both BSD
# make and GNU make are happy.
PROGRAMS != echo dmidecode ; test `uname -m 2>/dev/null` != ia64 && echo biosdecode ownership vpddecode


all : $(PROGRAMS)

module:
	sudo python setup.py clean
	python setup.py build
	sudo python setup.py install
	python -c 'import dmidecode'


#
# Shared Objects
#

libdmidecode.so: dmidecode.o util.o
	$(CC) $(LDFLAGS) $(SOFLAGS) $< -o $@

#
# Programs
#

dmidecode: dmidecodebin.c catsprintf.o libdmidecode.so dmidecode.o dmiopt.o dmioem.o util.o
	$(CC) $(LDFLAGS) $< -L. -ldmidecode -l$(PY) catsprintf.o dmidecode.o dmiopt.o dmioem.o util.o -o $@

biosdecode : biosdecode.o util.o
	$(CC) $(LDFLAGS) biosdecode.o util.o -o $@

ownership : ownership.o util.o
	$(CC) $(LDFLAGS) ownership.o util.o -o $@

vpddecode : vpddecode.o vpdopt.o util.o
	$(CC) $(LDFLAGS) vpddecode.o vpdopt.o util.o -o $@

#
# Objects
#

dmidecode.o : dmidecode.c version.h types.h util.h config.h dmidecode.h dmiopt.h dmioem.h
	$(CC) $(CFLAGS) -c $< -o $@

dmiopt.o : dmiopt.c config.h types.h util.h dmidecode.h dmiopt.h
	$(CC) $(CFLAGS) -c $< -o $@

dmioem.o : dmioem.c types.h dmidecode.h dmioem.h
	$(CC) $(CFLAGS) -c $< -o $@

biosdecode.o : biosdecode.c version.h types.h util.h config.h
	$(CC) $(CFLAGS) -c $< -o $@

ownership.o : ownership.c version.h types.h util.h config.h
	$(CC) $(CFLAGS) -c $< -o $@

vpddecode.o : vpddecode.c version.h types.h util.h config.h vpdopt.h
	$(CC) $(CFLAGS) -c $< -o $@

vpdopt.o : vpdopt.c config.h util.h vpdopt.h
	$(CC) $(CFLAGS) -c $< -o $@

util.o : util.c types.h util.h config.h
	$(CC) $(CFLAGS) -c $< -o $@

catsprintf.o: catsprintf.c catsprintf.h
	$(CC) $(CFLAGS) -c $< -o $@

#
# Commands
#

strip : $(PROGRAMS)
	strip $(PROGRAMS)

install : install-bin install-man install-doc

uninstall : uninstall-bin uninstall-man uninstall-doc

install-bin : $(PROGRAMS)
	$(INSTALL_DIR) $(DESTDIR)$(sbindir)
	for program in $(PROGRAMS) ; do \
	$(INSTALL_PROGRAM) $$program $(DESTDIR)$(sbindir) ; done

uninstall-bin :
	for program in $(PROGRAMS) ; do \
	$(RM) $(DESTDIR)$(sbindir)/$$program ; done

install-man :
	$(INSTALL_DIR) $(DESTDIR)$(man8dir)
	for program in $(PROGRAMS) ; do \
	$(INSTALL_DATA) man/$$program.8 $(DESTDIR)$(man8dir) ; done

uninstall-man :
	for program in $(PROGRAMS) ; do \
	$(RM) $(DESTDIR)$(man8dir)/$$program.8

install-doc :
	$(INSTALL_DIR) $(DESTDIR)$(docdir)
	$(INSTALL_DATA) README $(DESTDIR)$(docdir)
	$(INSTALL_DATA) CHANGELOG $(DESTDIR)$(docdir)
	$(INSTALL_DATA) AUTHORS $(DESTDIR)$(docdir)

uninstall-doc :
	$(RM) -r $(DESTDIR)$(docdir)

clean :
	python setup.py clean
	$(RM) *.so *.o $(PROGRAMS) core
	rm -rf build