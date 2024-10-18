# For development only
KEYDOGGER_KEYBOARD=/dev/input/event2

DEPENDENCIES=wl-copy wl-paste
DAEMON_NAME=keydoggerd
PREFIX=/opt/
CALLGRIND_FILE=benchmark.out

.PHONY: build
build: keydogger.h keydogger.c dependency-check
	gcc -DDEBUG_MODE=0 -DDAEMON_NAME=\"$(DAEMON_NAME)\" -w keydogger.c -o keydogger

.PHONY: dependency-check
dependency-check:
	@if which $(DEPENDENCIES) >/dev/null 2>&1; then \
		echo "Dependency found: wl-clipboard"; \
	else \
		echo "ERROR: Dependency missing: wl-clipboard"; \
	fi

.PHONY: dev
dev: keydogger.h keydogger.c dependency-check
	gcc -DDEBUG_MODE=1 -DKEYDOGGER_KEYBOARD=\"$(KEYDOGGER_KEYBOARD)\" -DDAEMON_NAME=\"$(DAEMON_NAME)\" -g -O0 keydogger.c -o keydogger -Wall  -Wextra -Wpedantic -Wsign-conversion -Wimplicit-function-declaration -Warray-bounds

.PHONY: install
install: build
	mkdir -p $(PREFIX)
	mv keydogger $(PREFIX)


.PHONY: debug
debug: dev
	sudo gdb keydogger

.PHONY: memcheck
memcheck: dev
	sudo valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all ./keydogger debug

.PHONY: benchmark
benchmark: dev
	-rm callgrind*
	sudo valgrind --tool=callgrind --dump-instr=yes --simulate-cache=yes --collect-jumps=yes --callgrind-out-file=$(CALLGRIND_FILE) ./keydogger debug

.PHONY: viz
viz:
	kcachegrind ./$(CALLGRIND_FILE)

.PHONY: clean
clean:
	-rm *.o > /dev/null 2>&1 || true
	-rm keydogger -f > /dev/null 2>&1 || true
	-rm callgrind* > /dev/null 2>&1 || true
	-rm vgcore* > /dev/null 2>&1 || true
	-rm *.out > /dev/null 2>&1 || true
