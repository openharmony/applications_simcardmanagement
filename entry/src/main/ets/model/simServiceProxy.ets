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

/**
 * @file: SIM card service interface
 */

import sim from '@ohos.telephony.sim';
import { BusinessError } from '@ohos.base';
import LogUtils from '../common/utils/LogUtils';
import { isEmpty } from '../common/utils/Utils';
import { LockType, TELECOM_PLMN } from '../common/utils/constant';
import SimStateConst from '../common/utils/SimStateConst';
import pinModel from './pinModel';

const TAG = 'SimServiceProxy';

export class SimServiceProxy {
  private searchHasSimCard(slotId: number, resolve: (value: boolean) => void = () => {},
    reject: (error: BusinessError<void>) => void = () => {}) {
    sim.hasSimCard(slotId, (error, data) => {
      if (error) {
        LogUtils.e(TAG, 'hasSimCard error card : ' + JSON.stringify(slotId) + '  ' + JSON.stringify(error));
        reject(error);
        return;
      }
      LogUtils.i(TAG, 'hasSimCard data card : ' + JSON.stringify(slotId) + '  ' + JSON.stringify(data));
      resolve(data);
    });
  }

  /**
   * is has simcard
   *
   * @param  {number} slotId - slot ID
   * @return {Promise}
   */
  hasSimCard(slotId = 0) {
    return new Promise((resolve: (value: boolean) => void, reject: (reason?: BusinessError) => void) => {
      try {
        this.searchHasSimCard(slotId, resolve, reject);
      } catch (error) {
        LogUtils.e(TAG, 'hasSimCard catch card : ' + JSON.stringify(slotId) + '  ' + JSON.stringify(error));
        reject(error);
      }
    });
  }

  private doGetSimSpn(slotId: number, resolve: (value: string) => void = () => {},
     reject: (error: BusinessError<void>) => void = () => {}) {
    sim.getSimSpn(slotId, (error, value) => {
      if (error) {
        LogUtils.e(TAG, 'getSimSpn error:' + JSON.stringify(error));
        reject(error);
        return;
      }
      LogUtils.i(TAG, 'getSimSpn data:' + JSON.stringify(value));
      resolve(value);
    });
  }

  /**
   * Get simSpn
   *
   * @param  {number} slotId - slot ID
   * @return {Promise}
   */
  getSimSpn(slotId = 0) {
    return new Promise((resolve: (value: string) => void, reject: (reason?: BusinessError) => void) => {
      try {
        this.doGetSimSpn(slotId, resolve, reject);
      } catch (error) {
        LogUtils.e(TAG, 'hasSimCard catch:' + JSON.stringify(error));
        reject(error);
      }
    });
  }

  private doGetSimTelephoneNumber(slotId: number, resolve: (value: string) => void = () => {},
                                  reject: (error: BusinessError<void>) => void = () => {}) {
    sim.getSimTelephoneNumber(slotId, (error, value) => {
      if (error) {
        LogUtils.e(TAG, `get number from impu slotId= ${slotId},error: ${JSON.stringify(error)}`);
        reject(error);
        return;
      }
      let isNumberEmpty = isEmpty(value);
      LogUtils.i(TAG, `get number from impu slotId= ${slotId},isEmpty: ${JSON.stringify(isNumberEmpty)}`);
      resolve(value);
    });
  }

  /**
   * Get sim telephone number
   *
   * @param  {number} slotId - slot ID
   * @return {Promise}
   */
  getSimTelephoneNumber(slotId = 0) {
    return new Promise((resolve: (value: string) => void, reject: (reason?: BusinessError) => void) => {
      try {
        this.doGetSimTelephoneNumber(slotId, resolve, reject);
      } catch (error) {
        LogUtils.e(TAG, `get number from impu slotId= ${slotId},catch: ${JSON.stringify(error)}`);
        reject(error);
      }
    });
  }

  private searchIsSimActive(slotId: number, resolve: (value: boolean) => void = () => {},
    reject: (error: BusinessError<void>) => void = () => {}) {
    sim.isSimActive(slotId, (error, value) => {
      if (error) {
        LogUtils.e(TAG, 'isSimActive error slotId: ' + JSON.stringify(slotId) + ' ' + JSON.stringify(error));
        reject(error);
        return;
      }
      LogUtils.i(TAG, 'isSimActive data slotId: ' + JSON.stringify(slotId) + ' ' + JSON.stringify(value));
      resolve(value);
    });
  }

  /**
   * Is sim active
   *
   * @param  {number} slotId - slot ID
   * @return {Promise}
   */
  isSimActive(slotId = 0) {
    return new Promise((resolve: (value: boolean) => void, reject: (reason?: BusinessError) => void) => {
      try {
        this.searchIsSimActive(slotId, resolve, reject);
      } catch (error) {
        LogUtils.e(TAG, 'isSimActive catch slotId: ' + JSON.stringify(slotId) + ' ' + JSON.stringify(error));
        reject(error);
      }
    });
  }

  /**
   * Whether the SIM card is activated.
   *
   * @param slotId - ID of the SIM card slot to be checked.
   * @returns ture:Activated;false:deactivated.
   */
  isSimActivatedSync(slotId: number): boolean {
    try {
      let isSimActived = sim.isSimActiveSync(slotId);
      LogUtils.i(TAG, `isSimActivatedSync slotId=${JSON.stringify(slotId)},res=${JSON.stringify(isSimActived)}`);
      return isSimActived;
    } catch (err) {
      LogUtils.e(TAG, 'isSimActivatedSync err=' + JSON.stringify(err));
      return false;
    }
  }

  public async getSimState(slotId = 0): Promise<number> {
    try {
      let res = await sim.getSimState(slotId);
      LogUtils.i(TAG, 'getSimState data:' + JSON.stringify(slotId) + ' data: ' + JSON.stringify(res));
      if (res === SimStateConst.SIM_STATE_LOCKED) {
        let lockType = await pinModel.getSimLockType(slotId);
        if (lockType === LockType.PUK_LOCK) {
          let attempts = await pinModel.getPinRemainAttempts(slotId, LockType.PUK_LOCK);
          if (attempts <= 0) {
            res = SimStateConst.SIM_STATE_NOT_PRESENT;
          }
        }
      }
      return res;
    } catch (err) {
      LogUtils.e(TAG, 'getSimState card :' + JSON.stringify(slotId) + ' error: ' + JSON.stringify(err));
      return err;
    }
  }

  private doGetDefaultVoiceSlotId(resolve: (value: sim.SimState) => void = () => {},
    reject: (error: BusinessError<void>) => void = () => {}) {
    sim.getDefaultVoiceSlotId((error, value) => {
      if (error) {
        LogUtils.e(TAG, 'getDefaultVoiceSlotId error:' + JSON.stringify(error));
        reject(error);
        return;
      }
      LogUtils.i(TAG, 'getDefaultVoiceSlotId data:' + JSON.stringify(value));
      resolve(value);
    });
  }

  /**
   * Get default voiceSlotId
   *
   * @return {Promise}
   */
  getDefaultVoiceSlotId() {
    return new Promise((resolve: (value: number) => void, reject: (reason?: BusinessError) => void) => {
      try {
        this.doGetDefaultVoiceSlotId(resolve, reject);
      } catch (error) {
        LogUtils.e(TAG, 'getDefaultVoiceSlotId catch:' + JSON.stringify(error));
        reject(error);
      }
    });
  }

  private doSetDefaultVoiceSlotId(slotId: number, resolve: (value: boolean) => void = () => {},
                          reject: (error: BusinessError<void>) => void = () => {}) {
    sim.setDefaultVoiceSlotId(slotId, (error, data) => {
      if (error) {
        LogUtils.e(TAG, 'setDefaultVoiceSlotId error:' + JSON.stringify(slotId) + ' ' + JSON.stringify(error));
        reject(error);
        return;
      }
      LogUtils.i(TAG, 'setDefaultVoiceSlotId data:' + JSON.stringify(slotId) + ' ' + JSON.stringify(data));
      resolve(true);
    });
  }

  /**
   * Set default voiceSlotId
   *
   * @param  {number} slotId - slot ID
   * @return {Promise}
   */
  setDefaultVoiceSlotId(slotId = 0) {
    return new Promise((resolve: (value: boolean) => void, reject: (reason?: BusinessError) => void) => {
      try {
        this.doSetDefaultVoiceSlotId(slotId, resolve, reject);
      } catch (error) {
        LogUtils.e(TAG, 'setDefaultVoiceSlotId catch:' + JSON.stringify(slotId) + ' ' + JSON.stringify(error));
        reject(error);
      }
    });
  }

  private doActivateSim(slotId: number, bool: boolean, resolve: (value: boolean) => void = () => {},
                reject: (error: BusinessError<void>) => void = () => {}) {
    sim.activateSim(slotId, (error) => {
      if (error) {
        LogUtils.e(TAG, 'activateSim error:' + JSON.stringify(error));
        reject(error);
        return;
      }
      LogUtils.i(TAG, 'activateSim data:' + JSON.stringify(bool));
      resolve(true);
    });
  }

  private doDeActivateSim(slotId: number, bool: boolean, resolve: (value: boolean) => void = () => {},
                reject: (error: BusinessError<void>) => void = () => {}) {
    sim.deactivateSim(slotId, (error) => {
      if (error) {
        LogUtils.e(TAG, 'activateSim error:' + JSON.stringify(error));
        reject(error);
        return;
      }
      LogUtils.i(TAG, 'activateSim data:' + JSON.stringify(bool));
      resolve(false);
    });
  }

  /**
   * Set sim active
   *
   * @param  {number} slotId - slot ID
   * @param  {boolean} bool - Is SIM card activated
   * @return {Promise}
   */
  setSimActive(slotId = 0, bool: boolean) {
    if (bool) {
      return new Promise((resolve: (value: boolean) => void, reject: (reason?: BusinessError) => void) => {
        try {
          this.doActivateSim(slotId, bool, resolve, reject);
        } catch (error) {
          LogUtils.e(TAG, 'activateSim catch:' + JSON.stringify(error));
          reject(error);
        }
      });
    } else {
      return new Promise((resolve: (value: boolean) => void, reject: (reason?: BusinessError) => void) => {
        try {
          this.doDeActivateSim(slotId, bool, resolve, reject);
        } catch (error) {
          LogUtils.e(TAG, 'deactivateSim catch:' + JSON.stringify(error));
          reject(error);
        }
      });
    }
  }

  private doSetShowName(slotId: number, name: string, resolve: (value: boolean) => void = () => {},
                  reject: (error: BusinessError<void>) => void = () => {}) {
    sim.setShowName(slotId, name, (error) => {
      if (error) {
        LogUtils.e(TAG, 'setShowName slotId=' + slotId + ',error:' + JSON.stringify(error));
        reject(error);
        return;
      }
      LogUtils.i(TAG, 'setShowName success,slotId=' + slotId);
      resolve(true);
    });
  }

  /**
   * Set show name
   *
   * @param  {number} slotId - slot ID
   * @param  {string} name - name Value
   * @return {Promise}
   */
  setShowName(slotId = 0, name = '') {
    const isNameEmpty = isEmpty(name);
    LogUtils.i(TAG, 'setShowName slotId=' + slotId + ',isNameEmpty:' + JSON.stringify(isNameEmpty));
    return new Promise((resolve: (value: boolean) => void, reject: (reason?: BusinessError) => void) => {
      try {
        this.doSetShowName(slotId, name, resolve, reject);
      } catch (error) {
        LogUtils.e(TAG, 'setShowName slotId=' + slotId + ',catch:' + JSON.stringify(error));
        reject(error);
      }
    });
  }

  private doGetShowName(slotId:number, resolve: (value: string) => void = () => {},
    reject: (error: BusinessError<void>) => void = () => {}) {
    sim.getShowName(slotId, (error, value) => {
      if (error) {
        LogUtils.e(TAG, 'getShowName error:' + JSON.stringify(error) + ',slotId=' + slotId);
        reject(error);
        return;
      }
      const isNameEmpty = isEmpty(value);
      LogUtils.i(TAG, 'getShowName isNameEmpty:' + JSON.stringify(isNameEmpty) + ',slotId=' + slotId);
      resolve(value);
    });
  }

  /**
   * Get show name
   *
   * @param  {number} slotId - slot ID
   * @return {Promise}
   */
  getShowName(slotId = 0) {
    return new Promise((resolve: (value: string) => void, reject: (reason?: BusinessError) => void) => {
      try {
        this.doGetShowName(slotId, resolve, reject)
      } catch (error) {
        LogUtils.e(TAG, 'getShowName catch:' + JSON.stringify(error) + ',slotId=' + slotId);
        reject(error);
      }
    });
  }

  private doSetShowNumber(slotId:number, phonenumber: string, resolve: (value: boolean) => void = () => {},
                  reject: (error: BusinessError<void>) => void = () => {}) {
    sim.setShowNumber(slotId, phonenumber, (error) => {
      if (error) {
        LogUtils.e(TAG, 'setShowNumber slotId=' + slotId + ',error:' + JSON.stringify(error));
        reject(error);
        return;
      }
      LogUtils.i(TAG, 'setShowNumber success,slotId=' + slotId);
      resolve(true);
    });
  }

  /**
   * Set show number
   *
   * @param  {number} slotId - slot ID
   * @param  {string} number - phone number
   * @return {Promise}
   */
  setShowNumber(slotId = 0, phonenumber = '') {
    return new Promise((resolve: (value: boolean) => void, reject: (reason?: BusinessError) => void) => {
      try {
        this.doSetShowNumber(slotId, phonenumber, resolve, reject);
      } catch (error) {
        LogUtils.e(TAG, 'setShowNumber slotId=' + slotId + ',catch:' + JSON.stringify(error));
        reject(error);
      }
    });
  }

  private doGetShowNumber(slotId:number, resolve: (value: string) => void = () => {},
    reject: (error: BusinessError<void>) => void = () => {}) {
    sim.getShowNumber(slotId, (error, value) => {
      if (error) {
        LogUtils.e(TAG, 'getShowNumber slotId=' + slotId + ',error:' + JSON.stringify(error));
        reject(error);
        return;
      }
      let isNumberEmpty = isEmpty(value);
      LogUtils.i(TAG, 'getShowNumber slotId=' + slotId + ',isEmpty=' + JSON.stringify(isNumberEmpty));
      resolve(value);
    });
  }

  /**
   * Get show number
   *
   * @param  {number} slotId - slot ID
   * @return {Promise}
   */
  getShowNumber(slotId = 0) {
    return new Promise((resolve: (value: string) => void, reject: (reason?: BusinessError) => void) => {
      try {
        this.doGetShowNumber(slotId, resolve, reject)
      } catch (error) {
        LogUtils.e(TAG, 'getShowNumber slotId=' + slotId + ',catch:' + JSON.stringify(error));
        reject(error);
      }
    });
  }

  /**
   * Check whether the SIM card belongs to China Telecom.
   *
   * @param {number} slotId - Card slot ID.
   * @returns {boolean} - true:It's China Telecom;false:Not China Telecom.
   */
  isChinaTelecomSim(slotId: number): boolean {
    let plmn = sim.getSimOperatorNumericSync(slotId);
    return TELECOM_PLMN.includes(plmn);
  }
}

let mSimServiceProxy = new SimServiceProxy();
export default mSimServiceProxy as SimServiceProxy;