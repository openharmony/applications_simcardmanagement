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

/**
 SIM_CARD_INFO
 */
import call from '@ohos.telephony.call';
import { addAirPlaneModeListener, queryAirPlaneMode, removeAirPlaneModeListener } from '../common/utils/AirplaneMode';
import HeadComponent from '../common/components/headComponent';
import CardInfomation from '../common/components/cardInfomation';
import SimServiceProxy from '../model/simServiceProxy';
import LogUtils from '../common/utils/LogUtils';
import {
  getMaxSimCount,
  registerAccountInfoChange,
  registerCallStateChange,
  registerNetworkStateChange,
  registerSimStateChange,
  unRegisterAccountInfoChange,
  unRegisterCallStateChange,
  unRegisterNetworkStateChange,
  unRegisterSimStateChange
} from '../model/registerSimStateApi';
import SubscriberManagement from '../common/utils/SubscriberManagement';
import { getPrimarySlotId } from '../model/radioServiceProxy';
import OperaNameStruct from '../common/struct/operaNameStruct';
import { observer } from '../model/api';
import { simIdFormat } from '../common/utils/SimIdFormat';
import { BusinessError } from '@ohos.base';
import CardInfoStruct from '../common/struct/CardInfoStruct';
import { isVSimEnabled } from '../common/utils/Utils';
import { OnPrimaryChangedListener, PrimaryCardEventManager } from '../common/utils/DefaultDataManager';
import { SimToolkitsComponent } from '../common/components/simToolkitsComponent';
import lazy { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import {
  SelectDefaultCallSimContent,
  setDefaultVoiceSlotId
} from '../common/components/dialog/selectDefaultVoiceDialog';
import { DeviceInfo, SimInfo } from '../data/Infos';
import { SimProtection } from './simProtection';
import { CustomSubHeader } from '../common/components/SubHeader';
import { TextArrowOption } from '../common/components/TextArrowOption';
import SimStateConst from '../common/utils/SimStateConst';
import DefaultDataComponent from '../common/components/defaultDataComponent';
import SmartDualCardComponent from '../common/components/smartDualCardComponent';
import SystemParameterEnhance from '@ohos.systemParameterEnhance';
import {
  addSatelliteToggleStateListener,
  querySatellite,
  removeSatelliteToggleStateListener
} from '../common/utils/SateToggleStateManager';
import { LengthMetrics } from '@kit.ArkUI';
import lazy { ReportUtil } from '../utils/ReportUtil';
import { accessibility } from '@kit.AccessibilityKit';
import { DynamicLoader } from '../utils/DynamicLoader';
import { displaySync } from '@kit.ArkGraphics2D';
import {
  DEFAULT_VOICE_SLOT_ID_NOT_INIT,
  MAX_SIM_COUNT,
  PAGE_PADDING,
  PRIMARY_SLOT_ID_NOT_INIT,
  SIM_SLOT_COUNT_1,
  SLOT_1,
  SLOT_2
} from '../common/utils/constant';
import { FontScaleState } from '../common/utils/fontScaleState';
import { bundleManager, common, Want } from '@kit.AbilityKit';

const TAG = 'Index';

@Builder
function dummyFunction(): void {
}

@Entry
@Component
struct Index {
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  scroller: Scroller = new Scroller();
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
  @State isShow: boolean = false;
  @State isShow2: boolean = false;
  @State number1: string = '';
  @State number2: string = '';
  @State defaultDataChange: boolean = true;
  @State isStop: boolean = true;
  @State defaultSet: Resource = $r('app.string.not_set');
  @State simActive: boolean = false;
  @State isCallings: boolean[] = [false, false];
  @State isCalling: boolean = false;
  @State isOpened1: boolean = true;
  @State isOpened2: boolean = true;
  @State smartDualCardSwitchOn: boolean = false;
  @StorageLink('operatorName') @Watch('updateInfo') operatorInfo: OperaNameStruct = new OperaNameStruct();
  // Mobile AirPlane Mode
  @State isAirPlaneMode: boolean = false;
  @State cardSwitchTarget: number = this.defaultDataChange ? 2 : 1;
  @State isDefaultDataChanging: boolean = false;
  @StorageProp('foldStatus') foldStatus: number = -1;
  @State primarySlotId: number = PRIMARY_SLOT_ID_NOT_INIT;
  @State defaultVoiceSlotId: number = DEFAULT_VOICE_SLOT_ID_NOT_INIT;
  @State maxSimSlotCount: number = -1;
  @State isMenu1Visible: boolean = false;
  @State isMenu2Visible: boolean = false;
  @Provide simState1: number = SimStateConst.SIM_STATE_UNKNOWN;
  @Provide simState2: number = SimStateConst.SIM_STATE_UNKNOWN;
  @State isSatelliteOn: boolean = false;
  @State isVsimOn: boolean = false;
  @State isSupportSmartDualcard: boolean = this.getSupportSmartDualcard();
  @BuilderParam setScreenLockPasswordPage : () => void = dummyFunction;
  @State stages:number = 0;
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  myDisplaySync: displaySync.DisplaySync = displaySync.create();
  private onSimStateChanged1: Callback<observer.SimStateData> = (simStateData: observer.SimStateData) => {
    LogUtils.i(TAG, 'onSimStateChanged slotId=' + SLOT_1 + ',simstate=' + JSON.stringify(simStateData));
    this.updateInfoBySlotId(SLOT_1);
    this.selectDefaultVoiceDialog.close();
    if (simStateData.state === SimStateConst.SIM_STATE_NOT_PRESENT) {
      this.refreshPrimarySlotIdAfterSimRemoval();
    }
  };
  private onSimStateChanged2: Callback<observer.SimStateData> = (simStateData: observer.SimStateData) => {
    LogUtils.i(TAG, 'onSimStateChanged slotId=' + SLOT_2 + ',simstate=' + JSON.stringify(simStateData));
    this.updateInfoBySlotId(SLOT_2);
    this.selectDefaultVoiceDialog.close();
    if (simStateData.state === SimStateConst.SIM_STATE_NOT_PRESENT) {
      this.refreshPrimarySlotIdAfterSimRemoval();
    }
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
  private onCallStateChanged1: Callback<observer.CallStateInfo> = (callStateInfo: observer.CallStateInfo) => {
    LogUtils.i(TAG, 'onCallStateChanged slotId=' + SLOT_1 + ',callStateInfo=' + JSON.stringify(callStateInfo));
    this.handleOnCallStateChanged(SLOT_1, callStateInfo);
  };
  private onCallStateChanged2: Callback<observer.CallStateInfo> = (callStateInfo: observer.CallStateInfo) => {
    LogUtils.i(TAG, 'onCallStateChanged slotId=' + SLOT_2 + ',callStateInfo=' + JSON.stringify(callStateInfo));
    this.handleOnCallStateChanged(SLOT_2, callStateInfo);
  };

  @Styles
  normalStyles() {
    .backgroundColor('rgba(255,255,255,0)')
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
  }

  SIM_CARD_STOP = 'sim_card_management_card_stop_boolean';
  SIM_CARD_CHANGE = 'sim_card_management_card_change_boolean';
  SIM_CARD_DEFAULT = 'sim_card_management_card_default_call';
  SIM_CARD_TRANSFER = 'sim_card_management_transfer';
  SIM_CARD_TRANSFER2 = 'sim_card_management_transfer2';
  SHOW_CHANGE = 'sim_change_data';
  //Dialog for selecting the default dialing card.
  selectDefaultVoiceDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.default_dial_card'),
      contentBuilder: () => {
        this.createSelectDefaultSimContent()
      },
      buttons: [
        {
          value: $r('app.string.cancel'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            ReportUtil.getInstance().reportSetDefaultDialingCardCanceled();
          }
        }
      ]
    }),
    autoCancel: false,
    showInSubWindow: true
  });

  @Builder
  createSelectDefaultSimContent() {
    SelectDefaultCallSimContent({
      defaultVoiceSlotId: this.defaultVoiceSlotId,
      phoneNumber1: this.number1,
      phoneNumber2: this.number2,
      fontSizeScale: this.fontSizeScale,
      onSelectedDefaultVoice: (slotId: number) => {
        setDefaultVoiceSlotId(slotId, (slotId: number) => {
          this.getDefaultVoiceSlotld();
          this.accessibilityAnnounceEvent(slotId);
        })
        if (!accessibility.isOpenTouchGuideSync()) { // 无障碍模式下等待朗读完文本之后再关闭弹窗
          this.selectDefaultVoiceDialog.close();
        }
      }
    });
  }

  onPrimaryCardChanged: OnPrimaryChangedListener = {
    onPrimaryChanged: (isDone: boolean) => {
      if (isDone) {
        this.getPrimarySlotId();
      }
    }
  };

  defaultCard() {
    LogUtils.i(TAG, 'onclick defaultDialCard open');
    ReportUtil.getInstance().reportDefaultDialingCardClicked();
    this.selectDefaultVoiceDialog.open();
  }

  private initData() {
    this.maxSimSlotCount = getMaxSimCount();
    LogUtils.i(TAG, `initData maxSimSlotCount=${JSON.stringify(this.maxSimSlotCount)}`);
    if (this.maxSimSlotCount === SIM_SLOT_COUNT_1) {
      this.list[SLOT_1].title = $r('app.string.sim_card');
    }
  }

  // init AirPlane Mode
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
    for (let slotId = 0; slotId < this.maxSimSlotCount; slotId++) {
      let isActivated = SimServiceProxy.isSimActivatedSync(slotId);
      if (slotId === 0) {
        this.isOpened1 = isActivated;
      } else {
        this.isOpened2 = isActivated;
      }
    }
  }

  getCallState() {
    call.getCallState().then((data: call.CallState) => {
      LogUtils.i(TAG, `getCallState success, promise: data->${JSON.stringify(data)}`)
      this.isCalling = data.valueOf() === 1 || data.valueOf() === 2;
    }).catch((err: BusinessError) => {
      LogUtils.i(TAG, `getCallState fail, promise: err->${JSON.stringify(err)}`)
    });
  }

  // query AirPlane Mode
  getAirPlaneMode() {
    try {
      queryAirPlaneMode((data: number) => {
        LogUtils.i(TAG, `getAirPlaneMode callback data=${data.toString()}`);
        this.isAirPlaneMode = data == 1 ? true : false;
      });
    } catch (err) {
      LogUtils.e(TAG, `getAirPlaneMode err = ${JSON.stringify(err)}`);
    }
  }

  getVsimState() {
    this.isVsimOn = isVSimEnabled();
  }

  /**
   * Get the customized mobile phone number set by the user
   */
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

  /**
   * Get the default voice sim card
   */
  getDefaultVoiceSlotld() {
    SimServiceProxy.getDefaultVoiceSlotId().then((res: number) => {
      LogUtils.i(TAG, 'getDefaultVoiceSlotId:res=' + JSON.stringify(res));
      if (res === 0 || res === 1) {
        this.defaultVoiceSlotId = res;
        this.defaultSet = $r('app.string.sim_card_one_no_space', simIdFormat(res + 1));
      } else {
        this.defaultVoiceSlotId = -1;
        this.defaultSet = $r('app.string.not_set');
      }
    }).catch(() => {
      this.defaultVoiceSlotId = -1;
      this.defaultSet = $r('app.string.not_set');
    });
  }

  updateInfoBySlotId(slotId: number) {
    this.getShowNumber(slotId);
    this.getDefaultVoiceSlotld();
  }

  updateInfo() {
    this.getShowNumber(SLOT_1);
    this.getShowNumber(SLOT_2);
    this.getDefaultVoiceSlotld();
  }

  private isAllUnkown() {
    return this.simState1 === SimStateConst.SIM_STATE_UNKNOWN && this.simState2 === SimStateConst.SIM_STATE_UNKNOWN;
  }

  handleOnCallStateChanged(slotId: number, callStateInfo: observer.CallStateInfo) {
    this.isCallings[slotId] = callStateInfo.state === 1 || callStateInfo.state === 2;
    this.isCalling = this.isCallings[SLOT_1] || this.isCallings[SLOT_2];
  }

  updateStage() {
    if (this.stages === 0) {
      this.myDisplaySync.start();
      this.myDisplaySync.on('frame', (frameInfo: displaySync.IntervalInfo) => {
        this.updateStage();
      });
    }
    this.stages = this.stages + 1;
    if (this.stages === 3) {
      this.myDisplaySync.stop()
    }
  }

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    this.updateStage();
    DynamicLoader.getInstance().registerIndexPageDynamicLoaderCb(async (key: string): Promise<boolean> => {
      if (key === DynamicLoader.SET_SCREEN_PASSWORD_PAGE) {
        return await this.initSetScreenLockPasswordPage();
      }
      return false;
    });
    this.initData();
    this.initSimActivatedSwitch();
    this.getPrimarySlotId();
    this.initAirPlaneMode();
    SubscriberManagement.registerSubscriber();
    PrimaryCardEventManager.subscribePrimaryChangedEvent(this.onPrimaryCardChanged);
    if (this.maxSimSlotCount >= MAX_SIM_COUNT) {
      this.addRegisterSimStateChange(1);
      this.addRegisterCallStateChange(1);
      this.addRegisterNetworkStateChange(1);
    }
    this.addRegisterNetworkStateChange(0);
    this.addRegisterSimStateChange(0);
    this.addRegisterAccountInfoChange();
    this.addRegisterCallStateChange(0);
    this.addRegisterSatelliteStateChange();
  }

  getPrimarySlotId() {
    if (this.isDefaultDataChanging) {
      return;
    }
    getPrimarySlotId().then((res) => {
      LogUtils.i(TAG, 'getPrimarySlotId: then: ' + JSON.stringify(res));
      this.primarySlotId = res;
      this.setDefaultDataChange(res);
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `getPrimarySlotId err = ${JSON.stringify(err)}`);
      this.primarySlotId = 0;
    });
  }

  /**
   * After hot-unplug, telephony may switch default data asynchronously; retry once.
   */
  refreshPrimarySlotIdAfterSimRemoval() {
    this.getPrimarySlotId();
    setTimeout(() => {
      this.getPrimarySlotId();
    }, 500);
  }

  setDefaultDataChange(res: number) {
    if (res === 1) {
      this.defaultDataChange = false;
    } else {
      this.defaultDataChange = true;
    }
  }

  onPageShow() {
    LogUtils.i(TAG, 'onPageShow start');
    this.getAirPlaneMode();
    this.getCallState();
    this.getVsimState();
    this.getPrimarySlotId();
    this.updateInfo();
    AppStorage.setOrCreate('STK_onPageShowOrHide', true);
    LogUtils.i(TAG, 'onPageShow end');
  }

  addRegisterSimStateChange(slotId: number) {
    if (slotId === SLOT_1) {
      registerSimStateChange(slotId, this.onSimStateChanged1);
    } else {
      registerSimStateChange(slotId, this.onSimStateChanged2);
    }
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

  addRegisterCallStateChange(slotId: number) {
    if (slotId === SLOT_1) {
      registerCallStateChange(slotId, this.onCallStateChanged1);
    } else {
      registerCallStateChange(slotId, this.onCallStateChanged2);
    }
  }

  toSimProtectionPage() {
    let simInfos: SimInfo[] =
      [new SimInfo(SLOT_1, this.number1, this.simState1, this.list[SLOT_1].hasCard, this.isOpened1)];
    if (this.maxSimSlotCount === MAX_SIM_COUNT) {
      simInfos.push(new SimInfo(SLOT_2, this.number2, this.simState2, this.list[SLOT_2].hasCard, this.isOpened2))
    }
    let deviceInfo: DeviceInfo = new DeviceInfo();
    deviceInfo.isAirPlaneOn = this.isAirPlaneMode;
    deviceInfo.simInfos = simInfos;
    this.pageInfos.pushPath({ name: 'simProtection', param: deviceInfo })
    ReportUtil.getInstance().reportCardProtectionClick();
  }

  addRegisterSatelliteStateChange() {
    addSatelliteToggleStateListener(getContext(this), (data: number) => {
      LogUtils.i(TAG, 'addSatelliteToggleStateListener:' + JSON.stringify(data));
      this.isSatelliteOn = (data == 1);
    });
    querySatellite(getContext(this), (data: number) => {
      this.isSatelliteOn = (data == 1);
      LogUtils.i(TAG, 'querySatellite:' + JSON.stringify(data));
    });
  }

  unRegisterRegisterSatelliteStateChange() {
    removeSatelliteToggleStateListener();
  }

  getSupportSmartDualcard(): boolean {
    try {
      let isEnable: String =
        SystemParameterEnhance.getSync('persist.netmanager_enhanced.smart_dualcard_enable', 'true');
      return isEnable === 'true';
    } catch (err) {
      LogUtils.e(TAG, `getSupportSmartDualcard err = ${JSON.stringify(err)}`);
      return false;
    }
  }

  aboutToDisappear() {
    LogUtils.i(TAG, 'aboutToDisappear');
    unRegisterSimStateChange(this.onSimStateChanged1);
    unRegisterNetworkStateChange(this.onNetworkStateChanged1);
    unRegisterCallStateChange(this.onCallStateChanged1);
    if (this.maxSimSlotCount === MAX_SIM_COUNT) {
      unRegisterSimStateChange(this.onSimStateChanged2);
      unRegisterNetworkStateChange(this.onNetworkStateChanged2);
      unRegisterCallStateChange(this.onCallStateChanged2);
    }
    unRegisterAccountInfoChange(this.onAccountInfoChanged);
    this.unRegisterRegisterSatelliteStateChange();
    SubscriberManagement.unsubscribe();
    PrimaryCardEventManager.unSubscribePrimaryChangedEvent();
  }

  onPageHide() {
    AppStorage.setOrCreate('STK_onPageShowOrHide', false);
    removeAirPlaneModeListener();
  }

  @Builder
  pageMap(name: string, params: Record<string, number>) {
    if (name === 'simProtection') {
      SimProtection()
    } else if (name === 'setScreenLockPassword') {
      this.setScreenLockPasswordPage();
    }
  }

  private async initSetScreenLockPasswordPage(): Promise<boolean> {
    let setScreenLockPasswrod = await import('./setScreenLockPasswrod')
    return true;
  }

  build() {
    Navigation(this.pageInfos) {
      GridRow({ columns: { xs: 4, sm: 4, md: 8, lg: 12 }, gutter: { x: 12 } }) {
        GridCol({ span: { xs: 4, sm: 4, md: 8, lg: 12 }, offset: { sm: 0, md: 1, lg: 2 } }) {
          Column() {
            HeadComponent({ headName: $r('app.string.sim_headName') });

            Stack({ alignContent: Alignment.TopStart }) {
              Scroll(this.scroller) {
                Column() {
                  Column() {
                  }
                  .height($r('sys.float.padding_level4'))
                  .width('100%')

                  CardInfomation({
                    maxSimSlotCount: this.maxSimSlotCount,
                    list: $list,
                    phone1Number: this.number1,
                    phone2Number: this.number2,
                    isCardChange: $defaultDataChange,
                    isCardChange2: $isShow,
                    isAirPlaneMode: this.isAirPlaneMode,
                    isCalling: this.isCalling,
                    isOpened1: this.isOpened1,
                    isOpened2: this.isOpened2,
                    cardSwitchTarget: this.cardSwitchTarget,
                    simState1: this.simState1,
                    simState2: this.simState2,
                    isDefaultDataChanging: $isDefaultDataChanging,
                    isSatelliteOn: this.isSatelliteOn,
                    isVSimOn: this.isVsimOn,
                    onSetPrimarySlotIdFinished: () => {
                      this.getPrimarySlotId();
                    },
                    onPrimarySlotRefreshNeeded: () => {
                      this.refreshPrimarySlotIdAfterSimRemoval();
                    }
                  })

                  if (this.stages === 3) {
                    if (this.maxSimSlotCount === MAX_SIM_COUNT) {
                      CustomSubHeader({ title: $r('app.string.dual_card_internet') })

                      Flex({
                        justifyContent: FlexAlign.SpaceBetween,
                        alignItems: ItemAlign.Center, wrap: FlexWrap.Wrap
                      }) {
                        DefaultDataComponent({
                          primarySlotId: $primarySlotId,
                          isDefaultDataChanging: $isDefaultDataChanging,
                          isAirplaneOn: this.isAirPlaneMode,
                          simState1: this.simState1,
                          simState2: this.simState2,
                          isActivated1: this.isOpened1,
                          isActivated2: this.isOpened2,
                          isCalling: this.isCalling,
                          isSatelliteOn: this.isSatelliteOn,
                          isVsimOn: this.isVsimOn,
                          onSetPrimarySlotIdFinished: () => {
                            this.getPrimarySlotId();
                          }
                        }).enabled(!this.isAirPlaneMode)

                        if (this.isOpened1 && this.isOpened2 && this.isSupportSmartDualcard) {
                          Divider()
                            .color($r('sys.color.comp_divider'))
                            .lineCap(LineCapStyle.Round)
                            .padding({
                              left: $r('sys.float.padding_level6'),
                              right: $r('sys.float.padding_level6')
                            })

                          SmartDualCardComponent({
                            primarySlotId: $primarySlotId,
                            isDefaultDataChanging: $isDefaultDataChanging,
                            isAirplaneOn: this.isAirPlaneMode,
                            isActivated1: this.isOpened1,
                            isActivated2: this.isOpened2,
                            isCalling: this.isCalling,
                            isSatelliteOn: this.isSatelliteOn,
                            simState1: this.simState1,
                            simState2: this.simState2
                          }).enabled(!this.isAirPlaneMode)
                        }
                      }
                      .padding({
                        top: $r('sys.float.padding_level2'),
                        bottom: $r('sys.float.padding_level2')
                      })
                      .width('100%')
                      .backgroundColor($r('sys.color.comp_background_primary'))
                      .borderRadius($r('sys.float.corner_radius_level10'))
                    }

                    if (this.maxSimSlotCount === MAX_SIM_COUNT) {
                      CustomSubHeader({ title: $r('app.string.dual_card_call') })

                      Flex(FontScaleState.isSmallerFourGeer(this.fontSizeScale) ?
                        { justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center } :
                        {
                          direction: FlexDirection.Column,
                          justifyContent: FlexAlign.Start,
                          alignItems: ItemAlign.Start
                        }) {
                        Text($r('app.string.default_dial_card'))
                          .fontSize($r('sys.float.Body_L'))
                          .fontFamily('HarmonyHeiTi')
                          .fontWeight(FontWeight.Medium)
                          .maxLines(FontScaleState.isStandardGeer(this.fontSizeScale) ? 1 :
                          FontScaleState.seniorMaxLines)
                          .opacity((this.isOpened1 && this.isOpened2 && !this.isAirPlaneMode && !this.isCalling &&
                            !this.isSatelliteOn && !this.isAllUnkown()) ? $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))
                        Row() {
                          Text(this.defaultSet ? this.defaultSet : $r('app.string.not_set'))
                            .fontSize($r('sys.float.Body_M'))
                            .fontColor($r('sys.color.font_secondary'))
                            .margin({ end: LengthMetrics.resource($r('app.float.value_5')) })
                            .maxLines(FontScaleState.isStandardGeer(this.fontSizeScale) ? 1 :
                            FontScaleState.seniorMaxLines)
                            .fontFamily('HarmonyHeiTi')
                            .fontWeight(FontWeight.Regular)
                            .visibility(this.defaultVoiceSlotId === DEFAULT_VOICE_SLOT_ID_NOT_INIT ?
                            Visibility.Hidden : Visibility.Visible)
                          Image($r('app.media.ic_public_arrow_right'))
                            .height($r('app.float.wh_value_24'))
                            .width($r('app.float.wh_value_12'))
                            .fillColor($r('sys.color.icon_fourth'))
                            .matchTextDirection(true)
                        }
                        .width(FontScaleState.isSmallerFourGeer(this.fontSizeScale) ? 'auto' : '100%')
                        .margin({
                          top: FontScaleState.isSmallerFourGeer(this.fontSizeScale) ? 0 : $r('app.float.wh_value_2')
                        })
                        .justifyContent(FlexAlign.SpaceBetween)
                        .opacity((this.isOpened1 && this.isOpened2 && !this.isAirPlaneMode && !this.isCalling &&
                          !this.isSatelliteOn && !this.isAllUnkown()) ? $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))
                      }
                      .enabled((this.isOpened1 && this.isOpened2 && !this.isAirPlaneMode &&
                        !this.isCalling && !this.isSatelliteOn && !this.isAllUnkown()))
                      .onClick(() => {
                        this.defaultCard();
                      })
                      .constraintSize({ minHeight: $r('app.float.value_56') })
                      .padding({
                        left: $r('sys.float.padding_level6'),
                        right: $r('sys.float.padding_level6'),
                        top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, $r('app.float.wh_value_2'),
                          $r('app.float.wh_value_10')),
                        bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale,
                          $r('app.float.wh_value_2'), $r('app.float.wh_value_10'))
                      })
                      .width('100%')
                      .backgroundColor($r('sys.color.comp_background_primary'))
                      .borderRadius($r('sys.float.corner_radius_level10'))
                    }

                    Column() {
                      CustomSubHeader({ title: $r('app.string.label_advanced') })

                      Column() {
                        TextArrowOption({
                          optionTag: $r('app.string.sim_pin'),
                          onClicked: () => {
                            this.toSimProtectionPage();
                          }
                        })
                          .enabled(!this.isAirPlaneMode && (this.isOpened1 || this.isOpened2) && !this.isSatelliteOn &&
                            !this.isAllUnkown())
                          .opacity(!this.isAirPlaneMode && !this.isAllUnkown() &&
                            (this.isOpened1 || this.isOpened2) && !this.isSatelliteOn ? $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))
                          .onClick(() => {
                            this.toSimProtectionPage();
                          })

                        Divider().color($r('sys.color.comp_divider'))
                          .visibility(this.isMenu1Visible || this.isMenu2Visible ? Visibility.Visible : Visibility.None)
                          .padding({
                            left: $r('sys.float.padding_level6'),
                            right: $r('sys.float.padding_level6')
                          })

                        // stk menu
                        SimToolkitsComponent({
                          isMenu1Visible: this.isMenu1Visible,
                          isMenu2Visible: this.isMenu2Visible
                        }).opacity(!this.isAllUnkown() ? $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))
                          .enabled(!this.isAllUnkown())
                      }
                      .backgroundColor($r('sys.color.comp_background_primary'))
                      .borderRadius($r('sys.float.corner_radius_level10'))
                      .padding({
                        top: $r('app.float.value_4'),
                        bottom: $r('app.float.value_4')
                      })
                    }.alignItems(HorizontalAlign.Start)

                    Column() {
                    }
                    .height($r('sys.float.padding_level4'))
                    .width('100%')
                  }
                }
                .width('100%')
                .padding({ left: PAGE_PADDING, right: PAGE_PADDING })
              }
              .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
              .scrollBar(BarState.Off)
            }
            .width('100%')
            .height('100%')
            .layoutWeight(1)
          }
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.KEYBOARD])
    .hideTitleBar(true)
    .navDestination(this.pageMap)
    .mode(NavigationMode.Stack)
  }

  private async accessibilityAnnounceEvent(slotId: number) {
    let accessibility = await DynamicLoader.getInstance().loadAccessibility();
    if (!accessibility.default.isOpenAccessibilitySync()) { // 无障碍能力不开启的情况不播报朗读文本
      return;
    }
    let announceStr = '';
    if (slotId < 0) {
      announceStr = getContext(this).resourceManager.getStringSync($r('app.string.not_set').id);
    } else if (slotId === 0) {
      announceStr =
        getContext(this)
          .resourceManager
          .getStringSync($r('app.string.sim_card_one_no_space').id, simIdFormat(SLOT_1 + 1));
    } else if (slotId === 1) {
      announceStr =
        getContext(this)
          .resourceManager
          .getStringSync($r('app.string.sim_card_one_no_space').id, simIdFormat(SLOT_2 + 1));
    }
    announceStr =
      announceStr + ' ' + getContext(this).resourceManager.getStringSync($r('app.string.accessibility_selected').id);
    this.sendAccessibilityEventInfo(announceStr);
  }

  private async sendAccessibilityEventInfo(info: string) {
    let eventInfo: accessibility.EventInfo = ({
      type: 'announceForAccessibility',
      bundleName: 'com.ohos.simcardmanagement',
      triggerAction: 'common',
      textAnnouncedForAccessibility: info
    });
    let accessibility = await DynamicLoader.getInstance().loadAccessibility();
    accessibility.default.sendAccessibilityEvent(eventInfo).then(() => {
      setTimeout(() => {
        this.selectDefaultVoiceDialog.close();
      }, 1500)
    });
  }
}