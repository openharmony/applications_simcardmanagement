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

import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import LogUtils from '../../common/utils/LogUtils';

const TAG: string = 'DefaultIntentBackgroundUiAbility';

export default class DefaultIntentBackgroundUiAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    LogUtils.i(TAG, 'onCreate is called');
    AppStorage.setOrCreate('pageContext', this.context);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    LogUtils.i(TAG, 'onNewWant is called');
  }

  onDestroy(): void {
    LogUtils.i(TAG, 'onDestroy is called');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    LogUtils.i(TAG, 'onWindowStageCreate is called');
  }
}
