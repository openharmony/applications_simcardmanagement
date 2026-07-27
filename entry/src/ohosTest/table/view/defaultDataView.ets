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
import {
  ItemRestriction,
  SegmentButton,
  SegmentButtonOptions,
  SegmentButtonTextItem
} from '@ohos.arkui.advanced.SegmentButton'
import { setPrimarySlotId } from '../../model/radioServiceProxy'
import { LockType, PRIMARY_SLOT_ID_NOT_INIT, SLOT_1, SLOT_2 } from '../utils/constant'
import LogUtils from '../utils/LogUtils'
import { simIdFormat } from '../utils/SimIdFormat'
import preferencesUtils from '../utils/PreferencesUtils'
import { isVSimEnabled } from '../utils/Utils'
import SimStateConst from '../utils/SimStateConst'
import { LengthMetrics } from '@kit.ArkUI'
import { ReportUtil } from '../../utils/ReportUtil';
import { AppStorageUtils } from '../utils/AppStorageUtils'

const TAG = 'DefaultDataComponent';

@Component
export default struct DefaultDataComponent {
  @State textHeight: number = preferencesUtils.getDefaultDataTextHeight(getContext(this));
  defaultDataButtons: ItemRestriction<SegmentButtonTextItem> = [
    { text: $r('app.string.sim_card_one_no_space', simIdFormat(SLOT_1 + 1)) },
    { text: $r('app.string.sim_card_one_no_space', simIdFormat(SLOT_2 + 1)) }
  ];
  @State buttonPadding: Padding = {
    top: (40 - this.textHeight - 4) / 2,
    bottom: (40 - this.textHeight - 4) / 2,
    left: $r('app.float.wh_value_12'),
    right: $r('app.float.wh_value_12')
  };
  @State singleSelectCapsuleOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    fontSize: $r('sys.float.Body_M'),
    selectedFontSize: $r('sys.float.Body_M'),
    fontWeight: FontWeight.Medium,
    selectedFontWeight: FontWeight.Medium,
    fontColor: $r('sys.color.font_secondary'),
    selectedFontColor: $r('sys.color.comp_background_primary_contrary'),
    backgroundColor: $r('sys.color.comp_background_tertiary'),
    selectedBackgroundColor: $r('sys.color.comp_background_emphasize'),
    buttons: this.defaultDataButtons,
    buttonPadding: this.buttonPadding
  })
  @Watch('onPrimarySlotIdChanged') @Link primarySlotId: number;
  @Watch('onSelectedChanged') @State selectedIndexes: number[] = [0];
  @Prop simState1: number
  @Prop simState2: number
  @Link isDefaultDataChanging: boolean;
  @Link isAirplaneOn: boolean;
  @Link isActivated1: boolean;
  @Link isActivated2: boolean;
  @Prop isCalling: boolean
  @State isSatelliteOn: boolean = false;
  @Prop isVsimOn: boolean = false;
  @StorageLink(AppStorageUtils.SIM_LOCK_TYPES) lockType: LockType[] = [LockType.NOT_LOCKED, LockType.NOT_LOCKED];
  onSetPrimarySlotIdFinished: Function = () => {
  };

  onPrimarySlotIdChanged() {
    LogUtils.i(TAG, 'onPrimarySlotIdChanged=' + JSON.stringify(this.primarySlotId))
    this.selectedIndexes[0] = this.primarySlotId;
  }

  onSelectedChanged() {
    LogUtils.i(TAG, 'onSelectedChanged=' + JSON.stringify(this.selectedIndexes))
    this.setPrimarySlotId(this.selectedIndexes[0]);
  }

  setPrimarySlotId(slotId: number) {
    if (slotId === this.primarySlotId) {
      LogUtils.i(TAG, 'setPrimarySlotId slotId and primarySlotId is same, return');
      return;
    }
    ReportUtil.getInstance().reportChangeDefaultMobileData(slotId);
    this.isDefaultDataChanging = true;
    setPrimarySlotId(slotId).then(() => {
      this.isDefaultDataChanging = false;
      this.onSetPrimarySlotIdFinished();
    }).catch(() => {
      this.isDefaultDataChanging = false;
      this.onSetPrimarySlotIdFinished();
    });
  }

  private isActivated() {
    return (this.isActivated1 && this.isActivated2) ||
      ((this.simState1 === SimStateConst.SIM_STATE_LOCKED && this.isActivated2) ||
        (this.simState2 === SimStateConst.SIM_STATE_LOCKED && this.isActivated1)) ||
      ((this.simState1 === SimStateConst.SIM_STATE_NOT_PRESENT && this.lockType[SLOT_1] === LockType.PUK_LOCK &&
      this.isActivated2) ||
        (this.simState2 === SimStateConst.SIM_STATE_NOT_PRESENT && this.lockType[SLOT_2] === LockType.PUK_LOCK &&
        this.isActivated1));
  }

  private isOtherLocked(): boolean {
    const state = this.primarySlotId === SLOT_1 ? this.simState2 : this.simState1;
    return state === SimStateConst.SIM_STATE_LOCKED;
  }

  private isAllUnkown() {
    return this.simState1 === SimStateConst.SIM_STATE_UNKNOWN && this.simState2 === SimStateConst.SIM_STATE_UNKNOWN;
  }

  aboutToAppear(): void {
    this.selectedIndexes[0] = this.primarySlotId;
  }

  build() {
    Row() {
      Text($r('app.string.default_mobile_data'))
        .fontSize($r('sys.float.Body_L'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Medium)
        .opacity(this.isActivated() && !this.isAirplaneOn && !this.isAllUnkown() && !this.isOtherLocked() &&
          !this.isCalling && !this.isVsimOn ? $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))
        .layoutWeight(1)

      Stack() {
        Text($r('app.string.sim_card_one_no_space', simIdFormat(SLOT_1 + 1)))
          .fontSize($r('sys.float.Body_M'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_secondary'))
          .visibility(Visibility.Hidden)
          .onAreaChange((oldValue: Area, newValue: Area) => {
            let height = newValue.height.valueOf() as number;
            if (height !== 0 && this.textHeight !== height) {
              preferencesUtils.putDefaultDataTextHeight(getContext(this), height);
              this.textHeight = height;
              this.singleSelectCapsuleOptions.buttonPadding = {
                top: (40 - this.textHeight - 4) / 2,
                bottom: (40 - this.textHeight - 4) / 2,
                left: $r('app.float.wh_value_12'),
                right: $r('app.float.wh_value_12')
              }
            }
          })

        SegmentButton({
          options: this.singleSelectCapsuleOptions,
          selectedIndexes: $selectedIndexes
        })
          .width($r('app.float.value_146'))
          .margin({ start: LengthMetrics.resource($r('sys.float.padding_level3')) })
          .visibility(this.primarySlotId !== PRIMARY_SLOT_ID_NOT_INIT &&
            this.textHeight !== 0 ? Visibility.Visible : Visibility.Hidden)
          .enabled(this.isActivated() && !this.isAirplaneOn && !this.isCalling && !this.isOtherLocked() &&
            !this.isDefaultDataChanging && !this.isSatelliteOn && !this.isVsimOn && !this.isAllUnkown())
          .opacity(this.isActivated() && !this.isAirplaneOn && !this.isCalling && !this.isAllUnkown() &&
            !this.isOtherLocked() && !this.isSatelliteOn && !this.isVsimOn ? $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))
          .onTouchIntercept((event: TouchEvent) => {
            return isVSimEnabled() ? HitTestMode.Block : HitTestMode.Default;
          })
      }
    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .height($r('app.float.value_48'))
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({
      left: $r('sys.float.padding_level6'),
      right: $r('sys.float.padding_level6')
    })
  }
}