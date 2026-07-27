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
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from '@ohos/hypium';
import { getPagePaddingByDeviceType, isEmpty } from '../../../../../main/ets/common/utils/Utils';
import { DeviceUtils } from '../../../../../main/ets/utils/DeviceUtils';

export default function UtilsTest() {
  describe('UtilsTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    })
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    })
    it('UtilsTest_isEmpty', 0, () => {
      const value1 = '';
      let isEmpty1 = isEmpty(value1);
      expect(isEmpty1).assertTrue();
      const value2 = '123';
      let isEmpty2 = isEmpty(value2);
      expect(isEmpty2).assertFalse();
    });
    it('UtilsTest_getPagePaddingByDeviceType', 0, () => {
      const res = getPagePaddingByDeviceType();
      const value = DeviceUtils.isTablet() ? $r('sys.float.padding_level12') : $r('sys.float.padding_level8');
      expect(res.id).assertEqual(value.id);
    });
  })
}