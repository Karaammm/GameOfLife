s? = $(subst $(empty) ,?,$1)
?s = $(subst ?, ,$1)
dirx = $(call ?s,$(dir $(call s?,$1)))
export HERE = $(patsubst %/,%,$(call dirx,$(abspath $(lastword $(MAKEFILE_LIST)))))

RVTOOLPREFIX=/opt/riscv/bin/riscv64-unknown-linux-gnu-
RVGCC=$(RVTOOLPREFIX)gcc 
RVOBJCOPY=$(RVTOOLPREFIX)objcopy 

OUT_DIR := out

GCC_FLAGS=-march=rv32i -mabi=ilp32 -static -nostdlib -nostartfiles -mcmodel=medany -g

ASSEMBLY_SOURCES=$(notdir $(wildcard *.s))
ASSEMBLY_SOURCES+=$(addprefix "$(HERE)/src/, $(addsuffix ",$(notdir $(wildcard src/*.s))))

.PHONY: clean build_%

clean:
	rm -rf $(OUT_DIR)

$(OUT_DIR):
	mkdir -p $@

assembly_%: $(OUT_DIR)
ifeq ($(strip $(ASSEMBLY_SOURCES)),)
	@echo "No assembly sources found"
else
	$(RVGCC) $(GCC_FLAGS) -o $(OUT_DIR)/$(basename $*) -T mmio.ld $(ASSEMBLY_SOURCES)
	$(RVOBJCOPY) -O binary  $(OUT_DIR)/$*  $(OUT_DIR)/$*.bin
endif

build_%: assembly_%
	@echo "Done"