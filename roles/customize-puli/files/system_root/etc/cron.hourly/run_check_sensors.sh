#!/bin/bash

module swap gnu14 llvm/14.0.6-zfuxl7x
ml py-pandas
ml py-termcolor

/root/bin/check_sensors.py