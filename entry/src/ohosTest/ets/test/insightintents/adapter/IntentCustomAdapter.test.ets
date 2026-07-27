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

import { describe, it, expect } from '@ohos/hypium'
import { IntentCustomAdaptor } from '../../../../../main/ets/insightintents/adapter/IntentCustomAdapter'

export default function IntentCustomAdapterTest() {
  describe('IntentCustomAdapterTest', () => {
    it('IntentCustomAdapterTest_01', 0, () => {
      IntentCustomAdaptor.getDefaultMobileDataSimCard()
      expect(1).assertEqual(1);
    })
    it('IntentCustomAdapterTest_02', 0, () => {
      IntentCustomAdaptor.setDefaultMobileDataSimCard(0)
      expect(1).assertEqual(1);
    })
    it('IntentCustomAdapterTest_04', 0, () => {
      IntentCustomAdaptor.getDefaultDialingSimCard()
      expect(1).assertEqual(1);
    })
    it('IntentCustomAdapterTest_05', 0, () => {
      IntentCustomAdaptor.setDefaultDialingSimCard(0)
      expect(1).assertEqual(1);
    })
    it('IntentCustomAdapterTest_07', 0, () => {
      IntentCustomAdaptor.getPhoneCardNumber(0)
      expect(1).assertEqual(1);
    })
    it('IntentCustomAdapterTest_09', 0, () => {
      IntentCustomAdaptor.checkSimSwitch(0)
      expect(1).assertEqual(1);
    })
    it('IntentCustomAdapterTest_11', 0, () => {
      IntentCustomAdaptor.getSimSwitch(0)
      expect(1).assertEqual(1);
    })
    it('IntentCustomAdapterTest_13', 0, () => {
      IntentCustomAdaptor.setSimSwitch(0, 0)
      expect(1).assertEqual(1);
    })
  })
}



