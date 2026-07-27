/**
 * Copyright (c) 2026 Huawei Device Co., Ltd. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

export enum IntentType {
  GET_SIM_CARD_NUMBER = 'GetSimCardNumber',
  GET_DEFAULT_DIALING_SIM_CARD = 'GetDefaultDialingSimCard',
  GET_DEFAULT_MOBILE_DATA_SIM_CARD = 'GetDefaultMobileDataSimCard',
  SET_DEFAULT_DIALING_SIM_CARD = 'SetDefaultDialingSimCard',
  SET_DEFAULT_MOBILE_DATA_SIM_CARD = 'SetDefaultMobileDataSimCard',
  CHECK_SIM_SWITCH = 'CheckSimSwitch',
  GET_SIM_SWITCH = 'GetSimSwitch',
  SET_SIM_SWITCH = 'SetSimSwitch',
  CHECK_SETTING_PAGE = 'CheckSettingPage',
  CHECK_SETTING_ITEM = 'CheckSettingItem'
}
