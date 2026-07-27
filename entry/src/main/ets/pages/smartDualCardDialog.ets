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

import { LengthMetrics } from '@kit.ArkUI';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import call from '@ohos.telephony.call';
import SimServiceProxy from '../model/simServiceProxy';
import LogUtils from '../common/utils/LogUtils';
import {
  getMaxSimCount,
  registerAccountInfoChange,
  registerNetworkStateChange,
  registerSimStateChange,
  unRegisterAccountInfoChange,
  unRegisterNetworkStateChange,
  unRegisterSimStateChange
} from '../model/registerSimStateApi';
import SubscriberManagement from '../common/utils/SubscriberManagement';
import { getOperatorName, getPrimarySlotId, setPrimarySlotId } from '../model/radioServiceProxy';
import { observer } from '../model/api';
import { simIdFormat } from '../common/utils/SimIdFormat';
import { BusinessError, Callback } from '@ohos.base';
import { OnPrimaryChangedListener, PrimaryCardEventManager } from '../common/utils/DefaultDataManager';
import { PRIMARY_SLOT_ID_NOT_INIT, SLOT_1, SLOT_2 } from '../common/utils/constant';
import { common } from '@kit.AbilityKit';
import settings from '@ohos.settings';
import i18n from '@ohos.i18n';
import { FontScaleState } from '../common/utils/fontScaleState';

const TAG = 'SmartDualCardDialog';
const MAX_SIM_COUNT = 2;
const SMART_DUAL_CARD_KEY = 'intelligence_card_switch_enable';
const SWITCH_ALREADY_SHOWN = 'intelligence_card_switch_enable_shown';

@Entry
@Component
export default struct SmartDualCardDialog {
  @State isShow: boolean = true;
  @State cardInfoSimName1: string = '';
  @State cardInfoSimName2: string = '';
  @State number1: string = '';
  @State number2: string = '';
  @State isDefaultDataChanging: boolean = false;
  @State primarySlotId: number = PRIMARY_SLOT_ID_NOT_INIT;
  private slaveSlotId: number = PRIMARY_SLOT_ID_NOT_INIT;
  @State getMaxSimCountValue: number = -1;
  @State isSmartDualCardOn: boolean = true;
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;

  private onSimStateChanged1: Callback<observer.SimStateData> = (simStateData: observer.SimStateData) => {
    LogUtils.i(TAG, 'onSimStateChanged slotId=' + SLOT_1 + ',simstate=' + JSON.stringify(simStateData));
    this.updateInfoBySlotId(SLOT_1);
  };
  private onSimStateChanged2: Callback<observer.SimStateData> = (simStateData: observer.SimStateData) => {
    LogUtils.i(TAG, 'onSimStateChanged slotId=' + SLOT_2 + ',simstate=' + JSON.stringify(simStateData));
    this.updateInfoBySlotId(SLOT_2);
  };
  private onAccountInfoChanged: Callback<void> = () => {
    LogUtils.i(TAG, 'onAccountInfoChanged');
    this.updateInfo();
  };
  private onNetworkStateChanged1: Callback<observer.NetworkState> = (networkState: observer.NetworkState) => {
    LogUtils.i(TAG, 'onNetworkStateChanged slotId=' + SLOT_1);
    this.updateInfoBySlotId(SLOT_1);
  };
  private onNetworkStateChanged2: Callback<observer.NetworkState> = (networkState: observer.NetworkState) => {
    LogUtils.i(TAG, 'onNetworkStateChanged slotId=' + SLOT_2);
    this.updateInfoBySlotId(SLOT_2);
  };

  onPrimaryCardChanged: OnPrimaryChangedListener = {
    onPrimaryChanged: (isDone: boolean) => {
      if (isDone) {
        this.getPrimarySlotId();
      }
    }
  };

  /**
   * Format phone number
   */
  async formatPhoneNum(phoneNumber: string): Promise<string> {
    let countryId: string = i18n.System.getSystemRegion();
    let options: call.NumberFormatOptions = {
      countryCode: countryId
    }
    try {
      let number = await call.formatPhoneNumber(phoneNumber, options) as string;
      LogUtils.i(TAG, 'formatPhoneNumber success');
      return number;
    } catch (err) {
      LogUtils.e(TAG, `formatPhoneNumber fail err = ${JSON.stringify(err)}`);
      return phoneNumber;
    }
  }

  /**
   * Get the customized mobile phone number set by the user
   */
  getShowNumber(slotId: number) {
    SimServiceProxy.getShowNumber(slotId).then((res: string) => {
      this.formatPhoneNum(res).then((res: string) => {
        if (res !== null && res !== '') {
          if (!slotId) {
            this.number1 = res;
          } else {
            this.number2 = res;
          }
        } else {
          this.getPhoneNumber(slotId);
        }
      })
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `getShowNumber err = ${JSON.stringify(err)}`);
    });
  }

  /**
   * Get the phone number of sim card
   */
  getPhoneNumber(slotId: number) {
    SimServiceProxy.getSimTelephoneNumber(slotId).then((res: string) => {
      this.formatPhoneNum(res).then((res: string) => {
        if (!slotId) {
          this.number1 = res;
        } else {
          this.number2 = res;
        }
      })
    });
  }

  setPrimarySlotId(slotId: number) {
    this.isDefaultDataChanging = true;
    setPrimarySlotId(slotId).then(() => {
      this.isDefaultDataChanging = false;
      this.primarySlotId = slotId;
    }).catch(() => {
      this.isDefaultDataChanging = false;
    });
  }

  onCard1ToggleChanged(isOn: boolean) {
    if (isOn) {
      setPrimarySlotId(SLOT_1);
    }
  }

  onCard2ToggleChanged(isOn: boolean) {
    if (isOn) {
      setPrimarySlotId(SLOT_2);
    }
  }

  updateInfoBySlotId(slotId: number) {
    this.getNetName(slotId);
    this.getShowNumber(slotId);
  }

  updateInfo() {
    this.getNetName(SLOT_1);
    this.getNetName(SLOT_2);
    this.getShowNumber(SLOT_1);
    this.getShowNumber(SLOT_2);
  }

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear:');
    this.setSettingsData(SWITCH_ALREADY_SHOWN, '1');
    this.getNetName(SLOT_1);
    this.getNetName(SLOT_2);
    this.getMaxSimCountValue = getMaxSimCount();
    this.getPrimarySlotId();
    SubscriberManagement.registerSubscriber();
    PrimaryCardEventManager.subscribePrimaryChangedEvent(this.onPrimaryCardChanged);
    if (this.getMaxSimCountValue >= MAX_SIM_COUNT) {
      this.addRegisterSimStateChange(1);
      this.addRegisterNetworkStateChange(1);
    }
    this.addRegisterNetworkStateChange(0);
    this.addRegisterSimStateChange(0);
    this.addRegisterAccountInfoChange();
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
      this.primarySlotId = 0;
    });
  }

  /*
   * 将开关变化写入数据库
   */
  setSmartDualCardMode(isOn: boolean) {
    LogUtils.i(TAG, 'setSmartDualCardMode, isOn = ' + isOn);
    if (isOn) {
      this.setSettingsData(SMART_DUAL_CARD_KEY, '1');
    } else {
      this.setSettingsData(SMART_DUAL_CARD_KEY, '0');
    }
  }

  setSettingsData(key: string, value: string): void {
    if (!key) {
      LogUtils.w(TAG, 'setSettingsData key invalid');
      return;
    }
    LogUtils.i(TAG, `setSettingsData key: ${key}, value: ${value}`);
    let context: common.Context | undefined = getContext(this);
    if (typeof context === 'undefined' || context === null) {
      LogUtils.e(TAG, 'setSettingsData failed, context is undefined');
      return;
    }
    try {
      settings.setValueSync(context, key, value ?? '0');
    } catch (error) {
      LogUtils.e(TAG, `setSettingsData failed, catch:${JSON.stringify(error)}`);
    }
  }

  onPageShow() {
    this.updateInfo();
  }

  addRegisterSimStateChange(slotId: number) {
    if (slotId === SLOT_1) {
      registerSimStateChange(slotId, this.onSimStateChanged1);
    } else {
      registerSimStateChange(slotId, this.onSimStateChanged2);
    }
  }

  getSlaveSlotId(): number {
    this.slaveSlotId = (this.primarySlotId === SLOT_1) ? SLOT_2 : SLOT_1;
    return (this.slaveSlotId + 1);
  }

  addRegisterAccountInfoChange() {
    registerAccountInfoChange(this.onAccountInfoChanged);
  }

  addRegisterNetworkStateChange(slotId: number) {
    if (slotId === SLOT_1) {
      registerNetworkStateChange(slotId, this.onNetworkStateChanged1);
    } else {
      registerNetworkStateChange(slotId, this.onNetworkStateChanged2);
    }
  }

  aboutToDisappear() {
    LogUtils.i(TAG, 'aboutToDisappear');
    unRegisterSimStateChange(this.onSimStateChanged1);
    unRegisterNetworkStateChange(this.onNetworkStateChanged1);
    if (this.getMaxSimCountValue === MAX_SIM_COUNT) {
      unRegisterSimStateChange(this.onSimStateChanged2);
      unRegisterNetworkStateChange(this.onNetworkStateChanged2);
    }
    unRegisterAccountInfoChange(this.onAccountInfoChanged);
    SubscriberManagement.unsubscribe();
    PrimaryCardEventManager.unSubscribePrimaryChangedEvent();
  }

  /**
   * Get card slot operator name
   */
  getNetName(slotId: number) {
    getOperatorName(slotId).then((res: string) => {
      let noService: string = getContext(this).resourceManager.getStringSync($r('app.string.sim_no_service').id);
      if (slotId === 0) {
        let cardNumber: string =
          getContext(this).resourceManager.getStringSync($r('app.string.sim_card_one_no_space').id, simIdFormat(1));
        if (res === null || res === '') {
          this.cardInfoSimName1 = `${cardNumber} ${noService}`;
        } else {
          this.cardInfoSimName1 = `${cardNumber} ${res}`;
        }
      } else {
        let cardNumber: string =
          getContext(this).resourceManager.getStringSync($r('app.string.sim_card_two_no_space').id, simIdFormat(2));
        if (res === null || res === '') {
          this.cardInfoSimName2 = `${cardNumber} ${noService}`;
        } else {
          this.cardInfoSimName2 = `${cardNumber} ${res}`;
        }
      }
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `getOperatorName err = ${JSON.stringify(err)} slotId = ${JSON.stringify(slotId)}`);
    });
  }

  @Builder
  DefaultDataText() {
    Column() {
      Text($r('app.string.default_mobile_data'))
        .width('100%')
        .constraintSize({ minHeight: $r('app.float.value_56') })
        .lineHeight(FontScaleState.isStandardGeer(this.fontSizeScale) ? $r('app.float.value_19') : 0)
        .fontWeight(FontWeight.Medium)
        .fontFamily('HarmonyHeiTi')
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_secondary'))
        .padding({
          top: $r('app.float.value_28'),
          bottom: $r('app.float.value_8'),
        })
    }
    .margin({
      top: $r('sys.float.padding_level2'),
      start: LengthMetrics.resource($r('app.float.value_28'))
    })
  }

  @Builder
  CardOneInformation() {
    Row() {
      Row() {
        Column() {
          Text(this.cardInfoSimName1)
            .width('100%')
            .lineHeight(FontScaleState.isStandardGeer(this.fontSizeScale) ? $r('app.float.wh_value_22') : 0)
            .fontSize($r('sys.float.Body_L'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Medium)
            .maxLines(FontScaleState.isStandardGeer(this.fontSizeScale) ? 1 : FontScaleState.seniorMaxLines)
          Text(this.number1)
            .width('100%')
            .lineHeight(FontScaleState.isStandardGeer(this.fontSizeScale) ? $r('app.float.value_19') : 0)
            .fontWeight(FontWeight.Regular)
            .fontFamily('HarmonyHeiTi')
            .fontSize($r('sys.float.Body_M'))
            .fontColor($r('sys.color.font_secondary'))
            .margin({ top: $r('sys.float.padding_level1') })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .constraintSize({ minHeight: $r('app.float.value_64') })
        .padding({
          top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, $r('sys.float.padding_level5'),
            $r('sys.float.padding_level5')),
          bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, $r('sys.float.padding_level5'),
            $r('sys.float.padding_level5'))
        })
        Row() {
          Radio({ value: 'card1', group: 'group' })
            .margin($r('app.float.value_0'))
            .padding({
              left: $r('app.float.wh_value_2'), right: $r('app.float.wh_value_2'),
              top: $r('app.float.wh_value_2'), bottom: $r('app.float.wh_value_2'),
            })
            .width($r('app.float.wh_value_24')).height($r('app.float.wh_value_24'))
            .enabled(!this.isDefaultDataChanging)
            .onChange((isOn: boolean) => {
              this.onCard1ToggleChanged(isOn);
            })
            .checked(this.primarySlotId === SLOT_1)
            .radioStyle({
              uncheckedBorderColor: Color.White
            })
        }
      }
      .padding({
        top: $r('app.float.value_4')
      })
      .onClick(() => {
        if (this.primarySlotId !== SLOT_1) {
          this.onCard1ToggleChanged(true);
        }
      })
    }
  }

  @Builder
  CardTwoInformation() {
    Row() {
      Row() {
        Column() {
          Text(this.cardInfoSimName2)
            .width('100%')
            .lineHeight(FontScaleState.isStandardGeer(this.fontSizeScale) ? $r('app.float.wh_value_22') : 0)
            .fontSize($r('sys.float.Body_L'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Medium)
            .maxLines(FontScaleState.isStandardGeer(this.fontSizeScale) ? 1 : FontScaleState.seniorMaxLines)
          Text(this.number2)
            .width('100%')
            .lineHeight(FontScaleState.isStandardGeer(this.fontSizeScale) ? $r('app.float.value_19') : 0)
            .fontWeight(FontWeight.Regular)
            .fontFamily('HarmonyHeiTi')
            .fontSize($r('sys.float.Body_M'))
            .fontColor($r('sys.color.font_secondary'))
            .margin({ top: $r('sys.float.padding_level1') })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .constraintSize({ minHeight: $r('app.float.value_64') })
        .padding({
          top:  FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, $r('sys.float.padding_level5'),
            $r('sys.float.padding_level5')),
          bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, $r('sys.float.padding_level5'),
            $r('sys.float.padding_level5'))
        })
        Row() {
          Radio({ value: 'card2', group: 'group' })
            .margin($r('app.float.value_0'))
            .padding({
              left: $r('app.float.wh_value_2'), right: $r('app.float.wh_value_2'),
              top: $r('app.float.wh_value_2'), bottom: $r('app.float.wh_value_2'),
            })
            .width($r('app.float.wh_value_24')).height($r('app.float.wh_value_24'))
            .enabled(!this.isDefaultDataChanging)
            .onChange((isOn: boolean) => {
              this.onCard2ToggleChanged(isOn);
            })
            .checked(this.primarySlotId === SLOT_2)
            .radioStyle({
              uncheckedBorderColor: Color.White
            })
        }
      }
      .padding({
        bottom: $r('app.float.value_4')
      })
      .onClick(() => {
        if (this.primarySlotId !== SLOT_2) {
          this.onCard2ToggleChanged(true);
        }
      })
    }
  }

  @Builder
  myBuilder() {
    Column() {
      this.DefaultDataText();

      Column() {
        this.CardOneInformation();

        Divider()
          .color($r('sys.color.comp_divider'))
          .lineCap(LineCapStyle.Round)

        this.CardTwoInformation();
      }
      .align(Alignment.Center)
      .constraintSize({ minHeight: $r('app.float.value_78') })
      .justifyContent(FlexAlign.SpaceBetween)
      .borderRadius($r('app.float.value_20'))
      .backgroundBlurStyle(BlurStyle.Thin,
        { colorMode: ThemeColorMode.LIGHT, adaptiveColor: AdaptiveColor.DEFAULT, scale: 1.0 })
      .margin({
        top: $r('sys.float.padding_level0'),
        left: $r('sys.float.padding_level8'),
        right: $r('sys.float.padding_level8'),
        bottom: $r('sys.float.padding_level3'),
      })
      .padding({
        start: LengthMetrics.resource($r('sys.float.padding_level6')),
        end: LengthMetrics.resource($r('sys.float.padding_level6')),
        top: $r('sys.float.padding_level4'),
        bottom: $r('sys.float.padding_level4')
      })

      this.SmartDualCardSwitch();

      this.GuideText();

      this.ConfirmButton();
    }
  }

  @Builder
  SmartDualCardSwitch() {
    Column() {
      Row() {
        Row() {
          Column() {
            Text($r('app.string.enable_intelligence_network'))
              .width('100%')
              .lineHeight(FontScaleState.isStandardGeer(this.fontSizeScale) ? $r('app.float.wh_value_21') : 0)
              .fontSize($r('sys.float.Body_L')).fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Medium)
              .maxLines(FontScaleState.isStandardGeer(this.fontSizeScale) ? 1 : FontScaleState.seniorMaxLines)
            Text($r('app.string.enable_intelligence_network_summary',
              simIdFormat(this.getSlaveSlotId()), simIdFormat(this.getSlaveSlotId())))
              .width('100%')
              .lineHeight(FontScaleState.isStandardGeer(this.fontSizeScale) ? $r('app.float.value_19') : 0)
              .fontWeight(FontWeight.Regular)
              .fontFamily('HarmonyHeiTi').fontSize($r('sys.float.Body_M'))
              .fontColor($r('sys.color.font_secondary'))
              .margin({ top: $r('sys.float.padding_level1') })
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
          .padding({
            top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, $r('sys.float.padding_level7'),
              $r('sys.float.padding_level7')),
            bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, $r('sys.float.padding_level7'),
              $r('sys.float.padding_level7'))
          })
        }
        Row() {
          Toggle({ type: ToggleType.Switch, isOn: this.isSmartDualCardOn })
            .margin($r('app.float.value_0'))
            .padding({
              left: $r('app.float.value_6'), right: $r('app.float.value_6'), top: $r('app.float.value_14'), bottom: $r('app.float.value_14'),
            })
            .width($r('app.float.value_48')).height($r('app.float.value_48'))
            .selectedColor($r('sys.color.icon_emphasize'))
            .switchPointColor($r('sys.color.comp_background_primary_contrary'))
            .onChange((isOn) => {
              this.isSmartDualCardOn = isOn;
            })
        }
        .padding({
          start: LengthMetrics.resource($r('sys.float.padding_level4')),
          end: LengthMetrics.resource($r('sys.float.padding_level0')),
        })
      }
    }
    .align(Alignment.Center).justifyContent(FlexAlign.SpaceBetween).borderRadius($r('app.float.value_20'))
    .backgroundBlurStyle(BlurStyle.Thin,
      { colorMode: ThemeColorMode.LIGHT, adaptiveColor: AdaptiveColor.DEFAULT, scale: 1.0 })
    .margin({
      top: $r('sys.float.padding_level3'), left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8'), bottom: $r('sys.float.padding_level2'),
    })
    .padding({
      start: LengthMetrics.resource($r('sys.float.padding_level6')),
      end: LengthMetrics.resource($r('app.float.value_62')),
      top: $r('sys.float.padding_level4'), bottom: $r('sys.float.padding_level4')
    })
  }

  @Builder
  GuideText() {
    Column() {
      Text($r('app.string.smart_dualcard_dialog_guide'))
        .width('100%')
        .lineHeight(FontScaleState.isStandardGeer(this.fontSizeScale) ? $r('app.float.value_19') : 0)
        .fontWeight(FontWeight.Regular)
        .fontFamily('HarmonyHeiTi')
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_secondary'))
        .margin({
          top: $r('app.float.value_4'),
          bottom: $r('app.float.value_12_vp')
        })
        .maxFontScale(2)
    }
    .margin({
      start: LengthMetrics.resource($r('app.float.value_28')),
    })
  }

  @Builder
  ConfirmButton() {
    Column() {
      Button($r('app.string.confirm'))
        .fontSize($r('sys.float.ohos_id_text_size_button1'))
        .onClick(()=>{
          this.setSmartDualCardMode(this.isSmartDualCardOn);
          this.isShow = false;
          let session = AppStorage.get<UIExtensionContentSession>('session');
          if (session) {
            session.terminateSelf();
          }
        })
        .width('100%')
        .constraintSize({ minHeight: $r('app.float.wh_value_40') })
    }
    .padding({
      left: $r('app.float.value_16'),
      right: $r('app.float.value_16'),
      bottom: $r('app.float.value_16'),
    })
    .margin({
      bottom: $r('app.float.value_28'),
    })
  }

  build() {
    Row()
      .width('100%')
      .bindSheet($$this.isShow, this.myBuilder(), {
        height: SheetSize.FIT_CONTENT,
        onAppear: () => {
          LogUtils.i(TAG, 'BindSheet onAppear.')
        },
        onDisappear: () => {
          let session = AppStorage.get<UIExtensionContentSession>('session');
          if (session) {
            session.terminateSelf();
          }
        },
        title: {
          title: $r('app.string.dual_card_internet')
        }
      })
  }
}