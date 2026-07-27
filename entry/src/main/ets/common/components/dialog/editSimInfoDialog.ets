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
import LogUtils from '../../utils/LogUtils';
import { PHONE_NUMBER_REGULAR } from '../../../common/utils/constant';
import SimServiceProxy from '../../../model/simServiceProxy';
import { isEmpty } from '../../utils/Utils';
import { LengthMetrics } from '@kit.ArkUI';
import { DeviceUtils } from '../../../utils/DeviceUtils';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'editSimInfoDialog';
const DIVIDER_STROKE_WIDTH_1 = 1;
const DIVIDER_STROKE_WIDTH_0_5 = 0.5;
const SET_SIM_INFO_RETRY_DELAY_MS = 500;
const SET_SIM_INFO_MAX_RETRY_COUNT = 2;

@Observed
export class EditSimInfo {
  public slotId: number = 0;
  public oldName: string = '';
  public newName: string = '';
  public oldNumber: string = '';
  public newNumber: string = '';
  public focusedIndex: number = 0;
  public onFocusChanged: (index: number, isFocused: boolean) => void = (index: number, isFocused: boolean) => {
  };
  public onNameChanged: (name: string) => void = (name: string) => {
  };
  public onNumberChanged: (phoneNumber: string) => void = (phoneNumber: string) => {
  };
  public setSimInfo? = (slotId: number, name: string, phoneNumber: string) => {
    this.slotId = slotId;
    this.oldName = isEmpty(name) ? '' : name;
    this.newName = this.oldName;
    this.oldNumber = isEmpty(phoneNumber) ? '' : phoneNumber;
    this.newNumber = this.oldNumber;
  };
}

/**
 * Content area of the Dialog for editing card information.
 *
 * @param editSimInfo Information required in the Dialog for editing card information
 */
@Builder
export function EditSimInfoContent(editSimInfo: EditSimInfo) {
  Column() {
    TextInput({ text: editSimInfo.newName, placeholder: $r('app.string.sim_card_name') })
      .maxLength(36)
      .constraintSize({ minHeight: $r('app.float.value_48') })
      .placeholderFont({ size: $r('sys.float.Body_L'), family: 'HarmonyHeiTi' })
      .fontWeight(FontWeight.Regular)
      .fontColor($r('sys.color.font_primary'))
      .fontSize($r('sys.float.Body_L'))
      .backgroundColor($r('app.color.color_00000000_transparent'))
      .caretColor($r('sys.color.font_emphasize'))
      .borderRadius($r('sys.float.corner_radius_level10'))
      .defaultFocus(true)
      .direction(Direction.Ltr)
      .textAlign(DeviceUtils.isRtl() ? TextAlign.End : TextAlign.Start)
      .padding({
        end: LengthMetrics.resource($r('app.float.value_16')),
        start: LengthMetrics.resource($r('app.float.value_0'))
      })
      .margin({
        top: $r('app.float.value_4'),
        bottom: $r('app.float.value_4'),
      })
      .onChange((value: string) => {
        editSimInfo.onNameChanged(value);
      })
      .onBlur(() => {
        editSimInfo.onFocusChanged(1, false);
      })
      .onFocus(() => {
        editSimInfo.onFocusChanged(1, true);
      })

    Divider()
      .vertical(false)
      .height($r('app.float.wh_value_1'))
      .strokeWidth(editSimInfo.focusedIndex === 1 ? DIVIDER_STROKE_WIDTH_1 : DIVIDER_STROKE_WIDTH_0_5)
      .color(editSimInfo.focusedIndex === 1 ? $r('sys.color.icon_primary') : $r('sys.color.comp_divider'))
      .opacity(editSimInfo.focusedIndex === 1 ? $r('sys.float.alpha_secondary') : $r('app.float.opacity_1'))

    TextInput({ text: editSimInfo.newNumber, placeholder: $r('app.string.sim_phone_number') })
      .maxLength(SimServiceProxy.isChinaTelecomSim(editSimInfo.slotId) ? 15 : 20)
      .constraintSize({ minHeight: $r('app.float.value_48') })
      .placeholderFont({ size: $r('sys.float.Body_L'), family: 'HarmonyHeiTi' })
      .fontWeight(FontWeight.Regular)
      .fontColor($r('sys.color.font_primary'))
      .fontSize($r('sys.float.Body_L'))
      .backgroundColor($r('app.color.color_00000000_transparent'))
      .caretColor($r('sys.color.font_emphasize'))
      .borderRadius($r('sys.float.corner_radius_level10'))
      .type(InputType.PhoneNumber)
      .direction(Direction.Ltr)
      .textAlign(DeviceUtils.isRtl() ? TextAlign.End : TextAlign.Start)
      .padding({
        end: LengthMetrics.resource($r('app.float.value_16')),
        start: LengthMetrics.resource($r('app.float.value_0'))
      })
      .margin({
        top: $r('app.float.value_4'),
        bottom: $r('app.float.value_4'),
      })
      .inputFilter(PHONE_NUMBER_REGULAR, (e) => {
        LogUtils.e(TAG, 'error input');
      })
      .onChange((value: string) => {
        editSimInfo.onNumberChanged(value);
      })
      .onBlur(() => {
        editSimInfo.onFocusChanged(2, false);
      })
      .onFocus(() => {
        editSimInfo.onFocusChanged(2, true);
      })
    Divider()
      .vertical(false)
      .height($r('app.float.wh_value_1'))
      .strokeWidth(editSimInfo.focusedIndex === 2 ? DIVIDER_STROKE_WIDTH_1 : DIVIDER_STROKE_WIDTH_0_5)
      .color(editSimInfo.focusedIndex === 2 ? $r('sys.color.icon_primary') : $r('sys.color.comp_divider'))
      .opacity(editSimInfo.focusedIndex === 2 ? $r('sys.float.alpha_secondary') : $r('app.float.opacity_1'))
  }
  .alignItems(HorizontalAlign.Start)
}

/**
 * Edit Card Information
 *
 * @param slotId The id of tht SIM slot.
 * @param oldName Old Card Name.
 * @param oldNumber Old phone number.
 * @param onSetShowNameResult Callback of the card name editing result.
 * @param onSetShowNumberResultCallback of the card number editing result.
 */
export function setSimInfo(editInfo: EditSimInfo, onSetShowNameResult: (slotId: number) => void,
                           onSetShowNumberResult: (slotId: number) => void) {
  setShowName(editInfo, onSetShowNameResult);
  setShowNumber(editInfo, onSetShowNumberResult);
}

function setShowName(editInfo: EditSimInfo, onSetShowNameResult: (slotId: number) => void, retryCount: number = 0) {
  if (editInfo.newName === editInfo.oldName) {
    LogUtils.i(TAG, 'setShowName: The new name is the same as the old name.');
    return;
  }
  if (!editInfo.newName) {
    editInfo.newName = '';
  }
  SimServiceProxy.setShowName(editInfo.slotId, editInfo.newName).then(() => {
    onSetShowNameResult(editInfo.slotId);
  }).catch((error: BusinessError) => {
    if (retryCount < SET_SIM_INFO_MAX_RETRY_COUNT) {
      setTimeout(() => {
        setShowName(editInfo, onSetShowNameResult, retryCount + 1);
      }, SET_SIM_INFO_RETRY_DELAY_MS);
      return;
    }
    LogUtils.e(TAG, 'setShowName failed, slotId=' + editInfo.slotId + ',error:' + JSON.stringify(error));
  })
}

function setShowNumber(editInfo: EditSimInfo, onSetShowNumberResult: (slotId: number) => void, retryCount: number = 0) {
  if (editInfo.newNumber === editInfo.oldNumber) {
    LogUtils.i(TAG, 'setShowNumber: The new number is the same as the old number.');
    return;
  }
  if (!editInfo.newNumber) {
    editInfo.newNumber = '';
  }
  SimServiceProxy.setShowNumber(editInfo.slotId, editInfo.newNumber).then(() => {
    onSetShowNumberResult(editInfo.slotId);
  }).catch((error: BusinessError) => {
    if (retryCount < SET_SIM_INFO_MAX_RETRY_COUNT) {
      setTimeout(() => {
        setShowNumber(editInfo, onSetShowNumberResult, retryCount + 1);
      }, SET_SIM_INFO_RETRY_DELAY_MS);
      return;
    }
    LogUtils.e(TAG, 'setShowNumber failed, slotId=' + editInfo.slotId + ',error:' + JSON.stringify(error));
  })
}