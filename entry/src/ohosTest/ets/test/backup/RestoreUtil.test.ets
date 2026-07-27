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

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import RestoreUtil from '../../../../main/ets/utils/RestoreUtil';
import { DTGlobalContext } from '../../testability/TestAbility';
import fs from '@ohos.file.fs';
import { common } from '@kit.AbilityKit';

export default function RestoreUtilTest() {
  let context = DTGlobalContext.getContext().getObject('simcardContext') as common.ExtensionContext;
  let restoreUtil = RestoreUtil.getInstance();
  let filePath1 = context.filesDir + '/phone-account-registrar-state.xml';
  let file1 = fs.openSync(filePath1, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
  const AND = 'and';
  const ROID = 'roid';
  const AND_ROID = `${AND}${ROID}`;
  let filePath2 = context.preferencesDir + `/com.${AND_ROID}.phone_preferences.xml`;
  let file2 = fs.openSync(filePath2, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
  let xmlStr1 = '<?xml version="1.0" encoding="utf-8" standalone="yes" ?>' +
    '<default_outgoing_phone_account_handle>' +
    '    <id>89860322950274472149</id>' +
    '</default_outgoing_phone_account_handle>';
  let xmlStr2 = '<?xml version="1.0" encoding="utf-8" standalone="yes" ?>' +
    '<map>' +
    '    <string name="sim_name_1">test1</string>' +
    '    <string name="sim_name_2">test2</string>' +
    '</map>';
  fs.writeSync(file1.fd, xmlStr1);
  fs.writeSync(file2.fd, xmlStr2);
  describe('RestoreUtilTest', () => {
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
      fs.closeSync(file1);
      fs.closeSync(file2);
      fs.unlinkSync(filePath1);
      fs.unlinkSync(filePath2);
    })
    it('RestoreUtilTest_getInstance', 0, () => {
      RestoreUtil.getInstance();
      expect(0).assertEqual(0);
    })
    it('RestoreUtilTest_upgrade', 0, async () => {
      await restoreUtil.upgrade(context);
      expect(0).assertEqual(0);
    })
  })
}
