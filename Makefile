#
#   Copyright 2022 Alexander Vollschwitz <xelalex@gmx.net>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

SHELL = /bin/bash

REPO = oqtadrive
ROOT = $(shell pwd)
SKETCH_DIR := $(ROOT)/src
SKETCH := $(SKETCH_DIR)/spectratur.ino

ARDUINO_CLI_IMAGE = xelalex/spectratur-arduino-cli

VERBOSE ?=
ifeq ($(VERBOSE),y)
    MAKEFLAGS += --trace
else
    MAKEFLAGS += -s
endif

PORT ?=
ifeq ($(PORT),)
	ARDUINO_CLI_ARGS = --clean --verify
	TTY_VOL =
else
	ARDUINO_CLI_ARGS = --clean --upload --port $(PORT)
	TTY_VOL = -v $(PORT):$(PORT)
endif

FQBN ?= arduino:avr:nano

export

#
#
#

.PHONY: imgarduino
imgarduino:
#	build the Arduino CLI image required for compiling adapter firmware
#
ifeq ($(shell docker images --digests --quiet $(ARDUINO_CLI_IMAGE)),)
	echo "building Arduino CLI image..."
	docker build -t $(ARDUINO_CLI_IMAGE) -f ./hack/arduino-cli.Dockerfile .
	echo "image build done"
endif


.PHONY: firmware
firmware: imgarduino
# compile the adapter firmware, set 'PORT' to port of connected adapter to
# actually upload instead of just compiling, e.g.:
#
#	    PORT=/dev/ttyUSB0 make firmware
#
	docker run --rm -ti --privileged -v "$(SKETCH_DIR):/spectratur/spectratur" \
		$(TTY_VOL) $(ARDUINO_CLI_IMAGE) \
		./arduino/arduino-cli compile $(ARDUINO_CLI_ARGS) \
			--fqbn $(FQBN) /spectratur/spectratur
