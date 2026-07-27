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

import LogUtils from '../common/utils/LogUtils';
import Want from '@ohos.app.ability.Want';
import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { FontScaleState } from '../common/utils/fontScaleState';
import { Configuration } from '@ohos.app.ability.Configuration';

const TAG = 'MobileDataChangeExtAbility';
const SCENEBOARD_NAME = 'com.ohos.sceneboard';

export default class MobileDataChangeExtAbility extends UIExtensionAbility {

  onCreate() {
    LogUtils.i(TAG, 'MobileDataChangeExtAbility onCreate');
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    // want校验,仅支持控制中心拉起
    LogUtils.i(TAG, 'MobileDataChangeExtAbility onSessionCreate');
    this.fetchSystemFontSizeScale();
    if (!this.isControlCenterInvocation(want)) {
      LogUtils.e(TAG, 'Only the control center can invoke this interface.');
      return;
    }
    let param: Record<string, UIExtensionContentSession> = {
      'uiExtensionSession': session
    }
    let storage: LocalStorage = new LocalStorage(param);
    try {
      session.loadContent('common/components/mobileDataToggleDialog', storage);
      session.setWindowBackgroundColor('#00000000');
    } catch (e) {
      LogUtils.e(TAG, `session.loadContent error`);
    }
  }

  isControlCenterInvocation(want: Want) {
    if (want.parameters?.['ohos.aafwk.param.callerBundleName'] === SCENEBOARD_NAME) {
      return true;
    }
    return false;
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    LogUtils.i(TAG, 'MobileDataChangeExtAbility onSessionDestroy');
  }

  onForeground() {
    LogUtils.i(TAG, 'MobileDataChangeExtAbility onForeground');
  }

  onBackground() {
    LogUtils.i(TAG, 'MobileDataChangeExtAbility onBackground');
  }

  onDestroy() {
    LogUtils.i(TAG, 'MobileDataChangeExtAbility onDestroy');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    FontScaleState.updateAppFontGearSize(newConfig.fontSizeScale)
  }

  fetchSystemFontSizeScale(): void {
    let fontSizeScale = this.context.config?.fontSizeScale;
    FontScaleState.updateAppFontGearSize(fontSizeScale);
  }
}