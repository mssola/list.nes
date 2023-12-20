CA65     ?= ca65
CC65     ?= cl65
CCOPTS   ?= --target nes
ifeq "$(DEBUG)" "1"
CCOPTS   += -g -Ln tmp/labels.txt
endif


.PHONY: test
test: prepare build example unit

.PHONY: prepare
prepare: clean deps

.PHONY: clean
clean:
	@sed -i '/RUN_TESTS = 1/d' test/suite.s
	@rm -rf tmp
	@mkdir tmp
	@find . -type f -name "*.o" -delete
	@find . -type f -name "*.nes" -delete

.PHONY: deps
deps:
	@which $(CC65) >/dev/null 2>/dev/null || (echo "ERROR: $(CC65) not found." && false)
	@which fceux >/dev/null 2>/dev/null || (echo "ERROR: fceux not found." && false)

.PHONY: build
build: list.o

%.o: %.s
	$(CA65) $< -o $@

test/%.nes: test/%.s
	$(CC65) $(CCOPTS) $< -o $@

.PHONY: unit
unit:
	@bash test/run.sh

.PHONY: example
example:
	$(CC65) $(CCOPTS) examples/mul.s -o examples/mul.nes
