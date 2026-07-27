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

import common from '@ohos.app.ability.common';
import LogUtils from '../common/utils/LogUtils';
import fs from '@ohos.file.fs';
import {
  querySlotIdByIccId,
  queryIccIdById,
  queryIccIdFromSimDB,
  querySubStateByIccId,
  querySlotIdFromSystem
} from '../database/DatabaseHelper';
import { sim } from '../model/api';
import { xmlParserUtil } from './XmlParserUtil';
import SimCardModel from '../model/SimCardModel';
import radio from '@ohos.telephony.radio';

const TAG = 'RestoreUtil';
const AND = 'and';
const ROID = 'roid';
const AND_ROID = `${AND}${ROID}`;

export default class RestoreUtil {
  private static instance: RestoreUtil;
  public errorInfo: string = '';

  public static getInstance(): RestoreUtil {
    if (RestoreUtil.instance == null || RestoreUtil.instance == undefined) {
      RestoreUtil.instance = new RestoreUtil();
    }
    return RestoreUtil.instance;
  }

  public addErrorInfo(newErrorInfo: string) {
    this.errorInfo = this.errorInfo + newErrorInfo;
  }

  //Upgrade from dual-framework to single-framework
  public async upgrade(context: common.Context): Promise<void> {
    LogUtils.i(TAG, 'upgrade start.');
    try {
      await this.setDefaultDialNumber(context, context.filesDir);
      await this.setSimName(context, context.preferencesDir);
      await this.setDefaultMobileData(context);
      await this.setDeactivateSim(context);
    } catch (err) {
      LogUtils.e(TAG, `upgrade err:${JSON.stringify(err)}`);
      this.addErrorInfo(`upgrade Error:${err?.message}`);
    }
  }

  public async setDefaultDialNumber(context: common.Context, filesDir: string): Promise<void> {
    LogUtils.i(TAG, 'setDefaultDialNumber start.');
    let file: fs.File | null = null;
    let iccId: string = '';
    try {
      file = fs.openSync(filesDir + '/phone-account-registrar-state.xml', fs.OpenMode.READ_ONLY);
      LogUtils.i(TAG, 'setDefaultDialNumber file opened');
      if (!file) {
        LogUtils.e(TAG, 'File is null');
        return;
      }
      let arrayBuffer = new ArrayBuffer(40960);
      let len: number = fs.readSync(file.fd, arrayBuffer);
      if (len === 0) {
        LogUtils.e(TAG, 'empty buffer');
        return;
      }
      LogUtils.i(TAG, `setDefaultDialNumber file len:${len}`);
      iccId = xmlParserUtil.xmlParserText(arrayBuffer);
      if (iccId === '') {
        LogUtils.i(TAG, 'defaultDialNumber does not set.')
        return;
      }
    } catch (err) {
      LogUtils.e(TAG, 'Failed. Cause: ' + JSON.stringify(err));
    } finally {
      try {
        if (file) {
          LogUtils.i(TAG, 'setDefaultDialNumber close file');
          fs.closeSync(file);
        }
      } catch (err) {
        LogUtils.e(TAG, 'closeSync Failed. Cause: ' + JSON.stringify(err));
      }
    }
    const slotId = await querySlotIdByIccId(context, iccId);
    LogUtils.i(TAG, `setDefaultDialNumber on ${slotId}`);
    if (slotId != -1) {
      try {
        await sim.setDefaultVoiceSlotId(slotId);
      } catch (err) {
        LogUtils.e(TAG, `setDefaultVoiceSlotId error: code: ${err.code}, message: ${err.message} `);
      }
    }
    LogUtils.i(TAG, 'setDefaultDialNumber end.');
  }

  public async setSimName(context: common.Context, prefDir: string): Promise<void> {
    LogUtils.i(TAG, 'setSimName start.');
    let file: fs.File | null = null;
    let simCards: SimCardModel[] = [];
    try {
      file = fs.openSync(prefDir + `/com.${AND_ROID}.phone_preferences.xml`, fs.OpenMode.READ_ONLY);
      LogUtils.i(TAG, 'setSimName file opened');
      if (!file) {
        LogUtils.e(TAG, 'File is null');
        return;
      }
      let arrayBuffer = new ArrayBuffer(40960);
      let len: number = fs.readSync(file.fd, arrayBuffer);
      if (len === 0) {
        LogUtils.e(TAG, 'empty buffer');
        return;
      }
      LogUtils.i(TAG, `setSimName file len:${len}`);
      simCards = xmlParserUtil.xmlParseKeyText(arrayBuffer);
    } catch (err) {
      LogUtils.e(TAG, 'Failed. Cause: ' + JSON.stringify(err));
    } finally {
      try {
        if (file) {
          LogUtils.i(TAG, 'setSimName close file');
          fs.closeSync(file);
        }
      } catch (err) {
        LogUtils.e(TAG, 'closeSync Failed. Cause: ' + JSON.stringify(err));
      }
    }
    LogUtils.i(TAG, `setSimName check simCards len:${simCards.length}`);
    for (let i = 0; i < simCards.length; i++) {
      const element = simCards[i];
      const iccId = await queryIccIdById(context, element.getId());
      element.setIccId(iccId);
      const slotId = await querySlotIdByIccId(context, iccId);
      LogUtils.i(TAG, `setSimName:${slotId}`);
      if (slotId != -1) {
        try {
          await sim.setShowName(slotId, element.getSimName());
        } catch (err) {
          LogUtils.e(TAG, `setShowName error: code: ${err.code}, message: ${err.message} `);
        }
      }
    }
    LogUtils.i(TAG, 'setSimName end.');
  }

  public async setDeactivateSim(context: common.Context): Promise<void> {
    LogUtils.i(TAG, 'setDeactivateSim start.');
    let iccId: string[] = [];
    try {
      iccId = await queryIccIdFromSimDB(context);
    } catch (err) {
      LogUtils.e(TAG, `setDeactivateSim queryIccIdFromSimDB err:${JSON.stringify(err)}`);
    }
    LogUtils.i(TAG, `setDeactivateSim len:${JSON.stringify(iccId.length)}`);
    for (let i = 0; i < iccId.length; i++) {
      const element = iccId[i];
      const subState = await querySubStateByIccId(context, element);
      if (subState !== 0) {
        LogUtils.i(TAG, 'setDeactivateSim already deactivated, no need set again');
        continue;
      }
      const slotId = await querySlotIdByIccId(context, element);
      LogUtils.i(TAG, `setDeactivateSim:${slotId}`);
      if (slotId !== -1) {
        try {
          await sim.deactivateSim(slotId);
        } catch (err) {
          LogUtils.e(TAG, `deactivateSim error: code: ${err.code}, message: ${err.message} `);
        }
      }
    }
    LogUtils.i(TAG, 'setDeactivateSim end.');
  }

  public async setDefaultMobileData(context: common.Context): Promise<void> {
    LogUtils.i(TAG, 'setDefaultMobileData start.');
    let slotId = await querySlotIdFromSystem(context);
    if (slotId === '') {
      LogUtils.i(TAG, 'defaultMobileData does not set.');
      return;
    }
    LogUtils.i(TAG, `defaultMobileData slotId:${slotId}`);
    if (Number(slotId) != -1) {
      try {
        await radio.setPrimarySlotId(Number(slotId));
      } catch (err) {
        LogUtils.e(TAG, `setPrimarySlotId error: code: ${err.code}, message: ${err.message} `);
        return;
      }
      LogUtils.i(TAG, 'setDefaultMobileData success.');
    }
    LogUtils.i(TAG, 'setDefaultMobileData end.');
  }
}
