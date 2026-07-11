# Copyright (C) 2026 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/twrp_kansas.mk

# fox_14.1's envsetup.sh requires the 3-part <product>-<release>-<variant>
# form — a 2-part combo fails immediately with "Invalid lunch combo".
# The release token is NOT free-form: build/make/core/release_config.mk
# validates it against a real (if minimal) release_config_map, and
# envsetup.sh's own generic fallback string ("trunk_staging") is NOT
# a valid entry in it — first CI attempt failed with "No release
# config found for TARGET_RELEASE: trunk_staging. Available releases
# are: ap2a." "ap2a" is the only release this manifest defines.
COMMON_LUNCH_CHOICES := \
    twrp_kansas-ap2a-user \
    twrp_kansas-ap2a-userdebug \
    twrp_kansas-ap2a-eng
