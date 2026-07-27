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
import commonEvent from '@ohos.commonEvent';
import LogUtils from './LogUtils';
import commonEventManager from '@ohos.commonEventManager';
import CardInfoStruct from '../struct/operaNameStruct';
let subscriber: commonEventManager.CommonEventSubscriber;
const TAG = 'SubscriberManagement';
const events = ['usual.event.SPN_INFO_CHANGED', 'usual.event.SPN_INFO_CHANGED0', 'usual.event.SPN_INFO_CHANGED1', 'usual.event.SIM_STATE_CHANGE'];

export class SubscriberManagement {

  /**
   * Registered subscribers
   */
  public async registerSubscriber() {
    subscriber = await new Promise((resolve) => {
      commonEvent.createSubscriber({
        events,
        priority: 1000
      },
        (err, data) => {
          resolve(data);
        }
      );
    });

    commonEvent.subscribe(subscriber, (err, res) => {
      LogUtils.i(TAG, 'commonEvent subscribe:' + JSON.stringify(res));
      if (err && err.code === 0 && res) {
        if (typeof res.parameters !== 'undefined' && res.parameters !== null) {
          AppStorage.setOrCreate('operatorName', res.parameters as CardInfoStruct);
        }
      } else {
        LogUtils.i(TAG, 'commonEvent subscribe err:' + JSON.stringify(err));
      }
    });
  }
  /**
   * unsubscribe
   */
  public unsubscribe() {
    commonEvent.unsubscribe(subscriber, (err) => {
      if (err.code !== 0) {
        LogUtils.i(TAG, 'commonEvent unsubscribe err:' + JSON.stringify(err))
      }
    });
  }
}

let mSubscriberManagement = new SubscriberManagement();

export default mSubscriberManagement as SubscriberManagement;