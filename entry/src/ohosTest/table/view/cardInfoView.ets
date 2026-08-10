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

import SimServiceProxy from '../../model/simServiceProxy';
import {
  getOperatorName,
  getSupportNetwork,
  registerImsRegStateChange,
  unRegisterImsRegStateChange
} from '../../model/radioServiceProxy';
import {
  registerAccountInfoChange,
  registerNetworkStateChange,
  registerSimStateChange,
  unRegisterAccountInfoChange,
  unRegisterNetworkStateChange,
  unRegisterSimStateChange
} from '../../model/registerSimStateApi';
import LogUtils from '../../common/utils/LogUtils';
import SimStateConst from '../utils/SimStateConst';
import OperaNameStruct from '../struct/operaNameStruct';
import { simIdFormat } from '../utils/SimIdFormat';

import { getNumber, getString, isEmpty } from '../utils/Utils';

import { SimCardGlobalContextHelper } from '../utils/SimCardGlobalContextHelper';
import common from '@ohos.app.ability.common';
import * as Constants from '../utils/constant';
import {
  LockType,
  MAX_SIM_COUNT,
  SIM_SLOT_COUNT_1,
  SLOT_1,
  SLOT_2,
  UpdatePinScenario
} from '../utils/constant';
import { needFilterEflInfo } from '../../common/utils/Utils';
import CardInfoStruct from '../struct/CardInfoStruct';
import { EditSimInfo, EditSimInfoContent, setSimInfo } from './dialog/editSimInfoDialog';
import lazy { AlertDialog, CustomContentDialog, LoadingDialog } from '@ohos.arkui.advanced.Dialog';
import { observer } from '../../model/api';
import { radio } from '@kit.TelephonyKit';
import { UnlockPinDialog } from './dialog/unlockPinDialog';
import { BusinessError, settings } from '@kit.BasicServicesKit';
import pinModel, { isConfirmBtnEnable } from '../../model/pinModel';
import { UnlockingPinInfo } from '../../data/Infos';
import { AppStorageUtils } from '../utils/AppStorageUtils';
import { LengthMetrics } from '@kit.ArkUI';
import { StringUtils } from '../../utils/StringUtils';
import lazy { ReportUtil } from '../../utils/ReportUtil';
import { PinViewModel } from '../../model/PinViewModel';
import { VerifyPukDialogContent } from './dialog/verifyPukDialog';
import { VerifyDialogType, VerifyPinDialogContent } from './dialog/verifyPinDialog';

const TAG = 'cardInformation';
const GET_PHONE_NUMBER_DELAY = 500;

@Component
export default struct eSimSet {
  @State cardInfoSimName1: string = '';
  @State cardInfoSimName2: string = '';
  @Link list: Array<CardInfoStruct>;
  @Link cardSwitchTarget: number;
  @Link phone1Number: string;
  @Link phone2Number: string;
  @State title: Resource = $r('app.string.sim_card_one_no_space', simIdFormat(1));
  @State curEditList: CardInfoStruct = new CardInfoStruct();
  @State isSimCardClosed: boolean = true;
  @State simName: string = '';
  @State phoneNumber: string = '';
  @State isChange: boolean = true;
  @State diaLing: number = 0;
  @State upisChange: boolean = true;
  @State isCancel: boolean = false;
  @Link isCardChange: boolean;
  @State upDataTitle: string = '';
  @State isStop1: boolean = true;
  @State isStop2: boolean = true;
  @Link isOpened1: boolean;
  @Link isOpened2: boolean;
  @Link isCardChange2: boolean;
  @StorageLink('operatorName') @Watch('updateOperatorName') operatorRes: OperaNameStruct = new OperaNameStruct();
  @Link @Watch('onAirplaneModeChanged') isAirPlaneMode: boolean;
  @Prop isCalling: boolean;
  @State defaultSimName: string = '';
  @Link isDefaultDataChanging: boolean;
  @Prop maxSimSlotCount: number;
  @StorageProp('foldStatus') foldStatus: number = -1;
  //Index of the TextInput that has the focus in the EditSimInfoDialog.
  @Link simState1: number;
  @Link simState2: number;
  @State unlockingPinInfo: UnlockingPinInfo = new UnlockingPinInfo();
  @StorageLink(AppStorageUtils.SIM_LOCK_TYPES) lockType: LockType[] = [LockType.NOT_LOCKED, LockType.NOT_LOCKED];
  @Link @Watch('UpdateSatelliteSlotId') isSatelliteOn: boolean;
  @State satelliteSlotId: number = -1;
  @State editInfo: EditSimInfo = new EditSimInfo();
  @State editImgStartMargins: LengthMetrics[] = [LengthMetrics.resource($r('app.float.wh_value_12')),
    LengthMetrics.resource($r('app.float.wh_value_12'))];
  @State pinViewModel: PinViewModel = new PinViewModel();
  private infoAreaWidths: number[] = [0, 0];
  private editNames: string[] = ['', ''];
  private operatorNames: string[] = ['', ''];
  private plmnSpns: string[] = ['', ''];
  private isActivating1: boolean = false;
  private isActivating2: boolean = false;
  private isEditSimInfoDialogShowing: boolean = false;
  private disablePrimaryDialogTitle: string | Resource = '';
  private disablePrimaryDialogMessage: string | Resource = '';
  private phoneNumberTimeoutId: number[] = [0, 0];
  timer: number = -1;
  SIM_CARD_DEFAULT = 'sim_card_management_card_default_call';
  SIM_CARD_INFO = 'sim_card_management_storage_card_info';
  SIM_CARD_KEYWORD = 'sim_card_keyword';
  SIM_CARD_INFO2 = 'sim_card_management_storage_card_info2';
  SIM_CARD_CHANGE = 'sim_card_management_card_change_boolean';
  SIM_CARD_STOP = 'sim_card_management_card_stop_boolean';
  SIM_CARD_DATA = 'sim_card_management_storage_card_data';
  SIM_LIST_DISABLED = 'sim_card_management_list_disabled';
  SIM_LIST_DISABLED2 = 'sim_card_management_list_disabled2';
  SIM_NAME1 = 'sim_card_name1';
  SIM_NAME2 = 'sim_card_name2';
  SIM_phoneNumber1 = 'sim_card_phoneNumber1';
  SIM_phoneNumber2 = 'sim_card_phoneNumber2';
  private onSimStateChanged1: Callback<observer.SimStateData> = (simStateData: observer.SimStateData) => {
    LogUtils.i(TAG, 'onSimStateChanged slotId=' + SLOT_1 + ',simState=' + JSON.stringify(simStateData));
    this.getSimState(SLOT_1);
  };
  private onSimStateChanged2: Callback<observer.SimStateData> = (simStateData: observer.SimStateData) => {
    LogUtils.i(TAG, 'onSimStateChanged slotId=' + SLOT_2 + ',simState=' + JSON.stringify(simStateData));
    this.getSimState(SLOT_2);
  };
  private onAccountInfoChanged: Callback<void> = () => {
    LogUtils.i(TAG, 'onAccountInfoChanged');
    this.updateOperatorName();
    this.closeEditSimInfoDialog();
    this.disablePrimaryCardDialog.close();
    this.pinViewModel.closeAllDialogs();
  };
  private onNetworkStateChange1: Callback<observer.NetworkState> = (networkState: observer.NetworkState) => {
    LogUtils.i(TAG, 'onNetworkStateChange slotId=' + SLOT_1 + ',networkState=' + JSON.stringify(networkState));
    this.updateOperatorName();
  };
  private onNetworkStateChange2: Callback<observer.NetworkState> = (networkState: observer.NetworkState) => {
    LogUtils.i(TAG, 'onNetworkStateChange slotId=' + SLOT_2 + ',newworkState=' + JSON.stringify(networkState));
    this.updateOperatorName();
  };
  private onImsRegStateChange1: Callback<radio.ImsRegInfo> = (data: radio.ImsRegInfo) => {
    LogUtils.i(TAG, 'onImsRegStateChange slotId=' + SLOT_1 + ',data=' + JSON.stringify(data));
    this.getPhoneNumberAfterDelay(SLOT_1);
  };
  private onImsRegStateChange2: Callback<radio.ImsRegInfo> = (data: radio.ImsRegInfo) => {
    LogUtils.i(TAG, 'onImsRegStateChange slotId=' + SLOT_2 + ',data=' + JSON.stringify(data));
    this.getPhoneNumberAfterDelay(SLOT_2);
  };
  //Dialog for editing card information.
  editSimInfoDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: this.getEditSimInfoDialogTitle(),
      contentBuilder: () => {
        this.createEditSimInfoDialogContent()
      },
      buttons: [
        {
          value: $r('app.string.cancel'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            this.onEditSimInfoDialogDismissed();
            ReportUtil.getInstance().reportCardInfoEditSelected(this.editInfo.slotId, false);
          }
        },
        {
          value: $r('app.string.confirm'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            this.onEditSimInfoDialogDismissed();
            setSimInfo(this.editInfo,
              (slotId: number) => {
                this.getShowName(slotId)
              }, (slotId: number) => {
                this.getShowNumber(slotId)
              })
            ReportUtil.getInstance().reportCardInfoEditSelected(this.editInfo.slotId, true);
          }
        }
      ]
    }),
    autoCancel: false,
    showInSubWindow: true,
    onWillDismiss: () => {
      this.onEditSimInfoDialogDismissed();
    }
  });
  //Dialog when the activation status is being set.
  setSimActiveLoadingDialog: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: this.upisChange ? $r('app.string.activating_card_tip', this.upDataTitle)
        : $r('app.string.deactivating_card_tip', this.upDataTitle),
    }),
    autoCancel: false,
    showInSubWindow: true
  });
  //Dialog notification when the primary card is disabled.
  disablePrimaryCardDialog: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: this.disablePrimaryDialogTitle,
      content: this.disablePrimaryDialogMessage,
      primaryButton: {
        value: $r('app.string.cancel'),
        buttonStyle: ButtonStyleMode.TEXTUAL,
        action: () => {
          this.onDisablePrimaryCardDialogCancelled();
        }
      },
      secondaryButton: {
        value: $r('app.string.stop_use'),
        action: () => {
          this.isChange = false;
          if (this.curEditList.id === 0) {
            this.setSimActivated(0, false);
            this.cardInfoSimName1 = getString($r('app.string.sim_not_enabled'));
            this.isStop1 = false;
            this.list[0].isOpened = false;
            this.isStop2 = true;
          } else {
            this.setSimActivated(1, false);
            this.cardInfoSimName2 = getString($r('app.string.sim_not_enabled'));
            this.list[1].isOpened = false;
            this.isStop1 = true;
            this.isStop2 = false;
          }
        }
      }
    }),
    onWillDismiss: () => {
      this.disablePrimaryCardDialog.close();
      this.onDisablePrimaryCardDialogCancelled();
    },
    autoCancel: false,
    showInSubWindow: true
  });

  /**
   * Input box area of the dialog box for editing card information.
   */
  @Builder
  createEditSimInfoDialogContent() {
    EditSimInfoContent({
      slotId: this.editInfo.slotId,
      oldName: this.editInfo.oldName,
      newName: this.editInfo.newName,
      oldNumber: this.editInfo.oldNumber,
      newNumber: this.editInfo.newNumber,
      focusedIndex: this.editInfo.focusedIndex,
      onFocusChanged: (index: number, isFocused: boolean) => {
        this.editInfo.focusedIndex = isFocused ? index : 0;
      },
      onNameChanged: (name: string) => {
        this.editInfo.newName = name;
      },
      onNumberChanged: (phoneNumber: string) => {
        this.editInfo.newNumber = phoneNumber;
      }
    });
  }

  @Builder
  createUnlockPinDialogContent() {
    UnlockPinDialog({
      isConfirmBtnEnabled: this.unlockingPinInfo.isDialogConfirmEnabled,
      remain: this.unlockingPinInfo.pinRemainTimes,
      onTextChanged: (text) => {
        this.unlockingPinInfo.isDialogConfirmEnabled = isConfirmBtnEnable(text);
        this.unlockingPinInfo.pin = text;
      },
      onCancelClick: () => {
        this.pinViewModel.openOrCloseUnlockPinDialog(false);
      },
      onConfirmClick: () => {
        this.pinViewModel.unlockByPin();
        this.pinViewModel.openOrCloseUnlockPinDialog(false);
      }
    });
  }

  @Builder
  private createVerifyPukDialogContent() {
    VerifyPukDialogContent({
      puk: this.unlockingPinInfo.puk,
      remainTimes: this.unlockingPinInfo.pukRemainTimes,
      isConfirmEnabled: this.unlockingPinInfo.isDialogConfirmEnabled,
      onTextChanged: (value: string) => {
        this.unlockingPinInfo.setPuk(value);
      },
      onCancelClick: () => {
        this.pinViewModel.openOrCloseVerifyPukDialog(false);
      },
      onConfirmClick: () => {
        this.pinViewModel.openOrCloseVerifyPukDialog(false);
        this.pinViewModel.openVerifyPinDialog(VerifyDialogType.RESET_INPUT_NEW_PIN);
      }
    });
  }

  @Builder
  createVerifyPinDialogContent() {
    VerifyPinDialogContent({
      type: this.unlockingPinInfo.verifyPinType,
      inputPlaceHolder: this.unlockingPinInfo.verifyPinPlaceHolder,
      pin: this.unlockingPinInfo.pin,
      remainTimes: Constants.DEFAULT_PIN_REMAIN,
      enterPinTips: ['', '', ''],
      isConfirmEnabled: this.unlockingPinInfo.isDialogConfirmEnabled,
      onTextChanged: (value) => {
        this.pinViewModel.onVerifyDialogTextChanged(value);
      },
      onCancelClick: () => {
        this.pinViewModel.closeVerifyPinDialog();
        ReportUtil.getInstance()
          .reportCardProtectionChoice(this.unlockingPinInfo.slotId, false, this.unlockingPinInfo.verifyPinType);
      },
      onConfirmClick: () => {
        this.pinViewModel.closeVerifyPinDialog();
        ReportUtil.getInstance()
          .reportCardProtectionChoice(this.unlockingPinInfo.slotId, true, this.unlockingPinInfo.verifyPinType);
        this.onVerifyDialogConfirmClicked()
      },
      onAboutPinClick: () => {
      }
    })
  }

  private onVerifyDialogConfirmClicked() {
    LogUtils.i(TAG, 'onVerifyDialogConfirmClicked=' + this.unlockingPinInfo.verifyPinType);
    switch (this.unlockingPinInfo.verifyPinType) {
      case VerifyDialogType.RESET_INPUT_NEW_PIN:
        this.pinViewModel.onInputNewPinConfirmClicked();
        break;
      case VerifyDialogType.UNMATCHED:
        this.pinViewModel.openVerifyPinDialog(VerifyDialogType.RESET_INPUT_NEW_PIN_AGAIN);
        break;
      case VerifyDialogType.RESET_INPUT_NEW_PIN_AGAIN:
        this.onInputNewPinAgainConfirmClick();
        break;
    }
  }

  private onInputNewPinAgainConfirmClick() {
    if (!this.unlockingPinInfo.isMatched()) {
      this.pinViewModel.openVerifyPinDialog(VerifyDialogType.UNMATCHED);
      return;
    }
    if (this.unlockingPinInfo.isResetPinByPuk()) {
      this.pinViewModel.updatePinByPuk();
    }
  }

  private getEditSimInfoDialogTitle(): Resource {
    return this.maxSimSlotCount === SIM_SLOT_COUNT_1 ?
    $r('app.string.edit_sim_card_info') : $r('app.string.sim_edit', simIdFormat(this.editInfo.slotId + 1))
  }

  private initViewModel() {
    this.pinViewModel.pinInfo = this.unlockingPinInfo;
    this.pinViewModel.verifyPukDialog = new CustomDialogController({
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
        this.pinViewModel.openOrCloseVerifyPukDialog(false);
      }
    });
    this.pinViewModel.verifyPinDialog = new CustomDialogController({
      builder: CustomContentDialog({
        primaryTitle: this.unlockingPinInfo.verifyPinTitle,
        contentAreaPadding: { left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') },
        contentBuilder: () => {
          this.createVerifyPinDialogContent();
        }
      }),
      autoCancel: false,
      showInSubWindow: true,
      onWillDismiss: () => {
        this.pinViewModel.closeVerifyPinDialog();
      }
    });
    this.pinViewModel.tooSimplePinDialog = new CustomDialogController({
      builder: AlertDialog({
        primaryTitle: $r('app.string.safety_tips_title'),
        content: $r('app.string.safety_tips_content'),
        secondaryButton: {
          value: $r('app.string.reset'),
          buttonStyle: ButtonStyleMode.EMPHASIZED,
          action: () => {
            this.pinViewModel.openVerifyPinDialog(VerifyDialogType.RESET_INPUT_NEW_PIN);
            ReportUtil.getInstance().reportSecurityHintChoice(this.unlockingPinInfo.slotId, false);
          }
        },
        primaryButton: {
          buttonStyle: ButtonStyleMode.TEXTUAL,
          value: $r('app.string.continue_to_use'),
          action: () => {
            this.pinViewModel.openVerifyPinDialog(VerifyDialogType.RESET_INPUT_NEW_PIN_AGAIN);
            ReportUtil.getInstance().reportSecurityHintChoice(this.unlockingPinInfo.slotId, true);
          }
        }
      }),
      autoCancel: false,
      showInSubWindow: true
    });
    this.pinViewModel.unlockPinDialog = new CustomDialogController({
      builder: CustomContentDialog({
        primaryTitle: $r('app.string.sim_pin_unlock'),
        contentAreaPadding: { left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') },
        contentBuilder: () => {
          this.createUnlockPinDialogContent();
        },
      }),
      onWillDismiss: () => {
        this.pinViewModel.openOrCloseUnlockPinDialog(false);
      },
      autoCancel: false,
      showInSubWindow: true
    });
  }

  private onEditSimInfoDialogDismissed() {
    this.isEditSimInfoDialogShowing = false;
  }

  private closeEditSimInfoDialog() {
    this.onEditSimInfoDialogDismissed();
    this.editSimInfoDialog.close();
  }

  private editSimInfo(item: CardInfoStruct) {
    if (this.isEditSimInfoDialogShowing) {
      LogUtils.i(TAG, 'editSimInfo ignored, dialog is showing');
      return;
    }
    LogUtils.i(TAG, 'onclick edit slotId:' + JSON.stringify(item.id));
    this.title = item.title;
    this.curEditList = item;
    this.phoneNumber = item.id === 0 ? this.phone1Number : this.phone2Number;
    this.editInfo.slotId = item.id;
    this.editInfo.setSimInfo?.(item.id, item.id === 0 ? this.cardInfoSimName1 : this.cardInfoSimName2,
      this.phoneNumber);
    this.isEditSimInfoDialogShowing = true;
    this.editSimInfoDialog.open();
    ReportUtil.getInstance().reportCardInfoEditClick(item.id);
  }

  private onDisablePrimaryCardDialogCancelled() {
    this.isChange = true;
    this.isCancel = true;
    if (this.curEditList.id === 0) {
      this.isOpened1 = true;
    } else {
      this.isOpened2 = true;
    }
  }

  stopCard(item: CardInfoStruct, isOn: boolean) {
    if (!isOn) {
      this.upisChange = isOn;
      item.isOpened = isOn;
    }
  }

  updateInfo(isActivated: boolean) {
    clearTimeout(this.timer);
    this.upisChange = isActivated;
    this.setSimActiveLoadingDialog.open();
    this.timer = setTimeout(() => {
      this.isActivating1 = false;
      this.isActivating2 = false;
      this.setSimActiveLoadingDialog.close();
    }, 15000);
  }

  getPhoneNumberAfterDelay(slotId: number) {
    this.phoneNumberTimeoutId[slotId] = setTimeout(() => {
      this.getShowNumber(slotId);
    }, GET_PHONE_NUMBER_DELAY)
  }

  clearPhoneNumberDelay() {
    this.phoneNumberTimeoutId.forEach((value) => {
      clearTimeout(value);
    })
  }

  private onAirplaneModeChanged() {
    if (this.isAirPlaneMode) {
      this.closeEditSimInfoDialog();
      this.disablePrimaryCardDialog.close();
      this.pinViewModel.closeAllDialogs();
    }
  }

  /**
   * Get the customized mobile phone number set by the user
   */
  getShowNumber(slotId: number) {
    SimServiceProxy.getShowNumber(slotId).then((res: string) => {
      if (isEmpty(res) || typeof res === 'undefined') {
        this.getPhoneNumber(slotId);
      } else {
        this.updatePhoneNumber(slotId, res);
      }
    }).catch(() => {
      this.getPhoneNumber(slotId);
    })
  }

  private updatePhoneNumber(slotId: number, number: string) {
    if (slotId === SLOT_1) {
      this.phone1Number = number;
    } else {
      this.phone2Number = number;
    }
  }

  /**
   * Get the custom operator name set by the user -- success
   */
  getShowName(slotId: number) {
    LogUtils.i(TAG, 'getShowName in cardInfomation');
    SimServiceProxy.getShowName(slotId).then((res: string) => {
      this.handleGetShowNameResult(slotId, res);
    }).catch(() => {
      this.handleGetShowNameResult(slotId, '');
    });
  }

  private handleGetShowNameResult(slotId: number, res: string) {
    if (slotId < 0 || slotId >= this.editNames.length) {
      LogUtils.w(TAG, 'handleGetShowNameResult slotId is invalid');
      return;
    }
    this.editNames[slotId] = res;
    if (isEmpty(this.editNames[slotId]) && isEmpty(this.plmnSpns[slotId])) {
      this.getNetName(slotId);
    }
    this.updateCardInfoSimName(slotId);
  }

  private updateCardInfoSimName(slotId: number) {
    if (slotId < 0 || slotId >= this.editNames.length) {
      LogUtils.w(TAG, 'updateName slotId is invalid');
      return;
    }
    let name = getString($r('app.string.sim_no_service'));
    if (!isEmpty(this.editNames[slotId])) {
      name = this.editNames[slotId];
    } else {
      if (!isEmpty(this.plmnSpns[slotId])) {
        name = this.plmnSpns[slotId];
      } else {
        if (!isEmpty(this.operatorNames[slotId])) {
          name = this.operatorNames[slotId];
        }
      }
    }
    if (slotId === SLOT_1) {
      this.cardInfoSimName1 = name;
    } else if (slotId === SLOT_2) {
      this.cardInfoSimName2 = name;
    }
  }

  /**
   * Get card slot operator name
   */
  getNetName(slotId: number) {
    getOperatorName(slotId).then((res: string) => {
      if (slotId >= 0 && slotId < this.operatorNames.length) {
        this.operatorNames[slotId] = res;
      }
      this.updateCardInfoSimName(slotId);
    }).catch(() => {
    });
  }

  /**
   * Whether there is a card
   */
  hasSimCard(slotId: number) {
    SimServiceProxy.hasSimCard(slotId).then((res: boolean) => {
      LogUtils.i(TAG, 'getSimState: hasSimCard card slotId=' + JSON.stringify(slotId) + ',res=' + JSON.stringify(res));
      this.list[slotId].isSimCardClosed = res;
      this.list[slotId].hasCard = res;
    }).catch(() => {
    });
  };

  updateOperatorName() {
    LogUtils.i(TAG, 'updateOperatorName start');
    const slotId = this.operatorRes.CUR_SLOT_ID;
    if (slotId < 0 || slotId >= this.plmnSpns.length) {
      LogUtils.w(TAG, 'updateOperatorName slotId is invalid');
      return;
    }
    if (this.operatorRes.CUR_PLMN_SHOW && !isEmpty(this.operatorRes.CUR_PLMN)) {
      this.plmnSpns[slotId] = this.operatorRes.CUR_PLMN;
    } else {
      this.plmnSpns[slotId] = '';
    }
    if (this.operatorRes.CUR_SPN_SHOW && !isEmpty(this.operatorRes.CUR_SPN)) {
      if (isEmpty(this.plmnSpns[slotId])) {
        this.plmnSpns[slotId] = this.operatorRes.CUR_SPN;
      } else {
        this.plmnSpns[slotId] = this.plmnSpns[slotId] + '|'
          + this.operatorRes.CUR_SPN;
      }
    }
    this.updateCardInfoSimName(slotId);
    this.hasSimCard(0);
    this.hasSimCard(1);
    this.onInit();
    LogUtils.i(TAG, 'updateOperatorName end');
  }

  setNoSimNameChange(slotId: number) {
    if (slotId === 0) {
      this.isOpened1 = false;
      this.cardInfoSimName1 = getString($r('app.string.sim_no_card_inserted'));
    } else {
      this.isOpened2 = false;
      this.cardInfoSimName2 = getString($r('app.string.sim_no_card_inserted'));
    }
    this.updatePhoneNumber(slotId, '');
  }

  /**
   * Get card status
   */
  async getSimState(slotId: number) {
    this.getSupportNetwork(slotId);
    this.hasSimCard(slotId);
    SimServiceProxy.getSimState(slotId).then((res: number) => {
      LogUtils.i(TAG, `getSimstate: slotId=${JSON.stringify(slotId)},state=${JSON.stringify(res)}`);
      if (slotId === SLOT_1) {
        this.simState1 = res;
      } else {
        this.simState2 = res;
      }
      if (res === SimStateConst.SIM_STATE_READY || res === SimStateConst.SIM_STATE_LOADED) {
        this.list[slotId].disabled = true;
        this.isSimActive(slotId);
      } else if (res === SimStateConst.SIM_STATE_LOCKED) {
        this.handleSimStateLocked(slotId);
      } else if (res === SimStateConst.SIM_STATE_NOT_READY) {
        if (slotId === 0) {
          this.cardInfoSimName1 = getString($r('app.string.sim_no_service'));
          this.isOpened1 = false;
        } else {
          this.cardInfoSimName2 = getString($r('app.string.sim_no_service'));
          this.isOpened2 = false;
        }
        this.getShowNumber(slotId);
      } else if (res === SimStateConst.SIM_STATE_NOT_PRESENT) {
        this.setNoSimNameChange(slotId);
        this.list[slotId].disabled = false;
        this.list[slotId].info = '4G/3G/2G';
      } else if (res === SimStateConst.SIM_STATE_UNKNOWN) {
        if (slotId === 0) {
          this.cardInfoSimName1 = getString($r('app.string.sim_no_service'));
        } else {
          this.cardInfoSimName2 = getString($r('app.string.sim_no_service'));
        }
        this.list[slotId].disabled = false;
      }
      this.setSimActiveLoadingDialog.close();
      clearTimeout(this.timer);
    }).catch(() => {
      this.setNoSimNameChange(slotId);
      this.list[slotId].disabled = false;
    });
  }

  private handleSimStateLocked(slotId: number) {
    this.list[slotId].disabled = true;
    this.getLockType(slotId);
    if (slotId === 0) {
      this.cardInfoSimName1 = getString($r('app.string.sim_not_enabled'));
      this.isOpened1 = false;
    } else {
      this.cardInfoSimName2 = getString($r('app.string.sim_not_enabled'));
      this.isOpened2 = false;
    }
  }

  async getSlotId(callback: (slotId: number) => void) {
    let context = SimCardGlobalContextHelper.getInstance()
      .getValue<common.UIExtensionContext>(Constants.SIM_CARD_ABILITY_CONTEXT);
    if (typeof context !== 'undefined' && context !== null) {
      let slotId: number = Number(settings.getValueSync(context, 'satellite_slot_id', '-1'));
      LogUtils.i(TAG, 'getSlotId:' + JSON.stringify(slotId));
      callback(slotId);
    }
  }

  onInit() {
    this.getSimState(0);
    this.getSimState(1);
  }

  doStopSim() {
    const simOne = simIdFormat(SLOT_1 + 1);
    const simTwo = simIdFormat(SLOT_2 + 1);
    this.disablePrimaryDialogTitle = getContext(this).resourceManager
      .getStringSync($r('app.string.stop_use_card').id, simIdFormat(this.curEditList.id + 1));
    this.disablePrimaryDialogMessage = $r('app.string.sim_mobile_data_change',
      `${this.curEditList.id === 0 ? simTwo : simOne}`, simIdFormat(this.curEditList.id + 1));
    this.disablePrimaryCardDialog.open();
  }

  /**
   * Get the phone number of sim card
   */
  getPhoneNumber(slotId: number) {
    SimServiceProxy.getSimTelephoneNumber(slotId).then((res: string) => {
      this.updatePhoneNumber(slotId, res);
    }).catch(() => {
      this.updatePhoneNumber(slotId, '');
    });
  }

  setSimActivated(slotId: number, isActivated: boolean) {
    ReportUtil.getInstance().reportEnableCard(slotId, isActivated);
    if (slotId === 0) {
      this.isOpened1 = isActivated;
      this.isActivating1 = true;
    } else {
      this.isOpened2 = isActivated;
      this.isActivating2 = true;
    }
    SimServiceProxy.setSimActive(slotId, isActivated).then(() => {
      if (!isActivated && slotId === 0) {
        this.cardInfoSimName1 = getString($r('app.string.sim_not_enabled'));
        this.list[0].info = '4G/3G/2G';
      } else if (!isActivated && slotId === 1) {
        this.cardInfoSimName2 = getString($r('app.string.sim_not_enabled'));
        this.list[1].info = '4G/3G/2G';
      } else if (isActivated) {
        this.getShowName(slotId);
      }
      this.handleSetActivateEnd(slotId, true);
    }).catch(() => {
      this.handleSetActivateEnd(slotId, false);
    })
  }

  handleSetActivateEnd(slotId: number, isSucceed: boolean) {
    if (slotId === 0) {
      this.isActivating1 = false;
      if (!isSucceed) {
        this.isOpened1 = !this.isOpened1;
      }
    } else {
      this.isActivating2 = false;
      if (!isSucceed) {
        this.isOpened2 = !this.isOpened2;
      }
    }
    this.setSimActiveLoadingDialog.close();
    clearTimeout(this.timer);
  }

  /**
   * Whether the sim card is activated
   */
  isSimActive(slotId: number) {
    if (slotId === 0 && this.isActivating1) {
      return;
    }
    if (slotId === 1 && this.isActivating2) {
      return;
    }
    SimServiceProxy.isSimActive(slotId).then((res: boolean) => {
      LogUtils.i(TAG, 'isSimActive slotId=' + JSON.stringify(slotId) + ',res=' + JSON.stringify(res));
      if (slotId === 0 && this.list[slotId].isSimCardClosed) {
        if (!res) {
          this.isOpened1 = false;
          this.cardInfoSimName1 = getString($r('app.string.sim_not_enabled'));
          this.list[slotId].info = '4G/3G/2G';
        } else {
          this.isOpened1 = true;
          this.getShowName(0);
          this.getShowNumber(0);
        }
      } else if (slotId === 1 && this.list[slotId].isSimCardClosed) {
        if (!res) {
          this.isOpened2 = false;
          this.cardInfoSimName2 = getString($r('app.string.sim_not_enabled'));
          this.list[slotId].info = '4G/3G/2G';
        } else {
          this.isOpened2 = true;
          this.getShowName(1);
          this.getShowNumber(1);
        }
      }
    }).catch(() => {
      if (slotId === 0) {
        this.isOpened1 = false;
      } else {
        this.isOpened2 = false;
      }
    });
  }

  private getLockType(slotId: number) {
    pinModel.getSimLockType(slotId).then((res) => {
      this.lockType[slotId] = res;
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'getLockType err = ' + JSON.stringify(err));
    });
  }

  private isPukLocked(slotId: number): boolean {
    if (slotId === SLOT_1) {
      return this.simState1 === SimStateConst.SIM_STATE_LOCKED && this.lockType[SLOT_1] === LockType.PUK_LOCK;
    }
    if (slotId === SLOT_2) {
      return this.simState2 === SimStateConst.SIM_STATE_LOCKED && this.lockType[SLOT_2] === LockType.PUK_LOCK;
    }
    return false;
  }

  private onUnlockPinTouched(slotId: number, event: TouchEvent): HitTestMode {
    const state = slotId === SLOT_1 ? this.simState1 : this.simState2;
    if (event.type === TouchType.Down && state === SimStateConst.SIM_STATE_LOCKED) {
      this.unlockingPinInfo.slotId = slotId;
      if (!this.isPukLocked(slotId)) {
        this.pinViewModel.openOrCloseUnlockPinDialog(true);
      } else {
        this.unlockingPinInfo.updatePinScenario = UpdatePinScenario.RESET_BY_PUK;
        this.pinViewModel.openOrCloseVerifyPukDialog(true);
      }
      return HitTestMode.Block;
    } else {
      return HitTestMode.Default;
    }
  }

  private getPhoneNumberOrPinName(slotId: number): string {
    const state = slotId === SLOT_1 ? this.simState1 : this.simState2;
    if (state === SimStateConst.SIM_STATE_LOCKED) {
      return this.lockType[slotId] === LockType.PUK_LOCK ? getString($r('app.string.puk_locked')) : getString($r('app.string.pin_locked'));
    }
    const phoneNumber = slotId === SLOT_1 ? this.phone1Number : this.phone2Number;
    return StringUtils.formatPhoneNumberWhenRtl(phoneNumber);
  }

  getSupportNetwork(slotId: number) {
    getSupportNetwork(slotId).then((res) => {
      LogUtils.i(TAG, '4g/3g/2g/:' + JSON.stringify(slotId) + '   ' + JSON.stringify(res));
      if (res) {
        this.list[slotId].info = '5G/4G/3G/2G';
      } else {
        this.list[slotId].info = '4G/3G/2G';
      }
    }).catch(() => {
    });
  }

  addRegisterImsRegStateChange(slotId: number) {
    if (slotId === SLOT_1) {
      registerImsRegStateChange(slotId, this.onImsRegStateChange1);
    } else {
      registerImsRegStateChange(slotId, this.onImsRegStateChange2);
    }
  }

  addRegisterSimStateChange(slotId: number) {
    if (slotId === SLOT_1) {
      registerSimStateChange(SLOT_1, this.onSimStateChanged1)
    } else {
      registerSimStateChange(SLOT_2, this.onSimStateChanged2)
    }
  }

  addRegisterAccountInfoChange() {
    registerAccountInfoChange(this.onAccountInfoChanged);
  }

  addRegisterNetworkStateChange(slotId: number) {
    if (slotId === SLOT_1) {
      registerNetworkStateChange(slotId, this.onNetworkStateChange1);
    } else {
      registerNetworkStateChange(slotId, this.onNetworkStateChange2);
    }
  }

  UpdateSatelliteSlotId() {
    this.getSlotId((slotId: number) => {
      this.satelliteSlotId = this.isSatelliteOn ? slotId : -1;
    })
  }

  private calculateEditImgStartMargin(slotId: number, newWidth: number) {
    this.infoAreaWidths[slotId] = newWidth;
    if (this.infoAreaWidths[SLOT_1] === 0 || this.infoAreaWidths[SLOT_2] === 0) {
      this.editImgStartMargins = [LengthMetrics.resource($r('app.float.wh_value_12')),
        LengthMetrics.resource($r('app.float.wh_value_12'))];
      return;
    }
    if (this.infoAreaWidths[SLOT_1] > this.infoAreaWidths[SLOT_2]) {
      let diffValue = this.infoAreaWidths[SLOT_1] - this.infoAreaWidths[SLOT_2];
      this.editImgStartMargins[SLOT_1] = LengthMetrics.resource($r('app.float.wh_value_12'));
      this.editImgStartMargins[SLOT_2] = LengthMetrics.vp(getNumber($r('app.float.wh_value_12')) + diffValue);
    } else {
      let diffValue = this.infoAreaWidths[SLOT_2] - this.infoAreaWidths[SLOT_1];
      this.editImgStartMargins[SLOT_2] = LengthMetrics.resource($r('app.float.wh_value_12'));
      this.editImgStartMargins[SLOT_1] = LengthMetrics.vp(getNumber($r('app.float.wh_value_12')) + diffValue);
    }
  }

  onToggle1Changed(isOn: boolean) {
    if (isOn === this.isOpened1) {
      return;
    }
    LogUtils.i(TAG, 'onclick toggle card one')
    this.upDataTitle = getContext(this).resourceManager.getStringSync(this.list[0].title.id, simIdFormat(1));
    if (this.isOpened2 && this.isOpened1 && this.isCardChange) {
      this.title = $r('app.string.sim_card_one_no_space');
      this.curEditList = this.list[0];
      this.isOpened1 = isOn;
      this.doStopSim();
      this.stopCard(this.list[0], false);
    } else if (!this.isOpened1 && this.isOpened2) {
      this.updateInfo(true);
      this.setSimActivated(0, true);
      this.stopCard(this.list[0], true);
      this.cardSwitchTarget = 1;
    } else if (this.isOpened1 && this.isOpened2 && !this.isCardChange) {
      this.updateInfo(false);
      this.setSimActivated(0, false);
      this.stopCard(this.list[0], false);
      this.cardSwitchTarget = 1;
    } else if (!this.isOpened1 && !this.isOpened2) {
      this.updateInfo(true);
      this.setSimActivated(0, true);
    } else if (this.isOpened1 && !this.isOpened2) {
      this.updateInfo(false);
      this.setSimActivated(0, false);
      this.stopCard(this.list[0], false);
    } else if (this.isOpened1 || !this.isOpened2) {
      this.stopCard(this.list[0], false);
    }
  }

  onToggle2Changed(isOn: boolean) {
    if (isOn === this.isOpened2) {
      return;
    }
    LogUtils.i(TAG, 'onclick toggle card two');
    this.upDataTitle = getContext(this).resourceManager.getStringSync(this.list[1].title.id, simIdFormat(2));
    if (this.isOpened1 && this.isOpened2 && !this.isCardChange) {
      this.title = $r('app.string.sim_card_two_no_space', simIdFormat(2));
      this.curEditList = this.list[1];
      this.isOpened2 = isOn;
      this.doStopSim();
      this.stopCard(this.list[1], false);
    } else if (this.isOpened1 && !this.isOpened2) {
      this.updateInfo(true);
      this.setSimActivated(1, true);
      this.stopCard(this.list[1], true);
      this.cardSwitchTarget = 2;
    } else if (this.isOpened1 && this.isOpened2 && this.isCardChange) {
      this.updateInfo(false);
      this.setSimActivated(1, false);
      this.stopCard(this.list[1], false);
      this.cardSwitchTarget = 2;
    } else if (!this.isOpened1 && !this.isOpened2) {
      this.updateInfo(true);
      this.setSimActivated(1, true);
    } else if (!this.isOpened1 && this.isOpened2) {
      this.updateInfo(false);
      this.setSimActivated(1, false);
      this.stopCard(this.list[1], false);
    } else if (!this.isOpened1 || this.isOpened2) {
      this.stopCard(this.list[1], false);
    }
  }

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    this.initViewModel();
    this.onInit();
    if (this.maxSimSlotCount === MAX_SIM_COUNT) {
      this.addRegisterSimStateChange(1);
      this.addRegisterNetworkStateChange(1);
      this.addRegisterImsRegStateChange(1);
      this.getLockType(SLOT_2);
    }
    this.addRegisterNetworkStateChange(0);
    this.addRegisterAccountInfoChange();
    this.addRegisterSimStateChange(0);
    this.addRegisterImsRegStateChange(0);
    this.getLockType(SLOT_1);
  }

  aboutToDisappear() {
    LogUtils.i(TAG, 'aboutToDisappear');
    this.pinViewModel.closeAllDialogs();
    if (this.maxSimSlotCount === MAX_SIM_COUNT) {
      unRegisterImsRegStateChange(SLOT_2, this.onImsRegStateChange2);
      unRegisterSimStateChange(this.onSimStateChanged2)
      unRegisterNetworkStateChange(this.onNetworkStateChange2);
    }
    unRegisterImsRegStateChange(SLOT_1, this.onImsRegStateChange1);
    unRegisterSimStateChange(this.onSimStateChanged1);
    unRegisterAccountInfoChange(this.onAccountInfoChanged);
    unRegisterNetworkStateChange(this.onNetworkStateChange1);
    this.clearPhoneNumberDelay();
  }

  onPageShow() {
    this.updateOperatorName();
  }

  isSatelliteSimTipsNeedShow(slotId: number): boolean {
    if (!this.isSatelliteOn || this.satelliteSlotId == -1) {
      return false;
    }
    if (this.satelliteSlotId == slotId) {
      return true;
    }
    let hasSimCardLocal = (slotId == 0) ? this.list[0].hasCard : this.list[1].hasCard;
    if (!this.isAirPlaneMode && hasSimCardLocal) {
      return true;
    }
    return false;
  }

  build() {
    Column() {
      Row() {
        Row() {
          Stack({ alignContent: Alignment.Start }) {
            Image($r('app.media.card'))
              .width($r('app.float.value_64'))
              .height($r('app.float.value_44'))
              .fillColor($r('sys.color.comp_foreground_primary'))
              .opacity($r('sys.float.alpha_fourth'))
              .matchTextDirection(true)

            Text(this.list[0].title)
              .fontSize('12vp')
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Regular)
              .fontFamily('HarmonyHeiTi')
              .margin({ left: $r('sys.float.padding_level5'), right: $r('sys.float.padding_level5') })
          }

          Column() {
            Text((this.isAirPlaneMode && this.list[0].hasCard && this.isOpened1) ? $r('app.string.sim_no_service') :
            this.cardInfoSimName1)
              .maxLines(2)
              .fontSize($r('sys.float.Body_L'))
              .fontColor($r('sys.color.font_primary'))
              .margin({ bottom: $r('app.float.wh_value_2') })
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Medium)
              .lineHeight($r('app.float.wh_value_21'))
              .alignSelf(ItemAlign.Start)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .flexShrink(1)
            if (this.phone1Number || this.simState1 === SimStateConst.SIM_STATE_LOCKED) {
              Text(this.getPhoneNumberOrPinName(SLOT_1))
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.Body_M'))
                .margin({ bottom: this.phone2Number ? $r('app.float.value_0') : $r('app.float.wh_value_2') })
                .lineHeight($r('app.float.value_19'))
                .fontFamily('HarmonyHeiTi')
                .fontWeight(FontWeight.Regular)
                .alignSelf(ItemAlign.Start)
            }
            if (this.isSatelliteSimTipsNeedShow(0)) {
              Text((this.satelliteSlotId == 0) ?
              $r('app.string.satellite_sim_tips') : $r('app.string.satellite_other_sim_tips'))
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.Body_M'))
                .margin({ bottom: this.phone2Number ? $r('app.float.value_0') : $r('app.float.wh_value_2') })
                .lineHeight($r('app.float.value_19'))
                .fontFamily('HarmonyHeiTi')
                .fontWeight(FontWeight.Regular)
                .alignSelf(ItemAlign.Start)
            }
            Text(needFilterEflInfo() ? '' : this.list[0].info)
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.Body_S'))
              .lineHeight($r('app.float.value_19'))
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Regular)
              .alignSelf(ItemAlign.Start)
          }
          .flexShrink(1)
          .margin({ start: LengthMetrics.resource($r('app.float.value_16')) })
          .constraintSize({ minWidth: $r('app.float.value_96') })
          .enabled(this.isOpened1 && !this.isAirPlaneMode && !this.isSatelliteOn &&
            this.simState1 !== SimStateConst.SIM_STATE_UNKNOWN)
          .onAreaChange((oldValue, newValue) => {
            this.calculateEditImgStartMargin(SLOT_1, newValue.width.valueOf() as number);
          })
          .onClick(() => {
            this.editSimInfo(this.list[0]);
          })

          Button() {
            Image($r('app.media.ic_public_edit'))
              .width($r('app.float.value_12_vp'))
              .height($r('app.float.value_12_vp'))
              .fillColor($r('sys.color.comp_foreground_primary'))
              .matchTextDirection(true)
          }
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .stateEffect(false)
          .accessibilityText($r('app.string.accessibility_edit'))
          .visibility(this.infoAreaWidths[SLOT_1] === 0 ? Visibility.Hidden : Visibility.Visible)
          .margin({
            start: this.editImgStartMargins[SLOT_1],
            end: LengthMetrics.resource($r('app.float.wh_value_24'))
          })
          .enabled(this.isOpened1 && !this.isAirPlaneMode && !this.isSatelliteOn &&
            this.simState1 !== SimStateConst.SIM_STATE_UNKNOWN)
          .onClick(() => {
            this.editSimInfo(this.list[0]);
          })
        }
        .flexShrink(1)
        .opacity((this.simState1 !== SimStateConst.SIM_STATE_UNKNOWN && this.isOpened1 && !this.isAirPlaneMode &&
          !this.isCalling && !this.isSatelliteOn) ? $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))

        Blank()

        Row() {
          if (this.simState1 !== SimStateConst.SIM_STATE_UNKNOWN && this.list[0].disabled && !this.isAirPlaneMode &&
            !this.isCalling && !this.isDefaultDataChanging && !this.isSatelliteOn && !this.isPukLocked(SLOT_1)) {
            Toggle({ type: ToggleType.Switch, isOn: this.isOpened1 })
              .width($r('app.float.value_36'))
              .height($r('app.float.value_20'))
              .margin($r('app.float.value_0'))
              .selectedColor($r('sys.color.icon_emphasize'))
              .switchPointColor($r('sys.color.comp_background_primary_contrary'))
              .enabled(true)
              .onChange((isOn) => {
                this.onToggle1Changed(isOn);
              })
          } else {
            Toggle({ type: ToggleType.Switch, isOn: this.isOpened1 })
              .width($r('app.float.value_36'))
              .height($r('app.float.value_20'))
              .margin($r('app.float.value_0'))
              .selectedColor($r('sys.color.icon_emphasize'))
              .switchPointColor($r('sys.color.comp_background_primary_contrary'))
              .enabled(false)
              .onChange((isOn) => {
                this.onToggle1Changed(isOn);
              })
          }
        }.onTouchIntercept((event: TouchEvent) => {
          return this.onUnlockPinTouched(SLOT_1, event);
        })
      }
      .enabled(this.list[0].disabled && !this.isAirPlaneMode && !this.isCalling && !this.isSatelliteOn &&
        this.simState1 !== SimStateConst.SIM_STATE_UNKNOWN)
      .padding({
        left: $r('sys.float.padding_level6'),
        right: $r('sys.float.padding_level6'),
        top: $r('app.float.value_13_5'),
        bottom: $r('app.float.value_13_5')
      })
      .width('100%')
      .borderRadius($r('sys.float.corner_radius_level10'))
      .backgroundColor($r('sys.color.comp_background_primary'))
      .constraintSize({ minHeight: $r('app.float.value_72') })

      if (this.maxSimSlotCount === MAX_SIM_COUNT) {
        Column() {
        }
        .height($r('app.float.wh_value_12'))
        .width('100%')

        Row() {
          Row() {
            Stack({ alignContent: Alignment.Start }) {
              Image($r('app.media.card'))
                .width($r('app.float.value_64'))
                .height($r('app.float.value_44'))
                .fillColor($r('sys.color.comp_foreground_primary'))
                .opacity($r('sys.float.alpha_fourth'))
                .matchTextDirection(true)

              Text(this.list[1].title)
                .fontSize('12vp')
                .fontColor($r('sys.color.font_primary'))
                .align(Alignment.Start)
                .fontWeight(FontWeight.Regular)
                .fontFamily('HarmonyHeiTi')
                .margin({ left: $r('sys.float.padding_level5'), right: $r('sys.float.padding_level5') })
            }

            Column() {
              Text((this.isAirPlaneMode && this.list[1].hasCard && this.isOpened2) ? $r('app.string.sim_no_service') :
              this.cardInfoSimName2)
                .maxLines(2)
                .fontSize($r('sys.float.Body_L'))
                .fontColor($r('sys.color.font_primary'))
                .margin({ bottom: $r('app.float.wh_value_2') })
                .fontFamily('HarmonyHeiTi')
                .fontWeight(FontWeight.Medium)
                .lineHeight($r('app.float.wh_value_21'))
                .alignSelf(ItemAlign.Start)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .flexShrink(1)
              if (this.phone2Number || this.simState2 === SimStateConst.SIM_STATE_LOCKED) {
                Text(this.getPhoneNumberOrPinName(SLOT_2))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.Body_M'))
                  .margin({ bottom: this.phone2Number ? $r('app.float.value_0') : $r('app.float.wh_value_2') })
                  .lineHeight($r('app.float.value_19'))
                  .fontFamily('HarmonyHeiTi')
                  .fontWeight(FontWeight.Regular)
                  .alignSelf(ItemAlign.Start)
              }
              if (this.isSatelliteSimTipsNeedShow(1)) {
                Text((this.satelliteSlotId == 1) ?
                $r('app.string.satellite_sim_tips') : $r('app.string.satellite_other_sim_tips'))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.Body_M'))
                  .margin({ bottom: this.phone2Number ? $r('app.float.value_0') : $r('app.float.wh_value_2') })
                  .lineHeight($r('app.float.value_19'))
                  .fontFamily('HarmonyHeiTi')
                  .fontWeight(FontWeight.Regular)
                  .alignSelf(ItemAlign.Start)
              }
              Text(needFilterEflInfo() ? '' : this.list[1].info)
                .fontSize($r('sys.float.Body_S'))
                .fontColor($r('sys.color.font_secondary'))
                .lineHeight($r('app.float.value_19'))
                .fontFamily('HarmonyHeiTi')
                .fontWeight(FontWeight.Regular)
                .alignSelf(ItemAlign.Start)
            }
            .flexShrink(1)
            .margin({ start: LengthMetrics.resource($r('app.float.value_16')) })
            .constraintSize({ minWidth: $r('app.float.value_96') })
            .enabled(this.isOpened2 && !this.isAirPlaneMode && !this.isSatelliteOn &&
              this.simState2 !== SimStateConst.SIM_STATE_UNKNOWN)
            .onAreaChange((oldValue, newValue) => {
              this.calculateEditImgStartMargin(SLOT_2, newValue.width.valueOf() as number);
            })
            .onClick(() => {
              this.editSimInfo(this.list[1]);
            })

            Button() {
              Image($r('app.media.ic_public_edit'))
                .width($r('app.float.value_12_vp'))
                .height($r('app.float.value_12_vp'))
                .fillColor($r('sys.color.comp_foreground_primary'))
                .matchTextDirection(true)
            }
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .stateEffect(false)
            .accessibilityText($r('app.string.accessibility_edit'))
            .visibility(this.infoAreaWidths[SLOT_2] === 0 ? Visibility.Hidden : Visibility.Visible)
            .margin({
              start: this.editImgStartMargins[SLOT_2],
              end: LengthMetrics.resource($r('app.float.wh_value_24'))
            })
            .enabled(this.isOpened2 && !this.isAirPlaneMode && !this.isSatelliteOn &&
              this.simState2 !== SimStateConst.SIM_STATE_UNKNOWN)
            .onClick(() => {
              this.editSimInfo(this.list[1]);
            })
          }
          .flexShrink(1)
          .opacity((this.simState2 !== SimStateConst.SIM_STATE_UNKNOWN && this.isOpened2 && !this.isAirPlaneMode &&
            !this.isCalling && !this.isSatelliteOn) ? $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))

          Blank()

          Row() {
            if (this.simState2 !== SimStateConst.SIM_STATE_UNKNOWN && this.list[1].disabled && !this.isAirPlaneMode &&
              !this.isCalling && !this.isDefaultDataChanging && !this.isSatelliteOn && !this.isPukLocked(SLOT_2)) {
              Toggle({ type: ToggleType.Switch, isOn: this.isOpened2 })
                .width($r('app.float.value_36'))
                .height($r('app.float.value_20'))
                .margin($r('app.float.value_0'))
                .selectedColor($r('sys.color.icon_emphasize'))
                .switchPointColor($r('sys.color.comp_background_primary_contrary'))
                .enabled(true)
                .onChange((isOn) => {
                  this.onToggle2Changed(isOn);
                })
            } else {
              Toggle({ type: ToggleType.Switch, isOn: this.isOpened2 })
                .width($r('app.float.value_36'))
                .height($r('app.float.value_20'))
                .margin($r('app.float.value_0'))
                .selectedColor($r('sys.color.icon_emphasize'))
                .switchPointColor($r('sys.color.comp_background_primary_contrary'))
                .enabled(false)
                .onChange((isOn) => {
                  this.onToggle2Changed(isOn);
                })
            }
          }.onTouchIntercept((event: TouchEvent) => {
            return this.onUnlockPinTouched(SLOT_2, event);
          })
        }
        .enabled(this.list[1].disabled && !this.isAirPlaneMode && !this.isCalling && !this.isSatelliteOn &&
          this.simState2 !== SimStateConst.SIM_STATE_UNKNOWN)
        .padding({
          left: $r('sys.float.padding_level6'),
          right: $r('sys.float.padding_level6'),
          top: $r('app.float.value_13_5'),
          bottom: $r('app.float.value_13_5')
        })
        .width('100%')
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius($r('sys.float.corner_radius_level10'))
        .constraintSize({ minHeight: $r('app.float.value_72') })
      }
    }
    .width('100%')
  }
}
