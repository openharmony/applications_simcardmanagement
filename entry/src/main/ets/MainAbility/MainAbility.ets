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

import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import LogUtils from '../common/utils/LogUtils';
import { SimCardGlobalContextHelper } from '../common/utils/SimCardGlobalContextHelper';
import * as Constants from '../common/utils/constant';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import display from '@ohos.display';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { FontScaleState } from '../common/utils/fontScaleState';
import { Configuration } from '@ohos.app.ability.Configuration';
import lazy { ReportUtil } from '../utils/ReportUtil';
import { DisplayUtils } from '../utils/DisplayUtils';
import { AppStorageUtils } from '../common/utils/AppStorageUtils';

const TAG = 'MainAbility';

export interface extensionProperties {
  session?: UIExtensionContentSession;
}

export default class MainAbility extends UIExtensionAbility {
  private static createdTimes = 0;
  private timerId: number = -1;

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtils.i(TAG, 'onSessionCreate');
    this.fetchSystemFontSizeScale();
    SimCardGlobalContextHelper.getInstance()
      .set<common.UIExtensionContext>(Constants.SIM_CARD_ABILITY_CONTEXT, this.context);
    let localStorage: LocalStorage = new LocalStorage({
      session: session,
    } as extensionProperties);
    this.handleWantParams(want, localStorage);
    AppStorageUtils.updateNavigationBarHeight(session);
    session.loadContent('pages/index', localStorage);
    this.timerId = setTimeout(() => {
      this.overlayWindow(session);
      try {
        AppStorage.setOrCreate('foldStatus', display.getFoldStatus());
        this.registerFoldStatusChanged();
        ReportUtil.getInstance().startStatisticReport();
        MainAbility.createdTimes++;
      } catch (exception) {
        LogUtils.e(TAG, 'Failed code' + JSON.stringify(exception));
      }
    }, 500)
  }

  onSessionDestroy() {
    LogUtils.i(TAG, 'onSessionDestroy');
    this.cancelTimeout();
    this.unregisterFoldStatusChanged();
    MainAbility.createdTimes--;
  }

  overlayWindow(session: UIExtensionContentSession) {
    let param: Record<string, UIExtensionContentSession> = {
      'session': session
    }
    let storage: LocalStorage = new LocalStorage(param);
    let windowProxy = session.getUIExtensionWindowProxy();
    let subWindowOpts: window.SubWindowOptions = {
      'title': 'This is a subwindow',
      decorEnabled: true,
      isModal: true
    };
    windowProxy.createSubWindowWithOptions('subWindowForHost', subWindowOpts)// 不直接loadContent，先创建子窗
      .then((subWindow: window.Window) => {
        let subWindow1 = subWindow;
        subWindow1.loadContent('pages/Index', storage, (err, data) => {
          if (err && err.code != 0) {
            return;
          }
          this.resize(subWindow1);
        });
      })
      .catch((error: BusinessError) => {
        LogUtils.e(TAG, `Create subwindow failed: ${JSON.stringify(error)}`);
      });
  }

  resize(subWindow1: window.Window) {
    subWindow1?.resize(1260, 2720, (err, data) => { // 窗口开放新能力后，不需要应用主动设置宽高、位置
      if (err && err.code != 0) {
        return;
      }
      this.moveWindowTo(subWindow1);
    });
  }

  moveWindowTo(subWindow1: window.Window) {
    subWindow1?.moveWindowTo(0, 0, (err, data) => {
      if (err && err.code != 0) {
        return;
      }
      subWindow1?.showWindow((err, data) => {
        if (err && err.code == 0) {
          LogUtils.i(TAG, `The subwindow has been shown!`);
        } else {
          LogUtils.e(TAG, `Failed to show the subwindow!`);
        }
      });
    });
  }

  onConfigurationUpdate(newConfig: Configuration) {
    FontScaleState.updateAppFontGearSize(newConfig.fontSizeScale)
  }

  fetchSystemFontSizeScale(): void {
    let fontSizeScale = this.context.config?.fontSizeScale;
    FontScaleState.updateAppFontGearSize(fontSizeScale);
  }

  private handleWantParams(want: Want, localStorage: LocalStorage) {
    let startReason = want?.parameters?.['startReason'] as string;
    localStorage.setOrCreate<string>('startReason', startReason);
  }

  private registerFoldStatusChanged() {
    if (MainAbility.createdTimes === Constants.TIMES_0) {
      DisplayUtils.registerFoldStatusChanged();
    }
  }

  private unregisterFoldStatusChanged() {
    if (MainAbility.createdTimes === Constants.TIMES_1) {
      DisplayUtils.unregisterFoldStatusChanged();
    }
  }

  private cancelTimeout() {
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
    }
  }
}
