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
import { BusinessError } from '@kit.BasicServicesKit';
import { workScheduler } from '@kit.BackgroundTasksKit';
import SimServiceProxy from '../model/simServiceProxy';
import { LockType, MAX_SIM_COUNT } from '../common/utils/constant';
import { getPrimarySlotId } from '../model/radioServiceProxy';
import pinModel from '../model/pinModel';
import { VerifyDialogType } from '../common/components/dialog/verifyPinDialog';
import { DynamicLoader } from './DynamicLoader';

class ReportOperate {
  public static ENABLE_SIM = 1;
  public static DISABLE_SIM = 2;
  public static CANCEL = 0;
  public static CONFIRM = 1;
  public static SET_DEFAULT_DIALING_CARD_CANCEL = 3;
  public static PASSWORD_TOO_SIMPLE_CONTINUE_USE = 0;
  public static PASSWORD_TOO_SIMPLE_RESET = 1;
  public static STATUS_OFF = 0;
  public static STATUS_ON = 1;
}

const TAG = 'ReportUtil';
const DOMAIN = 'SIM_UE';
const packageName = 'com.ohos.simcardmanagement';
const REPEAT_CYCLE_TIME = 1000 * 60 * 60 * 24 * 7; // 1 week

interface GeneratedObjectLiteralInterface_1 {
  domain: string;
  name: string;
  eventType: number;
  params: Record<string, string | number | boolean | undefined> | undefined;
}

export class ReportUtil {
  private static sReportUtil: ReportUtil;
  private versionName: string = '1.0.0.0';

  public static getInstance(): ReportUtil {
    if (!ReportUtil.sReportUtil) {
      ReportUtil.sReportUtil = new ReportUtil();
    }
    return ReportUtil.sReportUtil;
  }

  private constructor() {
  }

  domain(): string {
    return DOMAIN;
  }

  private async write(eventName: string, customizedParams?: Record<string, string | number | boolean | undefined>) {
    let hiSysEvent = await DynamicLoader.getInstance().loadHiSysEvent();
    // 默认值 hiSysEvent.default.EventType.BEHAVIOR为 4
    let type: number = 4;
    switch (eventName) {
      case 'INSERT_CARD_STATUS':
      case 'ENABLE_CARD_STATUS':
      case 'DEFAULT_MOBILE_DATA_STATUS':
      case 'DEFAULT_DAILING_CARD_STATUS':
      case 'ENABLE_DISABLE_PROTECT_STATUS':
      case 'REMEMBER_PIN_STATUS':
        type = hiSysEvent.default.EventType.STATISTIC;
        break;
      default:
        type = hiSysEvent.default.EventType.BEHAVIOR;
        break;
    }
    let eventInfo: GeneratedObjectLiteralInterface_1 = {
      domain: DOMAIN,
      name: eventName,
      eventType: type,
      params: customizedParams
    };
    hiSysEvent.default.write(eventInfo).then(() => {
      LogUtils.i(TAG, `hiSys write eventName:${eventInfo.name}, params:${JSON.stringify(eventInfo.params)}, success`);
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `hiSys write error code: ${err.code}, error msg: ${err.message}`);
    });
  }

  private report(eventName: string, customizedParams?: Record<string, string | number | boolean | undefined>) {
    try {
      if (customizedParams === null || customizedParams === undefined) {
        let params: Record<string, string | number | boolean | undefined> = {
          'PNAMEID': packageName,
          'PVERSIONID': this.versionName,
        };
        customizedParams = params;
      }
      this.write(eventName, customizedParams);
    } catch (err) {
      LogUtils.e(TAG, `report error code: ${(err as BusinessError).code}, error msg: ${(err as BusinessError).message}`);
    }
  }

  /**
   * 将槽位ID转换为报告ID
   *
   * @param {number} slotId - 槽位ID
   * @return {number} 返回报告ID
   */
  private slotId2Report(slotId: number): number {
    return slotId + 1;
  }

  public reportEnableCard(slotId: number, isActivated: boolean) {
    let operate: number = isActivated ? ReportOperate.ENABLE_SIM : ReportOperate.DISABLE_SIM;
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': this.slotId2Report(slotId),
      'OPERATE': operate,
    };
    this.report('ENABLE_CARD', params);
  }

  public reportCardInfoEditClick(slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': this.slotId2Report(slotId),
    };
    this.report('EDIT_CARD_NAME_CLICK', params);
  }

  public reportCardInfoEditSelected(slotId: number, isConfirmed: boolean) {
    let operate: number = isConfirmed ? ReportOperate.CONFIRM : ReportOperate.CANCEL;
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': this.slotId2Report(slotId),
      'OPERATE': operate,
    };
    this.report('EDIT_CARD_NAME_CHOISE', params);
  }

  public reportChangeDefaultMobileData(slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': this.slotId2Report(slotId),
    };
    this.report('DEFAULT_MOBILE_DATA', params);
  }

  public reportDefaultDialingCardClicked() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
    };
    this.report('DEFAULT_DIALING_CARD_CLICK', params);
  }

  public reportDefaultDialingCardSetting(slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'RESULT': this.slotId2Report(slotId),
    };
    this.report('DEFAULT_DIALING_CARD_SETTING', params);
  }

  public reportSetDefaultDialingCardCanceled() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'RESULT': ReportOperate.SET_DEFAULT_DIALING_CARD_CANCEL,
    };
    this.report('DEFAULT_DIALING_CARD_SETTING', params);
  }

  public reportCardProtectionClick() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
    };
    this.report('PROTECT_CLICK', params);
  }

  public reportCardProtectionTabSwitch(slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': this.slotId2Report(slotId),
    };
    this.report('CARD_SWITCH_TAB_CLICK', params);
  }

  public reportCardProtectionEnable(slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': this.slotId2Report(slotId),
    };
    this.report('PROTECT_ENABLE', params);
  }

  private reportCardProtectionEnableChoice(slotId: number, isConfirmed: boolean) {
    const operate: number = isConfirmed ? ReportOperate.CONFIRM : ReportOperate.CANCEL;
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': this.slotId2Report(slotId),
      'RESULT': operate,
    };
    this.report('PROTECT_ENABLE_CHOISE', params);
  }

  public reportCardProtectionDisable(slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': this.slotId2Report(slotId),
    };
    this.report('PROTECT_DISABLE', params);
  }

  private reportCardProtectionDisableChoice(slotId: number, isConfirmed: boolean) {
    const operate: number = isConfirmed ? ReportOperate.CONFIRM : ReportOperate.CANCEL;
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': this.slotId2Report(slotId),
      'OPERATE': operate,
    };
    this.report('PROTECT_DISABLE_CHOISE', params);
  }

  public reportCardProtectionChoice(slotId: number, isConfirmed: boolean, verifyPinType: number) {
    switch (verifyPinType) {
      case VerifyDialogType.OPEN_PIN:
        this.reportCardProtectionEnableChoice(slotId, isConfirmed);
        break;
      case VerifyDialogType.CLOSE_PIN:
        this.reportCardProtectionDisableChoice(slotId, isConfirmed);
        break;
      case VerifyDialogType.CHANGE_PIN:
        this.reportModifyPinCurrentPin(slotId, isConfirmed);
        break;
      case VerifyDialogType.RESET_INPUT_NEW_PIN:
        this.reportModifyPinNewPin(slotId, isConfirmed);
        break;
      case VerifyDialogType.RESET_INPUT_NEW_PIN_AGAIN:
        this.reportModifyPinNewPinAgain(slotId, isConfirmed);
        break;
    }
  }

  public reportCardProtectionForgotPin(slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': this.slotId2Report(slotId),
    };
    this.report('PROTECT_DISABLE_FOGOT_PIN', params);
  }

  public reportCardProtectionAboutPin() {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
    };
    this.report('PROTECT_ENABLE_ABOUT_PIN', params);
  }

  public reportModifyPinClick(slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': this.slotId2Report(slotId),
    };
    this.report('MODIFY_PIN_CLICK', params);
  }

  public reportSecurityHintChoice(slotId: number, isContinueUsed: boolean) {
    const operate =
      isContinueUsed ? ReportOperate.PASSWORD_TOO_SIMPLE_CONTINUE_USE : ReportOperate.PASSWORD_TOO_SIMPLE_RESET;
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': this.slotId2Report(slotId),
      'OPERATE': operate,
    };
    this.report('SECURITY_HINT_CONTINUE_USE_RESET', params);
  }

  private reportModifyPinCurrentPin(slotId: number, isConfirmed: boolean) {
    const operate = isConfirmed ? ReportOperate.CONFIRM : ReportOperate.CANCEL;
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': this.slotId2Report(slotId),
      'OPERATE': operate,
    };
    this.report('MODIFY_PIN_CURRENT_CHOISE', params);
  }

  private reportModifyPinNewPin(slotId: number, isConfirmed: boolean) {
    const operate = isConfirmed ? ReportOperate.CONFIRM : ReportOperate.CANCEL;
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': this.slotId2Report(slotId),
      'OPERATE': operate,
    };
    this.report('MODIFY_PIN_NEW_CHOISE', params);
  }

  private reportModifyPinNewPinAgain(slotId: number, isConfirmed: boolean) {
    const operate = isConfirmed ? ReportOperate.CONFIRM : ReportOperate.CANCEL;
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': this.slotId2Report(slotId),
      'OPERATE': operate,
    };
    this.report('MODIFY_PIN_NEW_AGAIN_CHOISE', params);
  }

  public reportInputPinErrorThreeTimes(slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'SLOTID': this.slotId2Report(slotId),
    };
    this.report('PIN_INPUT_ERROR_LOCKING', params);
  }

  public startStatisticReport() {
    const workInfo: workScheduler.WorkInfo = {
      workId: 1,
      bundleName: packageName,
      abilityName: 'ReporterWorkSchedulerAbility',
      isRepeat: true,
      isPersisted: true,
      repeatCycleTime: REPEAT_CYCLE_TIME
    }
    try {
      workScheduler.startWork(workInfo);
    } catch (err) {
      LogUtils.e(TAG, `startStatisticReport failed, code is ${err.code}, message is ${err.message}`);
    }
  }

  public reportStatistics() {
    this.reportSimActiveStatus();
    this.reportDefaultMobileDataStatus();
    this.reportDefaultDailingDataStatus();
    this.reportSimProtectionStatus();
  }

  private async reportSimActiveStatus() {
    try {
      let activeCount: number = 0;
      let isActivated: boolean = false;
      for (let slotId = 0; slotId < MAX_SIM_COUNT; slotId++) {
        isActivated = SimServiceProxy.isSimActivatedSync(slotId);
        if (isActivated) {
          activeCount++;
        }
      }
      let params: Record<string, string | number | boolean | undefined> = {
        'PNAMEID': packageName,
        'PVERSIONID': this.versionName,
        'CARDCOUNT': activeCount,
      };
      this.report('ENABLE_CARD_STATUS', params);
    } catch (error) {
      LogUtils.e(TAG, `getSimaActiveState err = ${JSON.stringify(error)}`);
    }
  }

  private async reportDefaultMobileDataStatus() {
    try {
      let defaultMobileSlot = await getPrimarySlotId();
      let params: Record<string, string | number | boolean | undefined> = {
        'PNAMEID': packageName,
        'PVERSIONID': this.versionName,
        'SLOTID': this.slotId2Report(defaultMobileSlot),
      };
      this.report('DEFAULT_MOBILE_DATA_STATUS', params);
    } catch (err) {
      LogUtils.e(TAG, `reportDefaultMobileDataStatus err = ${JSON.stringify(err)}`);
    }
  }

  private async reportDefaultDailingDataStatus() {
    try {
      let slotId = await SimServiceProxy.getDefaultVoiceSlotId();
      let params: Record<string, string | number | boolean | undefined> = {
        'PNAMEID': packageName,
        'PVERSIONID': this.versionName,
        'STATUS': this.slotId2Report(slotId),
      };
      this.report('DEFAULT_DAILING_CARD_STATUS', params);
    } catch (err) {
      LogUtils.e(TAG, `reportDefaultDailingDataStatus err = ${JSON.stringify(err)}`);
    }
  }

  private async reportSimProtectionStatus() {
    try {
      let status: number = ReportOperate.STATUS_OFF;
      for (let slotId = 0; slotId < MAX_SIM_COUNT; slotId++) {
        let isHasSim = await SimServiceProxy.hasSimCard(slotId);
        if (!isHasSim) {
          continue;
        }
        let lockType: LockType = await pinModel.getSimLockType(slotId);
        if (lockType === LockType.PIN_LOCK || lockType === LockType.PUK_LOCK) {
          status = ReportOperate.STATUS_ON;
        }
        let params: Record<string, string | number | boolean | undefined> = {
          'PNAMEID': packageName,
          'PVERSIONID': this.versionName,
          'SLOTID': this.slotId2Report(slotId),
          'STATUS': status,
        };
        this.report('ENABLE_DISABLE_PROTECT_STATUS', params);
      }
    } catch (error) {
      LogUtils.e(TAG, `getSimCardPortectionStatus err = ${JSON.stringify(error)}`);
    }
  }
}