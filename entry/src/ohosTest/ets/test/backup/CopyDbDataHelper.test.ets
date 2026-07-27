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
import { copyDbDataHelper } from '../../../../main/ets/backup/CopyDbDataHelper';
import { DTGlobalContext } from '../../testability/TestAbility';
import fs from '@ohos.file.fs';
import { common } from '@kit.AbilityKit';

export default function CopyDbDataHelperTest() {
  describe('CopyDbDataHelperTest', () => {
    let context = DTGlobalContext.getContext().getObject('simcardContext') as common.ExtensionContext;
    let testSourcePath = context.filesDir + '/testDir';
    if (!fs.accessSync(testSourcePath)) {
      fs.mkdirSync(testSourcePath);
    }
    let filePath = testSourcePath + '/test.txt';
    let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of function.
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    })
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
      fs.closeSync(file);
      fs.rmdirSync(testSourcePath);
      fs.unlinkSync(context.databaseDir + '/rdb/test.txt');
      fs.unlinkSync(context.filesDir + '/test.txt');
    })
    it('CopyDbDataHelperTest_copyDbListFile', 0, () => {
      copyDbDataHelper.copyDbListFile(testSourcePath, context.databaseDir);
      expect(0).assertEqual(0);
    })
    it('CopyDbDataHelperTest_copyFile', 0, () => {
      copyDbDataHelper.copyFile(testSourcePath, context.filesDir, 'files');
      expect(0).assertEqual(0);
    })
  })
}