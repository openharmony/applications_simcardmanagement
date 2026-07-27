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
import { DeviceInfo, SetScreenPwdResult, SimInfo } from '../data/Infos';
import {
  ItemRestriction,
  SegmentButton,
  SegmentButtonOptions,
  SegmentButtonTextItem
} from '@ohos.arkui.advanced.SegmentButton';
import { MAX_SIM_COUNT, PAGE_PADDING, SIM_CARD_ABILITY_CONTEXT, SLOT_1, SLOT_2 } from '../common/utils/constant';
import { getString } from '../common/utils/Utils';
import { simIdFormat } from '../common/utils/SimIdFormat';
import LogUtils from '../common/utils/LogUtils';
import pinModel, { isScreenLockPasswordSet } from '../model/pinModel';
import { PinComponent } from '../common/components/pinComponent';
import { addAirPlaneModeListener, removeAirPlaneModeListener } from '../common/utils/AirplaneMode';
import Want from '@ohos.app.ability.Want';
import { SimCardGlobalContextHelper } from '../common/utils/SimCardGlobalContextHelper';
import { common } from '@kit.AbilityKit';
import { registerAccountInfoChange, unRegisterAccountInfoChange } from '../model/registerSimStateApi';
import SimServiceProxy from '../model/simServiceProxy';
import preferencesUtils from '../common/utils/PreferencesUtils';
import { LengthMetrics } from '@kit.ArkUI';
import { AppStorageUtils } from '../common/utils/AppStorageUtils';
import { ReportUtil } from '../utils/ReportUtil';
import { DynamicLoader } from '../utils/DynamicLoader';

const TAG = 'SimProtection';
const MY_OH_BUNDLE_NAME = 'com.oh';
const MY_OH_PIN_URI = '://dispatch/phoneservice/search?keyword=关于PIN码&openType=1';


@Component
export struct SimProtection {
  @Consume('pageInfos') pageInfos: NavPathStack;
  @State deviceInfo: DeviceInfo = new DeviceInfo();
  @State simInfos: SimInfo[] = [];
  @State textHeight: number = preferencesUtils.getDefaultDataTextHeight(getContext(this));
  @State buttonPadding: Padding = {
    top: (40 - this.textHeight - 4) / 2,
    bottom: (40 - this.textHeight - 4) / 2,
    left: $r('app.float.wh_value_12'),
    right: $r('app.float.wh_value_12')
  };
  @State tabOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    fontSize: $r('sys.float.Body_M'),
    selectedFontSize: $r('sys.float.Body_M'),
    fontWeight: FontWeight.Medium,
    selectedFontWeight: FontWeight.Medium,
    fontColor: $r('sys.color.font_secondary'),
    selectedFontColor: $r('sys.color.font_primary'),
    backgroundColor: $r('sys.color.comp_background_tertiary'),
    selectedBackgroundColor: $r('sys.color.ohos_id_color_foreground_contrary_disable'),
    buttons: [
      { text: $r('app.string.sim_card_one_no_space', simIdFormat(SLOT_1 + 1)) },
      { text: $r('app.string.sim_card_one_no_space', simIdFormat(SLOT_2 + 1)) },
    ] as ItemRestriction<SegmentButtonTextItem>,
    buttonPadding: this.buttonPadding
  })
  @Watch('onTabSelectedIndexChanged') @State tabSelectedIndexes: number[] = [SLOT_1]
  @State currentIndex: number = SLOT_1;
  @State setScreenPwdResult: SetScreenPwdResult = new SetScreenPwdResult(false);
  @Consume @Watch('onSimStateChanged') simState1: number;
  @Consume @Watch('onSimStateChanged') simState2: number;
  private tabsController: TabsController = new TabsController()

  private onSimStateChanged(changedPropertyName: string) {
    if (changedPropertyName === 'simState1') {
      LogUtils.i(TAG, 'onSimStateChanged slotId=' + SLOT_1 + ',simstate=' + JSON.stringify(this.simState1));
      this.simInfos[SLOT_1].state = this.simState1;
      this.updateAllPinState(SLOT_1);
    } else {
      LogUtils.i(TAG, 'onSimStateChanged slotId=' + SLOT_2 + ',simstate=' + JSON.stringify(this.simState2));
      this.simInfos[SLOT_2].state = this.simState2;
      this.updateAllPinState(SLOT_2);
    }
    this.checkSimState();
  }

  private onAccountInfoChanged: Callback<void> = () => {
    LogUtils.i(TAG, 'onAccountInfoChanged');
    this.updateSimActivated();
  };

  private initData() {
    if (this.simInfos === null || this.simInfos.length === 0) {
      LogUtils.i(TAG, 'simInfos is null,return.')
      return;
    }
    this.simInfos[SLOT_1].state = this.simState1;
    if (this.simInfos.length === MAX_SIM_COUNT) {
      this.simInfos[SLOT_2].state = this.simState2;
    }
    this.updateSimActivated();
  }

  checkSimState() {
    if (!this.deviceInfo.hasSim()) {
      this.finish();
    }
  }

  updateSimActivated() {
    for (let index = 0; index < this.simInfos.length; index++) {
      SimServiceProxy.isSimActive(index).then((res: boolean) => {
        LogUtils.i(TAG, 'isSimActive id ' + JSON.stringify(index) + ',res=' + JSON.stringify(res));
        this.simInfos[index].isActivated = res;
      }).catch(() => {
        LogUtils.e(TAG, 'isSimActive id ' + JSON.stringify(index) + ' is error');
      });
    }
  }

  private updateAllPinState(slotId: number) {
    if (!this.simInfos[slotId].isSimStateLocked() && !this.simInfos[slotId].isReadyOrLoaded()) {
      return;
    }
    pinModel.getAllState(slotId).then((res) => {
      LogUtils.i(TAG, `updateAllPinState res=${JSON.stringify(res)}`);
      this.simInfos[slotId].lockedType = res.lockType;
      this.simInfos[slotId].isPinRemembered = res.isRemembered;
      AppStorageUtils.updateSimLockType(slotId, res.lockType);
    })
  }

  toMyHuawei() {
    ReportUtil.getInstance().reportCardProtectionAboutPin();
    const want: Want = {
      bundleName: MY_OH_BUNDLE_NAME,
      uri: MY_OH_PIN_URI
    }
    SimCardGlobalContextHelper.getInstance()
      .getValue<common.UIAbilityContext>(SIM_CARD_ABILITY_CONTEXT)?.startAbility(want).then(() => {
      LogUtils.i(TAG, 'toMyHuawei startAbility success');
    }).catch((err: Error) => {
      LogUtils.e(TAG, `toMyHuawei startAbility occurs error = ${err}`);
    });
  }

  onTabSelectedIndexChanged() {
    this.tabsController.changeIndex(this.tabSelectedIndexes[0])
  }

  private toSetScreenPwdPage(slotId: number) {
    DynamicLoader.getInstance().fireToIndexPage(DynamicLoader.SET_SCREEN_PASSWORD_PAGE).then(() => {
      this.pageInfos.pushPath({
        name: 'setScreenLockPassword', param: null, onPop: (popInfo: PopInfo) => {
          let message = '[pushPath]last page is: ' + popInfo.info.name +
            ', result: ' + JSON.stringify(popInfo.result);
          LogUtils.i(TAG, 'onPop:' + message);
          this.onSetScreenPwdResult(slotId, popInfo.result as SetScreenPwdResult);
        }
      });
    })
  }

  onSetScreenPwdResult(slotId: number, result: SetScreenPwdResult) {
    this.setScreenPwdResult.slotId = slotId;
    this.setScreenPwdResult.isSucceed = result.isSucceed;
    this.setScreenPwdResult.openTimesAdded();
  }

  finish() {
    const popDestinationInfo = this.pageInfos.pop();
    LogUtils.i(TAG, 'pop result = ' + JSON.stringify(popDestinationInfo));
  }

  aboutToAppear(): void {
    registerAccountInfoChange(this.onAccountInfoChanged);
    isScreenLockPasswordSet();
    addAirPlaneModeListener((data: number) => {
      LogUtils.i(TAG, 'addAirPlaneModeListener callback');
      this.deviceInfo.isAirPlaneOn = data == 1 ? true : false;
      if (this.deviceInfo.isAirPlaneOn) {
        this.finish();
      }
    });
  }

  aboutToDisappear(): void {
    unRegisterAccountInfoChange(this.onAccountInfoChanged);
    removeAirPlaneModeListener()
    if (this.simInfos === null || this.simInfos.length === 0) {
      LogUtils.i(TAG, 'simInfos is null,return.')
      return;
    }
  }

  @Styles
  normalStyles() {
    .borderRadius($r('sys.float.corner_radius_level10'))
    .backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Styles
  pressedStyles() {
    .borderRadius($r('sys.float.corner_radius_level10'))
    .backgroundColor($r('sys.color.interactive_click'))
  }

  @Builder
  NavigationMenus() {
    Stack({ alignContent: Alignment.Center }) {
      Stack({ alignContent: Alignment.Center }) {
        Image($r('sys.media.ohos_ic_public_more'))
          .width($r('app.float.wh_value_24'))
          .height($r('app.float.wh_value_24'))
          .fillColor($r('sys.color.icon_primary'))
      }
      .width($r('app.float.wh_value_40'))
      .height($r('app.float.wh_value_40'))
      .backgroundColor($r('sys.color.comp_background_tertiary'))
      .borderRadius($r('app.float.value_20'))
      .bindMenu(this.DropDwonMenu(), { offset: { y: 20 }, placement: Placement.BottomLeft })
    }
    .padding({
      top: $r('sys.float.padding_level4'),
      bottom: $r('sys.float.padding_level4'),
      right: PAGE_PADDING,
      left: PAGE_PADDING
    })
  }

  @Builder
  TabContent(index: number) {
    Column() {
      PinComponent({
        deviceInfo: this.deviceInfo,
        simInfo: this.deviceInfo.simInfos[index],
        setScreenPwdResult: this.setScreenPwdResult,
        onAboutPinClick: () => {
          this.toMyHuawei();
        },
        toSetScreenLockPwdPage: (slotId) => {
          this.toSetScreenPwdPage(slotId);
        }
      });
    }
    .padding({
      left: PAGE_PADDING,
      right: PAGE_PADDING
    })
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  DropDwonMenu() {
    Menu() {
      MenuItem({ content: $r('app.string.help') })
        .padding({ start: LengthMetrics.resource($r('sys.float.padding_level6')) })
        .height($r('app.float.value_48'))
        .contentFont({ size: $r('sys.float.Body_L'), weight: FontWeight.Medium, family: 'HarmonyHeiTi' })
        .contentFontColor($r('sys.color.ohos_id_color_text_primary'))
        .borderRadius($r('sys.float.corner_radius_level10'))
        .onClick(() => {
          this.toMyHuawei();
        })
    }
    .width($r('app.float.value_224'))
    .height($r('app.float.value_56'))
    .radius($r('sys.float.corner_radius_level10'))
    .padding($r('sys.float.padding_level2'))
  }

  build() {
    NavDestination() {
      GridRow({ columns: { sm: 4, md: 8, lg: 12 }, gutter: { x: 12 } }) {
        GridCol({ span: { sm: 4, md: 8, lg: 12 }, offset: { sm: 0, md: 1, lg: 2 } }) {
          Column() {
            if (this.deviceInfo.simInfos.length === MAX_SIM_COUNT) {
              Stack() {
                SegmentButton({
                  options: this.tabOptions,
                  selectedIndexes: $tabSelectedIndexes,
                })
              }
              .height($r('app.float.value_56'))
              .padding({
                top: $r('sys.float.padding_level4'),
                bottom: $r('sys.float.padding_level4'),
                left: PAGE_PADDING,
                right: PAGE_PADDING
              })
            }

            Tabs({ index: this.currentIndex, controller: this.tabsController }) {
              ForEach(this.simInfos, (simInfo: SimInfo, index: number) => {
                TabContent() {
                  this.TabContent(index);
                }
              })
            }
            .barHeight(0)
            .defaultFocus(true)
            .onChange((index: number) => {
              this.currentIndex = index;
              this.tabSelectedIndexes[0] = index;
              ReportUtil.getInstance().reportCardProtectionTabSwitch(index);
            })
            .scrollable(this.simInfos.length === MAX_SIM_COUNT ? true : false)
          }
        }
      }
    }
    .title(getString($r('app.string.sim_pin')),
      {
        paddingStart: LengthMetrics.resource(PAGE_PADDING),
      })
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.KEYBOARD])
    .onBackPressed(() => {
      this.finish();
      return true;
    })
    .menus(this.NavigationMenus())
    .onReady((ctx: NavDestinationContext) => {
      try {
        this.deviceInfo = ctx?.pathInfo?.param as DeviceInfo;
        this.simInfos = this.deviceInfo.simInfos;
        this.initData();
      } catch (e) {
        LogUtils.e(TAG, 'onReady error = ' + JSON.stringify(e));
      }
    })
  }
}