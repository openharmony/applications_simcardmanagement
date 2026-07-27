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
import { PRIMARY_SLOT_ID_NOT_INIT, SLOT_1, SLOT_2, SIM_CARD_ABILITY_CONTEXT } from '../utils/constant'
import LogUtils from '../utils/LogUtils'
import { simIdFormat } from '../utils/SimIdFormat'
import common from '@ohos.app.ability.common';
import { SimCardGlobalContextHelper } from '../utils/SimCardGlobalContextHelper';
import settings from '@ohos.settings';
import { LengthMetrics } from '@kit.ArkUI';
import SimStateConst from '../utils/SimStateConst';
import { FontScaleState } from '../utils/fontScaleState';

const SMART_DUAL_CARD_KEY = 'intelligence_card_switch_enable';
const SWITCH_ALREADY_SHOWN = 'intelligence_card_switch_enable_shown';
const TAG = 'SmartDualCardComponent';

@Component
export default struct SmartDualCardComponent {
  @Watch('onPrimarySlotIdChanged') @Link primarySlotId: number;
  @Link isDefaultDataChanging: boolean;
  @Link isAirplaneOn: boolean;
  @Link isActivated1: boolean;
  @Link isActivated2: boolean;
  @Link isCalling: boolean;
  @State isSatelliteOn: boolean = false;
  @State isSmartDualCardOn: boolean = false;
  @Prop simState1: number
  @Prop simState2: number
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  private slaveSlotId: number = PRIMARY_SLOT_ID_NOT_INIT;

  aboutToAppear(): void {
    this.isSmartDualCardOn = this.getSmartDualCardMode();
    this.setSettingsData(SWITCH_ALREADY_SHOWN, '1');
    this.onPrimarySlotIdChanged();
  }

  onPrimarySlotIdChanged(): void {
    if (this.primarySlotId === SLOT_1 || this.primarySlotId === SLOT_2) {
      this.slaveSlotId = (this.primarySlotId === SLOT_1) ? SLOT_2 : SLOT_1;
      LogUtils.i(TAG, 'onPrimarySlotIdChanged primarySlotId=' + this.primarySlotId +
        ', slaveSlotId=' + this.slaveSlotId);
    }
  }

  getSlaveSlotId(): number {
    if (this.primarySlotId === SLOT_1 || this.primarySlotId === SLOT_2) {
      this.slaveSlotId = (this.primarySlotId === SLOT_1) ? SLOT_2 : SLOT_1;
    }
    return (this.slaveSlotId + 1);
  }

  build() {
    Row() {
      Row() {
        Column() {
          Text($r('app.string.enable_intelligence_network'))
            .width('100%')
            .lineHeight(FontScaleState.isStandardGeer(this.fontSizeScale) ? $r('app.float.wh_value_21') : 0)
            .fontSize($r('sys.float.Body_L'))
            .fontFamily('HarmonyHeiTi').fontWeight(FontWeight.Medium)
            .maxLines(FontScaleState.isStandardGeer(this.fontSizeScale) ? 1 : FontScaleState.seniorMaxLines)
            .opacity(this.isActivated1 && this.isActivated2 && !this.isAirplaneOn && !this.isAllUnkown() &&
              !this.isCalling ? $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))
          Text($r('app.string.enable_intelligence_network_summary',
            simIdFormat(this.getSlaveSlotId()), simIdFormat(this.getSlaveSlotId())))
            .width('100%')
            .lineHeight(FontScaleState.isStandardGeer(this.fontSizeScale) ? $r('app.float.value_19') : 0)
            .fontWeight(FontWeight.Regular).fontFamily('HarmonyHeiTi')
            .fontSize($r('sys.float.Body_M')).fontColor($r('sys.color.font_secondary'))
            .margin({ top: $r('sys.float.padding_level1') })
            .opacity(this.isActivated1 && this.isActivated2 && !this.isAirplaneOn && !this.isAllUnkown() &&
              !this.isCalling ? $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      Row() {
        Toggle({ type: ToggleType.Switch, isOn: this.isSmartDualCardOn })
          .margin($r('app.float.value_0'))
          .padding({
            left: $r('app.float.value_6'), right: $r('app.float.value_6'),
            top: $r('app.float.value_14'), bottom: $r('app.float.value_14')
          })
          .width($r('app.float.value_48')).height($r('app.float.value_48'))
          .selectedColor($r('sys.color.icon_emphasize'))
          .switchPointColor($r('sys.color.comp_background_primary_contrary'))
          .enabled(this.isActivated1 && this.isActivated2 && !this.isAirplaneOn && !this.isAllUnkown() &&
            !this.isCalling && !this.isSatelliteOn)
          .onChange((isOn: boolean) => {
            this.isSmartDualCardOn = isOn;
            this.setSmartDualCardMode(isOn);
          })
      }
      .padding({
        start: LengthMetrics.resource($r('sys.float.padding_level4')),
        end: LengthMetrics.resource($r('sys.float.padding_level0')),
      })
      .onTouchIntercept(() => {
        if (this.isDefaultDataChanging) {
          return HitTestMode.Block;
        }
        return HitTestMode.Default;
      })
    }
    .width('100%')
    .padding({
      start: LengthMetrics.resource($r('sys.float.padding_level6')),
      end: LengthMetrics.resource($r('app.float.value_62')),
      top: $r('sys.float.padding_level4'), bottom: $r('sys.float.padding_level4')
    })
    .margin({
      top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, $r('app.float.wh_value_10')),
      bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, $r('app.float.wh_value_10'))
    })
    .constraintSize({ minHeight: $r('app.float.value_78') })
    .justifyContent(FlexAlign.SpaceBetween)
  }

  /*
   * 读取开关状态
   */
  getSmartDualCardMode(): boolean {
    let value: String = this.getSettingsData(SMART_DUAL_CARD_KEY, '0');
    return value === '1';
  }

  getSettingsData(key: string, defaultValue: string): string {
    if (!key) {
      LogUtils.w(TAG, 'getSettingsData key invalid');
      return '0';
    }
    let context: common.Context | undefined =
      SimCardGlobalContextHelper.getInstance().getValue<common.UIAbilityContext>(SIM_CARD_ABILITY_CONTEXT);
    if (typeof context === 'undefined' || context === null) {
      LogUtils.e(TAG, 'getSettingsData failed, context is undefined');
      return defaultValue ?? '0';
    }
    return settings.getValueSync(context, key, defaultValue ?? '0');
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
    let context: common.Context | undefined =
      SimCardGlobalContextHelper.getInstance().getValue<common.UIAbilityContext>(SIM_CARD_ABILITY_CONTEXT);
    if (typeof context === 'undefined' || context === null) {
      LogUtils.e(TAG, 'setSettingsData failed, context is undefined');
      return;
    }
    try {
      settings.setValueSync(context, key, value ?? '0');
    } catch (error) {
      LogUtils.e(TAG, `setSettingsData failed, catch: ${JSON.stringify(error)}`);
    }
  }

  private isAllUnkown() {
    return this.simState1 === SimStateConst.SIM_STATE_UNKNOWN && this.simState2 === SimStateConst.SIM_STATE_UNKNOWN;
  }
}