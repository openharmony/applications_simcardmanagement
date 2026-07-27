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

import bundleManager from '@ohos.bundle.bundleManager';
import common from '@ohos.app.ability.common';
import settings from '@ohos.settings';
import commonEventManager from '@ohos.commonEventManager';
import { BusinessError } from '@ohos.base';
import osAccount from '@ohos.account.osAccount';
import { getMaxSimCount } from '../../model/registerSimStateApi';
import LogUtils from '../utils/LogUtils';
import { simIdFormat } from '../utils/SimIdFormat';
import { TextArrowOption } from './TextArrowOption';

const IS_HAVE_MAIN_MENU_PROP_KEY = 'HwSimToolkits_hasMainMenu_';
const STK_PACKAGE_NAME = 'com.oh.simtoolkits';
const STK_ABILITY_NAME = 'EntryAbility';
const STK_PAGE_URL = 'pages/Index';
const EVENT_PUBLISHER_PERMISSION = 'ohos.permission.SET_TELEPHONY_STATE'
const NOT_HAVE_APP_CODE = 17700001;
const SIM_SLOT_ID_0 = 0;
const SIM_SLOT_ID_1 = 1;
const SIM_SLOT_INDEX_1 = 1;
const SIM_SLOT_INDEX_2 = 2;
const MAX_SIM_COUNT = 2;
const TAG = 'SimToolkitsComponent';

@Component
export struct SimToolkitsButton {
  @Prop textName: string = '';
  @Link isVisible: boolean;
  private click?: () => void = undefined;

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

  build() {
    TextArrowOption({
      optionTag: this.textName,
      onClicked: () => {
        this.click?.();
      }
    }).visibility(this.isVisible ? Visibility.Visible : Visibility.None)
  }
}

@Component
export struct SimToolkitsComponent {
  @Link isMenu1Visible: boolean;
  @Link isMenu2Visible: boolean;
  @StorageProp('STK_onPageShowOrHide') @Watch('onPageShowOrHide') isPageShowOrHide: boolean = true;
  private commonEventSubscriber: commonEventManager.CommonEventSubscriber | undefined = undefined;
  private menuText: string = getContext(this).resourceManager.getStringSync($r('app.string.sim_card_application').id);
  private menu1Text: string = getContext(this).resourceManager
    .getStringSync($r('app.string.sim_card_application_number').id, simIdFormat(SIM_SLOT_INDEX_1));
  private menu2Text: string = getContext(this).resourceManager
    .getStringSync($r('app.string.sim_card_application_number').id, simIdFormat(SIM_SLOT_INDEX_2));
  private hasStkApp: boolean = false;
  private isTwoSimCount: boolean = false;
  private isMainOsAccount: boolean = true;

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.isTwoSimCount = getMaxSimCount() === MAX_SIM_COUNT;
    this.hasStkApp = this.hasStkApplication();
    this.isMainOsAccountInner().then((isMain: boolean) => {
      this.isMainOsAccount = isMain;
      this.checkIsShow(SIM_SLOT_ID_0);
      this.checkIsShow(SIM_SLOT_ID_1);
      this.registerStkMainMenuStatus();
    });
  }

  onPageShowOrHide(): void {
    LogUtils.i(TAG, `onPageShowOrHide isPageShowOrHide:: ${this.isPageShowOrHide}`);
    if (this.isPageShowOrHide) {
      this.hasStkApp = this.hasStkApplication();
      this.isMainOsAccountInner().then((isMain: boolean) => {
        this.isMainOsAccount = isMain;
        this.checkIsShow(SIM_SLOT_ID_0);
        this.checkIsShow(SIM_SLOT_ID_1);
      });
    }
  }

  aboutToDisappear(): void {
    this.unRegisterStkMainMenuStatus();
  }

  private async isMainOsAccountInner(): Promise<boolean> {
    let isMain = true;
    try {
      isMain = (await osAccount.getAccountManager().getForegroundOsAccountLocalId()) === 100;
    } catch (error) {
      LogUtils.e(TAG, 'isMainOsAccount error');
    }
    LogUtils.i(TAG, `isMainOsAccount getForegroundOsAccountLocalId isMain:${isMain}`);
    return Promise.resolve(isMain);
  }

  private hasStkApplication(): boolean {
    try {
      bundleManager.isApplicationEnabledSync(STK_PACKAGE_NAME);
    } catch (err) {
      LogUtils.e(TAG, 'hasStkApplication error');
      let code = (err as BusinessError).code;
      if (code === NOT_HAVE_APP_CODE) {
        return false;
      }
    }
    return true;
  }

  private registerStkMainMenuStatus(): void {
    if (this.commonEventSubscriber) {
      return;
    }
    let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [IS_HAVE_MAIN_MENU_PROP_KEY],
      publisherPermission: EVENT_PUBLISHER_PERMISSION
    };
    commonEventManager.createSubscriber(subscribeInfo).then(data => {
      this.commonEventSubscriber = data;
      commonEventManager.subscribe(data, (err: BusinessError, eventData: commonEventManager.CommonEventData) => {
        if (err) {
          LogUtils.e(TAG, 'registerStkMainMenuStatus subscribe error');
          return;
        }
        this.checkIsShow(eventData.code);
      });
    });
  }

  private unRegisterStkMainMenuStatus(): void {
    if (!this.commonEventSubscriber) {
      return;
    }
    commonEventManager.unsubscribe(this.commonEventSubscriber);
    this.commonEventSubscriber = undefined;
  }

  private checkIsShow(slotId?: number): void {
    if (slotId === undefined) {
      return;
    }
    let menuStatus = settings.getValueSync(getContext(this), `${IS_HAVE_MAIN_MENU_PROP_KEY}${slotId}`, '')
    LogUtils.i(TAG, `checkIsShow: slotId:${slotId}  menuStatus:${menuStatus}`);
    let isVisible = this.isMainOsAccount && this.hasStkApp && menuStatus === '1';
    if (slotId === SIM_SLOT_ID_0) {
      this.isMenu1Visible = isVisible;
    } else if (slotId === SIM_SLOT_ID_1) {
      this.isMenu2Visible = isVisible;
    }
  }

  private stkMenuClick(slotId: number): void {
    // need ohos.permission.SET_TELEPHONY_STATE
    (getContext(this) as common.UIAbilityContext).startAbility({
      bundleName: STK_PACKAGE_NAME,
      abilityName: STK_ABILITY_NAME,
      parameters: {
        'pageUrl': STK_PAGE_URL,
        'slotId': slotId
      }
    });
  }

  build() {
    Column() {
      Column() {
        // sim 1
        SimToolkitsButton({
          textName: (this.isTwoSimCount ? this.menu1Text : this.menuText),
          isVisible: $isMenu1Visible,
          click: () => {
            this.stkMenuClick(SIM_SLOT_ID_0);
          }
        })
        if (this.isTwoSimCount) {
          Divider()
            .color($r('sys.color.comp_divider'))
            .lineCap(LineCapStyle.Round)
            .margin({
              left: $r('app.float.wh_value_12'),
              right: $r('app.float.wh_value_12')
            })
            .visibility((this.isMenu1Visible && this.isMenu2Visible) ? Visibility.Visible : Visibility.None)

          SimToolkitsButton({
            textName: this.menu2Text,
            isVisible: $isMenu2Visible,
            click: () => {
              this.stkMenuClick(SIM_SLOT_ID_1);
            }
          })
        }
      }
      .borderRadius($r('sys.float.corner_radius_level10'))
      .backgroundColor($r('sys.color.comp_background_primary'))
    }
  }
}

