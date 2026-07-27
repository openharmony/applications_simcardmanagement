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
 * Log Util
 *
 * standard:
 * 1. define TAG, recommend class name.
 * 2. switch IS_DEBUG_ON as true, when debugging.
 * 3. msg should be short and valuable.
 * 4. choose appropriate function.
 * 5. the function execute many times can not print.
 * 6. uniqueness.
 */

/**
 *  log package tool class
 */
export class LogUtils {
  d(tag, msg): void {
    console.debug('[simCardManagement:]' + tag + ':' + msg);
  }

  i(tag, msg): void {
    console.info('[simCardManagement:]' + tag + ':' + msg);
  }

  w(tag, msg): void {
    console.warn('[simCardManagement:]' + tag + ':' + msg);
  }

  e(tag, msg): void {
    console.error('[simCardManagement:]' + tag + ':' + msg);
  }
}

let mLogUtil = new LogUtils();

export default mLogUtil as LogUtils;
