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
import { display } from '@kit.ArkUI';
import { settings } from '@kit.BasicServicesKit';
import LogUtils from '../common/utils/LogUtils';
import { DeviceUtils } from './DeviceUtils';
import { common } from '@kit.AbilityKit';
import { isEmpty } from '../common/utils/Utils';

const TAG = 'DisplayUtils';

export class DisplayUtils {
  /**
   * 是否处于设置分栏
   *
   * @param context 上下文
   * @return boolean true: 设置分栏, false: 全屏显示
   */
  public static isSplit(context: common.Context): boolean {
    try {
      if (display.isFoldable() && (display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_EXPANDED ||
        display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_HALF_FOLDED)) {
        LogUtils.i(TAG, `isSplit,fold expanded or half folded.`);
        return true;
      }
      if (DeviceUtils.isTablet()) {
        let currentDpiStr = settings.getValueSync(context, 'user_set_dpi_value', '');
        let currentDpi = isEmpty(currentDpiStr) ? 0 : Number(currentDpiStr);
        const PORTRAIT_NO_SPLIT_DPI = 480;
        const isSplit = !DeviceUtils.isDevicePortrait() || currentDpi < PORTRAIT_NO_SPLIT_DPI;
        LogUtils.i(TAG, `isSplit = ${JSON.stringify(isSplit)}`);
        return isSplit;
      }
    } catch (err) {
      LogUtils.e(TAG, `isSplit error: ${err?.code} ${err?.message}`);
    }
    return false;
  }

  /**
   * 注册折叠屏展开状态监听
   */
  public static registerFoldStatusChanged() {
    try {
      if (!display.isFoldable()) {
        LogUtils.i(TAG, 'registerFoldStatusChanged is not a folded phone');
        return;
      }
      display.on('foldStatusChange', (foldStatus: display.FoldStatus) => {
        LogUtils.i(TAG, `onFoldStatusChanged foldStatus=${foldStatus}`);
        AppStorage.setOrCreate('foldStatus', foldStatus);
      });
    } catch (exception) {
      LogUtils.e(TAG, 'registerFoldStatusChanged fFailed error=' + JSON.stringify(exception));
    }
  }

  /**
   * 解除注册折叠屏展开状态监听
   */
  public static unregisterFoldStatusChanged() {
    try {
      if (!display.isFoldable()) {
        LogUtils.i(TAG, 'unregisterFoldStatusChanged is not a folded phone');
        return;
      }
      display.off('foldStatusChange');
    } catch (exception) {
      LogUtils.e(TAG, 'unregisterFoldStatusChanged Failed error=' + JSON.stringify(exception));
    }
    AppStorage.delete('foldStatus');
  }
}