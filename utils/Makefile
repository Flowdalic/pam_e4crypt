INSTALL=install

TARGETS=init halt

all: $(TARGETS)

$(TARGETS): %: %.c
	$(CC) $(CFLAGS) -o $@ $^

install: $(TARGETS)
	test -d $(TARGET_ROOT)/sbin || mkdir -p $(TARGET_ROOT)/sbin
	$(INSTALL) $(TARGETS) $(TARGET_ROOT)/sbin

.PHONY: install

