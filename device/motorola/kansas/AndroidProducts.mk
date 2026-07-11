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
# form (confirmed from source: its own default fallback combo is
# aosp_cf_x86_64_phone-trunk_staging-eng, and "trunk_staging" is the
# hardcoded release token used throughout that fork even though it has
# no real build/release/release_config_map.textproto). A 2-part combo
# fails with "Invalid lunch combo" before anything else even starts.
COMMON_LUNCH_CHOICES := \
    twrp_kansas-trunk_staging-user \
    twrp_kansas-trunk_staging-userdebug \
    twrp_kansas-trunk_staging-eng
