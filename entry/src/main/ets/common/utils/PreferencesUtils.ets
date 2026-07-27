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
import dataPreferences from '@ohos.data.preferences';
import { ValueType } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import LogUtils from './LogUtils';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'PreferencesUtils';
const SIM_MANAGER_STORE_NAME = 'sim_manager_store';
const DEFAULT_DATA_TEXT_HEIGHT = 'default_data_text_height';
const IS_OPEN_PIN_FIRST_TIME = 'is_open_pin_first_time';

class PreferencesUtils {
  putSync(context: Context, key: string, value: ValueType) {
    try {
      let options: dataPreferences.Options = { name: SIM_MANAGER_STORE_NAME };
      let pref = dataPreferences.getPreferencesSync(context, options);
      pref.putSync(key, value)
      pref.flush(((err: BusinessError) => {
        if (err) {
          LogUtils.e(TAG, 'Failed to flush,name=' + key + 'error=' + JSON.stringify(err));
        }
      }));
    } catch (error) {
      LogUtils.e(TAG, `putSync fialed,name=${key},error=${JSON.stringify(error)}`);
    }
  }

  getSync<T>(context: Context, key: string, defaultValue: ValueType): T {
    try {
      let options: dataPreferences.Options = { name: SIM_MANAGER_STORE_NAME };
      let pref = dataPreferences.getPreferencesSync(context, options);
      return pref.getSync(key, defaultValue) as T;
    } catch (error) {
      LogUtils.e(TAG, `getSync fialed,name=${key},error=${JSON.stringify(error)}`);
      return defaultValue as T;
    }
  }

  deleteSync(context: Context, key: string) {
    try {
      let options: dataPreferences.Options = { name: SIM_MANAGER_STORE_NAME };
      let pref = dataPreferences.getPreferencesSync(context, options);
      pref.deleteSync(key);
    } catch (error) {
      LogUtils.e(TAG, `deleteSync fialed,name=${key},error=${JSON.stringify(error)}`);
    }
  }

  putDefaultDataTextHeight(context: Context, value: number) {
    this.putSync(context, DEFAULT_DATA_TEXT_HEIGHT, value);
  }

  getDefaultDataTextHeight(context: Context): number {
    return this.getSync<number>(context, DEFAULT_DATA_TEXT_HEIGHT, 0);
  }

  setOpenPinFirstTimeToFalse(context: Context) {
    this.putSync(context, IS_OPEN_PIN_FIRST_TIME, false);
  }

  isOpenPinFirstTime(context: Context): boolean {
    return this.getSync<boolean>(context, IS_OPEN_PIN_FIRST_TIME, true);
  }
}

let preferencesUtils = new PreferencesUtils();

export default preferencesUtils;