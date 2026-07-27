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
import { getNumber } from '../utils/Utils'
import { LengthMetrics } from '@kit.ArkUI'
import { FontScaleState } from '../utils/fontScaleState'

const LEFT_RIGHT_REALLY_PADDING = getNumber($r('sys.float.padding_level6')) - getNumber($r('app.float.value_4'))

@Extend(Text)
function generaTextStyle(fontSize: Resource, fontWeight: FontWeight, opacity: number | Resource,
  maxLines: number | Resource = 1) {
  .fontSize(fontSize)
  .fontWeight(fontWeight)
  .maxFontSize(maxLines)
  .opacity(opacity)
  .fontFamily('HarmonyHeiTi')
}

@Component
export struct TextArrowOption {
  @State optionTag: string | Resource = ''
  @State optionInfo: string | Resource = ''
  @State optionTagOpacity: number | Resource = 1
  @State optionInfoOpacity: number | Resource = 1
  @State arrowOpacity: number | Resource = 1
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  onClicked: () => void = () => {
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
    if (FontScaleState.isStandardGeer(this.fontSizeScale)) {
      this.noramlLayout();
    } else {
      this.seniorLayout();
    }
  }

  @Builder
  noramlLayout() {
    Row() {
      Row() {
        Text(this.optionTag)
          .generaTextStyle($r('sys.float.Body_L'), FontWeight.Medium, this.optionTagOpacity)
        Row() {
          if (this.optionInfo) {
            Text(this.optionInfo)
              .generaTextStyle($r('sys.float.Body_M'), FontWeight.Regular, this.optionInfoOpacity)
              .fontColor($r('sys.color.font_secondary'))
              .margin({ end: LengthMetrics.resource($r('app.float.value_5')) })
          }
          this.arrowImageBuild();
        }
      }
      .width('100%')
      .constraintSize({ minHeight: $r('app.float.value_48') })
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({
        top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, $r('app.float.wh_value_10')),
        bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, $r('app.float.wh_value_10')),
      })
      .padding({
        left: LEFT_RIGHT_REALLY_PADDING,
        right: LEFT_RIGHT_REALLY_PADDING
      })
      .stateStyles({
        pressed: this.pressedStyles,
        normal: this.normalStyles
      })
      .onClick(() => {
        this.onClicked();
      })
    }
    .width('100%')
    .padding({
      left: $r('app.float.value_4'),
      right: $r('app.float.value_4')
    })
  }

  @Builder
  seniorLayout() {
    Column() {
      if (this.optionInfo) {
        this.seniorOptionTagTextBuild();
        Row() {
          Text(this.optionInfo)
            .fontColor($r('sys.color.font_secondary'))
            .margin({ end: LengthMetrics.resource($r('app.float.value_5')) })
            .constraintSize({
              maxWidth: `calc(100% - ${getNumber($r('app.float.value_5'))}vp - ${getNumber($r('app.float.wh_value_12'))}vp)`
            })
            .generaTextStyle($r('sys.float.Body_M'), FontWeight.Regular, this.optionInfoOpacity,
              FontScaleState.seniorMaxLines)
          this.arrowImageBuild();
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

      } else {
        Row() {
          this.seniorOptionTagTextBuild();
          this.arrowImageBuild();
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
    }
    .margin({
      left: $r('app.float.value_4'),
      right: $r('app.float.value_4')
    })
    .padding({
      top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, $r('app.float.wh_value_10')),
      bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, $r('app.float.wh_value_10')),
      left: LEFT_RIGHT_REALLY_PADDING,
      right: LEFT_RIGHT_REALLY_PADDING
    })
    .alignItems(HorizontalAlign.Start)
    .stateStyles({
      pressed: this.pressedStyles,
      normal: this.normalStyles
    })
    .onClick(() => {
      this.onClicked();
    })
  }

  @Builder
  arrowImageBuild() {
    Image($r('app.media.ic_public_arrow_right'))
      .height($r('app.float.wh_value_24'))
      .width($r('app.float.wh_value_12'))
      .fillColor($r('sys.color.icon_fourth'))
      .opacity(this.arrowOpacity)
      .matchTextDirection(true)
  }

  @Builder
  seniorOptionTagTextBuild() {
    Text(this.optionTag)
      .generaTextStyle($r('sys.float.Body_L'), FontWeight.Medium, this.optionTagOpacity,
        FontScaleState.seniorMaxLines)
      .constraintSize({
        maxWidth: `calc(100% - ${getNumber($r('app.float.value_5'))}vp - ${getNumber($r('app.float.wh_value_12'))}vp)`
      })
  }
}