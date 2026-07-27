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

import LogUtils from '../../common/utils/LogUtils';
import { common } from '@kit.AbilityKit';
import Settings from '@ohos.settings';
import SimServiceProxy from '../../model/simServiceProxy';
import { getPrimarySlotId, setPrimarySlotId } from '../../model/radioServiceProxy';
import call from '@ohos.telephony.call';
import { getMaxSimCount } from '../../model/registerSimStateApi';
import { MAX_SIM_COUNT, SATELLITE_STATE_ON, SIM_SLOT_COUNT_1, SLOT_1, SLOT_2 } from '../../common/utils/constant';
import SimStateConst from '../../common/utils/SimStateConst';
import { querySatellite } from '../../common/utils/SateToggleStateManager';

const TAG = 'SimCardUtil';
const AIR_PLANE_MODE: string = 'settings.telephony.airplanemode';
const AIR_PLANE_MODE_DEFAULT_VAL: string = '0';
const EMPTY_STRING: string = '';
const NUMBER_TWO: number = 2;

const SIM_STATE: Record<string, number> = {
  'SIM_STATE_UNKNOWN': 0,
  'SIM_STATE_NOT_PRESENT': 1,
  'SIM_STATE_LOCKED': 2,
  'SIM_STATE_NOT_READY': 3,
  'SIM_STATE_READY': 4,
  'SIM_STATE_LOADED': 5
};

/**
 * SIM卡操作工具类
 *
 * @since 2024-05-31
 */
export class SimCardUtil {
  private constructor() {
  }

  /**
   * Get Airplane Mode Status
   *
   * @returns
   */
  static isAirplaneActive(): boolean {
    let value: string =
      Settings.getValueSync((AppStorage.get<common.Context>('pageContext') as common.Context), AIR_PLANE_MODE,
        AIR_PLANE_MODE_DEFAULT_VAL);
    LogUtils.i(TAG, 'isAirplaneActive success: value:' + value);
    return !(value === AIR_PLANE_MODE_DEFAULT_VAL);
  }

  /**
   * Obtains the SIM card status of a card slot.
   *
   * @param slotId
   */
  static async getSimStateActive(slotId: number): Promise<boolean> {
    LogUtils.i(TAG, `getSimStateActive slotId is: ${slotId}`);
    let result: number;
    try {
      result = await SimServiceProxy.getSimState(slotId);
    } catch (e) {
      LogUtils.e(TAG, `getSimStateActive slotId ${slotId} error`);
      result = SIM_STATE.SIM_STATE_UNKNOWN;
    }
    return result === SIM_STATE.SIM_STATE_READY || result === SIM_STATE.SIM_STATE_LOADED;
  }

  /**
   * Obtains calling state.
   */
  static async getCallingState(): Promise<boolean> {
    LogUtils.i(TAG, 'getCallingState');
    let result: call.CallState;
    try {
      result = await call.getCallState();
    } catch (e) {
      LogUtils.e(TAG, 'getCallingState error');
      result = call.CallState.CALL_STATE_UNKNOWN;
    }
    return result === call.CallState.CALL_STATE_RINGING || result === call.CallState.CALL_STATE_OFFHOOK;
  }

  /**
   * SIM card switch status in a specified slot
   *
   * @param slotId card one ：0，card two ：1
   * @returns
   */
  static async isSimActive(slotId: number): Promise<boolean> {
    LogUtils.i(TAG, `isSimActive slotId ${slotId}`)
    let result: boolean;
    try {
      result = await SimServiceProxy.isSimActive(slotId);
    } catch (e) {
      LogUtils.e(TAG, `isSimActive slotId ${slotId} error`);
      result = false;
    }
    LogUtils.i(TAG, `isSimActive slotId ${slotId}, result ${result}`);
    return result;
  }

  /**
   * is dual-SIM device
   *
   * @returns
   */
  static isDualSimDevice(): boolean {
    return getMaxSimCount() === NUMBER_TWO;
  }

  /**
   * is dual-SIM card active
   *
   * @returns
   */
  static async isDualSimStateActive(): Promise<boolean> {
    const isSlotOneActive: boolean = await SimCardUtil.getSimStateActive(SLOT_1);
    const isSlotTwoActive: boolean = await SimCardUtil.getSimStateActive(SLOT_2);
    return isSlotOneActive && isSlotTwoActive;
  }

  /**
   * is dual-SIM active
   *
   * @returns
   */
  static async isDualSimActive(): Promise<boolean> {
    const isSimOneActive: boolean = await SimCardUtil.isSimActive(SLOT_1);
    const isSimTwoActive: boolean = await SimCardUtil.isSimActive(SLOT_2);
    return isSimOneActive && isSimTwoActive;
  }

  /**
   * check device is support getDefaultIntent
   *
   * @returns
   */
  static async isSupportGetDefaultMobileDataIntent(): Promise<boolean> {
    LogUtils.i(TAG, 'isSupportGetDefaultMobileDataIntent');
    if (!SimCardUtil.isDualSimDevice()) {
      LogUtils.e(TAG, 'isSupportGetDefaultMobileDataIntent :: this is not dual sim device');
      return false;
    }
    const isSlotOneActive: boolean = await SimCardUtil.getSimStateActive(SLOT_1);
    const isSlotTwoActive: boolean = await SimCardUtil.getSimStateActive(SLOT_2);
    if (!isSlotOneActive && !isSlotTwoActive) {
      LogUtils.e(TAG, 'isSupportGetDefaultMobileDataIntent :: dual sim is both unActive');
      return false;
    }
    return true;
  }

  /**
   * Turn on the SIM card switch.
   *
   * @param slotId
   * @returns
   */
  static async setSimActivate(slotId: number): Promise<boolean> {
    LogUtils.i(TAG, `setSimActivate slotId ${slotId}`);
    try {
      await SimServiceProxy.setSimActive(slotId, true);
    } catch (e) {
      LogUtils.i(TAG, `setSimActivate slotId ${slotId} error`);
      return Promise.reject(new Error(`setSimActivate slotId ${slotId} error`));
    }
    return true;
  }

  /**
   * Disabling the SIM card
   *
   * @param slotId
   * @returns
   */
  static async setSimDeactivate(slotId: number): Promise<boolean> {
    LogUtils.i(TAG, `setSimDeactivate slotId ${slotId}`);
    try {
      await SimServiceProxy.setSimActive(slotId, false);
    } catch (e) {
      LogUtils.e(TAG, `setSimDeactivate slotId ${slotId} error`);
      return Promise.reject(new Error(`setSimDeactivate slotId ${slotId} error`));
    }
    return true;
  }

  /**
   * Get Default Dialing Card
   *
   * @returns number
   */
  static async getDefaultVoiceSlotId(): Promise<number> {
    LogUtils.i(TAG, 'getDefaultVoiceSlotId');
    let result = -1;
    try {
      result = await SimServiceProxy.getDefaultVoiceSlotId();
    } catch (e) {
      LogUtils.e(TAG, 'getDefaultVoiceSlotId error ');
    }
    LogUtils.i(TAG, `getDefaultVoiceSlotId result ${result}`);
    return result
  }

  /**
   * Setting the Default Dialing Card
   *
   * @param slotId
   * @returns void
   */
  static async setDefaultVoiceSlotId(slotId: number): Promise<boolean> {
    LogUtils.i(TAG, `setDefaultVoiceSlotId slotId ${slotId}`);
    let result = true;
    try {
      await SimServiceProxy.setDefaultVoiceSlotId(slotId);
    } catch (e) {
      result = false;
      LogUtils.e(TAG, 'setDefaultVoiceSlotId error ');
    }
    LogUtils.i(TAG, `setDefaultVoiceSlotId slotId ${slotId}, result ${result}`);
    return result;
  }

  /**
   * Obtain the default mobile data card
   *
   * @returns number slot id
   */
  static async getPrimarySlotId(): Promise<number> {
    LogUtils.i(TAG, 'getPrimarySlotId');
    let result = -1;
    try {
      result = await getPrimarySlotId();
    } catch (e) {
      LogUtils.e(TAG, 'getPrimarySlotId error ');
    }
    LogUtils.i(TAG, `getPrimarySlotId result ${result}`);
    return result
  }

  /**
   * Setting the Default Mobile Data Card
   *
   * @param slotId
   * @returns void
   */
  static async setPrimarySlotId(slotId: number): Promise<boolean> {
    LogUtils.i(TAG, `setPrimarySlotId slotId ${slotId}`);
    let result = true;
    try {
      await setPrimarySlotId(slotId);
    } catch (e) {
      result = false;
      LogUtils.e(TAG, 'setDefaultVoiceSlotId error');
    }
    LogUtils.i(TAG, `setPrimarySlotId slotId ${slotId}, result ${result}`);
    return result;
  }

  /**
   * Obtains SIM card numbers.
   *
   * @param slotId
   * @returns
   */
  static async getPhoneCardNumber(slotId: number): Promise<string> {
    LogUtils.i(TAG, `getPhoneCardNumber slotId ${slotId}`);
    let result = EMPTY_STRING;
    try {
      result = await SimServiceProxy.getSimTelephoneNumber(slotId);
    } catch (e) {
      result = EMPTY_STRING;
      LogUtils.e(TAG, 'getPhoneCardNumber error ');
    }
    LogUtils.i(TAG, `getPhoneCardNumber slotId ${slotId}, result.length ${result.length}`);
    return result;
  }

  /**
   * 判断手机中是否有SIM卡
   *
   * @returns ture:至少有一张；false：一张都没有；
   */
  static async hasSim(): Promise<boolean> {
    try {
      const simCount = getMaxSimCount();
      if (simCount === SIM_SLOT_COUNT_1) {
        return await SimServiceProxy.hasSimCard(SLOT_1);
      } else if (simCount === MAX_SIM_COUNT) {
        return await SimServiceProxy.hasSimCard(SLOT_1) || await SimServiceProxy.hasSimCard(SLOT_2);
      } else {
        return false;
      }
    } catch (err) {
      LogUtils.e(TAG, 'hasSim error');
      return false;
    }
  }

  /**
   * 判断手机中是否有SIM卡是激活状态
   *
   * @returns ture:至少有一张SIM卡是激活状态；false：没有激活状态的SIM卡；
   */
  static async hasSimActivated(): Promise<boolean> {
    try {
      const simCount = getMaxSimCount();
      if (simCount === SIM_SLOT_COUNT_1) {
        return await SimServiceProxy.isSimActive(SLOT_1);
      } else if (simCount === MAX_SIM_COUNT) {
        return await SimServiceProxy.isSimActive(SLOT_1) || await SimServiceProxy.isSimActive(SLOT_2);
      } else {
        return false;
      }
    } catch (err) {
      LogUtils.e(TAG, 'hasSimActivated error');
      return false;
    }
  }

  /**
   * 判断是否所有的SIM卡都是UNKNOWN状态
   *
   * @returns ture:所有的SIM卡都是UNKNOWN状态；false：至少一张SIM卡不是UNKNOWN状态；
   */
  static async isAllSimUnknown(): Promise<boolean> {
    try {
      const simCount = getMaxSimCount();
      if (simCount === SIM_SLOT_COUNT_1) {
        return await SimServiceProxy.getSimState(SLOT_1) === SimStateConst.SIM_STATE_UNKNOWN
      } else if (simCount === MAX_SIM_COUNT) {
        return await SimServiceProxy.getSimState(SLOT_1) === SimStateConst.SIM_STATE_UNKNOWN &&
          await SimServiceProxy.getSimState(SLOT_2) === SimStateConst.SIM_STATE_UNKNOWN;
      } else {
        return false;
      }
    } catch (err) {
      LogUtils.e(TAG, 'isAllSimUnknown error');
      return false;
    }
  }

  /**
   * 查询卫星通信状态
   *
   * @param context - 上下文
   * @returns - true：卫星通信开启；false:卫星通信关闭
   */
  static async isSatelliteStateOn(context: Context): Promise<boolean> {
    return await new Promise((resolve: (result: boolean) => void) => {
      querySatellite(context, (data: number) => {
        resolve(data === SATELLITE_STATE_ON);
      })
    });
  }
}