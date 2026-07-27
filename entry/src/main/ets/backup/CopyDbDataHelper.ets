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

import LogUtils from '../common/utils/LogUtils';
import { BusinessError } from '@ohos.base';
import fs, { ConflictFiles } from '@ohos.file.fs';

const TAG = 'CopyDbDataHelper';

class CopyDbDataHelper {
  private getSrcDirListFile(srcDir: string): string[] {
    let listFile: string[] = [];
    try {
      const isSrcDirExists = fs.accessSync(srcDir);
      if (!isSrcDirExists) {
        return listFile;
      }
      listFile = fs.listFileSync(srcDir);
      return listFile;
    } catch (error) {
      LogUtils.i(TAG, `getSrcDirListFile catch error:${error?.code}`);
    }
    return listFile;
  }

  public copyDbListFile(sourcePath: string, applicationContextPath: string): boolean {
    let targetPath = applicationContextPath + '/rdb';
    try {
      return this.copyFiles(sourcePath, targetPath);
    } catch (error) {
      LogUtils.i(TAG, `copyDbListFile error: ${JSON.stringify(error)}`);
    }
    return false;
  }

  private copyFiles(sourcePath: string, targetPath: string): boolean {
    const isSourcePathExists = fs.accessSync(sourcePath);
    if (!isSourcePathExists) {
      LogUtils.e(TAG, 'rdb file path is not exists');
      return false;
    }
    LogUtils.i(TAG, 'accessSync rdb file path success')

    const isTargetPathExists = fs.accessSync(targetPath);
    if (!isTargetPathExists) {
      try {
        fs.mkdirSync(targetPath);
      } catch (error) {
        LogUtils.i(TAG, `targetPath: ${error.code}`);
      }
    }
    LogUtils.i(TAG, 'accessSync targetPath success');

    let listFileName = this.getSrcDirListFile(sourcePath);
    if (listFileName === undefined || listFileName === null || listFileName.length === 0) {
      LogUtils.i(TAG, 'copyFiles sourcePath is not file');
      return false;
    }
    listFileName.forEach((value: string) => {
      let srcPath = `${sourcePath}/${value}`;
      let destPath = `${targetPath}/${value}`;
      if (fs.statSync(srcPath).isFile()) {
        fs.copyFileSync(srcPath, destPath);
      } else {
        fs.copyDir(srcPath, targetPath, (err: BusinessError<ConflictFiles[]> | undefined) => {
          LogUtils.i(TAG, 'copy directory : ' + JSON.stringify(err));
        });
      }
    });
    LogUtils.i(TAG, 'copyDbFile success');
    return true;
  }

  public copyFile(sourcePath: string, targetPath: string, type: string): boolean {
    try {
      return this.copyFiles(sourcePath, targetPath);
    } catch (error) {
      LogUtils.i(TAG, `copy${type} error: ${JSON.stringify(error)}`);
    }
    return false;
  }
}

export let copyDbDataHelper: CopyDbDataHelper = new CopyDbDataHelper();