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
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import DataShareResultSet from '@ohos.data.DataShareResultSet';
import LogUtils from '../common/utils/LogUtils';
import relationalStore from '@ohos.data.relationalStore';

const TAG = 'DatabaseHelper';
const SIMDB_URI = 'datashare:///com.ohos.simability/sim/sim_info';
const SETTINGS_DATA_SYSTEM_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/USER_SETTINGSDATA_100?Proxy=true';
const ICCID = 'icc_id';
const SLOTID = 'slot_index';
const ID = '_id';
const SUBSTATE = 'sub_state';
const KEYWORD = 'KEYWORD';
const VALUE = 'VALUE';

async function initSimDBDataShare(context: common.Context): Promise<dataShare.DataShareHelper | undefined> {
  LogUtils.i(TAG, 'initSimDBDataShare start.');
  let dataShareHelper: dataShare.DataShareHelper | undefined = undefined;
  try {
    dataShareHelper = await dataShare.createDataShareHelper(context, SIMDB_URI);
  } catch (err) {
    LogUtils.e(TAG, 'initSimDBDataShare fail.');
  }
  return dataShareHelper;
}

async function initTelephonyRDB(context: common.Context): Promise<relationalStore.RdbStore | undefined> {
  LogUtils.i(TAG, 'initTelephonyRDB start.');
  let rdbStore: relationalStore.RdbStore | undefined = undefined;
  const STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'telephony.db',
    securityLevel: relationalStore.SecurityLevel.S1
  };
  try {
    rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
  } catch (err) {
    LogUtils.e(TAG, 'initTelephonyRDB fail.');
  }
  return rdbStore;
}

async function initSystemDataShare(context: common.Context): Promise<dataShare.DataShareHelper | undefined> {
  LogUtils.i(TAG, 'initSystemDataShare start.');
  let dataShareHelper: dataShare.DataShareHelper | undefined = undefined;
  try {
    dataShareHelper = await dataShare.createDataShareHelper(context, SETTINGS_DATA_SYSTEM_URI);
  } catch (err) {
    LogUtils.e(TAG, 'initSystemDataShare fail.');
  }
  return dataShareHelper;
}

export async function querySlotIdByIccId(context: common.Context, iccId: string): Promise<number> {
  try {
    let dataShareHelper = await initSimDBDataShare(context);
    let columns = ['*'];
    let da = new dataSharePredicates.DataSharePredicates();
    da.equalTo(ICCID, iccId);
    if (dataShareHelper != undefined) {
      let resultSet: DataShareResultSet = await dataShareHelper.query(SIMDB_URI, da, columns);
      if (resultSet && resultSet.goToFirstRow()) {
        let getLong = resultSet.getLong(resultSet.getColumnIndex(SLOTID));
        resultSet.close();
        return getLong;
      }
      LogUtils.i(TAG, 'resultSet is null.')
    }
  } catch (err) {
    LogUtils.e(TAG, `querySlotIdByIccId err:${JSON.stringify(err)}`);
  }
  return -1;
}

export async function queryIccIdById(context: common.Context, id: number): Promise<string> {
  try {
    let rdbStore = await initTelephonyRDB(context);
    let predicates = new relationalStore.RdbPredicates('siminfo');
    predicates.equalTo(ID, id);
    if (rdbStore != undefined) {
      let resultSet = await rdbStore.query(predicates);
      if (resultSet && resultSet.goToFirstRow()) {
        let getString = resultSet.getString(resultSet.getColumnIndex(ICCID));
        resultSet.close();
        return getString;
      }
      LogUtils.i(TAG, 'resultSet is null.');
    }
  } catch (err) {
    LogUtils.e(TAG, `queryIccIdById err:${JSON.stringify(err)}`);
  }
  return '';
}

export async function queryIccIdFromSimDB(context: common.Context): Promise<string[]> {
  let dataShareHelper = await initSimDBDataShare(context);
  let columns = ['*'];
  let da = new dataSharePredicates.DataSharePredicates();
  da.in(SLOTID, [0, 1]);
  let iccId: string[] = [];
  let index = 0;
  if (dataShareHelper != undefined) {
    let resultSet: DataShareResultSet = await dataShareHelper.query(SIMDB_URI, da, columns);
    LogUtils.i(TAG, `columnCount:${resultSet.columnCount}`);
    if (resultSet && resultSet.goToFirstRow()) {
      let getString = resultSet.getString(resultSet.getColumnIndex(ICCID));
      iccId[index++] = getString;
      if (resultSet.goToNextRow()) {
        let getString = resultSet.getString(resultSet.getColumnIndex(ICCID));
        iccId[index] = getString;
      }
      resultSet.close();
      return iccId;
    }
    LogUtils.i(TAG, 'resultSet is null.');
  }
  return iccId;
}

export async function querySubStateByIccId(context: common.Context, iccId: string): Promise<number> {
  try {
    let rdbStore = await initTelephonyRDB(context);
    let predicates = new relationalStore.RdbPredicates('siminfo');
    predicates.equalTo(ICCID, iccId);
    if (rdbStore != undefined) {
      let resultSet = await rdbStore.query(predicates);
      if (resultSet && resultSet.goToFirstRow()) {
        let getLong = resultSet.getLong(resultSet.getColumnIndex(SUBSTATE));
        LogUtils.i(TAG, 'subState: ' + getLong);
        resultSet.close();
        return getLong;
      }
      LogUtils.i(TAG, 'resultSet is null.');
    }
  } catch (err) {
    LogUtils.e(TAG, `querySubStateByIccId err:${JSON.stringify(err)}`);
  }
  return 1;
}

export async function querySlotIdFromSystem(context: common.Context): Promise<string> {
  try {
    let dataShareHelper = await initSystemDataShare(context);
    let columns = ['*'];
    let da = new dataSharePredicates.DataSharePredicates();
    da.equalTo(KEYWORD, 'switch_dual_card_slots');
    if (dataShareHelper != undefined) {
      let resultSet: DataShareResultSet = await dataShareHelper.query(SETTINGS_DATA_SYSTEM_URI, da, columns);
      if (resultSet && resultSet.goToFirstRow()) {
        let getString = resultSet.getString(resultSet.getColumnIndex(VALUE));
        LogUtils.i(TAG, 'Value: ' + getString);
        resultSet.close();
        return getString;
      }
      LogUtils.i(TAG, 'resultSet is null.')
    }
  } catch (err) {
    LogUtils.e(TAG, `querySlotIdFromSystem err:${JSON.stringify(err)}`);
  }
  return '';
}
