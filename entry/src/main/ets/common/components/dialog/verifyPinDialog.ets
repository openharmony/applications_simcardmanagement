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
import { DEFAULT_PIN_REMAIN, DIVIDER_STROKE_WIDTH_1, PIN_MAX_LENGTH, PIN_MIN_LENGTH } from '../../utils/constant';
import { FontScaleState } from '../../utils/fontScaleState';
import { getPluralStringValueSync } from '../../utils/Utils';

export enum VerifyDialogType {
  OPEN_PIN,
  CLOSE_PIN,
  CHANGE_PIN,
  RESET_INPUT_NEW_PIN,
  RESET_INPUT_NEW_PIN_AGAIN,
  UNMATCHED
}

export class VerifyPinInfo {
  public type: VerifyDialogType = VerifyDialogType.OPEN_PIN;
  public inputPlaceHolder: ResourceStr = '';
  public pin: string = '';
  public remainTimes = DEFAULT_PIN_REMAIN;
  public enterPinTips: string[] = ['', '', ''];
  public isConfirmEnabled: boolean = false;
  public fontSizeScale: number = 0;
  public onTextChanged: (value: string) => void = (value) => {
  };
  public onCancelClick: () => void = () => {
  };
  public onConfirmClick: () => void = () => {
  };
  public onAboutPinClick: () => void = () => {
  };
}

function isInputTextPaddingTopAndBottom(type: VerifyDialogType): boolean {
  return type === VerifyDialogType.RESET_INPUT_NEW_PIN || type === VerifyDialogType.RESET_INPUT_NEW_PIN_AGAIN ||
    type === VerifyDialogType.UNMATCHED || type === VerifyDialogType.OPEN_PIN;
}

@Builder
export function VerifyPinDialogContent(info: VerifyPinInfo) {
  Scroll() {
    Column() {
      if (info.type === VerifyDialogType.UNMATCHED) {
        Column() {
          Text($r('app.string.unmatched'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Regular)
            .fontSize($r('sys.float.Subtitle_M'))
            .fontColor($r('sys.color.font_primary'))
            .lineHeight(FontScaleState.isStandardGeer(info.fontSizeScale) ? $r('app.float.wh_value_21') : 0)
            .maxFontScale(2)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
        .padding({
          bottom: $r('sys.float.padding_level2'),
          left: $r('sys.float.padding_level4'),
          right: $r('sys.float.padding_level4')
        })
      }
      Column() {
        TextInput({ placeholder: info.inputPlaceHolder })
          .width('100%')
          .constraintSize({ minHeight: $r('app.float.value_48') })
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
        top: isInputTextPaddingTopAndBottom(info.type) ? $r('sys.float.padding_level2') : $r('app.float.value_0'),
        bottom: isInputTextPaddingTopAndBottom(info.type) ? $r('sys.float.padding_level2') : $r('app.float.value_0')
      })

      Column() {
        if (info.type === VerifyDialogType.RESET_INPUT_NEW_PIN ||
          info.type === VerifyDialogType.RESET_INPUT_NEW_PIN_AGAIN || info.type === VerifyDialogType.UNMATCHED) {
          Text($r('app.string.reset_pin_format_tips', PIN_MIN_LENGTH, PIN_MAX_LENGTH))
            .width('100%')
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Regular)
            .fontSize($r('sys.float.Body_S'))
            .fontColor($r('sys.color.font_secondary'))
            .lineHeight(FontScaleState.isStandardGeer(info.fontSizeScale) ? $r('app.float.value_16') : 0)
            .maxFontScale(2)
        } else if (info.type === VerifyDialogType.OPEN_PIN) {
          Text() {
            Span(info.enterPinTips[0])
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Regular)
              .fontSize($r('sys.float.Body_S'))
              .fontColor($r('sys.color.font_secondary'))
              .lineHeight(FontScaleState.isStandardGeer(info.fontSizeScale) ? $r('app.float.value_16') : 0)
            Span(info.enterPinTips[1])
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Medium)
              .fontSize($r('sys.float.Body_S'))
              .fontColor($r('sys.color.font_emphasize'))
              .lineHeight(FontScaleState.isStandardGeer(info.fontSizeScale) ? $r('app.float.value_16') : 0)
              .onClick(() => {
                info.onAboutPinClick();
              })
            Span(info.enterPinTips[2])
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Regular)
              .fontSize($r('sys.float.Body_S'))
              .fontColor($r('sys.color.font_secondary'))
              .lineHeight(FontScaleState.isStandardGeer(info.fontSizeScale) ? $r('app.float.value_16') : 0)
          }
          .width('100%')
          .lineHeight(FontScaleState.isStandardGeer(info.fontSizeScale) ? $r('app.float.value_16') : 0)
          .maxFontScale(2)

          Text(getPluralStringValueSync($r('app.plural.warn_on_wrong_pin'), info.remainTimes))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Regular)
            .fontSize($r('sys.float.Body_S'))
            .fontColor($r('sys.color.warning'))
            .margin({ top: $r('sys.float.padding_level4') })
            .lineHeight(FontScaleState.isStandardGeer(info.fontSizeScale) ? $r('app.float.value_16') : 0)
            .maxFontScale(2)
        }
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
          .layoutWeight(1)
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
          .layoutWeight(1)
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
  .scrollable(ScrollDirection.Vertical)
  .scrollBar(BarState.Off)
  .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
}