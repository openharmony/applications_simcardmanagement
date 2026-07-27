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
/**
 * Message/AirplaneMode utils
 */
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { BusinessError } from '@ohos.base';
import LogUtils from './LogUtils';
import { SimCardGlobalContextHelper } from '../utils/SimCardGlobalContextHelper';
import * as Constants from '../utils/constant';
import common from '@ohos.app.ability.common';

const SETTING_AIRPLANE_MODE_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';
const ON_SETTING_AIRPLANE_MODE_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?' +
  'Proxy=true&key=airplane_mode';
const QUERY_AIRPLANE_MODE_KEY = 'settings.telephony.airplanemode';
const TAG = 'AirplaneMode';

let dataShareHelper: dataShare.DataShareHelper;

function airPlaneModeChange(callback: Function) {
  try {
    dataShareHelper.on('dataChange', ON_SETTING_AIRPLANE_MODE_URI, () => {
      LogUtils.i(TAG, 'addAirPlaneModeListener dataChange');
      queryAirPlaneMode(callback);
    });
    queryAirPlaneMode(callback);
      } catch (err) {
      LogUtils.e(TAG, 'addAirPlaneModeListener error: code: ' + (err as BusinessError).code +
        ', message: ' + (err as BusinessError).message);
    }
}

/**
 * add AirPlaneMode Listener.
 */
export function addAirPlaneModeListener(callback: Function) {
  LogUtils.i(TAG, 'addAirPlaneModeListener');
  try {
    const context = SimCardGlobalContextHelper.getInstance()
      .getValue<common.UIAbilityContext>(Constants.SIM_CARD_ABILITY_CONTEXT)
    if (typeof context === 'undefined' || context === null) {
      LogUtils.w(TAG, 'addAirPlaneModeListener context is null');
      return;
    }
    dataShare.createDataShareHelper(context, SETTING_AIRPLANE_MODE_URI, (err, data) => {
      if (err != undefined) {
        LogUtils.e(TAG, 'addAirPlaneModeListener error: code: ' + err.code + ', message: ' + err.message);
        return;
      }
      dataShareHelper = data;
      airPlaneModeChange(callback);
    });
  } catch (err) {
    LogUtils.e(TAG, 'addAirPlaneModeListener error: code: ' + (err as BusinessError).code +
      ', message: ' + (err as BusinessError).message);
  }
}

/**
 * remove AirPlaneMode Listener.
 */
export function removeAirPlaneModeListener() {
  LogUtils.i(TAG, 'removeAirPlaneModeListener');
  if (!dataShareHelper) {
    LogUtils.e(TAG, 'removeAirPlaneModeListener dataShareHelper null');
    return;
  }
  try {
    dataShareHelper.off('dataChange', ON_SETTING_AIRPLANE_MODE_URI, () => {
      LogUtils.i(TAG, 'removeAirPlaneModeListener dataChange');
    });
  } catch (err) {
    LogUtils.e(TAG, 'removeAirPlaneModeListener error: code: ' + (err as BusinessError).code + ', message: ' +
      (err as BusinessError).message);
  }
}

/**
 * query AirPlaneMode.
 */
export function queryAirPlaneMode(callback: Function) {
  LogUtils.i(TAG, 'queryAirPlaneMode');
  if (!dataShareHelper) {
    LogUtils.e(TAG, 'queryAirPlaneMode dataShareHelper null');
    callback(-1);
    return;
  }
  let condition = new dataSharePredicates.DataSharePredicates();
  condition.equalTo('KEYWORD', QUERY_AIRPLANE_MODE_KEY);
  try {
    // ID, KEYWORD, VALUE
    dataShareHelper.query(ON_SETTING_AIRPLANE_MODE_URI, condition, []).then((data) => {
      if (data && data.goToFirstRow()) {
        LogUtils.i(TAG, 'queryAirPlaneMode query succeed return key');
        callback(data.getLong(data.getColumnIndex('VALUE')));
      } else {
        LogUtils.i(TAG, 'queryAirPlaneMode query failed');
        callback(-1);
      }
      if (data) {
        data.close();
        LogUtils.i(TAG, 'queryAirPlaneMode data closed');
      }
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'queryAirPlaneMode query in error: err: ' + JSON.stringify(err));
      callback(-1);
    });
  } catch (err) {
    LogUtils.e(TAG, 'queryAirPlaneMode query out error: code: ' + (err as BusinessError).code + ', message: ' +
      (err as BusinessError).message);
    callback(-1);
  }
}