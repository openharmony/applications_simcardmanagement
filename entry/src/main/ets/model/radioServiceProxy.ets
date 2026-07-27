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
 * @file: radio service interface
 */

import radio from '@ohos.telephony.radio';
import { BusinessError } from '@ohos.base';
import LogUtils from '../common/utils/LogUtils';

const TAG = 'radioserviceProxy';

/**
 * Get support network
 *
 * @param  {number} slotId - slot ID
 * @return {Promise}
 */
export function getSupportNetwork(slotId = 0) {
  return new Promise((resolve: (value: boolean) => void, reject: (reason?: BusinessError) => void) =>{
    try {
      let isSupported = radio.isNrSupported();
      LogUtils.i(TAG, 'getSupportNetwork isNrSupported:' + isSupported);
      resolve(isSupported);
    } catch (error) {
      LogUtils.e(TAG, 'getSupportNetwork isNrSupported:catch' + JSON.stringify(error));
      reject(error);
    }
  });
};

function doGetOpName(slotId:number, resolve: (value: string) => void = () => {},
  reject: (error: BusinessError<void>) => void = () => {}) {
    radio.getOperatorName(slotId, (error, value) => {
      if (error) {
        LogUtils.e(TAG, 'getOperatorName error:' + JSON.stringify(error) + ',slotId=' + slotId);
        reject(error);
        return;
      }
      LogUtils.i(TAG, 'getOperatorName value:' + JSON.stringify(value) + ',slotId=' + slotId);
      resolve(value);
    });
}
/**
 * Get operation name
 *
 * @param {number} slotId - slot id
 * @return {Promise}
 */
export function getOperatorName(slotId = 0) {
  return new Promise((resolve: (value: string) => void, reject: (reason?: BusinessError) => void) => {
    try {
      doGetOpName(slotId, resolve, reject);
    } catch (error) {
      LogUtils.e(TAG, 'getOperatorName catch:' + JSON.stringify(error));
      reject(error);
    }
  });
};

function doGetPrimarySlotId(resolve: (value: number) => void = () => {},
  reject: (error: BusinessError<void>) => void = () => {}) {
  radio.getPrimarySlotId((error, value) => {
    if (error) {
      LogUtils.e(TAG, 'getPrimarySlotId error:' + JSON.stringify(error));
      reject(error);
      return;
    }
    LogUtils.i(TAG, 'getPrimarySlotId data:' + JSON.stringify(value));
    resolve(value);
  });
}

/**
 * Get Primary SlotId
 *
 * @param  {number} slotId - slot ID
 * @return {Promise}
 */
export function getPrimarySlotId() {
  return new Promise((resolve: (value: number) => void, reject: (reason?: BusinessError) => void) => {
    try {
      doGetPrimarySlotId(resolve, reject);
    } catch (error) {
      LogUtils.e(TAG, 'getPrimarySlotId catch:' + JSON.stringify(error));
      reject(error);
    }
  });
}

function doSetPrimarySlotId(slotId: number, resolve: (value: boolean) => void = () => {},
  reject: (error: BusinessError<void>) => void = () => {}) {
    radio.setPrimarySlotId(slotId, (error, data) => {
      if (error) {
        LogUtils.e(TAG, 'setPrimarySlotId error:' + JSON.stringify(error));
        reject(error);
        return;
      }
      LogUtils.i(TAG, 'setPrimarySlotId data:' + JSON.stringify(data));
      resolve(true);
    });
}

/**
 * Set Primary SlotId
 *
 * @param  {number} slotId - slot ID
 * @return {Promise}
 */
export function setPrimarySlotId(slotId = 0) {
  return new Promise((resolve: (value: boolean) => void, reject: (reason?: BusinessError) => void) => {
    try {
      doSetPrimarySlotId(slotId, resolve, reject);
    } catch (error) {
      LogUtils.e(TAG, 'setPrimarySlotId catch:' + JSON.stringify(error));
      reject(error);
    }
  });
}

/**
 * register imsRegStateChange
 *
 * @param slotId  {number} slotId - slot ID
 * @param callBack Callback Interface
 * @returns {Promise}
 */
export function registerImsRegStateChange(slotId: number, callBack: Callback<radio.ImsRegInfo>) {
  let mode: radio.ImsServiceType = radio.ImsServiceType.TYPE_VIDEO;
  LogUtils.i(TAG, `registerImsRegStateChange`);
  try {
    radio.on('imsRegStateChange', slotId, mode, callBack);
  } catch (err) {
    LogUtils.e(TAG, 'registerImsRegStateChange catch:' + JSON.stringify(err));
  }
}

/**
 * unregister imsRegStateChange
 *
 * @param slotId {number} slotId - slot ID
 * @param callBack Callback Interface
 * @returns {Promise}
 */
export function unRegisterImsRegStateChange(slotId: number, callBack: Callback<radio.ImsRegInfo>) {
  let mode: radio.ImsServiceType = radio.ImsServiceType.TYPE_VIDEO;
  LogUtils.i(TAG, `unRegisterImsRegStateChange slotId=` + slotId);
  try {
    radio.off('imsRegStateChange', slotId, mode, callBack);
  } catch (err) {
    LogUtils.e(TAG, 'unRegisterImsRegStateChange catch:' + JSON.stringify(err));
  }
}