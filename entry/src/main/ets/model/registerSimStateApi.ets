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
 * @file: registerSimStateApi
 */

import observer from '@ohos.telephony.observer';
import LogUtils from '../common/utils/LogUtils';
import sim from '@ohos.telephony.sim';
import { JSON } from '@kit.ArkTS';

const TAG = 'registerSimStateApi';

/**
 * Monitor the SIM card status
 *
 * @param {function} callBack - call-back
 * @param {string} slotId - card The slot id
 */
export function registerSimStateChange(slotId: number, callback: Callback<observer.SimStateData>) {
  LogUtils.i(TAG, 'registerSimStateChange slotId=' + slotId);
  try {
    observer.on('simStateChange', { slotId: slotId }, callback);
  } catch (err) {
    LogUtils.e(TAG, 'registerSimStateChange err=' + JSON.stringify(err));
  }
}

export function unRegisterSimStateChange(callback: Callback<observer.SimStateData>) {
  LogUtils.i(TAG, 'unRegisterSimStateChange');
  try {
    observer.off('simStateChange', callback);
  } catch (err) {
    LogUtils.e(TAG, 'unRegisterSimStateChange err=' + JSON.stringify(err));
  }
}

export function registerAccountInfoChange(callBack: Callback<void>) {
  LogUtils.i(TAG, 'registerAccountInfoChange');
  try {
    observer.on('iccAccountInfoChange', callBack);
  } catch (err) {
    LogUtils.e(TAG, 'registerAccountInfoChange err=' + JSON.stringify(err));
  }
}

export function unRegisterAccountInfoChange(callBack: Callback<void>) {
  LogUtils.i(TAG, 'unRegisterAccountInfoChange');
  try {
    observer.off('iccAccountInfoChange', callBack);
  } catch (err) {
    LogUtils.e(TAG, 'unRegisterAccountInfoChange err=' + JSON.stringify(err));
  }
}

export function registerNetworkStateChange(slotId: number, callback: Callback<observer.NetworkState>) {
  LogUtils.i(TAG, 'registerNetworkStateChange slotId=' + slotId);
  try {
    observer.on('networkStateChange', { slotId: slotId }, callback);
  } catch (err) {
    LogUtils.e(TAG, 'registerNetworkStateChange err=' + JSON.stringify(err));
  }
}

export function unRegisterNetworkStateChange(callback: Callback<observer.NetworkState>) {
  LogUtils.i(TAG, 'unRegisterNetworkStateChange');
  try {
    observer.off('networkStateChange', callback);
  } catch (err) {
    LogUtils.e(TAG, 'unRegisterNetworkStateChange err=' + JSON.stringify(err));
  }
}

export function registerCallStateChange(slotId: number, callback: Callback<observer.CallStateInfo>) {
  LogUtils.i(TAG, 'registerCallStateChange slotId=' + slotId);
  try {
    observer.on('callStateChange', { slotId: slotId }, callback);
  } catch (err) {
    LogUtils.e(TAG, 'registerCallStateChange err=' + JSON.stringify(err));
  }
}

export function unRegisterCallStateChange(callback: Callback<observer.CallStateInfo>) {
  LogUtils.i(TAG, 'unRegisterCallStateChange');
  try {
    observer.off('callStateChange', callback);
  } catch (err) {
    LogUtils.e(TAG, 'unRegisterCallStateChange err=' + JSON.stringify(err));
  }
}

export function getMaxSimCount() {
  try {
    return sim.getMaxSimCount();
  } catch (err) {
    LogUtils.e(TAG, 'getMaxSimCount err=' + JSON.stringify(err));
    return 0;
  }
}