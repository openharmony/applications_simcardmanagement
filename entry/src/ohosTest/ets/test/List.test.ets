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

import TypeUtilsTest from './TypeUtils.test';
import abilityTest from './Ability.test';
import CardInfoStructTest from './CardInfoStruct.test';
import simIdFormatTest from './common/utils/SimIdFormat.test';
import ConstantTest from './Constant.test';
import IntellectChangeTest from './SmartDualCardSwitch.test';
import GetMaxSimCount from './GetMaxSimCount.test';
import GetCallState from './GetCallState.test';
import BackupExtensionTest from './backup/BackupExtension.test';
import RestoreUtilTest from './backup/RestoreUtil.test';
import CopyDbDataHelperTest from './backup/CopyDbDataHelper.test';
import UtilsTest from './common/utils/Utils.test';
import PreferencesUtilsTest from './common/utils/PreferencesUtils.test';
import DefaultIntentBackgroundUiAbilityTest from './insightintents/ability/DefaultIntentBackgroundUiAbility.test';
import IntentExecutorImplTest from './insightintents/IntentExecutorImpl.test';
import IntentCustomAdapterTest from './insightintents/adapter/IntentCustomAdapter.test';
import IntentCodeConstantTest from './insightintents/constant/IntentCodeConstant.test';
import IntentTypeTest from './insightintents/constant/IntentType.test';
import SimCardUtilTest from './insightintents/util/SimCardUtil.test';

export default function testsuite() {
  ConstantTest();
  abilityTest();
  TypeUtilsTest();
  CardInfoStructTest();
  simIdFormatTest();
  IntellectChangeTest();
  GetMaxSimCount();
  GetCallState();
  BackupExtensionTest();
  CopyDbDataHelperTest();
  RestoreUtilTest();
  UtilsTest();
  PreferencesUtilsTest();
  DefaultIntentBackgroundUiAbilityTest();
  IntentExecutorImplTest();
  IntentCustomAdapterTest();
  IntentCodeConstantTest();
  IntentTypeTest();
  SimCardUtilTest();
}