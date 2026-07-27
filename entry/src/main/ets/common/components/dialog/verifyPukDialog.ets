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
import { DEFAULT_PUK_REMAIN, DIVIDER_STROKE_WIDTH_1, PUK_MAX_LENGTH } from '../../utils/constant';
import { FontScaleState } from '../../utils/fontScaleState';
import { getPluralStringValueSync } from '../../utils/Utils';

export class VerifyPukInfo {
  public puk: string = '';
  public remainTimes = DEFAULT_PUK_REMAIN;
  public isConfirmEnabled: boolean = false;
  public fontSizeScale: number = 0;
  public onTextChanged: (value: string) => void = (value: string) => {
  };
  public onCancelClick: () => void = () => {
  };
  public onConfirmClick: () => void = () => {
  };
}

@Builder
export function VerifyPukDialogContent(info: VerifyPukInfo) {
  Column() {
    Column() {
      TextInput({ placeholder: $r('app.string.puk_code') })
        .width('100%')
        .constraintSize({ minHeight: $r('app.float.value_48') })
        .type(InputType.NUMBER_PASSWORD)
        .defaultFocus(true)
        .showPasswordIcon(false)
        .maxLength(PUK_MAX_LENGTH)
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
        })
        .margin({
          top: $r('app.float.value_4'),
          bottom: $r('app.float.value_4'),
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
      Text($r('app.string.prompt_when_entering_PUK'))
        .maxFontScale(2)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.Body_S'))
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
        .lineHeight(FontScaleState.isStandardGeer(info.fontSizeScale) ? $r('app.float.value_16') : 0)

      Text(getPluralStringValueSync($r('app.plural.warn_on_wrong_puk'), info.remainTimes))
        .fontFamily('HarmonyHeiTi')
        .maxFontScale(2)
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.Body_S'))
        .fontColor($r('sys.color.warning'))
        .margin({ top: $r('sys.float.padding_level4') })
        .lineHeight(FontScaleState.isStandardGeer(info.fontSizeScale) ? $r('app.float.value_16') : 0)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
    .padding({
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4')
    })

    Row() {
      Button($r('app.string.cancel'))
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .constraintSize({ minHeight: $r('app.float.wh_value_40') })
        .layoutWeight(FontScaleState.isStandardGeer(info.fontSizeScale) ? 1 : 0)
        .fontSize(FontScaleState.isSmallerFourGeer(info.fontSizeScale) ? $r('sys.float.Body_L') :
      $r('app.float.font_32'))
        .fontColor($r('sys.color.font_emphasize'))
        .onClick(() => {
          info.onCancelClick();
        })

      Divider()
        .borderColor($r('sys.color.comp_divider'))
        .vertical(true)
        .height($r('app.float.wh_value_24'))
        .margin({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })

      Button($r('app.string.confirm'))
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .constraintSize({ minHeight: $r('app.float.wh_value_40') })
        .layoutWeight(FontScaleState.isStandardGeer(info.fontSizeScale) ? 1 : 0)
        .enabled(info.isConfirmEnabled)
        .fontSize(FontScaleState.isSmallerFourGeer(info.fontSizeScale) ? $r('sys.float.Body_L') :
        $r('app.float.font_32'))
        .fontColor($r('sys.color.font_emphasize'))
        .opacity(info.isConfirmEnabled ? $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))
        .onClick(() => {
          info.onConfirmClick();
        })
    }
    .padding({ top: $r('sys.float.padding_level4'), bottom: $r('sys.float.padding_level8') })
    .justifyContent(FlexAlign.Center)
  }
}