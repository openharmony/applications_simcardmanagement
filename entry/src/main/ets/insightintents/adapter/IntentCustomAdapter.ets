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

import insightIntent from '@ohos.app.ability.insightIntent';
import LogUtils from '../../common/utils/LogUtils';
import { isEmpty } from '../../common/utils/Utils';
import pinModel from '../../model/pinModel';
import { getMaxSimCount } from '../../model/registerSimStateApi';
import { SimServiceProxy } from '../../model/simServiceProxy';
import { ERROR_MSG, IntentCodeConstants, SettingItems } from '../constant/IntentCodeConstant';
import { SimCardUtil } from '../util/SimCardUtil';

const TAG: string = 'IntentCustomAdaptor';
const SIM_CARD_MANAGEMENT_ENTRY: string = 'sim_card_management_entry';

const SIM_ONE_SLOT_ID: number = 0;
const SIM_TWO_SLOT_ID: number = 1;

const SWITCH_ON: number = 0;
const SWITCH_OFF: number = 1;


/**
 * Intention Framework Operation Setting Switch Transfer Class - Customized Setting Intention
 *
 * @since 2024-05-29
 */
export class IntentCustomAdaptor {
  private constructor() {
  }

  /**
   * Check whether the setting page are exist.
   *
   * @param entryKey settings page entry key
   * @param appBundleName app bundle name
   * @returns
   */
  static async checkSettingPage(entryKey: string, appBundleName: string): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, `checkSettingPage intent entryKey is ${entryKey}, appBundleName is ${appBundleName}`);
    let isSupport: boolean = false;
    if (entryKey === SIM_CARD_MANAGEMENT_ENTRY) {
      isSupport = true;
    }
    let rsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_SUCCESS,
      result: {
        'entryKey': entryKey,
        'appBundleName': appBundleName,
        'isSupport': isSupport
      }
    }
    return rsp;
  }

  /**
   * Obtain the default mobile data card
   *
   * @returns
   */
  static async getDefaultMobileDataSimCard(): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, 'getDefaultMobileDataSimCard');
    if (!await SimCardUtil.isSupportGetDefaultMobileDataIntent()) {
      LogUtils.e(TAG, 'getDefaultMobileDataSimCard :: do not support getDefaultIntent');
      return IntentCustomAdaptor.buildDefaultUnSupportResult();
    }
    let resultSlotId = await SimCardUtil.getPrimarySlotId();
    if (resultSlotId === SIM_ONE_SLOT_ID || resultSlotId === SIM_TWO_SLOT_ID) {
      let defaultRsp: insightIntent.ExecuteResult = {
        code: IntentCodeConstants.DEFAULT_CODE_SUCCESS,
        result: { slotId: String(resultSlotId) }
      }
      LogUtils.i(TAG, 'getDefaultMobileDataSimCard success');
      return defaultRsp;
    }
    let errorRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_FAILED,
      result: {
        errMsg: ERROR_MSG[IntentCodeConstants.DEFAULT_CODE_FAILED]
      }
    }
    return errorRsp;
  }

  /**
   * Setting the Default Mobile Data Card
   *
   * @param slotId
   * @returns
   */
  static async setDefaultMobileDataSimCard(slotId: number): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, 'setDefaultMobileDataSimCard');
    if (!SimCardUtil.isDualSimDevice()) {
      LogUtils.e(TAG, 'setDefaultMobileDataSimCard :: do not support getDefaultDialingSimCard');
      return IntentCustomAdaptor.buildDefaultUnSupportResult();
    }
    if (!await SimCardUtil.isDualSimStateActive()) {
      LogUtils.e(TAG, 'setDefaultMobileDataSimCard :: neither sim state is active');
      return IntentCustomAdaptor.buildDefaultUnSupportResult();
    }
    if (!await SimCardUtil.isDualSimActive()) {
      LogUtils.e(TAG, 'setDefaultMobileDataSimCard :: neither sim is active');
      return IntentCustomAdaptor.buildDefaultUnSupportResult();
    }
    const checkRsp = await IntentCustomAdaptor.checkSimSwitch(slotId);
    if (!IntentCustomAdaptor.isSupport(checkRsp)) {
      LogUtils.e(TAG, 'setDefaultMobileDataSimCard  unSupported');
      return checkRsp;
    }
    let result = await SimCardUtil.setPrimarySlotId(slotId);
    if (result) {
      let defaultRsp: insightIntent.ExecuteResult = {
        code: IntentCodeConstants.DEFAULT_CODE_SUCCESS,
        result: { slotId: String(slotId) }
      }
      LogUtils.i(TAG, 'setDefaultMobileDataSimCard success');
      return defaultRsp;
    }
    let errorRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_FAILED,
      result: {
        errMsg: ERROR_MSG[IntentCodeConstants.DEFAULT_CODE_FAILED]
      }
    }
    return errorRsp;
  }

  /**
   * Get Default Dialing Card
   *
   * @returns
   */
  static async getDefaultDialingSimCard(): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, 'getDefaultDialingSimCard');
    if (!SimCardUtil.isDualSimDevice()) {
      LogUtils.e(TAG, 'getDefaultDialingSimCard :: this is not dual sim device');
      return IntentCustomAdaptor.buildDefaultUnSupportResult();
    }

    let resultSlotId = await SimCardUtil.getDefaultVoiceSlotId();
    if (resultSlotId === SIM_ONE_SLOT_ID || resultSlotId === SIM_TWO_SLOT_ID) {
      let defaultRsp: insightIntent.ExecuteResult = {
        code: IntentCodeConstants.DEFAULT_CODE_SUCCESS,
        result: { slotId: String(resultSlotId) }
      }
      LogUtils.i(TAG, 'getDefaultDialingSimCard success');
      return defaultRsp;
    }
    let errorRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.NO_DEFAULT_CALLING_CARD,
      result: {
        errMsg: ERROR_MSG[IntentCodeConstants.NO_DEFAULT_CALLING_CARD]
      }
    }
    return errorRsp;
  }

  /**
   * Setting the Default Dialing Card
   *
   * @param slotId
   * @returns
   */
  static async setDefaultDialingSimCard(slotId: number): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, 'setDefaultDialingSimCard');
    if (!SimCardUtil.isDualSimDevice()) {
      LogUtils.e(TAG, 'setDefaultDialingSimCard :: this is not dual sim device');
      return IntentCustomAdaptor.buildDefaultUnSupportResult();
    }
    if (!await SimCardUtil.isDualSimStateActive()) {
      LogUtils.e(TAG, 'setDefaultDialingSimCard :: neither sim state is active');
      return IntentCustomAdaptor.buildDefaultUnSupportResult();
    }
    if (!await SimCardUtil.isDualSimActive()) {
      LogUtils.e(TAG, 'setDefaultDialingSimCard :: neither sim is active');
      return IntentCustomAdaptor.buildDefaultUnSupportResult();
    }
    const checkRsp = await IntentCustomAdaptor.checkSimSwitch(slotId);
    if (!IntentCustomAdaptor.isSupport(checkRsp)) {
      LogUtils.e(TAG, 'setDefaultDialingSimCard :: checkSimSwitch is unSupported');
      return checkRsp;
    }
    let result = await SimCardUtil.setDefaultVoiceSlotId(slotId);
    if (result) {
      let defaultRsp: insightIntent.ExecuteResult = {
        code: IntentCodeConstants.DEFAULT_CODE_SUCCESS,
        result: { slotId: String(slotId) }
      }
      LogUtils.i(TAG, 'setDefaultDialingSimCard success');
      return defaultRsp;
    }
    let errorRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_FAILED,
      result: {
        errMsg: ERROR_MSG[IntentCodeConstants.DEFAULT_CODE_FAILED]
      }
    }
    return errorRsp;
  }

  /**
   * Obtaining the Card Number
   *
   * @param slotId
   * @returns
   */
  static async getPhoneCardNumber(slotId: number): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, 'getPhoneCardNumber');
    const checkRsp = await IntentCustomAdaptor.checkSimSwitch(slotId);
    if (!IntentCustomAdaptor.isSupport(checkRsp)) {
      LogUtils.e(TAG, 'getPhoneCardNumber :: checkSimSwitch is unSupported');
      return checkRsp;
    }
    let resultPhoneNumber = await SimCardUtil.getPhoneCardNumber(slotId);
    if (!isEmpty(resultPhoneNumber)) {
      let defaultRsp: insightIntent.ExecuteResult = {
        code: IntentCodeConstants.DEFAULT_CODE_SUCCESS,
        result: {
          slotId: String(slotId),
          carNumber: resultPhoneNumber
        }
      }
      LogUtils.i(TAG, 'getPhoneCardNumber success');
      return defaultRsp;
    }
    let errorRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_FAILED,
      result: {
        errMsg: ERROR_MSG[IntentCodeConstants.DEFAULT_CODE_FAILED]
      }
    }
    return errorRsp;

  }

  /**
   * Checking the SIM Card Status
   *
   * @param slotId
   * @returns
   */
  static async checkSimSwitch(slotId: number): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, `checkSimSwitch slotId ${slotId}`);
    let code: number = IntentCodeConstants.DEFAULT_CODE_SUCCESS;
    let isSupport: boolean = true;
    let isActive: boolean = await SimCardUtil.getSimStateActive(slotId);
    if (!isActive) {
      code = IntentCodeConstants.NO_SIM_CARD;
      isSupport = false;
      return IntentCustomAdaptor.buildExecuteResult(slotId, code, isSupport);
    }
    let isAirPlaneActive: boolean = SimCardUtil.isAirplaneActive();
    if (isAirPlaneActive) {
      code = IntentCodeConstants.LIMITED_BY_AIRPLANE_MODE;
      isSupport = false;
      return IntentCustomAdaptor.buildExecuteResult(slotId, code, isSupport);
    }
    let isCalling: boolean = await SimCardUtil.getCallingState();
    if (isCalling) {
      code = IntentCodeConstants.DEFAULT_CODE_FAILED;
      isSupport = false;
      return IntentCustomAdaptor.buildExecuteResult(slotId, code, isSupport);
    }
    return IntentCustomAdaptor.buildExecuteResult(slotId, code, isSupport);
  }

  /**
   * Obtains the SIM card switch status.
   *
   * @param slotId
   * @returns
   */
  static async getSimSwitch(slotId: number): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, `getSimSwitch,slotId: ${slotId}`);
    const checkRsp = await IntentCustomAdaptor.checkSimSwitch(slotId);
    if (!IntentCustomAdaptor.isSupport(checkRsp)) {
      LogUtils.e(TAG, 'getSimSwitch :: checkSimSwitch is unSupported');
      return checkRsp;
    }
    let switchFlag: number = await SimCardUtil.isSimActive(slotId) ? SWITCH_ON : SWITCH_OFF;
    let rsp: Record<string, Object> = {
      'slotId': String(slotId),
      'switchFlag': switchFlag,
    }
    let defaultRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_SUCCESS,
      result: rsp
    }
    return defaultRsp;
  }

  static async handleCheckSettingItem(itemName: string): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, `handleCheckSettingItem`);
    let defaultRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_SUCCESS,
      result: {
        'itemName': itemName,
        'isSupport': false,
      }
    }
    return defaultRsp;
  }

  /**
   * Sets the SIM card switch status.
   *
   * @param itemName
   * @param appBundleName
   * @param switchFlag
   * @param slotId
   * @returns
   */
  static async setSimSwitch(switchFlag: number, slotId: number): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, `setSimSwitch, switchFlag: ${switchFlag}, slotId: ${slotId}`);
    const checkRsp = await IntentCustomAdaptor.checkSimSwitch(slotId);
    if (!IntentCustomAdaptor.isSupport(checkRsp)) {
      LogUtils.e(TAG, 'setSimSwitch :: checkSimSwitch is unSupported');
      return checkRsp;
    }
    let rsp: Record<string, Object> = {
      'switchFlag': switchFlag,
      'slotId': String(slotId),
    }
    let defaultRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_SUCCESS,
      result: rsp,
    }
    let isSwitchOn: boolean = await SimCardUtil.isSimActive(slotId);
    if (switchFlag === SWITCH_ON) {
      if (isSwitchOn) {
        LogUtils.i(TAG, `simSwitch: ${slotId} has already turn on`);
        return defaultRsp;
      } else {
        if (await SimCardUtil.setSimActivate(slotId)) {
          LogUtils.i(TAG, ` simSwitch: ${slotId} turn on success`);
          return defaultRsp;
        }
      }
    } else if (switchFlag === SWITCH_OFF) {
      if (!isSwitchOn) {
        LogUtils.i(TAG, ` simSwitch: ${slotId} has already turn off`);
        return defaultRsp;
      } else {
        if (await SimCardUtil.setSimDeactivate(slotId)) {
          LogUtils.i(TAG, ` simSwitch: ${slotId} turn off success`);
          return defaultRsp;
        }
      }
    }
    let errorRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED,
      result: {
        errMsg: ERROR_MSG[IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED]
      },
    }
    return errorRsp;
  }

  private static buildDefaultUnSupportResult() : insightIntent.ExecuteResult {
    const unSupportRsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED,
      result: {
        errMsg: ERROR_MSG[IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED]
      }
    }
    return unSupportRsp;
  }

  private static buildExecuteResult(slotId: number, code: number, isSupport: boolean): insightIntent.ExecuteResult {
    let rsp: insightIntent.ExecuteResult = {
      code: code,
      result: {
        'slotId': String(slotId),
        'isSupport': isSupport
      }
    }
    return rsp;
  }

  private static isSupport(rsp: insightIntent.ExecuteResult): boolean {
    return (rsp && rsp.code === 0 && rsp.result?.isSupport) as boolean;
  }

  private static buildCheckItemResult(code: number, itemName: string,
    isSupported: boolean): insightIntent.ExecuteResult {
    let defaultRsp: insightIntent.ExecuteResult = {
      code: code,
      result: {
        'itemName': itemName,
        'isSupport': isSupported,
      }
    }
    return defaultRsp;
  }
}


