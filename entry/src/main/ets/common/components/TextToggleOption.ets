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
import { getNumber } from '../utils/Utils';
import { LengthMetrics } from '@kit.ArkUI';
import { FontScaleState } from '../utils/fontScaleState';

const TOGGLE_RIGHT_MARGIN = 0 - getNumber($r('app.float.value_6'));

@Component
export struct TextToggleOption {
  @State optionTitle: string | Resource = '';
  @State optionInfo: string | Resource = '';
  @Link isSwitchEnabled: boolean;
  @Link isSwitchOn: boolean;
  @Link isEnabled: boolean;
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  onChange: (isOn: boolean) => void = (isOn) => {
  };
  onToggleTouchIntercept: (event: TouchEvent) => HitTestMode = (event: TouchEvent) => {
    return HitTestMode.Default;
  };

  @Styles
  normalStyles() {
    .borderRadius($r('sys.float.corner_radius_level10'))
    .backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Styles
  pressedStyles() {
    .borderRadius($r('sys.float.corner_radius_level10'))
    .backgroundColor($r('sys.color.interactive_click'))
  }

  build() {
    Row() {
      Row() {
        Column() {
          Text(this.optionTitle)
            .width('100%')
            .fontSize($r('sys.float.Body_L'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
            .maxLines(FontScaleState.isStandardGeer(this.fontSizeScale) ? 1 : FontScaleState.seniorMaxLines)
            .lineHeight(FontScaleState.isStandardGeer(this.fontSizeScale) ? $r('app.float.wh_value_21') : 0)
            .opacity(this.isEnabled ? $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))

          if (this.optionInfo) {
            Text(this.optionInfo)
              .width('100%')
              .fontWeight(FontWeight.Regular)
              .fontFamily('HarmonyHeiTi')
              .fontSize($r('sys.float.Body_M'))
              .fontColor($r('sys.color.font_secondary'))
              .margin({ top: $r('sys.float.padding_level1') })
              .lineHeight(FontScaleState.isStandardGeer(this.fontSizeScale) ? $r('app.float.value_19') : 0)
              .opacity(this.isEnabled ? $r('app.float.opacity_1') : $r('sys.float.alpha_tertiary'))
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row() {
          if (this.isSwitchEnabled) {
            Toggle({ type: ToggleType.Switch, isOn: this.isSwitchOn })
              .width($r('app.float.value_48'))
              .height($r('app.float.value_48'))
              .margin($r('app.float.value_0'))
              .selectedColor($r('sys.color.icon_emphasize'))
              .switchPointColor($r('sys.color.comp_background_primary_contrary'))
              .enabled(true)
              .padding({
                left: $r('app.float.value_6'),
                right: $r('app.float.value_6'),
                top: $r('app.float.value_14'),
                bottom: $r('app.float.value_14')
              })
              .onChange(this.onChange)
          } else {
            Toggle({ type: ToggleType.Switch, isOn: this.isSwitchOn })
              .width($r('app.float.value_48'))
              .height($r('app.float.value_48'))
              .margin($r('app.float.value_0'))
              .selectedColor($r('sys.color.icon_emphasize'))
              .switchPointColor($r('sys.color.comp_background_primary_contrary'))
              .enabled(false)
              .padding({
                left: $r('app.float.value_6'),
                right: $r('app.float.value_6'),
                top: $r('app.float.value_14'),
                bottom: $r('app.float.value_14')
              })
              .onChange(this.onChange)
          }
        }.margin({
          start: LengthMetrics.resource($r('sys.float.padding_level4')),
          end: LengthMetrics.vp(TOGGLE_RIGHT_MARGIN)
        })
        .onTouchIntercept((event: TouchEvent) => {
          return this.onToggleTouchIntercept(event);
        })
      }
    }
    .width('100%')
    .constraintSize({ minHeight: $r('app.float.value_64') })
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({
      left: $r('sys.float.padding_level6'),
      right: $r('sys.float.padding_level6'),
      top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, $r('sys.float.padding_level4'),
        $r('sys.float.padding_level4')),
      bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, $r('sys.float.padding_level4'),
        $r('sys.float.padding_level4'))
    })
  }
}