/*
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
import { DeviceUtils } from '../../utils/DeviceUtils';

/**
 * @file: Constant selection data
 */

export const DIALOG_TYPE: Record<string, string> = {
  'TWO_BUTTON_DIALOG': 'twoButton',
  'TOAST_DIALOG': 'toast'
};

export const UPDATE_DIALOG_TYPE: Record<string, string> = {
  'ADD_ESIM': 'addESim'
};

export const CARD_CALLING_SET: Record<string, number> = {
  'NO_SETTING': -1,
  'CARD1': 0,
  'CARD2': 1
};

export const CARD_NET_SUPPORT: Record<string, string> = {
  'NO_SUPPORT_5G': '4G/3G/2G',
  'SUPPORT_5G': '5G/4G/3G/2G'
};

export const REGULAR: Record<string, RegExp> = {
  'regular': new RegExp('^[+]?[0-9*#]+', 'g'),
  'regular2': new RegExp('[^~!@$%^&()#+*_\\-=<>?:"{}|,.\\/;₠₵￠￠Πη℅©¶￠€∣∅√÷×≈™′℗®＇´＇\'ˊ¢`•▪.·°∉￠φ£△∆·£￥￡฿€$¥′″∏' +
    '~～﹏﹋≈\'\\\\[\\]·~！@￥%……&（）——\\-={}|《》？：“”【】、；‘\'，。、A-Za-z\\x22]', 'g')
};

export const SIM_CARD_ABILITY_CONTEXT = 'simCardAbilityContext';

/**
 * Primary card change event.
 */
export const COMMON_EVENT_SET_PRIMARY_SLOT_STATUS = 'usual.event.SET_PRIMARY_SLOT_STATUS';

/**
 * Uninitialized value of the primary card
 */
export const PRIMARY_SLOT_ID_NOT_INIT = -1;

/**
 * Uninitialized value for the default dial card
 */
export const DEFAULT_VOICE_SLOT_ID_NOT_INIT = -2;

/**
 * Regular expression of a mobile number.
 */
export const PHONE_NUMBER_REGULAR: string = '^([+0-9#*][0-9#*]*)$';

/**
 * Card slot 1.
 */
export const SLOT_1 = 0;

/**
 * Card slot 2.
 */
export const SLOT_2 = 1;

/**
 * Inner margins of the page.
 */
export const PAGE_PADDING = DeviceUtils.isTablet() ? $r('sys.float.padding_level12') : $r('sys.float.padding_level8');

/*
 * China Telecom's plmn.
 */
export const TELECOM_PLMN = ['46003', '46011'];

/**
 * Minimum PIN length.
 */
export const PIN_MIN_LENGTH = 4;

/**
 * Maximum PIN length.
 */
export const PIN_MAX_LENGTH = 8;

/**
 * Maximum PUK length.
 */
export const PUK_MAX_LENGTH = 8;

/**
 * Divider Height 1.
 */
export const DIVIDER_STROKE_WIDTH_1 = 1;

/**
 * Default PIN
 */
export const DEFAULT_PIN = 1234;

/**
 * Maximum number of SIM cards.
 */
export const MAX_SIM_COUNT = 2;

/**
 * The maximum number of sim slots is 1.
 */
export const SIM_SLOT_COUNT_1 = 1;

/**
 * PIN default Remaining Times.
 */
export const DEFAULT_PIN_REMAIN = 3;

/**
 * PUK default Remaining Times.
 */
export const DEFAULT_PUK_REMAIN = 10;

/**
 * mirroring language.
 */
export const RTL = 'rtl';

/**
 * want参数中的startReason值的一种，表示从设置搜索进入的界面
 */
export const START_REASON_FROM_SEARCH = 'from_search';

/**
 * 次数：0
 */
export const TIMES_0 = 0;

/**
 * 次数：1
 */
export const TIMES_1 = 1;

/**
 * toast提示框距离底部默认的边距：80vp
 */
export const TOAST_BOTTOM_MARGIN_DEFAULT = 80;

/**
 * 卫星通信状态-开启
 */
export const SATELLITE_STATE_ON = 1;

/**
 * SIM locked type.
 */
export enum LockType {
  NOT_LOCKED = 0,
  PIN_LOCK = 1,
  FDN_LOCK = 2,
  PUK_LOCK = 3
}

/**
 * Unlocked successfully.
 */
export const UNLOCK_SUCCEED = 0;

/**
 * Name of the lock type.
 */
export enum SimLockTypeName {
  PIN = 'pin',
  PUK = 'puk',
  UNLOCK = ''
}

/**
 * PIN Change Scenario
 */
export enum UpdatePinScenario {
  NORMAL_CHANGE,
  RESET_BY_PUK
}

/**
 * Scenarios for changing saved PIN.
 */
export enum PinSavingScenario {
  UPDATE_CACHE_PIN = 0,
  ALTER_SIM_PIN = 1,
  RESET_SIM_PIN = 2,
}
