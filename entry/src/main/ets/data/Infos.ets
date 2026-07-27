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
import { VerifyDialogType } from '../common/components/dialog/verifyPinDialog';
import {
  DEFAULT_PIN_REMAIN,
  DEFAULT_PUK_REMAIN,
  LockType,
  PUK_MAX_LENGTH,
  SIM_SLOT_COUNT_1,
  SLOT_1,
  UpdatePinScenario
} from '../common/utils/constant';
import SimStateConst from '../common/utils/SimStateConst';
import { isEmpty } from '../common/utils/Utils';
import { getMaxSimCount } from '../model/registerSimStateApi';

@Observed
export class DeviceInfo {
  public simCount = getMaxSimCount();
  public isAirPlaneOn: boolean = false;
  public simInfos: SimInfo[] = [];

  /**
   * Whether a card is inserted.
   *
   * @returns true:has;false:not has.
   */
  public hasSim(): boolean {
    for (let index = 0; index < this.simInfos.length; index++) {
      const sim = this.simInfos[index];
      if (sim.isReadyOrLoaded()) {
        return true;
      }
    }
    return false;
  }

  public isSingleSlotDevice(): boolean {
    return this.simCount === SIM_SLOT_COUNT_1;
  }
}

@Observed
export class SimInfo {
  public slotId: number = 0;
  public phoneNumber: string = '';
  public state: number = SimStateConst.SIM_STATE_UNKNOWN;
  public isActivated: boolean = true;
  public hasSim: boolean = true;
  public lockedType: LockType = LockType.NOT_LOCKED;

  constructor(slotId: number, phoneNumber: string, state: number, hasSim: boolean, isActivated: boolean) {
    this.slotId = slotId;
    this.phoneNumber = phoneNumber;
    this.state = state;
    this.hasSim = hasSim;
    this.isActivated = isActivated;
  }

  /**
   * Check whether the card is ready or loaded.
   *
   * @returns true:ready || loaded;false:not ready && not loaded.
   */
  public isReadyOrLoaded(): boolean {
    return this.state === SimStateConst.SIM_STATE_READY || this.state === SimStateConst.SIM_STATE_LOADED;
  }

  public isSimStateLocked(): boolean {
    return this.state === SimStateConst.SIM_STATE_LOCKED;
  }

  public isLockedEnabled(): boolean {
    return this.isPinType() || this.isPukType();
  }

  public isPinType(): boolean {
    return this.lockedType === LockType.PIN_LOCK;
  }

  public isPukType(): boolean {
    return this.lockedType === LockType.PUK_LOCK;
  }

  public isLocked(): boolean {
    return this.state === SimStateConst.SIM_STATE_LOCKED;
  }
}

@Observed
export class UnlockingPinInfo {
  public slotId: number = SLOT_1;
  public isDialogConfirmEnabled: boolean = false;
  public pinRemainTimes: number = DEFAULT_PIN_REMAIN;
  public pin: string = '';
  public newPin: string = '';
  public newPinAgain: string = '';
  public updatePinScenario: UpdatePinScenario = UpdatePinScenario.NORMAL_CHANGE;
  public puk: string = '';
  public pukRemainTimes: number = DEFAULT_PUK_REMAIN;
  public verifyPinType: VerifyDialogType = VerifyDialogType.OPEN_PIN;
  public verifyPinTitle: ResourceStr = '';
  public verifyPinPlaceHolder: ResourceStr = '';

  public clear() {
    this.isDialogConfirmEnabled = false;
    this.pin = '';
    this.newPin = '';
    this.newPinAgain = '';
    this.updatePinScenario = UpdatePinScenario.NORMAL_CHANGE;
    this.puk = '';
  }

  public isMatched(): boolean {
    return this.newPin === this.newPinAgain;
  }

  public isNormalChange(): boolean {
    return this.updatePinScenario === UpdatePinScenario.NORMAL_CHANGE &&
      !isEmpty(this.pin) && !isEmpty(this.newPin);
  }

  public isResetPinByPuk(): boolean {
    return !isEmpty(this.puk) && !isEmpty(this.newPin) && this.updatePinScenario === UpdatePinScenario.RESET_BY_PUK;
  }

  public setPuk(puk: string) {
    this.puk = puk;
    this.isDialogConfirmEnabled = !isEmpty(puk) && puk.length === PUK_MAX_LENGTH;
  }
}

export class SetScreenPwdResult {
  @Track public openTimes = 0;
  public isSucceed: boolean = false;
  public slotId: number = 0;

  constructor(isSucceed: boolean) {
    this.isSucceed = isSucceed;
  }

  public openTimesAdded() {
    if (this.openTimes > 100) {
      this.openTimes = 0;
    } else {
      this.openTimes++;
    }
  }
}
