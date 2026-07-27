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
import { LockType } from './constant';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export class AppStorageUtils {
  public static SIM_LOCK_TYPES = 'simLockTypes'
  public static NAVIGATION_BAR_HEIGHT = 'navigationBarHeight'

  private constructor() {
  }

  /**
   * Saves the SIM lock type as a global state and provides the method to update it.
   *
   * @param slotId - Card slot ID corresponding to the lock type.
   * @param lockType - Lock type of the SIM.
   */
  public static updateSimLockType(slotId: number, lockType: LockType) {
    let lockTypes = AppStorage.get<LockType[]>(AppStorageUtils.SIM_LOCK_TYPES);
    if (typeof lockTypes === 'undefined' || lockTypes === null) {
      lockTypes = [LockType.NOT_LOCKED, LockType.NOT_LOCKED]
    }
    if (slotId >= 0 && slotId < lockTypes.length) {
      lockTypes[slotId] = lockType;
    }
    AppStorage.setOrCreate<LockType[]>(AppStorageUtils.SIM_LOCK_TYPES, lockTypes);
  }

  /**
   * 更新保存导航条的高度
   *
   * @param session 会话窗口
   */
  public static updateNavigationBarHeight(session: UIExtensionContentSession) {
    let height = session.getUIExtensionWindowProxy()
      .getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height;
    AppStorage.setOrCreate<number>(AppStorageUtils.NAVIGATION_BAR_HEIGHT, height);
  }

  /**
   * 获取缓存的导航条高度
   *
   * @returns 导航条的高度
   */
  public static getNavigationBarHeight(): number {
    let height = AppStorage.get<number>(AppStorageUtils.NAVIGATION_BAR_HEIGHT);
    if (typeof height === 'undefined') {
      height = 0;
    }
    return height;
  }
}