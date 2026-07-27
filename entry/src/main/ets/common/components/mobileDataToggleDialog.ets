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

import { addAirPlaneModeListener, removeAirPlaneModeListener } from '../../common/utils/AirplaneMode';
import SimServiceProxy from '../../model/simServiceProxy';
import LogUtils from '../../common/utils/LogUtils';
import { simIdFormat } from '../utils/SimIdFormat';
import { LockType, MAX_SIM_COUNT, PRIMARY_SLOT_ID_NOT_INIT, SIM_SLOT_COUNT_1, SLOT_1, SLOT_2 } from '../utils/constant';
import { getOperatorName, getPrimarySlotId, getSupportNetwork, setPrimarySlotId } from '../../model/radioServiceProxy';
import SimStateConst from '../utils/SimStateConst';
import { BusinessError } from '@ohos.base';
import {
  getMaxSimCount,
  registerCallStateChange,
  registerNetworkStateChange,
  registerSimStateChange,
  unRegisterCallStateChange,
  unRegisterNetworkStateChange,
  unRegisterSimStateChange
} from '../../model/registerSimStateApi';
import common from '@ohos.app.ability.common';
import { AppStorageUtils } from '../utils/AppStorageUtils';
import { StringUtils } from '../../utils/StringUtils';
import CardInfoStruct from '../struct/CardInfoStruct';
import pinModel from '../../model/pinModel';
import telephonyData from '@ohos.telephony.data';
import { observer } from '../../model/api';
import { FontScaleState } from '../utils/fontScaleState';
import { LengthMetrics } from '@kit.ArkUI';
import call from '@ohos.telephony.call';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { uiEffect } from '@kit.ArkGraphics2D';

const TAG = 'mobileDataToggleDialog';

@Extend(Text)
function simCardInfoTextStyle() {
  .fontSize($r('sys.float.Body_M'))
  .fontWeight(FontWeight.Regular)
  .fontFamily('HarmonyHeiTi')
}

@Extend(Text)
function simCardTextStyle() {
  .fontSize($r('sys.float.Body_L'))
  .fontWeight(FontWeight.Medium)
  .fontFamily('HarmonyHeiTi')
}

@Extend(Image)
function checkMarkStyle() {
  .height($r('app.float.font_18'))
  .width($r('app.float.font_18'))
  .matchTextDirection(false)
}

let blenderDark: uiEffect.BrightnessBlender = uiEffect.createBrightnessBlender({
  cubicRate: 1,
  quadraticRate: 1,
  linearRate: 1,
  degree: 153 / 255,
  saturation: 1.2,
  positiveCoefficient: [1, 2, 1],
  negativeCoefficient: [0.5, 1, 0.5],
  fraction: 0
});

let textInfoBlenderDark: uiEffect.BrightnessBlender = uiEffect.createBrightnessBlender({
  cubicRate: 0.1239,
  quadraticRate: 0.1239,
  linearRate: 0.1239,
  degree: 229.5 / 255,
  saturation: 2,
  positiveCoefficient: [1.6, 3, 1.5],
  negativeCoefficient: [1.2, 1.2, 1],
  fraction: 0
});

let blenderLight: uiEffect.BrightnessBlender = uiEffect.createBrightnessBlender({
  cubicRate: 0.4,
  quadraticRate: 0.4,
  linearRate: 0.4,
  degree: -25 / 255,
  saturation: 1.5,
  positiveCoefficient: [1.9, 3.8, 1.3],
  negativeCoefficient: [0.5, 0.67, 1.3],
  fraction: 1
});

@Entry
@Component
export default struct MobileDataToggleDialog {
  @State cardInfoSimName1: string = '';
  @State cardInfoSimName2: string = '';
  @State isAirPlaneMode: boolean = false;
  @State maxSimSlotCount: number = -1;
  @State simState1: number = SimStateConst.SIM_STATE_UNKNOWN;
  @State simState2: number = SimStateConst.SIM_STATE_UNKNOWN;
  @State isDefaultDataChanging: boolean = false;
  @Watch('ifWindowClose') @State isOpened1: boolean = true;
  @Watch('ifWindowClose') @State isOpened2: boolean = true;
  @State isDataEnable: boolean = false;
  @Watch('onPrimarySlotIdChanged') @State primarySlotId: number = PRIMARY_SLOT_ID_NOT_INIT;
  @Watch('onSelectedChanged') @State selectedIndexes: number[] = [0];
  @StorageLink(AppStorageUtils.SIM_LOCK_TYPES) lockType: LockType[] =
    [LockType.NOT_LOCKED, LockType.NOT_LOCKED];
  @State number1: string = '';
  @State number2: string = '';
  @State isCallings: boolean[] = [false, false];
  @State isCalling: boolean = false;
  @State colorMode: number = 0;
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  @State list: Array<CardInfoStruct> = [
    {
      id: 0,
      title: $r('app.string.sim_card_one_no_space', simIdFormat(1)),
      isOpened: false,
      disabled: true,
      info: '',
      isSimCardClosed: false,
      hasCard: false
    },
    {
      id: 1,
      title: $r('app.string.sim_card_two_no_space', simIdFormat(2)),
      isOpened: false,
      disabled: true,
      info: '',
      isSimCardClosed: false,
      hasCard: false
    }
  ];
  private onSimStateChanged1: Callback<observer.SimStateData> = (simStateData: observer.SimStateData) => {
    LogUtils.i(TAG, 'onSimStateChanged slotId=' + SLOT_1 + ',simstate=' + JSON.stringify(simStateData));
    this.getShowNumber(SLOT_1);
  };
  private onSimStateChanged2: Callback<observer.SimStateData> = (simStateData: observer.SimStateData) => {
    LogUtils.i(TAG, 'onSimStateChanged slotId=' + SLOT_2 + ',simstate=' + JSON.stringify(simStateData));
    this.getShowNumber(SLOT_2);
  };
  private onNetworkStateChange1: Callback<observer.NetworkState> = (networkState: observer.NetworkState) => {
    LogUtils.i(TAG, 'onNetworkStateChange slotId=' + SLOT_1 + ',newworkState=' + JSON.stringify(networkState));
    this.update();
  };
  private onNetworkStateChange2: Callback<observer.NetworkState> = (networkState: observer.NetworkState) => {
    LogUtils.i(TAG, 'onNetworkStateChange slotId=' + SLOT_2 + ',newworkState=' + JSON.stringify(networkState));
    this.update();
  };
  private onCallStateChanged1: Callback<observer.CallStateInfo> = (callStateInfo: observer.CallStateInfo) => {
    LogUtils.i(TAG, 'onCallStateChanged slotId=' + SLOT_1 + ',callStateInfo=' + JSON.stringify(callStateInfo));
    this.handleOnCallStateChanged(SLOT_1, callStateInfo);
  };
  private onCallStateChanged2: Callback<observer.CallStateInfo> = (callStateInfo: observer.CallStateInfo) => {
    LogUtils.i(TAG, 'onCallStateChanged slotId=' + SLOT_2 + ',callStateInfo=' + JSON.stringify(callStateInfo));
    this.handleOnCallStateChanged(SLOT_2, callStateInfo);
  };
  private session: UIExtensionContentSession | undefined =
    LocalStorage.getShared().get<UIExtensionContentSession>('uiExtensionSession');

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
    .borderRadius($r('sys.float.corner_radius_level8'))
    .opacity(1)
  }

  @Styles
  normalStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_background_transparent'))
    .borderRadius($r('sys.float.corner_radius_level8'))
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    let context = getContext(this) as common.UIExtensionContext
    this.colorMode = Number(context.config.colorMode);
    this.initData();
    this.initSimActivatedSwitch();
    this.getPrimarySlotId();
    this.initAirPlaneMode();
    this.getCellularDataState();
    this.getCallState();
    if (this.maxSimSlotCount === MAX_SIM_COUNT) {
      registerSimStateChange(SLOT_2, this.onSimStateChanged2);
      registerNetworkStateChange(SLOT_2, this.onNetworkStateChange2);
      registerCallStateChange(SLOT_2, this.onCallStateChanged2);
      this.getLockType(SLOT_2);
    }
    registerSimStateChange(SLOT_1, this.onSimStateChanged1);
    registerNetworkStateChange(SLOT_1, this.onNetworkStateChange1);
    registerCallStateChange(SLOT_1, this.onCallStateChanged1);
    this.getLockType(SLOT_1);
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    if (this.maxSimSlotCount === MAX_SIM_COUNT) {
      unRegisterSimStateChange(this.onSimStateChanged2);
      unRegisterCallStateChange(this.onCallStateChanged2);
      unRegisterNetworkStateChange(this.onNetworkStateChange2);
    }
    unRegisterSimStateChange(this.onSimStateChanged1);
    unRegisterCallStateChange(this.onCallStateChanged1);
    unRegisterNetworkStateChange(this.onNetworkStateChange1);
    removeAirPlaneModeListener();
  }

  private initData() {
    this.maxSimSlotCount = getMaxSimCount();
    LogUtils.i(TAG, `initData maxSimSlotCount = ${JSON.stringify(this.maxSimSlotCount)}`);
    this.getSimState(SLOT_1);
    this.getSimState(SLOT_2);
  }

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
        if (slotId === SLOT_1) {
          this.cardInfoSimName1 = this.getString($r('app.string.sim_no_service'));
          this.isOpened1 = false;
        } else {
          this.cardInfoSimName2 = this.getString($r('app.string.sim_no_service'));
          this.isOpened2 = false;
        }
        this.getShowNumber(slotId);
      } else if (res === SimStateConst.SIM_STATE_NOT_PRESENT) {
        if (slotId === SLOT_1) {
          this.isOpened1 = false;
          this.cardInfoSimName1 = this.getString($r('app.string.sim_no_card_inserted'));
          this.number1 = '';
        } else {
          this.isOpened2 = false;
          this.cardInfoSimName2 = this.getString($r('app.string.sim_no_card_inserted'));
          this.number2 = '';
        }
        this.list[slotId].disabled = false;
        this.list[slotId].info = '4G/3G/2G';
      } else if (res === SimStateConst.SIM_STATE_UNKNOWN) {
        if (slotId === SLOT_1) {
          this.cardInfoSimName1 = this.getString($r('app.string.sim_no_service'));
        } else {
          this.cardInfoSimName2 = this.getString($r('app.string.sim_no_service'));
        }
        this.list[slotId].disabled = false;
      }
    }).catch(() => {
      this.setNoSimNameChange(slotId);
      this.list[slotId].disabled = false;
    });
  }

  getCallState() {
    call.getCallState().then((data: call.CallState) => {
      LogUtils.i(TAG, `getCallState success, promise: data->${JSON.stringify(data)}`)
      this.isCalling = data.valueOf() === 1 || data.valueOf() === 2;
    }).catch((err: BusinessError) => {
      LogUtils.i(TAG, `getCallState fail, promise: err->${JSON.stringify(err)}`)
    });
  }

  handleOnCallStateChanged(slotId: number, callStateInfo: observer.CallStateInfo) {
    this.isCallings[slotId] = callStateInfo.state === 1 || callStateInfo.state === 2;
    this.isCalling = this.isCallings[SLOT_1] || this.isCallings[SLOT_2];
  }

  setNoSimNameChange(slotId: number) {
    if (slotId === SLOT_1) {
      this.isOpened1 = false;
      this.cardInfoSimName1 = this.getString($r('app.string.sim_no_card_inserted'));
      this.number1 = '';
    } else {
      this.isOpened2 = false;
      this.cardInfoSimName2 = this.getString($r('app.string.sim_no_card_inserted'));
      this.number2 = '';
    }
  }

  hasSimCard(slotId: number) {
    SimServiceProxy.hasSimCard(slotId).then((res: boolean) => {
      LogUtils.i(TAG, 'getSimState: hasSimCard card slotId=' +
      JSON.stringify(slotId) + ', res=' + JSON.stringify(res));
      this.list[slotId].isSimCardClosed = res;
      this.list[slotId].hasCard = res;
    }).catch(() => {
    });
  };

  handleSimStateLocked(slotId: number) {
    this.list[slotId].disabled = true;
    this.getLockType(slotId);
    if (slotId === SLOT_1) {
      this.cardInfoSimName1 = this.getString($r('app.string.sim_not_enabled'));
      this.isOpened1 = false;
    } else {
      this.cardInfoSimName2 = this.getString($r('app.string.sim_not_enabled'));
      this.isOpened2 = false;
    }
  }

  getString(value: Resource) {
    const context = getContext(this);
    if (typeof context !== 'undefined' && context !== null) {
      return context.resourceManager.getStringSync(value.id);
    }
    LogUtils.e(TAG, 'context is null')
    return '';
  }

  update() {
    LogUtils.i(TAG, 'updateOperatorName start');
    this.hasSimCard(SLOT_1);
    this.hasSimCard(SLOT_2);
    this.getSimState(SLOT_1);
    this.getSimState(SLOT_2);
    LogUtils.i(TAG, 'updateOperatorName end');
  }

  private getLockType(slotId: number) {
    pinModel.getSimLockType(slotId).then((res) => {
      this.lockType[slotId] = res;
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'getLockType err = ' + JSON.stringify(err));
    });
  }

  isSimActive(slotId: number) {
    SimServiceProxy.isSimActive(slotId).then((res: boolean) => {
      LogUtils.i(TAG, 'isSimActive slotId=' + JSON.stringify(slotId) + ',res=' + JSON.stringify(res));
      if (slotId === SLOT_1 && this.list[slotId].isSimCardClosed) {
        if (!res) {
          this.isOpened1 = false;
          this.cardInfoSimName1 = this.getString($r('app.string.sim_not_enabled'));
          this.list[slotId].info = '4G/3G/2G';
          this.getShowNumber(SLOT_1);
        } else {
          this.isOpened1 = true;
          this.getShowName(SLOT_1);
          this.getShowNumber(SLOT_1);
        }
      } else if (slotId === SLOT_2 && this.list[slotId].isSimCardClosed) {
        if (!res) {
          this.isOpened2 = false;
          this.cardInfoSimName2 = this.getString($r('app.string.sim_not_enabled'));
          this.list[slotId].info = '4G/3G/2G';
          this.getShowNumber(SLOT_2);
        } else {
          this.isOpened2 = true;
          this.getShowName(SLOT_2);
          this.getShowNumber(SLOT_2);
        }
      }
    }).catch(() => {
      if (slotId === SLOT_1) {
        this.isOpened1 = false;
      } else {
        this.isOpened2 = false;
      }
    });
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

  getShowName(slotId: number) {
    LogUtils.i(TAG, 'getShowName in cardinfomation');
    SimServiceProxy.getShowName(slotId).then((res: string) => {
      if (res === '' || res === null) {
        this.getNetName(slotId);
      } else {
        if (slotId === SLOT_1) {
          this.cardInfoSimName1 = res;
        } else {
          this.cardInfoSimName2 = res;
        }
      }
    }).catch(() => {
      this.getNetName(slotId);
    })
  }

  getNetName(slotId: number) {
    getOperatorName(slotId).then((res: string) => {
      if (slotId === SLOT_1) {
        if (res === null || res === '') {
          this.cardInfoSimName1 = this.getString($r('app.string.sim_no_service'));
        } else {
          this.cardInfoSimName1 = res;
        }
      } else {
        if (res === null || res === '') {
          this.cardInfoSimName2 = this.getString($r('app.string.sim_no_service'));
        } else {
          this.cardInfoSimName2 = res;
        }
      }
    }).catch(() => {
    });
  }

  initAirPlaneMode() {
    LogUtils.i(TAG, 'initAirPlaneMode');
    try {
      addAirPlaneModeListener((data: number) => {
        LogUtils.i(TAG, `onAirPlaneModeChanged callback data=${data.toString()}`);
        this.isAirPlaneMode = data == 1 ? true : false;
      });
    } catch (err) {
      LogUtils.e(TAG, `onAirPlaneModeChanged err = ${JSON.stringify(err)}`);
    }
  }

  initSimActivatedSwitch() {
    for (let slotId = SLOT_1; slotId < this.maxSimSlotCount; slotId++) {
      let isActivated = SimServiceProxy.isSimActivatedSync(slotId);
      if (slotId === SLOT_1) {
        this.isOpened1 = isActivated;
      } else {
        this.isOpened2 = isActivated;
      }
    }
  }

  getPrimarySlotId() {
    if (this.isDefaultDataChanging) {
      return;
    }
    getPrimarySlotId().then((res) => {
      LogUtils.i(TAG, 'getPrimarySlotId: then: ' + JSON.stringify(res));
      this.primarySlotId = res;
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `getPrimarySlotId err = ${JSON.stringify(err)}`);
      this.primarySlotId = SLOT_1;
    });
  }

  getCellularDataState() {
    telephonyData.isCellularDataEnabled()?.then((data) => {
      LogUtils.i(TAG, 'isCellularDataEnabled success: isON:' + JSON.stringify(data));
      this.isDataEnable = data;
    }).catch((error: BusinessError) => {
      LogUtils.i(TAG, 'isCellularDataEnabled error catch' + JSON.stringify(error));
    });
  }

  onPrimarySlotIdChanged() {
    LogUtils.i(TAG, 'onPrimarySlotIdChanged=' + JSON.stringify(this.primarySlotId))
    this.selectedIndexes[0] = this.primarySlotId;
  }

  onSelectedChanged() {
    LogUtils.i(TAG, 'onSelectedChanged=' + JSON.stringify(this.selectedIndexes))
    this.isDefaultDataChanging = true;
    setPrimarySlotId(this.selectedIndexes[0]).then(() => {
      this.isDefaultDataChanging = false;
    }).catch(() => {
      this.isDefaultDataChanging = false;
    });
  }

  private getPhoneNumberOrPinName(slotId: number): string {
    const state = slotId === SLOT_1 ? this.simState1 : this.simState2;
    if (state === SimStateConst.SIM_STATE_LOCKED) {
      return this.lockType[slotId] === LockType.PUK_LOCK ?
      this.getString($r('app.string.puk_locked')) : this.getString($r('app.string.pin_locked'));
    }
    const phoneNumber = slotId === SLOT_1 ? this.number1 : this.number2;
    return StringUtils.formatPhoneNumberWhenRtl(phoneNumber);
  }

  getShowNumber(slotId: number) {
    SimServiceProxy.getShowNumber(slotId).then((res: string) => {
      if (res !== null && res !== '') {
        if (!slotId) {
          this.number1 = res;
        } else {
          this.number2 = res;
        }
      } else {
        this.getPhoneNumber(slotId);
      }
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `getShowNumber err = ${JSON.stringify(err)}`);
    });
  }

  /**
   * Get the phone number of sim card
   */
  getPhoneNumber(slotId: number) {
    SimServiceProxy.getSimTelephoneNumber(slotId).then((res: string) => {
      if (!slotId) {
        this.number1 = res;
      } else {
        this.number2 = res;
      }
    });
  }

  openMobileDataEvent() {
    if (this.isDataEnable) {
      return;
    }
    this.isDataEnable = !this.isDataEnable;
    LogUtils.i(TAG, 'mobile data switch changes enable:' + JSON.stringify(this.isDataEnable));
    if (this.isDataEnable) {
      telephonyData.enableCellularData()?.then((data) => {
        LogUtils.i(TAG, 'enableCellularData: success then' + JSON.stringify(data));
      }).catch((error: BusinessError) => {
        LogUtils.i(TAG, 'enableCellularData: error catch' + JSON.stringify(error));
      });
    }
  }

  ifWindowClose() {
    if ((this.maxSimSlotCount === SIM_SLOT_COUNT_1 && !this.isOpened1) ||
      (this.maxSimSlotCount === MAX_SIM_COUNT && !this.isOpened1 && !this.isOpened2)) {
      LogUtils.i(TAG, 'window close')
      try {
        this.session?.sendData({
          'method': 'hideSubPage'
        })
      } catch (error) {
        LogUtils.e(TAG, 'session sendData failed')
      }
    }
  }

  private getCardColor(slotId: number, isOpen: boolean): Resource {
    let cardColor: Resource = $r('sys.color.font_secondary');
    if (this.colorMode === 0) {
      cardColor = $r('sys.color.white')
    } else if (this.selectedIndexes[0] === slotId && isOpen && this.isDataEnable) {
      cardColor = $r('sys.color.font_emphasize')
    } else {
      cardColor = $r('sys.color.font_secondary')
    }
    return cardColor;
  }

  private card1text() {
    let card1text1 = (this.isAirPlaneMode && this.list[0].hasCard && this.isOpened1) ?
    this.getString($r('app.string.sim_no_service')) : this.cardInfoSimName1;
    let card1text2 = this.getPhoneNumberOrPinName(SLOT_1);
    return card1text1 + ' ' + card1text2;
  }

  private card2text() {
    let card2text1 = (this.isAirPlaneMode && this.list[1].hasCard && this.isOpened2) ?
    this.getString($r('app.string.sim_no_service')) : this.cardInfoSimName2;
    let card2text2 = this.getPhoneNumberOrPinName(SLOT_2);
    return card2text1 + ' ' + card2text2;
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      this.headView();
      Scroll() {
        this.contentView();
      }
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
      .enableScrollInteraction(true)
      .scrollBar(BarState.Auto)
      .width('100%')

      Blank();
      this.bottomView();
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background_transparent'))
  }

  @Builder
  headView() {
    Column() {
      Image($r('app.media.mobiledata'))
        .width(24)
        .height(24)
        .draggable(false)
        .matchTextDirection(true)
        .fillColor(this.colorMode === 1 ? $r('sys.color.icon_secondary') : $r('sys.color.white'))
        .margin({ bottom: 8 })
        .align(Alignment.Center)
        .objectFit(ImageFit.Contain)
      Text($r('app.string.mobile_data'))
        .fontSize($r('sys.float.Title_S'))
        .fontWeight(FontWeight.Medium)
        .fontFamily('HarmonyHeiTi')
        .fontColor(this.colorMode === 1 ? $r('sys.color.font_secondary') : $r('sys.color.white'))
        .align(Alignment.Center)
        .maxFontScale(2)
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .advancedBlendMode(this.colorMode === 1 ? blenderLight : blenderDark, BlendApplyType.OFFSCREEN)
  }

  @Builder
  contentView() {
    Column() {
      this.cardOneRow()
      Column() {
        Divider()
          .vertical(false)
          .strokeWidth('0.5px')
          .color($r('sys.color.comp_divider'))
          .padding({ left: 16, right: 16 })
        this.cardTwoRow()
      }
      .visibility(this.maxSimSlotCount === MAX_SIM_COUNT ? Visibility.Visible : Visibility.None)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 8, right: 8 })
  }

  @Builder
  cardOneRow() {
    Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
      Column() {
        this.card1Title()

        if (FontScaleState.isStandardGeer(this.fontSizeScale)) {
          Row() {
            Text(this.card1text())
              .simCardInfoTextStyle()
              .fontColor($r('sys.color.font_tertiary'))
              .advancedBlendMode(this.colorMode === 1 ? blenderLight : textInfoBlenderDark)
          }
          .width('100%')
          .flexShrink(1)
          .justifyContent(FlexAlign.Start);
        } else {
          this.seniorCardOneDetails();
        }
      }
      .clip(true)
      .margin({ end: LengthMetrics.vp(16) })
      .alignItems(HorizontalAlign.Start);

      Column() {
        Image($r('app.media.checkmark'))
          .checkMarkStyle()
          .fillColor(this.colorMode === 1 ? $r('sys.color.font_emphasize') : $r('sys.color.white'))
          .visibility(this.selectedIndexes[0] === SLOT_1 && this.isOpened1 && this.isDataEnable ?
          Visibility.Visible : Visibility.None)
      };
    }
    .width('100%')
    .constraintSize({ minHeight: 64 })
    .borderRadius($r('sys.float.corner_radius_level8'))
    .padding({
      left: 16,
      right: 16,
      top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 8, 8),
      bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 8, 8)
    })
    .stateStyles({
      normal: this.normalStyles,
      pressed: this.pressedStyles
    })
    .onClick(() => {
      this.selectedIndexes[0] = SLOT_1;
      this.openMobileDataEvent();
    })
    .enabled(!this.isAirPlaneMode && this.isOpened1 && !this.isDefaultDataChanging && !this.isCalling)
    .opacity(!this.isAirPlaneMode && this.isOpened1 && !this.isDefaultDataChanging && !this.isCalling ?
    $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))
  }

  @Builder
  card1Title() {
    Row() {
      if (this.maxSimSlotCount == 1){
        Text(this.selectedIndexes[0] === SLOT_1 ? $r('app.string.sim_card_one_no_space_default', '') :
        $r('app.string.sim_card_one_no_space', ''))
          .fontColor(this.getCardColor(SLOT_1, this.isOpened1))
          .simCardTextStyle()
          .advancedBlendMode(this.colorMode === 1 ? blenderLight : blenderDark);
      } else {
        Text(this.selectedIndexes[0] === SLOT_1 ? $r('app.string.sim_card_one_no_space_default', SLOT_1 + 1) :
        $r('app.string.sim_card_one_no_space', simIdFormat(SLOT_1 + 1)))
          .fontColor(this.getCardColor(SLOT_1, this.isOpened1))
          .simCardTextStyle()
          .advancedBlendMode(this.colorMode === 1 ? blenderLight : blenderDark);
      }
    }
    .visibility(this.selectedIndexes[0] === SLOT_1 && this.isOpened1 && this.isDataEnable ? Visibility.None :
    Visibility.Visible)

    Row() {
      Text($r('app.string.sim_card_one_no_space_default', SLOT_1 + 1))
        .fontColor(this.getCardColor(SLOT_1, this.isOpened1))
        .simCardTextStyle();
    }
    .visibility(this.selectedIndexes[0] === SLOT_1 && this.isOpened1 && this.isDataEnable ? Visibility.Visible :
    Visibility.None)
  }

  @Builder
  seniorCardOneDetails() {
    Column({ space: 2 }) {
      Text((this.isAirPlaneMode && this.list[0].hasCard && this.isOpened1) ?
      this.getString($r('app.string.sim_no_service')) :
      this.cardInfoSimName1)
        .simCardInfoTextStyle()
        .fontColor($r('sys.color.font_tertiary'))

      Text(this.getPhoneNumberOrPinName(SLOT_1))
        .simCardInfoTextStyle()
        .fontColor($r('sys.color.font_tertiary'))
    }
    .advancedBlendMode(this.colorMode === 1 ? blenderLight : textInfoBlenderDark)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start);
  }

  @Builder
  cardTwoRow() {
    Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
      Column() {
        this.card2Title()

        if (FontScaleState.isStandardGeer(this.fontSizeScale)) {
          Row() {
            Text(this.card2text())
              .simCardInfoTextStyle()
              .fontColor($r('sys.color.font_tertiary'))
              .advancedBlendMode(this.colorMode === 1 ? blenderLight : textInfoBlenderDark)
          }
          .width('100%')
          .flexShrink(1)
          .justifyContent(FlexAlign.Start);
        } else {
          this.seniorCardTwoDetails();
        }
      }
      .clip(true)
      .margin({ end: LengthMetrics.vp(16) })
      .alignItems(HorizontalAlign.Start);

      Column() {
        Image($r('app.media.checkmark'))
          .checkMarkStyle()
          .fillColor(this.colorMode === 1 ? $r('sys.color.font_emphasize') : $r('sys.color.white'))
          .visibility(this.selectedIndexes[0] === SLOT_2 && this.isOpened2 && this.isDataEnable ?
          Visibility.Visible : Visibility.None)
      };
    }
    .width('100%')
    .constraintSize({ minHeight: 64 })
    .borderRadius($r('sys.float.corner_radius_level8'))
    .padding({
      left: 16,
      right: 16,
      top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 8, 8),
      bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 8, 8)
    })
    .stateStyles({
      normal: this.normalStyles,
      pressed: this.pressedStyles
    })
    .onClick(() => {
      this.selectedIndexes[0] = SLOT_2;
      this.openMobileDataEvent();
    })
    .enabled(!this.isAirPlaneMode && this.isOpened2 && !this.isDefaultDataChanging && !this.isCalling)
    .opacity(!this.isAirPlaneMode && this.isOpened2 && !this.isDefaultDataChanging && !this.isCalling ?
    $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))
  }

  @Builder
  card2Title() {
    Row() {
      Text(this.selectedIndexes[0] === SLOT_2 ? $r('app.string.sim_card_one_no_space_default', SLOT_2 + 1) :
      $r('app.string.sim_card_one_no_space', simIdFormat(SLOT_2 + 1)))
        .fontColor(this.getCardColor(SLOT_2, this.isOpened2))
        .simCardTextStyle()
        .advancedBlendMode(this.colorMode === 1 ? blenderLight : blenderDark);
    }
    .visibility(this.selectedIndexes[0] === SLOT_2 && this.isOpened2 && this.isDataEnable ? Visibility.None :
    Visibility.Visible)

    Row() {
      Text($r('app.string.sim_card_one_no_space_default', SLOT_2 + 1))
        .fontColor(this.getCardColor(SLOT_2, this.isOpened2))
        .simCardTextStyle();
    }
    .visibility(this.selectedIndexes[0] === SLOT_2 && this.isOpened2 && this.isDataEnable ? Visibility.Visible :
    Visibility.None)
  }

  @Builder
  seniorCardTwoDetails() {
    Column({ space: 2 }) {
      Text((this.isAirPlaneMode && this.list[1].hasCard && this.isOpened2) ?
      this.getString($r('app.string.sim_no_service')) :
      this.cardInfoSimName2)
        .simCardInfoTextStyle()
        .fontColor(this.colorMode === 1 ? $r('sys.color.font_tertiary') : $r('sys.color.white'))

      Text(this.getPhoneNumberOrPinName(SLOT_2))
        .simCardInfoTextStyle()
        .fontColor($r('sys.color.font_tertiary'))
    }
    .advancedBlendMode(this.colorMode === 1 ? blenderLight : textInfoBlenderDark)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start);
  }

  @Builder
  bottomView() {
    Column() {
      Text($r('app.string.more_settings'))
        .width('100%')
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Medium)
        .fontSize($r('sys.float.Body_L'))
        .fontColor(this.colorMode === 1 ? $r('sys.color.ohos_id_color_text_primary_activated') :
        $r('sys.color.white'))
        .textAlign(TextAlign.Center)
        .maxFontScale(2)
        .margin({ top: 10, bottom: 10 })
    }
    .constraintSize({ minHeight: 40 })
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      LogUtils.i(TAG, 'click on more settings');
      let context = getContext(this) as common.UIAbilityContext;
      let want: Want = {
        bundleName: 'com.oh.settings',
        abilityName: 'com.oh.settings.MainAbility',
        uri: 'sim_card_management_entry'
      };
      context.startAbility(want).then(() => {
        LogUtils.i(TAG, `invoke SIM card management successfully.`);
      }).catch(() => {
        LogUtils.e(TAG, `Failed to invoke SIM card management.`);
      });
    })
    .stateStyles({
      clicked: {
        .backgroundColor($r('sys.color.interactive_click'))
        .borderRadius($r('sys.float.corner_radius_level10'))
      }, pressed: {
        .backgroundColor($r('sys.color.interactive_click'))
        .borderRadius($r('sys.float.corner_radius_level10'))
      }, normal: {
        .backgroundColor($r('sys.color.ohos_id_color_background_transparent'))
      }
    })
    .margin({
      left: 16,
      right: 16,
      top: 6,
      bottom: 15
    })
  }
}