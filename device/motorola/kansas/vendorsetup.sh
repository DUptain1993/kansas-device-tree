#!/bin/bash
# add_lunch_combo is obsolete on fox_14.1 (confirmed via the build's own
# warning: "add_lunch_combo is obsolete. Use COMMON_LUNCH_CHOICES in your
# AndroidProducts.mk instead.") — lunch choices are declared there now,
# not here. This file is kept only because vendorsetup.sh is still
# sourced automatically and some device-tree tooling expects it to exist.
