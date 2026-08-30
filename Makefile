.PHONY: release, debug, run, check

ODIN ?= odin

VET_FLAGS =   -vet                \
              -strict-style       \
              -warnings-as-errors

BUILD_FLAGS = -out:bin/first-battle

# Arguments after --
EXTRA_FLAGS = $(filter-out $@,$(MAKECMDGOALS))

all: run

release:
	$(ODIN) build . $(BUILD_FLAGS) $(VET_FLAGS) $(EXTRA_FLAGS) \
		-o:speed         \
		-disable-assert  \
		-no-bounds-check

debug:
	$(ODIN) build . $(BUILD_FLAGS) $(EXTRA_FLAGS) \
		-debug

run:
	$(ODIN) run . $(BUILD_FLAGS) $(EXTRA_FLAGS)

check:
	$(ODIN) check . $(VET_FLAGS) $(EXTRA_FLAGS) -target:linux_amd64
	$(ODIN) check . $(VET_FLAGS) $(EXTRA_FLAGS) -target:darwin_amd64
	$(ODIN) check . $(VET_FLAGS) $(EXTRA_FLAGS) -target:windows_amd64

# Prevent make from trying to build files named after extra flags
%:
	@:
