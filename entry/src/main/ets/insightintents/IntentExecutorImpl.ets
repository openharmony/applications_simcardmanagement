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

import { insightIntent, InsightIntentExecutor } from '@kit.AbilityKit';
import LogUtils from '../common/utils/LogUtils';
import { ERROR_MSG, IntentCodeConstants } from './constant/IntentCodeConstant';
import { IntentType } from './constant/IntentType';
import { isEmpty } from '../common/utils/Utils';
import { IntentCustomAdaptor } from './adapter/IntentCustomAdapter';

const TAG = 'IntentExecutorImpl';

/**
 * Entry for insight intent execution.
 */
export default class IntentExecutorImpl extends InsightIntentExecutor {
  /**
   * Intention Framework Startup Background Ability Callback
   */
  async onExecuteInUIAbilityBackgroundMode(intentName: string,
    intentParam: Record<string, Object>): Promise<insightIntent.ExecuteResult> {
    LogUtils.i(TAG, `onExecuteInUIAbilityBackgroundMode intentName is ${intentName}`);
    let rsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED,
      result: {
        'errMsg': ERROR_MSG[IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED],
      }
    };
    try {
      rsp = await this.executeCustomIntent(intentName, intentParam);
    } catch (error) {
      LogUtils.e(TAG, `onExecuteInUIAbilityBackgroundMode error code is ${error.code}, message is ${error.message}`);
    }
    return rsp;
  }

  private async executeCustomIntent(intentName: string, intentParam: Record<string, Object>) {
    let rsp: insightIntent.ExecuteResult = {
      code: IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED,
      result: {
        'errMsg': ERROR_MSG[IntentCodeConstants.DEFAULT_CODE_UNSUPPORTED],
      }
    };
    let appBundleName: string = this.getAppBundleName(intentParam);
    LogUtils.i(TAG, `executeCustomIntent, intentName: ${intentName},appBundleName: ${appBundleName}`);
    switch (intentName) {
      case IntentType.CHECK_SETTING_PAGE:
        if (intentParam !== null && typeof intentParam !== 'undefined') {
          const entryKey: string = String(intentParam.entryKey);
          const appBundleName: string = String(intentParam.appBundleName);
          rsp = await IntentCustomAdaptor.checkSettingPage(entryKey, appBundleName);
        }
        break;
      case IntentType.GET_DEFAULT_MOBILE_DATA_SIM_CARD:
        rsp = await IntentCustomAdaptor.getDefaultMobileDataSimCard();
        break;
      case IntentType.SET_DEFAULT_MOBILE_DATA_SIM_CARD:
        if (intentParam !== null && typeof intentParam !== 'undefined') {
          rsp = await IntentCustomAdaptor.setDefaultMobileDataSimCard(Number(intentParam.slotId));
        }
        break;
      case IntentType.GET_DEFAULT_DIALING_SIM_CARD:
        rsp = await IntentCustomAdaptor.getDefaultDialingSimCard();
        break;
      case IntentType.GET_SIM_CARD_NUMBER:
        if (intentParam !== null && typeof intentParam !== 'undefined') {
          rsp = await IntentCustomAdaptor.getPhoneCardNumber(Number(intentParam.slotId));
        }
        break;
      case IntentType.SET_DEFAULT_DIALING_SIM_CARD:
        if (intentParam !== null && typeof intentParam !== 'undefined') {
          rsp = await IntentCustomAdaptor.setDefaultDialingSimCard(Number(intentParam.slotId));
        }
        break;
      case IntentType.CHECK_SIM_SWITCH:
        if (intentParam !== null && typeof intentParam !== 'undefined') {
          rsp = await IntentCustomAdaptor.checkSimSwitch(Number(intentParam.slotId));
        }
        break;
      case IntentType.GET_SIM_SWITCH:
        if (intentParam !== null && typeof intentParam !== 'undefined') {
          rsp = await IntentCustomAdaptor.getSimSwitch(Number(intentParam.slotId));
        }
        break;
      case IntentType.SET_SIM_SWITCH:
        if (intentParam !== null && typeof intentParam !== 'undefined') {
          rsp = await IntentCustomAdaptor.setSimSwitch(Number(intentParam.switchFlag), Number(intentParam.slotId));
        }
        break;
      case IntentType.CHECK_SETTING_ITEM:
        if (intentParam !== null && typeof intentParam !== 'undefined') {
          rsp = await IntentCustomAdaptor.handleCheckSettingItem(String(intentParam.itemName));
        }
        break;
      default:
        LogUtils.e(TAG, 'unSupport intent');
        break;
    }
    return rsp;
  }

  private getAppBundleName(intentParam: Record<string, Object>) {
    let appBundleName: string = String(intentParam.appBundleName);
    if (isEmpty(appBundleName)) {
      AppStorage.setOrCreate('appBundleName', null);
    } else {
      AppStorage.setOrCreate('appBundleName', appBundleName);
    }
    return appBundleName;
  }
}