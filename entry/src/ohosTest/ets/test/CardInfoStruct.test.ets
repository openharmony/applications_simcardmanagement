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
import CardInfoStruct from '../../../main/ets/common/struct/operaNameStruct';

export default function CardInfoStructTest() {
  describe('CardInfoStructTest', () => {
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
    it('CardInfoStruct', 0, () => {
      let CardInfo = new CardInfoStruct();
      let CUR_SLOT_ID = CardInfo.CUR_SLOT_ID;
      expect(CUR_SLOT_ID).assertEqual(-1);
      let CUR_PLMN_SHOW = CardInfo.CUR_PLMN_SHOW;
      expect(CUR_PLMN_SHOW).assertEqual(false);

      let spn = CardInfo.CUR_PLMN;
      expect(spn).assertEqual('');

      let plmnShow = CardInfo.CUR_PLMN_SHOW;
      expect(plmnShow).assertEqual(false);

      let curSpnShow = CardInfo.CUR_SPN_SHOW;
      expect(curSpnShow).assertEqual(false);
    })
  })
}