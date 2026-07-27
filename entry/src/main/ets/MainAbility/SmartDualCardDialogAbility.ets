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

import Want from '@ohos.app.ability.Want';
import LogUtils from '../common/utils/LogUtils';
import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import rpc from '@ohos.rpc';
import { FontScaleState } from '../common/utils/fontScaleState';

const TAG: string = 'SmartDualCardDialogAbility';
const localStorage: LocalStorage = new LocalStorage();
const ACCESS_TYPE_MASK: number = 0b11;
const SHIFT_DIGIT: number = 27;
const TOKEN_NATIVE: number = 1;
const TOKEN_HAP: number = 0;
const BG_COLOR: string = '#00000000';
const COLOR_MODE_NOT_SET: number = -1;

export default class SmartDualCardDialogAbility extends UIExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    LogUtils.i(TAG, 'onSessionCreate');
    let callingTokenId: number = rpc.IPCSkeleton.getCallingTokenId();
    if (!this.isSystemAbility(callingTokenId)) {
      LogUtils.e(TAG, 'check permission fail');
      return;
    }
    AppStorage.setOrCreate('session', session);
    this.fetchSystemFontSizeScale();
    (session as UIExtensionContentSession)?.loadContent('pages/smartDualCardDialog', localStorage);
    try {
      (session as UIExtensionContentSession)?.setWindowBackgroundColor(BG_COLOR);
      this.context?.getApplicationContext()?.setColorMode(COLOR_MODE_NOT_SET);
    } catch (error) {
      LogUtils.e(TAG, 'onSessionCreate error: ' + error?.code);
      (session as UIExtensionContentSession)?.terminateSelf();
    }
    return;
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
    LogUtils.i(TAG, 'onSessionDestroy');
  }

  private isSystemAbility(callingTokenId: number): boolean {
    let type: number = ACCESS_TYPE_MASK & (callingTokenId >> SHIFT_DIGIT);
    LogUtils.i(TAG, 'isSystemAbility, type:' + type);
    return type === TOKEN_NATIVE || type === TOKEN_HAP;
  }

  fetchSystemFontSizeScale(): void {
    let fontSizeScale = this.context.config?.fontSizeScale;
    FontScaleState.updateAppFontGearSize(fontSizeScale);
  }

};
