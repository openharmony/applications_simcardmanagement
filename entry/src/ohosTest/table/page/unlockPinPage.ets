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
import { DeviceUtils } from '../../../utils/DeviceUtils';
import { DIVIDER_STROKE_WIDTH_1, PIN_MAX_LENGTH, PIN_MIN_LENGTH } from '../../utils/constant';
import { getPluralStringValueSync } from '../../utils/Utils';

export class UnLockPinDialogInfo {
  public isConfirmBtnEnabled: boolean = false;
  public remain: number = 3;
  public onTextChanged: (text: string) => void = (text) => {
  };
  public onCancelClick: () => void = () => {
  };
  public onConfirmClick: () => void = () => {
  };
}


@Builder
export function UnlockPinDialog(info: UnLockPinDialogInfo) {
  Column() {
    Column() {
      TextInput({ placeholder: $r('app.string.unlock_pin_dialog_input_hint', PIN_MIN_LENGTH, PIN_MAX_LENGTH) })
        .width('100%')
        .height($r('app.float.value_48'))
        .type(InputType.NUMBER_PASSWORD)
        .defaultFocus(true)
        .showPasswordIcon(false)
        .maxLength(PIN_MAX_LENGTH)
        .placeholderFont({ size: $r('sys.float.Body_L'), family: 'HarmonyHeiTi' })
        .fontWeight(FontWeight.Regular)
        .fontColor($r('sys.color.font_primary'))
        .fontSize($r('sys.float.Body_L'))
        .backgroundColor($r('app.color.color_00000000_transparent'))
        .caretColor($r('sys.color.font_emphasize'))
        .borderRadius($r('sys.float.corner_radius_level10'))
        .defaultFocus(true)
        .direction(DeviceUtils.isRtl() ? Direction.Rtl : Direction.Ltr)
        .padding({
          left: $r('sys.float.padding_level4'),
          right: $r('sys.float.padding_level4'),
          top: $r('app.float.value_8'),
          bottom: $r('app.float.value_8')
        })
        .onChange((value) => {
          info.onTextChanged(value);
        })

      Divider()
        .vertical(false)
        .height($r('app.float.wh_value_1'))
        .strokeWidth(DIVIDER_STROKE_WIDTH_1)
        .color($r('sys.color.icon_primary'))
        .opacity($r('sys.float.alpha_secondary'))
        .padding({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })
    }
    .width('100%')
    .padding({
      top: $r('sys.float.padding_level2'),
      bottom: $r('sys.float.padding_level2')
    })


    Column() {
      Text(getPluralStringValueSync($r('app.plural.unlock_pin_dialog_hint'), info.remain))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.Body_S'))
        .fontColor($r('sys.color.font_secondary'))
        .lineHeight($r('app.float.value_16'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
    .padding({
      top: $r('sys.float.padding_level4'),
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4')
    })

    Row() {
      Button($r('app.string.cancel'))
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .height($r('app.float.wh_value_40'))
        .layoutWeight(1)
        .fontColor($r('sys.color.font_emphasize'))
        .onClick(() => {
          info.onCancelClick();
        })

      Divider()
        .vertical(true)
        .height($r('app.float.wh_value_24'))
        .margin({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })

      Button($r('app.string.confirm'))
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .height($r('app.float.wh_value_40'))
        .layoutWeight(1)
        .enabled(info.isConfirmBtnEnabled)
        .fontColor($r('sys.color.font_emphasize'))
        .opacity(info.isConfirmBtnEnabled ? $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))
        .onClick(() => {
          info.onConfirmClick();
        })
    }
    .padding({ top: $r('sys.float.padding_level4'), bottom: $r('sys.float.padding_level8') })
    .justifyContent(FlexAlign.Center)
  }
}