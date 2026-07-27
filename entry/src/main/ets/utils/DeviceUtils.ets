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
import deviceInfo from '@ohos.deviceInfo';
import { Configuration, display } from '@kit.ArkUI';
import { RTL } from '../common/utils/constant';
import LogUtils from '../common/utils/LogUtils';

const TAG = 'DeviceUtils';

export class DeviceUtils {
  private static DEFAULT: string = 'default';
  private static PHONE: string = 'phone';
  private static TABLET: string = 'tablet';

  private constructor() {
  }

  /**
   * Determine whether the device is a mobile phone.
   *
   * @return true:is phone;flase:is not phone.
   */
  public static isPhone(): boolean {
    return deviceInfo.deviceType === DeviceUtils.PHONE || deviceInfo.deviceType === DeviceUtils.DEFAULT;
  }

  /**
   * Determine if the device is a tablet
   *
   * @returns true:is tablet;fale:is not tablet.
   */
  public static isTablet(): boolean {
    return deviceInfo.deviceType === DeviceUtils.TABLET;
  }

  /**
   * Determine whether the device uses the mirroring language.
   *
   * @returns true:It's mirror language.;false:Not mirror language
   */
  public static isRtl(): boolean {
    return Configuration.getLocale().dir === RTL;
  }

  /**
   * 当前设备是否为竖屏
   *
   * @return true: 竖屏  false: 横屏
   */
  public static isDevicePortrait(): boolean {
    try {
      const orientation: display.Orientation = display.getDefaultDisplaySync().orientation;
      if (orientation === display.Orientation.LANDSCAPE || orientation === display.Orientation.LANDSCAPE_INVERTED) {
        return false;
      }
    } catch (err) {
      LogUtils.e(TAG, `isDevicePortrait failed. error: ${err?.code} ${err?.message}`);
    }
    return true;
  }

  /**
   * 当前设备是否为折叠屏
   *
   * @returns boolean
   */
  public static isFoldable() {
    try {
      return display.isFoldable();
    } catch (err) {
      LogUtils.e(TAG, `isFoldable error: ${err?.code} ${err?.message}`);
    }
    return false;
  }
}