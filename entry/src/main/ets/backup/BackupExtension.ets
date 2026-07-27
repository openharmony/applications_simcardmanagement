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

import BackupExtensionAbility, { BundleVersion } from '@ohos.application.BackupExtensionAbility';
import LogUtils from '../common/utils/LogUtils';
import RestoreUtil from '../utils/RestoreUtil';
import { contextConstant } from '@kit.AbilityKit';
import { copyDbDataHelper } from './CopyDbDataHelper';
import rdb from '@ohos.data.relationalStore';

const TAG = 'BackupExtension';
const AND = 'and';
const ROID = 'roid';
const AND_ROID = `${AND}${ROID}`;
const BACKUP_DB_PATH = `/restore/com.${AND_ROID}.providers.telephony/de/databases/`;
const BACKUP_FILES_PATH = `/restore/com.${AND_ROID}.server.telecom/de/files/`;
const BACKUP_PREFS_PATH = `/restore/com.${AND_ROID}.phone/de/shared_prefs/`;

/**
 * Upgrade data handler
 */
export default class BackupExtension extends BackupExtensionAbility {
  private restoreErrorInfo: string = '';

  onBackup() {
    LogUtils.i(TAG, `onBackup init`);
  }

  async onRestore(bundleVersion: BundleVersion): Promise<void> {
    LogUtils.i(TAG, 'onRestore start');

    let versionName: string = bundleVersion.name + '';
    let restoreUtil: RestoreUtil = RestoreUtil.getInstance();
    if (versionName.startsWith('0.0.0.0')) {
      LogUtils.i(TAG, '0.0.0.0 start');
      this.context.area = contextConstant.AreaMode.EL1;
      copyDbDataHelper.copyDbListFile(this.context.backupDir + BACKUP_DB_PATH, this.context.databaseDir);
      copyDbDataHelper.copyFile(this.context.backupDir + BACKUP_FILES_PATH, this.context.filesDir, 'XmlFile');
      copyDbDataHelper.copyFile(this.context.backupDir + BACKUP_PREFS_PATH, this.context.preferencesDir, 'Prefs');
      await restoreUtil.upgrade(this.context);
      this.restoreErrorInfo = restoreUtil.errorInfo;
      try {
        await rdb.deleteRdbStore(this.context, 'telephony.db');
        await rdb.deleteRdbStore(this.context, 'mmssms.db');
        await rdb.deleteRdbStore(this.context, 'carrierIdentification.db');
        await rdb.deleteRdbStore(this.context, 'HbpcdLookup.db');
        await rdb.deleteRdbStore(this.context, 'CarrierInformation.db');
      } catch (error) {
        LogUtils.e(TAG, `delte failed, error code:${error?.code}`);
      }
    }
  }

  async onRestoreEx(bundleVersion: BundleVersion, restoreInfo: string): Promise<string> {
    LogUtils.i(TAG, `onRestoreEx ver:${JSON.stringify(bundleVersion)} restoreInfo:${JSON.stringify(restoreInfo)}`);
    await this.onRestore(bundleVersion);
    let resultInfo = await this.makeResultInfo();
    LogUtils.i(TAG, `resultInfo:${resultInfo}`);
    return resultInfo;
  }

  async makeResultInfo(): Promise<string> {
    let errorInfoRecord: Record<string, ESObject> = {
      'type':'ErrorInfo',
      'errorCode': (this.restoreErrorInfo !== '') ? '13500099' : '0',
      'errorInfo': this.restoreErrorInfo
    };
    return `{"resultInfo":[${JSON.stringify(errorInfoRecord)}]}`;
  }
}