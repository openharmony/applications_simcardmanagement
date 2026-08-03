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
import { Want } from '@kit.AbilityKit';
import { SetScreenPwdResult } from '../data/Infos';

const TAG = 'SetScreenLockPassword';
const RESULT_CODE_SUCCEED = 0;
const RESULT_CODE_ERROR = -1;

@Builder
export function SetScreenLockPasswordBuilder(): void {
  SetScreenLockPassword();
}

@Component
export default struct SetScreenLockPassword {
  @Consume('pageInfos') pageInfos: NavPathStack
  private want: Want = {
    bundleName: 'com.ohos.settings',
    abilityName: 'PasswordSettingExtensionAbility',
    parameters: {
      'ability.want.params.uiExtensionType': 'sysDialog/common',
      'pushParams': {
        'challenge': 'MTExMETx',
        'token': '',
        'from': 'UIExtension'
      }
    }
  }

  onSetScreenPwdReceived(result: Object) {
    if (!Number.isNaN(result)) {
      let code = result as number;
      LogUtils.i(TAG, `onSetScreenPwdReceived code = ${JSON.stringify(code)}`);
      this.finishWithResult(new SetScreenPwdResult(code === RESULT_CODE_SUCCEED));
    }
  }

  finishWithResult(result: SetScreenPwdResult) {
    this.pageInfos.pop(result);
  }

  @Styles
  normalStyles() {
    .backgroundColor('rgba(255,255,255,0)')
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
  }

  build() {
    NavDestination() {
      Column() {
        UIExtensionComponent(this.want)
          .onRemoteReady((proxy: UIExtensionProxy) => {
            LogUtils.i(TAG, 'onRemoteReady ' + JSON.stringify(proxy));
          })
          .onReceive((obj) => {
            LogUtils.i(TAG, 'onReceive ' + JSON.stringify(obj));
            this.onSetScreenPwdReceived(obj['result']);
          })
          .onResult((data) => {
            LogUtils.i(TAG, 'onResult ' + JSON.stringify(data));
          })
          .onRelease((code) => {
            LogUtils.i(TAG, 'onRelease ' + JSON.stringify(code));
          })
          .defaultFocus(true)
          .onError((err) => {
            LogUtils.i(TAG, 'onError ' + JSON.stringify(err));
          })
          .size({ width: '100%', height: '100%' })
      }
    }
    .hideTitleBar(true)
    .mode(NavDestinationMode.STANDARD)
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.KEYBOARD])
    .onBackPressed(() => {
      const popDestinationInfo = this.onSetScreenPwdReceived(RESULT_CODE_ERROR);
      LogUtils.i(TAG, 'pop result = ' + JSON.stringify(popDestinationInfo));
      return true;
    })
  }
}