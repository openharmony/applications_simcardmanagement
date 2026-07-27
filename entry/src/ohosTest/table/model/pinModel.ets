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
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
import LogUtils from '../common/utils/LogUtils';
import {
  DEFAULT_PIN,
  DEFAULT_PIN_REMAIN,
  DEFAULT_PUK_REMAIN,
  LockType,
  PIN_MIN_LENGTH,
  PinSavingScenario,
  SimLockTypeName,
  UNLOCK_SUCCEED
} from '../common/utils/constant';
import account_osAccount from '@ohos.account.osAccount';
import { isEmpty } from '../common/utils/Utils';
import { PinInfoResp, PinResp, RespCode } from '../data/ResponseInfo';
import { DynamicLoader } from '../utils/DynamicLoader';
import { observer, sim } from '@kit.TelephonyKit';

const TAG = 'pinModel';

class PinModel {
  /**
   * Obtains all states required by the SIM card protection page.
   *
   * @param slotId - The card slot index number.
   * @returns All Statuses
   */
  public async getAllState(slotId: number): Promise<PinInfoResp> {
    let resp = new PinInfoResp();
    try {
      resp.lockType = await this.getSimLockType(slotId);
      resp.isRemembered = await this.getPinRememberedState(slotId);
      LogUtils.i(TAG, `getAllState slotId=${slotId},res->${JSON.stringify(resp)}`);
    } catch (err) {
      LogUtils.e(TAG, `getAllState slotId=${slotId},error->${JSON.stringify(err)}`);
    }
    return resp;
  }

  /**
   * Obtains the SIM card lock type.
   *
   * @param slotId - SIM slot ID.
   * @returns SIM card lock type.
   */
  public async getSimLockType(slotId: number): Promise<LockType> {
    let pinLockType: LockType = LockType.NOT_LOCKED;
    try {
      const simState = sim.getSimStateSync(slotId);
      if (simState === sim.SimState.SIM_STATE_LOCKED) {
        let remainTimes = await this.getPinRemainAttempts(slotId, LockType.PIN_LOCK);
        pinLockType = remainTimes <= 0 ? LockType.PUK_LOCK : LockType.PIN_LOCK;
      } else {
        let lockState: sim.LockState = await sim.getLockState(slotId, sim.LockType.PIN_LOCK);
        LogUtils.i(TAG, `getSimLockType pin success, slotId=${slotId},data->${JSON.stringify(lockState)}`);
        pinLockType = lockState !== sim.LockState.LOCK_OFF ? LockType.PIN_LOCK : pinLockType;
        if (pinLockType === LockType.PIN_LOCK) {
          let remainTimes = await this.getPinRemainAttempts(slotId, pinLockType);
          pinLockType = remainTimes <= 0 ? LockType.PUK_LOCK : pinLockType;
        }
      }
    } catch (err) {
      LogUtils.e(TAG, `getSimLockType pin failed, slotId=${slotId},error->${JSON.stringify(err)}`);
    }
    LogUtils.i(TAG, `getSimLockType slotId=${slotId},pinLockType=${pinLockType}`);
    return pinLockType;
  }

  /**
   * Change PIN.
   *
   * @param slotId - The card slot index number.
   * @param oldPin - The old pin.
   * @param newPin - The new pin.
   * @returns Result of changing the PIN.
   */
  public async changePin(slotId: number, oldPin: string, newPin: string): Promise<PinResp> {
    let pinResp = new PinResp();
    try {
      let alterPinResp = await sim.alterPin(slotId, newPin, oldPin);
      LogUtils.i(TAG, `changePin slotId= ${slotId},res->${JSON.stringify(alterPinResp)}`);
      if (!alterPinResp) {
        return pinResp;
      }
      if (alterPinResp.result !== 0) {
        pinResp.remainTimes = await this.getPinRemainAttempts(slotId, LockType.PIN_LOCK);
        pinResp.code = RespCode.CHANGE_PIN_ERROR;
        return pinResp;
      }
      pinResp.isSucceed = true;
      pinResp.code = RespCode.SUCCEED;
    } catch (err) {
      LogUtils.e(TAG, `changePin slotId=${slotId},error->${JSON.stringify(err)}`);
    }
    return pinResp;
  }

  /**
   * Obtains the number of remaining PIN attempts.
   *
   * @param slotId - The card slot index number.
   * @param lockTypeName - Name of the lock type,Defined in SimLockTypeName.
   * @param lockType - Type of lock.
   * @returns Attempts remaining.
   */
  public async getPinRemainAttempts(slotId: number, lockType: LockType): Promise<number> {
    if (lockType === LockType.NOT_LOCKED) {
      return 0;
    }
    const slotNum = slotId + 1;
    const name = lockType === LockType.PIN_LOCK ? SimLockTypeName.PIN : SimLockTypeName.PUK;
    const propKey: string = `ril.gsm.slot${slotNum}.num.${name}1`;
    const defaultVal: number = name === SimLockTypeName.PIN ? DEFAULT_PIN_REMAIN : DEFAULT_PUK_REMAIN;
    const systemParameter = await DynamicLoader.getInstance().loadSystemParameter();
    const attempts: string = systemParameter.default.getSync(propKey, defaultVal.toString());
    LogUtils.i(TAG, `slotId=${slotId},lockTypeName=${name},propKey=${propKey},available=${attempts}`)
    return Number.parseInt(attempts);
  }

  /**
   * Verify PUK and reset PIN.
   *
   * @param slotId - SIM slot ID.
   * @param puk - PUK of SIM.
   * @param newPin - New PIN to set.
   * @returns Operation result.
   */
  public async verifyPukAndResetPin(slotId: number, puk: string, newPin: string): Promise<PinResp> {
    let pukResp: PinResp = new PinResp();
    try {
      let res = await sim.unlockPuk(slotId, newPin, puk);
      if (res && res.result === UNLOCK_SUCCEED) {
        let isRemembered = await this.getPinRememberedState(slotId);
        if (isRemembered) {
          return await this.changePinWhenRemembered(slotId, newPin);
        }
        pukResp.isSucceed = true;
        pukResp.code = RespCode.SUCCEED;
      } else if (res && typeof res.remain !== 'undefined') {
        pukResp.isSucceed = false;
        pukResp.code = RespCode.UNLOCK_PUK_ERROR;
        pukResp.remainTimes = res.remain;
      }
    } catch (err) {
      LogUtils.e(TAG, `verifyPukAndResetPin slotId=${slotId},err->${JSON.stringify(err)}`);
    }
    LogUtils.i(TAG, `verifyPukAndResetPin slotId=${slotId},result=${JSON.stringify(pukResp)}`)
    return pukResp;
  }

  /**
   * Unlock PIN.
   *
   * @param slotId - The card slot index number.
   * @param pin - SIM PIN.
   * @returns - Unlock Result.
   */
  public async unlockPin(slotId: number, pin: string): Promise<PinResp> {
    let unlockResp = new PinResp();
    try {
      let result = await sim.unlockPin(slotId, pin);
      if (result && result.result === UNLOCK_SUCCEED) {
        unlockResp.isSucceed = true;
        unlockResp.code = RespCode.SUCCEED;
      } else {
        unlockResp.isSucceed = false;
        unlockResp.code = RespCode.UNLOCK_PIN_ERROR;
        unlockResp.remainTimes = await this.getPinRemainAttempts(slotId, LockType.PIN_LOCK);
      }
    } catch (err) {
      LogUtils.e(TAG, `unlockPin callback: slotId=${slotId},err->${JSON.stringify(err)}`);
    }
    LogUtils.i(TAG, `unlockPin callback: slotId=${slotId},data->${JSON.stringify(unlockResp)}`);
    return unlockResp;
  }

  /**
   * Set the SIM card protection status.
   *
   * @param slotId - Card slot ID.
   * @param pin - PIN code.
   * @param isOn - On or Off.
   * @returns - Operation result.
   */
  private async setLockState(slotId: number, pin: string, isOn: boolean): Promise<PinResp> {
    let pinResp = new PinResp();
    try {
      let lockInfo: sim.LockInfo = {
        lockType: sim.LockType.PIN_LOCK,
        password: pin,
        state: isOn ? sim.LockState.LOCK_ON : sim.LockState.LOCK_OFF
      };
      let setLockResp = await sim.setLockState(slotId, lockInfo);
      LogUtils.i(TAG, `setPinState slotId=${slotId},res->${JSON.stringify(setLockResp)}`);
      if (!setLockResp) {
        pinResp.code = RespCode.SET_LOCK_STATE_ERROR;
        return pinResp;
      }
      if (setLockResp.result !== 0) {
        pinResp.remainTimes = await this.getPinRemainAttempts(slotId, LockType.PIN_LOCK);
        pinResp.code = RespCode.SET_LOCK_STATE_ERROR;
        return pinResp;
      }
      pinResp.isSucceed = true;
      pinResp.code = RespCode.SUCCEED;
    } catch (err) {
      LogUtils.e(TAG, `setPinState slotId=${slotId},error->${JSON.stringify(err)}`);
    }
    return pinResp;
  }
}

let pinModel = new PinModel();

export default pinModel;

/**
 * Get the PIN status of the SIM card in the specified slot.
 *
 * @param slotId The card slot index number,
 * @returns Status of PIN.
 */
export function getPinState(slotId: number) {
  return new Promise((resolve: (isOn: boolean) => void, reject: (reason?: BusinessError) => void) => {
    sim.getLockState(slotId, sim.LockType.PIN_LOCK, (err: BusinessError, data: sim.LockState) => {
      if (err) {
        LogUtils.i(TAG, `getPinState callback: slotId=${slotId},err->${JSON.stringify(err)}`);
        reject(err);
      } else {
        LogUtils.e(TAG, `getPinState callback: slotId=${slotId},data->${JSON.stringify(data)}`);
        resolve(data === sim.LockState.LOCK_ON);
      }
    });
  })
}

/**
 * Check whether a screen lock password is set.
 *
 * @returns Return whether the screen lock password is set.
 */
export function isScreenLockPasswordSet() {
  return new Promise((resolve: (result: boolean) => void, reject: (reason?: BusinessError) => void) => {
    getAuthInfo(resolve, reject);
  });
}

function getAuthInfo(resolve: (result: boolean) => void, reject: (reason?: BusinessError) => void) {
  let userIDM = new account_osAccount.UserIdentityManager();
  try {
    userIDM.getAuthInfo(account_osAccount.AuthType.PIN,
      (err: BusinessError, result: account_osAccount.EnrolledCredInfo[]) => {
        if (err) {
          LogUtils.e(TAG, 'getAuthInfo err = ' + JSON.stringify(err));
          reject(err);
        } else {
          LogUtils.i(TAG, 'getAuthInfo result = ' + JSON.stringify(result));
          resolve(result === null || result.length === 0 ? false : true);
        }
      });
  } catch (err) {
    reject(err);
    LogUtils.e(TAG, 'getAuthInfo exception = ' + JSON.stringify(err));
  }
}

/**
 * Determine whether a button can be clicked based on the PIN length.
 *
 * @param pin - Currently entered PIN
 * @returns - true:clickable;false:Not clickable.
 */
export function isConfirmBtnEnable(pin: string): boolean {
  return (!isEmpty(pin)) && pin.length >= PIN_MIN_LENGTH;
}
/**
 * Determine whether the SIM card is locked based on the lock type.
 *
 * @param lockType - Lock Type;
 * @returns true:It's locked.;false:It's unlocked.
 */
export function isLocked(lockType: LockType): boolean {
  return lockType !== LockType.NOT_LOCKED;
}