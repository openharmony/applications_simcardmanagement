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

import CommonEventManager from '@ohos.commonEventManager';
import { BusinessError } from '@ohos.base';
import LogUtils from './LogUtils';
import { COMMON_EVENT_SET_PRIMARY_SLOT_STATUS } from './constant';
import Queue from '@ohos.util.Queue';

const TAG = 'PrimaryCardEventManager';

let primarySubscriberQueue: Queue<CommonEventManager.CommonEventSubscriber> = new Queue();

let primarySubscribeInfo: CommonEventManager.CommonEventSubscribeInfo = {
  events: [COMMON_EVENT_SET_PRIMARY_SLOT_STATUS]
};

class PrimaryChangedEventData {
  public setDone: boolean = false;
}

/**
 * Manager of the default data event.
 */
export class PrimaryCardEventManager {
  /**
   * Register to listen to the change event of the primary card.
   *
   * @param onPrimaryChanged Callback interface of the primary card change event.
   */
  public static subscribePrimaryChangedEvent(onPrimaryChanged: OnPrimaryChangedListener) {
    LogUtils.i(TAG, 'subscribePrimaryChangedEvent');
    CommonEventManager.createSubscriber(primarySubscribeInfo, (err: BusinessError,
      commonEventSubscriber: CommonEventManager.CommonEventSubscriber) => {
      if (err) {
        LogUtils.i(TAG, 'subscribePrimaryChangedEvent: createSubscriber err=' + JSON.stringify(err));
        return;
      }
      primarySubscriberQueue.add(commonEventSubscriber);
      LogUtils.i(TAG, 'subscribePrimaryChangedEvent primarySubscriberQueue size = ' + primarySubscriberQueue.length);
      CommonEventManager.subscribe(commonEventSubscriber, (err: BusinessError,
        data: CommonEventManager.CommonEventData) => {
        if (err) {
          LogUtils.i(TAG, 'subscribePrimaryChangedEvent: callback err=' + JSON.stringify(err));
          return;
        }
        if (onPrimaryChanged !== null && data.event === COMMON_EVENT_SET_PRIMARY_SLOT_STATUS && data !== null &&
          data.parameters !== null) {
          LogUtils.i(TAG, 'subscribePrimaryChangedEvent: onSetDefaultDataEvent' + JSON.stringify(data));
          onPrimaryChanged.onPrimaryChanged((data.parameters as PrimaryChangedEventData).setDone);
        }
      });
    });
  }

  /**
   * Unregister the change event of the primary card.
   */
  public static unSubscribePrimaryChangedEvent() {
    LogUtils.i(TAG, 'unSubscribePrimaryChangedEvent');
    try {
      let primarySubscriber = primarySubscriberQueue.pop();
      LogUtils.i(TAG, 'unSubscribePrimaryChangedEvent primarySubscriberQueue size = ' + primarySubscriberQueue.length);
      if (primarySubscriber === null) {
        LogUtils.i(TAG, 'unSubscribePrimaryChangedEvent primarySubscriber is null');
        return;
      }
      CommonEventManager.unsubscribe(primarySubscriber, (err: BusinessError) => {
        if (err) {
          LogUtils.i(TAG, 'unSubscribePrimaryChangedEvent failed, err = ' + JSON.stringify(err));
        }
      });
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtils.i(TAG, `unSubscribePrimaryChangedEvent failed, code is ${err.code}, message is ${err.message}`);
    }
  }
}

/**
 * Interface for listening to the change of the primary card.
 */
export interface OnPrimaryChangedListener {
  onPrimaryChanged: (isDone: boolean) => void
}