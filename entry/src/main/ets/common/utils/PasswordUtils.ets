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
import { isEmpty } from './Utils';

const TAG = 'PasswordUtils';

class PasswordUtils {
  /**
   * judge whether the password is weak password
   *
   * @param password - Password to verify
   * @returns true:is a weak password;false:Not a weak password.
   */
  public isWeakPasswords(password: string): boolean {
    if (isEmpty(password)) {
      LogUtils.i(TAG, 'password is empty');
      return false;
    }
    let length = password.length;
    let strings: string[] = [];
    for (let index = 0; index < length; index++) {
      const element = password.substring(index, index + 1);
      strings.push(element);
    }
    let isAllSame = true;
    strings.forEach((str) => {
      if (strings[0] !== str) {
        isAllSame = false;
        return;
      }
    })
    if (isAllSame) {
      return true;
    }
    if (this.isAscendingOrDescendingOrder(length, strings)) {
      return true;
    }
    return false;
  }

  private isAscendingOrDescendingOrder(pwdListLength: number, strings: string[]): boolean {
    let numbers = 0;
    let passwords: number[] = [];
    for (let i = 0; i < pwdListLength; i++) {
      let element = strings[i].charAt(0);
      if (element >= '0' && element <= '9') {
        numbers++;
        if (!isNaN(Number(strings[i]))) {
          passwords[i] = Number(strings[i]);
        }
      }
    }
    let isWeakPwd = true;
    if (numbers == pwdListLength && passwords.length == pwdListLength) {
      let rank = passwords[1] - passwords[0];
      if (Math.abs(rank) != 1) {
        return false;
      }
      for (let i = 0; i < pwdListLength - 1; i++) {
        if (passwords[i + 1] - passwords[i] != rank) {
          isWeakPwd = false;
          break;
        }
      }
    } else {
      isWeakPwd = false;
    }
    return isWeakPwd;
  }
}

let passwordUtils = new PasswordUtils();

export default passwordUtils;