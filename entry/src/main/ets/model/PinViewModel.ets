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
import { DEFAULT_PIN_REMAIN, DEFAULT_PUK_REMAIN, LockType,
  TOAST_BOTTOM_MARGIN_DEFAULT } from '../common/utils/constant';
import pinModel, { isConfirmBtnEnable } from './pinModel';
import { UnlockingPinInfo } from '../data/Infos';
import { DynamicLoader } from '../utils/DynamicLoader';
import { closeSoftKeyboard, setWindowPrivacyMode } from '../common/utils/Utils';
import { VerifyDialogType } from '../common/components/dialog/verifyPinDialog';
import { ReportUtil } from '../utils/ReportUtil';
import LogUtils from '../common/utils/LogUtils';
import { AppStorageUtils } from '../common/utils/AppStorageUtils';
import passwordUtils from '../common/utils/PasswordUtils';

const TAG = 'PinViewModel';

@Observed
export class PinViewModel {
  public pinInfo: UnlockingPinInfo = new UnlockingPinInfo();
  public verifyPukDialog?: CustomDialogController;
  public verifyPinDialog?: CustomDialogController;
  public tooSimplePinDialog?: CustomDialogController;
  public unlockPinDialog?: CustomDialogController;

  /**
   * 打开或关闭解锁PUK码的弹窗
   *
   * @param isOpen - true:打开；false：关闭。
   */
  public openOrCloseVerifyPukDialog(isOpen: boolean) {
    if (isOpen) {
      pinModel.getPinRemainAttempts(this.pinInfo.slotId, LockType.PUK_LOCK)
        .then((remainTimes) => {
          this.pinInfo.pukRemainTimes = remainTimes;
          if (remainTimes > 0) {
            setWindowPrivacyMode(isOpen, TAG);
            this.verifyPukDialog?.open()
          } else {
            this.showToast($r('app.string.sim_has_been_invalidated'));
          }
        });
    } else {
      setWindowPrivacyMode(isOpen, TAG);
      this.verifyPukDialog?.close();
      closeSoftKeyboard();
    }
  }

  /**
   * 验证PUK并重置PIN。
   */
  public updatePinByPuk() {
    pinModel.verifyPukAndResetPin(this.pinInfo.slotId, this.pinInfo.puk, this.pinInfo.newPin).then((res) => {
      if (res.isSucceed) {
        this.pinInfo.pukRemainTimes = DEFAULT_PUK_REMAIN;
      } else {
        this.openOrCloseVerifyPukDialog(true);
      }
    })
  }

  /**
   * 打开验证PIN码弹窗
   *
   * @param type - 使用弹窗的类型。
   */
  public openVerifyPinDialog(type: VerifyDialogType) {
    this.pinInfo.isDialogConfirmEnabled = false;
    this.pinInfo.verifyPinType = type;
    this.initVerifyDialogInfo();
    setWindowPrivacyMode(true, TAG);
    this.verifyPinDialog?.open();
  }

  /**
   * 关闭验证PIN码弹窗
   */
  public closeVerifyPinDialog() {
    this.verifyPinDialog?.close();
    setWindowPrivacyMode(false, TAG);
    closeSoftKeyboard();
  }

  private initVerifyDialogInfo() {
    switch (this.pinInfo.verifyPinType) {
      case VerifyDialogType.OPEN_PIN:
        this.pinInfo.verifyPinTitle = $r('app.string.enable_sim_pin');
        this.pinInfo.verifyPinPlaceHolder = $r('app.string.sim_pin_enter_hint');
        break;
      case VerifyDialogType.CLOSE_PIN:
        this.pinInfo.verifyPinTitle = $r('app.string.disable_sim_pin');
        this.pinInfo.verifyPinPlaceHolder = $r('app.string.sim_pin_enter_hint');
        break;
      case VerifyDialogType.CHANGE_PIN:
        this.pinInfo.verifyPinTitle = $r('app.string.enter_sim_pin_please');
        this.pinInfo.verifyPinPlaceHolder = $r('app.string.current_pin');
        break;
      case VerifyDialogType.RESET_INPUT_NEW_PIN:
        this.pinInfo.verifyPinTitle = $r('app.string.set_new_sim_pin');
        this.pinInfo.verifyPinPlaceHolder = $r('app.string.new_pin');
        break;
      case VerifyDialogType.RESET_INPUT_NEW_PIN_AGAIN:
        this.pinInfo.verifyPinTitle = $r('app.string.set_new_sim_pin_again');
        this.pinInfo.verifyPinPlaceHolder = $r('app.string.new_pin');
        break;
      case VerifyDialogType.UNMATCHED:
        this.pinInfo.verifyPinTitle = $r('app.string.set_new_sim_pin');
        this.pinInfo.verifyPinPlaceHolder = $r('app.string.new_pin');
        break;
    }
  }

  /**
   * 输入框内容发生变化处理
   *
   * @param text - 输入框内的内容
   */
  public onVerifyDialogTextChanged(text: string) {
    this.pinInfo.isDialogConfirmEnabled = isConfirmBtnEnable(text);
    switch (this.pinInfo.verifyPinType) {
      case VerifyDialogType.RESET_INPUT_NEW_PIN:
        this.pinInfo.newPin = text;
        break;
      case VerifyDialogType.RESET_INPUT_NEW_PIN_AGAIN:
        this.pinInfo.newPinAgain = text;
        break;
      case VerifyDialogType.UNMATCHED:
        this.pinInfo.newPin = text;
        break;
      default:
        this.pinInfo.pin = text;
        break;
    }
  }

  /**
   * 输入新密码的弹窗中确定按钮被点击的处理。
   */
  public async onInputNewPinConfirmClicked() {
    if (passwordUtils.isWeakPasswords(this.pinInfo.newPin)) {
      this.tooSimplePinDialog?.open();
    } else {
      this.openVerifyPinDialog(VerifyDialogType.RESET_INPUT_NEW_PIN_AGAIN);
    }
  }

  /**
   * 打开或关闭解锁PIN码的弹窗
   *
   * @param isOpen - true:打开;false:关闭.
   */
  public openOrCloseUnlockPinDialog(isOpen: boolean) {

    if (isOpen) {
      this.pinInfo.clear();
      pinModel.getPinRemainAttempts(this.pinInfo.slotId, LockType.PIN_LOCK)
        .then((remainTimes: number) => {
          this.pinInfo.pinRemainTimes = remainTimes;
          setWindowPrivacyMode(isOpen, TAG);
          this.unlockPinDialog?.open();
        });
    } else {
      setWindowPrivacyMode(isOpen, TAG);
      this.unlockPinDialog?.close();
      closeSoftKeyboard();
    }
  }

  /**
   * 使用PIN码解锁SIM卡
   *
   * @param onLockTypeChanged - 输错三次之后，锁类型变化的回调。
   */
  public async unlockByPin(onLockTypeChanged?: (lockType: LockType) => void) {
    try {
      let res = await pinModel.unlockPin(this.pinInfo.slotId, this.pinInfo.pin);
      if (res.isSucceed) {
        this.pinInfo.pinRemainTimes = DEFAULT_PIN_REMAIN;
      } else if (res.remainTimes !== undefined) {
        if (res.remainTimes === 0) {
          ReportUtil.getInstance().reportInputPinErrorThreeTimes(this.pinInfo.slotId);
          let lockType = await pinModel.getSimLockType(this.pinInfo.slotId);
          onLockTypeChanged?.(lockType);
        } else {
          this.openOrCloseUnlockPinDialog(true);
        }
      }
      this.pinInfo.clear();
    } catch (err) {
      LogUtils.e(TAG, 'unlockByPin err = ' + JSON.stringify(err));
      this.pinInfo.clear();
    }
  }

  /**
   * 显示提示框。
   *
   * @param messageToShow - 提示内容。
   */
  public async showToast(messageToShow: ResourceStr) {
    let promptAction = await DynamicLoader.getInstance().loadPromptAction();
    let bottomHeight = AppStorageUtils.getNavigationBarHeight();
    promptAction.default.showToast({
      message: messageToShow,
      bottom: TOAST_BOTTOM_MARGIN_DEFAULT - px2vp(bottomHeight)
    });
  }

  /**
   * 关闭所有弹窗，一般在退出界面时使用。
   */
  public closeAllDialogs() {
    this.openOrCloseVerifyPukDialog(false);
    this.closeVerifyPinDialog()
    this.tooSimplePinDialog?.close();
    this.openOrCloseUnlockPinDialog(false)
    closeSoftKeyboard();
  }
}