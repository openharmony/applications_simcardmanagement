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
import { SimCardGlobalContextHelper } from '../utils/SimCardGlobalContextHelper';
import * as Constants from '../utils/constant';
import common from '@ohos.app.ability.common';
import SystemParameterEnhance from '@ohos.systemParameterEnhance';
import LogUtils from './LogUtils';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { JSON } from '@kit.ArkTS';
import { DeviceUtils } from '../../utils/DeviceUtils';
import { DynamicLoader } from '../../utils/DynamicLoader';

const TAG = 'Utils';

/**
 * @file: Utils
 */
export function getString(value: Resource) {
  const context = SimCardGlobalContextHelper.getInstance()
    .getValue<common.UIAbilityContext>(Constants.SIM_CARD_ABILITY_CONTEXT);
  if (typeof context !== 'undefined' && context !== null) {
    return context.resourceManager.getStringSync(value.id);
  }
  return '';
}

/**
 * Get the string value of a resource using a method with parameters.
 *
 * @param resource Resources for String.
 * @param args Parameter value in the resource.
 * @returns The last generated string value.
 */
export function getStringWithArgs(resource: Resource, ...args: Array<string | number>) {
  const context = SimCardGlobalContextHelper.getInstance()
    .getValue<common.UIAbilityContext>(Constants.SIM_CARD_ABILITY_CONTEXT);
  if (typeof context !== 'undefined' && context !== null) {
    return context.resourceManager.getStringSync(resource.id, ...args);
  }
  return '';
}

/**
 * Obtains the number result with a specified resource object.
 *
 * @param { Resource } resource - Indicates the resource object.
 * @returns { number } The number resource corresponding to the resource object.
 */
export function getNumber(resource: Resource) {
  const context = SimCardGlobalContextHelper.getInstance()
    .getValue<common.UIAbilityContext>(Constants.SIM_CARD_ABILITY_CONTEXT);
  if (typeof context !== 'undefined' && context !== null) {
    return context.resourceManager.getNumber(resource);
  }
  return 0;
}

/**
 * @function : needFilterEflInfo
 */
export function needFilterEflInfo(): boolean {
  let eflFilterSwitch: String = SystemParameterEnhance.getSync('const.telephony.efl_forbidden', 'false');
  return eflFilterSwitch === 'true';
}

/**
 * Check if the string is empty.
 *
 * @param str - Entered string.
 * @returns true:is empty;false:not empty.
 */
export function isEmpty(str: string): boolean {
  return str === null || str === '';
}

/**
 * Obtains the singular-plural character string represented by the resource object string corresponding to the
 * specified number.
 *
 * @param { Resource } resource - Indicates the resource object.
 * @param { number } num - Indicates the number.
 * @returns { string } The singular-plural character string represented by the ID string
 *         corresponding to the specified number.
 */
export function getPluralStringValueSync(resource: Resource, num: number): string | undefined {
  const context = SimCardGlobalContextHelper.getInstance()
    .getValue<common.UIAbilityContext>(Constants.SIM_CARD_ABILITY_CONTEXT);
  if (typeof context !== 'undefined' && context !== null) {
    return context.resourceManager.getPluralStringValueSync(resource.id, num);
  }
  return undefined;
}

/**
 * Set whether the window can take screenshots
 *
 * @param isPrivacyMode - true:Can take screenshots;false:Screenshots cannot be taken.
 * @param tag - Log tag.
 */
export function setWindowPrivacyMode(isPrivacyMode: boolean, tag: string) {
  let session = LocalStorage.getShared()?.get<UIExtensionContentSession>('session');
  if (typeof session !== 'undefined' && session !== null) {
    try {
      session.setWindowPrivacyMode(isPrivacyMode);
    } catch (err) {
      LogUtils.e(tag, 'Failed to set the window to privacy mode.');
    }
  }
}

/**
 * Check whether the SkyTone function is enabled.
 *
 * @returns Indicates the VSim is enabled or not. Return true if VSim is enabled.
 */
export function isVSimEnabled(): boolean {
  let enabled: boolean = false;
  try {
    let vsimSwitch: String = SystemParameterEnhance.getSync('const.telephony.vsim_enabled', 'false');
    enabled = vsimSwitch === 'true';
  } catch (err) {
    LogUtils.e(TAG, 'isVSimEnabled err=' + JSON.stringify(err));
  }
  LogUtils.i(TAG, 'isVSimEnabled=' + enabled);
  return enabled;
}

/**
 * Close the soft keyboard.
 */
export async function closeSoftKeyboard() {
  try {
    let inputMethod = await DynamicLoader.getInstance().loadInputMethod();
    inputMethod.default.getController().stopInputSession();
  } catch (err) {
    LogUtils.e(TAG, 'closeSoftKeyboard err=' + JSON.stringify(err));
  }
}

/**
 * Obtains the left and right margins of a page based on the device type.
 *
 * @returns Inner margins of the page
 */
export function getPagePaddingByDeviceType(): Resource {
  return DeviceUtils.isTablet() ? $r('sys.float.padding_level12') : $r('sys.float.padding_level8');
}