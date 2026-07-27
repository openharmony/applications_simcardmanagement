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

import { userAuth } from '@kit.UserAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import LogUtils from './LogUtils';
import json from '@ohos.util.json';
import { getString } from './Utils';

const TAG = 'UserAuthUtils';
const authParam: userAuth.AuthParam = {
  challenge: new Uint8Array([49, 49, 49, 49, 49, 49]),
  authType: [userAuth.UserAuthType.PIN],
  authTrustLevel: userAuth.AuthTrustLevel.ATL3,
};

// 配置认证界面
const widgetParam: userAuth.WidgetParam = {
  title: getString($r('app.string.sim_pin'))
};

export class UserAuthUtils {

  /**
   * Invoke the screen lock password verification page.
   *
   * @param userAuthCallback Verifying the Screen Lock Password.
   */
  public static verifyScreenLockPassword(userAuthCallback: (result: boolean) => void) {
    try {
      // 获取认证对象
      let userAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);
      LogUtils.i(TAG, 'verifyScreenLockPassword,get userAuth instance success');
      // 订阅认证结果
      userAuthInstance.on('result', {
        onResult(result) {
          LogUtils.i(TAG, 'verifyScreenLockPassword,userAuthInstance callback result: ' + JSON.stringify(result));
          let res = result.result === userAuth.UserAuthResultCode.SUCCESS;
          userAuthCallback(res);
          // 可在认证结束或其他业务需要场景，取消订阅认证结果
          userAuthInstance.off('result');
        }
      });
      LogUtils.i(TAG, 'verifyScreenLockPassword,auth on success');
      userAuthInstance.start();
      LogUtils.i(TAG, 'verifyScreenLockPassword,start success');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      LogUtils.e(TAG, 'verifyScreenLockPassword,auth catch error:' + json.stringify(err));
      userAuthCallback(false);
    }
  }
}