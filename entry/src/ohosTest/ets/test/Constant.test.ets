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

import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from '@ohos/hypium';
import {
  CARD_CALLING_SET,
  CARD_NET_SUPPORT,
  DIALOG_TYPE,
  SIM_CARD_ABILITY_CONTEXT,
  UPDATE_DIALOG_TYPE
} from '../../../main/ets/common/utils/constant';

export default function ConstantTest() {
  describe('ConstantTest', () => {
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
    it('testConstant', 0, () => {
      const dialogtype: string = 'twoButton';
      expect(dialogtype).assertEqual(DIALOG_TYPE.TWO_BUTTON_DIALOG);
      const toastdialog: string = 'toast';
      expect(toastdialog).assertEqual(DIALOG_TYPE.TOAST_DIALOG);
      const updateDialogAddEsim: string = 'addESim';
      expect(updateDialogAddEsim).assertEqual(UPDATE_DIALOG_TYPE.ADD_ESIM);
      const callingNotSet = -1;
      expect(callingNotSet).assertEqual(CARD_CALLING_SET.NO_SETTING);
      const card1 = 0;
      expect(card1).assertEqual(CARD_CALLING_SET.CARD1);
      const card2 = 1;
      expect(card2).assertEqual(CARD_CALLING_SET.CARD2);

      const noSupport5g = '4G/3G/2G';
      expect(noSupport5g).assertEqual(CARD_NET_SUPPORT.NO_SUPPORT_5G);

      const support5g = '5G/4G/3G/2G';
      expect(support5g).assertEqual(CARD_NET_SUPPORT.SUPPORT_5G);

      const simCardAbilityContext = 'simCardAbilityContext';
      expect(simCardAbilityContext).assertEqual(SIM_CARD_ABILITY_CONTEXT);
    })
  })
}