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
import { DeviceInfo, SetScreenPwdResult, SimInfo, UnlockingPinInfo } from '../../data/Infos'
import pinModel, { isConfirmBtnEnable, isScreenLockPasswordSet } from '../../model/pinModel'
import LogUtils from '../utils/LogUtils'
import { TextArrowOption } from './TextArrowOption'
import lazy { TextToggleOption } from './TextToggleOption'
import lazy { AlertDialog, CustomContentDialog } from '@ohos.arkui.advanced.Dialog'
import { BusinessError } from '@kit.BasicServicesKit'
import { VerifyDialogType, VerifyPinDialogContent } from './dialog/verifyPinDialog'
import { closeSoftKeyboard, getString, getStringWithArgs } from '../utils/Utils'
import { JSON } from '@kit.ArkTS'
import { DEFAULT_PIN, DEFAULT_PIN_REMAIN, UpdatePinScenario } from '../utils/constant'
import { simIdFormat } from '../utils/SimIdFormat'
import { CustomSubHeader } from './SubHeader'
import SimServiceProxy from '../../model/simServiceProxy'
import { PinResp, RespCode } from '../../data/ResponseInfo'
import preferencesUtils from '../utils/PreferencesUtils'
import { DeviceUtils } from '../../utils/DeviceUtils'
import { StringUtils } from '../../utils/StringUtils'
import { ReportUtil } from '../../utils/ReportUtil'
import { VerifyPukDialogContent } from './dialog/verifyPukDialog'
import { PinViewModel } from '../../model/PinViewModel'
import { UnlockPinDialog } from './dialog/unlockPinDialog'

const TAG = 'PinComponent';

@Component
export struct PinComponent {
  @Watch('updateUiData') @ObjectLink deviceInfo: DeviceInfo
  @Watch('updateUiData') @ObjectLink simInfo: SimInfo;
  @State isPinEnabled: boolean = false;
  @State isPinOpened: boolean = false;
  @State isChangePinEnable: boolean = false;
  @State viewModel:PinViewModel = new PinViewModel();
  @State pinInfo: UnlockingPinInfo = new UnlockingPinInfo();
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  private enterPinTips: string[] = ['', '', ''];
  private onAboutPinClick: () => void = () => {
  }
  private toSetScreenLockPwdPage: (slotId: number) => void = (slotId) => {
  }

  @Builder
  createVerifyPinDialogContent() {
    VerifyPinDialogContent({
      type: this.pinInfo.verifyPinType,
      inputPlaceHolder: this.pinInfo.verifyPinPlaceHolder,
      pin: this.pinInfo.pin,
      remainTimes: DEFAULT_PIN_REMAIN,
      enterPinTips: this.enterPinTips,
      isConfirmEnabled: this.pinInfo.isDialogConfirmEnabled,
      fontSizeScale: this.fontSizeScale,
      onTextChanged: (value) => {
        this.viewModel.onVerifyDialogTextChanged(value);
      },
      onCancelClick: () => {
        this.viewModel.closeVerifyPinDialog();
        this.updateUiData();
        ReportUtil.getInstance()
          .reportCardProtectionChoice(this.simInfo.slotId, false, this.pinInfo.verifyPinType);
      },
      onConfirmClick: () => {
        this.viewModel.closeVerifyPinDialog();
        ReportUtil.getInstance()
          .reportCardProtectionChoice(this.simInfo.slotId, true, this.pinInfo.verifyPinType);
        this.onVerifyDialogConfirmClicked()
      },
      onAboutPinClick: () => {
        this.onAboutPinClick();
      }
    })
  }

  @Builder
  private createVerifyPukDialogContent() {
    VerifyPukDialogContent({
      puk: this.pinInfo.puk,
      remainTimes: this.pinInfo.pukRemainTimes,
      isConfirmEnabled: this.pinInfo.isDialogConfirmEnabled,
      fontSizeScale: this.fontSizeScale,
      onTextChanged: (value: string) => {
        this.pinInfo.setPuk(value);
      },
      onCancelClick: () => {
        this.viewModel.openOrCloseVerifyPukDialog(false);
      },
      onConfirmClick: () => {
        this.viewModel.openOrCloseVerifyPukDialog(false);
        this.viewModel.openVerifyPinDialog(VerifyDialogType.RESET_INPUT_NEW_PIN);
      }
    });
  }

  @Builder
  createUnlockPinDialogContent() {
    UnlockPinDialog({
      isConfirmBtnEnabled: this.pinInfo.isDialogConfirmEnabled,
      remain: this.pinInfo.pinRemainTimes,
      fontSizeScale: this.fontSizeScale,
      onTextChanged: (text) => {
        this.pinInfo.isDialogConfirmEnabled = isConfirmBtnEnable(text);
        this.pinInfo.pin = text;
      },
      onCancelClick: () => {
        this.viewModel.openOrCloseUnlockPinDialog(false);
      },
      onConfirmClick: () => {
        this.viewModel.unlockByPin((lockType) => {
          this.simInfo.lockedType = lockType;
        });
        this.viewModel.openOrCloseUnlockPinDialog(false);
      }
    });
  }

  onVerifyDialogConfirmClicked() {
    LogUtils.i(TAG, 'onVerifyDialogConfirmClicked=' + this.pinInfo.verifyPinType);
    switch (this.pinInfo.verifyPinType) {
      case VerifyDialogType.OPEN_PIN:
        this.setPinState(true);
        break;
      case VerifyDialogType.CLOSE_PIN:
        this.setPinState(false);
        break;
      case VerifyDialogType.CHANGE_PIN:
        this.viewModel.openVerifyPinDialog(VerifyDialogType.RESET_INPUT_NEW_PIN);
        break;
      case VerifyDialogType.RESET_INPUT_NEW_PIN:
        this.viewModel.onInputNewPinConfirmClicked();
        break;
      case VerifyDialogType.UNMATCHED:
        this.viewModel.openVerifyPinDialog(VerifyDialogType.RESET_INPUT_NEW_PIN_AGAIN);
        break;
      case VerifyDialogType.RESET_INPUT_NEW_PIN_AGAIN:
        this.onInputNewPinAgainConfirmClick();
        break;
    }
  }

  private initData() {
    let enterPinTipsStr = getStringWithArgs($r('app.string.sim_pin_enter_tips'), DEFAULT_PIN);
    enterPinTipsStr = enterPinTipsStr.replace('/', '');
    this.enterPinTips = enterPinTipsStr.split('<a>');
    this.pinInfo.slotId = this.simInfo.slotId;
    this.pinInfo.pinRemainTimes = DEFAULT_PIN_REMAIN;
  }

  private initViewModel() {
    this.viewModel.pinInfo = this.pinInfo;
    this.viewModel.verifyPukDialog = new CustomDialogController({
      builder: CustomContentDialog({
        primaryTitle: $r('app.string.please_enter_puk'),
        contentAreaPadding: { left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') },
        contentBuilder: () => {
          this.createVerifyPukDialogContent();
        }
      }),
      autoCancel: false,
      showInSubWindow: true,
      onWillDismiss: () => {
        this.updateUiData();
        this.viewModel.openOrCloseVerifyPukDialog(false);
      }
    });

    this.viewModel.verifyPinDialog = new CustomDialogController({
      builder: CustomContentDialog({
        primaryTitle: this.pinInfo.verifyPinTitle,
        contentAreaPadding: { left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') },
        contentBuilder: () => {
          this.createVerifyPinDialogContent();
        }
      }),
      autoCancel: false,
      showInSubWindow: true,
      onWillDismiss: () => {
        this.updateUiData();
        this.viewModel.closeVerifyPinDialog();
      }
    });

    this.viewModel.tooSimplePinDialog = new CustomDialogController({
      builder: AlertDialog({
        primaryTitle: $r('app.string.safety_tips_title'),
        content: $r('app.string.safety_tips_content'),
        secondaryButton: {
          value: $r('app.string.reset'),
          buttonStyle: ButtonStyleMode.EMPHASIZED,
          action: () => {
            this.viewModel.openVerifyPinDialog(VerifyDialogType.RESET_INPUT_NEW_PIN);
            ReportUtil.getInstance().reportSecurityHintChoice(this.simInfo.slotId, false);
          }
        }, primaryButton: {
          buttonStyle: ButtonStyleMode.TEXTUAL,
          value: $r('app.string.continue_to_use'),
          action: () => {
            this.viewModel.openVerifyPinDialog(VerifyDialogType.RESET_INPUT_NEW_PIN_AGAIN);
            ReportUtil.getInstance().reportSecurityHintChoice(this.simInfo.slotId, true);
          }
        }
      }),
      autoCancel: false,
      showInSubWindow: true
    });
    this.viewModel.unlockPinDialog = new CustomDialogController({
      builder: CustomContentDialog({
        primaryTitle: $r('app.string.sim_pin_unlock'),
        contentAreaPadding: { left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') },
        contentBuilder: () => {
          this.createUnlockPinDialogContent();
        },
      }),
      onWillDismiss: () => {
        this.viewModel.openOrCloseUnlockPinDialog(false);
      },
      autoCancel: false,
      showInSubWindow: true
    });
  }

  private updateAllState() {
    pinModel.getAllState(this.simInfo.slotId).then((res) => {
      this.simInfo.lockedType = res.lockType;
    })
  }

  private updateSimState() {
    SimServiceProxy.getSimState(this.simInfo.slotId).then((res: number) => {
      this.simInfo.state = res;
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'updateSimState error:' + JSON.stringify(err));
    })
  }

  private updateUiData() {
    this.isPinEnabled = !this.deviceInfo.isAirPlaneOn && this.simInfo.isActivated;
    this.isPinOpened = this.simInfo.isLockedEnabled();
    this.isChangePinEnable = this.isPinEnabled && this.isPinOpened && !this.simInfo.isLocked() &&
      !this.simInfo.isPukType();
  }

  private clearPins() {
    this.pinInfo.clear();
  }

  private getSubHeaderTitle(): string {
    let headerTitle = getStringWithArgs($r('app.string.sim_card_one_no_space'), simIdFormat(this.simInfo.slotId + 1));
    if (this.deviceInfo.isSingleSlotDevice()) {
      headerTitle = getString($r('app.string.sim_card'));
    }
    if (this.simInfo.phoneNumber) {
      return headerTitle + '(' + StringUtils.formatPhoneNumberWhenRtl(this.simInfo.phoneNumber) + ')';
    } else {
      return headerTitle;
    }
  }

  private getSimPinTips(): Resource {
    return DeviceUtils.isTablet() ? $r('app.string.pin_description_tablet') : $r('app.string.sim_pin_tips');
  }

  private onPinOpenedChanged(isOn: boolean) {
    this.clearPins();
    LogUtils.i(TAG, 'onPinOpenedChanged,isOn=' + isOn);
    if (isOn) {
      this.viewModel.openVerifyPinDialog(VerifyDialogType.OPEN_PIN);
      ReportUtil.getInstance().reportCardProtectionEnable(this.simInfo.slotId);
    } else {
      this.viewModel.openVerifyPinDialog(VerifyDialogType.CLOSE_PIN);
      ReportUtil.getInstance().reportCardProtectionDisable(this.simInfo.slotId);
    }
  }

  private onChangePinClick() {
    this.clearPins();
    this.pinInfo.updatePinScenario = UpdatePinScenario.NORMAL_CHANGE;
    this.viewModel.openVerifyPinDialog(VerifyDialogType.CHANGE_PIN);
  }

  private onInputNewPinAgainConfirmClick() {
    if (!this.pinInfo.isMatched()) {
      this.viewModel.openVerifyPinDialog(VerifyDialogType.UNMATCHED);
      return;
    }
    if (this.pinInfo.isNormalChange()) {
      this.changePin();
    } else if (this.pinInfo.isResetPinByPuk()) {
      this.viewModel.updatePinByPuk();
    }
  }

  private setPinState(isOn: boolean) {
    pinModel.setPinState(this.simInfo.slotId, this.pinInfo.pin, isOn)
      .then((res) => {
        this.handleSetPinStateResult(res);
      })
      .catch((err: BusinessError) => {
        LogUtils.e(TAG, 'setPinState err = ' + JSON.stringify(err));
        this.updateUiData();
      });
  }

  private handleSetPinStateResult(res: PinResp) {
    if (res.isSucceed) {
      this.updatePinRemainTimes(DEFAULT_PIN_REMAIN);
    } else {
      this.updatePinRemainTimes(res.remainTimes);
      this.viewModel.showToast($r('app.string.pin_error_retry', res.remainTimes));
      this.updateUiData();
    }
    this.updateAllState();
  }

  private changePin() {
    pinModel.changePin(this.simInfo.slotId, this.pinInfo.pin, this.pinInfo.newPin)
      .then((data) => {
        if (data.isSucceed) {
          this.updatePinRemainTimes(DEFAULT_PIN_REMAIN);
        } else {
          this.updatePinRemainTimes(data.remainTimes);
          this.viewModel.showToast($r('app.string.pin_error_retry', data.remainTimes));
        }
      })
      .catch((err: BusinessError) => {
        LogUtils.e(TAG, 'changePin err = ' + JSON.stringify(err));
      });
  }

  private updatePinRemainTimes(times: number) {
    this.pinInfo.pinRemainTimes = times;
    if (times === 0) {
      ReportUtil.getInstance().reportInputPinErrorThreeTimes(this.simInfo.slotId);
    }
  }

  private onPinSwitchTouchIntercept(): HitTestMode {
    if (this.simInfo.isPukType()) {
      this.clearPins();
      this.pinInfo.updatePinScenario = UpdatePinScenario.RESET_BY_PUK;
      this.viewModel.openOrCloseVerifyPukDialog(true);
      return HitTestMode.Block;
    }
    if (this.simInfo.isLocked() && this.simInfo.isPinType()) {
      this.viewModel.openOrCloseUnlockPinDialog(true);
      return HitTestMode.Block;
    }
    return HitTestMode.Default;
  }

  aboutToAppear(): void {
    this.initViewModel();
    this.updateSimState();
    this.initData();
    this.updateUiData();
    this.updateAllState();
  }

  aboutToDisappear(): void {
    this.viewModel.closeAllDialogs()
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Scroll() {
        Stack({ alignContent: Alignment.TopStart }) {
          Column() {
            CustomSubHeader({
              title: this.getSubHeaderTitle()
            })

            Column() {
              TextToggleOption({
                optionTitle: $r('app.string.enable_sim_pin'),
                optionInfo: this.getSimPinTips(),
                isSwitchEnabled: this.isPinEnabled,
                isSwitchOn: this.isPinOpened,
                isEnabled: this.isPinEnabled,
                onToggleTouchIntercept: (event) => {
                  return this.onPinSwitchTouchIntercept();
                },
                onChange: (isOn) => {
                  if (this.isPinOpened === isOn) {
                    return;
                  }
                  LogUtils.i(TAG, 'onSimPinSwitchChanged isOn=' + isOn);
                  this.isPinOpened = isOn;
                  this.onPinOpenedChanged(isOn);
                }
              })

              Divider().color($r('sys.color.comp_divider'))
                .padding({
                  left: $r('sys.float.padding_level6'),
                  right: $r('sys.float.padding_level6')
                })

              TextArrowOption({
                optionTag: $r('app.string.sim_pin_change'),
                onClicked: () => {
                  this.onChangePinClick();
                  ReportUtil.getInstance().reportModifyPinClick(this.simInfo.slotId);
                }
              }).enabled(this.isChangePinEnable)
                .opacity(this.isChangePinEnable ? $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .backgroundColor($r('sys.color.comp_background_primary'))
            .borderRadius($r('sys.float.corner_radius_level10'))
            .padding({
              top: $r('app.float.value_4'),
              bottom: $r('app.float.value_4')
            })

            Column() {
            }
            .height($r('app.float.value_56'))
            .width('100%')

            Column() {
            }
            .height($r('sys.float.padding_level4'))
            .width('100%')
          }
          .width('100%')
        }
      }
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
      .width('100%')
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }
}