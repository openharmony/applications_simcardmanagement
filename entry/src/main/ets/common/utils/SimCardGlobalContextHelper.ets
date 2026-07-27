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

import LogUtils from './LogUtils';

const TAG = 'SimCardGlobalContextHelper'
export class SimCardGlobalContextHelper {
  private constructor() {}
  private static instance: SimCardGlobalContextHelper;
  private objects = new Map<string, Object>();
  private static registerKeys = [
    'simCardAbilityContext',
  ];

  public static getInstance(): SimCardGlobalContextHelper {
    if (!SimCardGlobalContextHelper.instance) {
      SimCardGlobalContextHelper.instance = new SimCardGlobalContextHelper();
    }
    return SimCardGlobalContextHelper.instance;
  }

  getValue<T>(key: string): T | undefined {
    const value = this.objects.get(key);
    if (typeof value !== 'undefined' && value !== null) {
      return value as T;
    } else {
      return undefined;
    }
  }

  set<T extends Object>(key: string, value: T): void {
    const element = SimCardGlobalContextHelper.registerKeys.find((ele: string) => ele === key);
    if (element === undefined) {
      LogUtils.i(TAG, 'GlobalContextHelper can not find register key:' + JSON.stringify(key));
      return;
    }
    this.objects.set(key, value);
  }
}