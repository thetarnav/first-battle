.PHONY: \
	release, debug, run, \
	build-web, release-web, serve-web, \
	check

ODIN ?= odin

VET_FLAGS =   -vet                \
              -warnings-as-errors

RELEASE_FLAGS = -o:speed         \
                -disable-assert  \
                -no-bounds-check

BUILD_FLAGS = -out:bin/first-battle

# Arguments after --
EXTRA_FLAGS = $(filter-out $@,$(MAKECMDGOALS))

all: run

release:
	$(ODIN) build . $(BUILD_FLAGS) $(VET_FLAGS) $(EXTRA_FLAGS) $(RELEASE_FLAGS)

build-web:
	$(ODIN) run karl2d/build_web -- . $(EXTRA_FLAGS)

release-web:
	$(ODIN) run karl2d/build_web -- . $(VET_FLAGS) $(EXTRA_FLAGS) $(RELEASE_FLAGS)

serve-web:
	cd bin/web && python -m http.server

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
