BSS=0x1000
TARGETS=hello.elf rpn.elf
all: $(TARGETS)
clean:
	rm -f $(TARGETS)
.PHONY: all clean
%.bin: %.asm
	fasm $<
%.elf: %.bin
	./elfdude $(BSS) 16777216 $< $@
	chmod +x $@