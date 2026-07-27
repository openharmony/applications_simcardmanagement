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
import { CARD_CALLING_SET, SLOT_1, SLOT_2 } from '../../utils/constant';
import SimServiceProxy from '../../../model/simServiceProxy';
import { simIdFormat } from '../../utils/SimIdFormat';
import { StringUtils } from '../../../utils/StringUtils';
import { ReportUtil } from '../../../utils/ReportUtil';
import { getString, getStringWithArgs } from '../../utils/Utils';
import { FontScaleState } from '../../utils/fontScaleState';

class SelectDefaultVoiceInfo {
  public defaultVoiceSlotId: number = -1;
  public phoneNumber1: string = '';
  public phoneNumber2: string = '';
  public fontSizeScale: number = 0;
  public onSelectedDefaultVoice: (slotId: number) => void = (slotId: number) => {
  };
}

function getRadioIcon(slotId: number, defaultVoiceSlotId: number): Resource {
  return slotId === defaultVoiceSlotId ? $r('app.media.radio_checked') : $r('app.media.radio_unchecked');
}

function getStringOfRadioSelectStatus(slotId: number, defaultVoiceSlotId: number): string {
  return slotId === defaultVoiceSlotId ? getString($r('app.string.accessibility_selected')) :
  getString($r('app.string.accessibility_unselected'));
}

function getAccessibilityText(selectDefaultVoiceInfo: SelectDefaultVoiceInfo, slotId: number,
  defaultVoiceSlotId: number): string {
  let accessibilityText = '';
  if (slotId === CARD_CALLING_SET.NO_SETTING) {
    accessibilityText = getString($r('app.string.not_set'))
  } else if (slotId === CARD_CALLING_SET.CARD1) {
    accessibilityText = getStringWithArgs($r('app.string.sim_card_one_no_space'), simIdFormat(SLOT_1 + 1));
    let phoneNumber = StringUtils.formatPhoneNumberWhenRtl(selectDefaultVoiceInfo.phoneNumber1);
    if (phoneNumber.length > 0) {
      accessibilityText = accessibilityText + ' ' + phoneNumber;
    }
  } else if (slotId === CARD_CALLING_SET.CARD2) {
    accessibilityText = getStringWithArgs($r('app.string.sim_card_one_no_space'), simIdFormat(SLOT_2 + 1));
    let phoneNumber = StringUtils.formatPhoneNumberWhenRtl(selectDefaultVoiceInfo.phoneNumber2)
    if (phoneNumber.length > 0) {
      accessibilityText = accessibilityText + ' ' + phoneNumber;
    }
  }
  accessibilityText = accessibilityText + ' ' + getStringOfRadioSelectStatus(slotId, defaultVoiceSlotId);
  return accessibilityText;
}

/**
 * Content area of the Dialog for setting the default dialing card.
 *
 * @param selectDefaultVoiceInfo Information needed to set the Dialog for the default dialing card.
 */
@Builder
export function SelectDefaultCallSimContent(selectDefaultVoiceInfo: SelectDefaultVoiceInfo) {
  Scroll() {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Text($r('app.string.not_set'))
          .fontSize($r('sys.float.Body_L'))
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .fontFamily('HarmonyHeiTi')
          .align(Alignment.Center | Alignment.Start)
          .lineHeight(FontScaleState.isStandardGeer(selectDefaultVoiceInfo.fontSizeScale) ?
          $r('app.float.wh_value_21') : 0)
        Image(getRadioIcon(CARD_CALLING_SET.NO_SETTING, selectDefaultVoiceInfo.defaultVoiceSlotId))
          .height($r('app.float.wh_value_24'))
          .width($r('app.float.wh_value_24'))
          .onClick(() => {
            selectDefaultVoiceInfo.onSelectedDefaultVoice(CARD_CALLING_SET.NO_SETTING);
          })
          .accessibilityLevel('no')
      }
      .accessibilityText(getAccessibilityText(selectDefaultVoiceInfo, CARD_CALLING_SET.NO_SETTING,
        selectDefaultVoiceInfo.defaultVoiceSlotId))
      .constraintSize({ minHeight: $r('app.float.value_48') })
      .onClick(() => {
        selectDefaultVoiceInfo.onSelectedDefaultVoice(CARD_CALLING_SET.NO_SETTING);
      })
      .padding({
        top: FontScaleState.fetchSeniorTopAndBottomSpace(selectDefaultVoiceInfo.fontSizeScale, 0,
          $r('app.float.wh_value_10')),
        bottom: FontScaleState.fetchSeniorTopAndBottomSpace(selectDefaultVoiceInfo.fontSizeScale, 0,
          $r('app.float.wh_value_10'))
      })

      Divider().vertical(false).color($r('sys.color.comp_divider'))

      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Column() {
          Text($r('app.string.sim_card_one_no_space', simIdFormat(SLOT_1 + 1)))
            .fontSize($r('sys.float.Body_L'))
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Medium)
            .fontFamily('HarmonyHeiTi')
            .align(Alignment.Start)
            .lineHeight(FontScaleState.isStandardGeer(selectDefaultVoiceInfo.fontSizeScale) ? $r('app.float.value_22') :
              0)
          Text(StringUtils.formatPhoneNumberWhenRtl(selectDefaultVoiceInfo.phoneNumber1))
            .fontSize($r('sys.float.Body_M'))
            .fontWeight(FontWeight.Regular)
            .fontFamily('HarmonyHeiTi')
            .align(Alignment.Start)
            .lineHeight(FontScaleState.isStandardGeer(selectDefaultVoiceInfo.fontSizeScale) ? $r('app.float.value_19') :
              0)
            .fontColor($r('sys.color.font_secondary'))
        }.alignItems(HorizontalAlign.Start)

        Column() {
          Image(getRadioIcon(CARD_CALLING_SET.CARD1, selectDefaultVoiceInfo.defaultVoiceSlotId))
            .height($r('app.float.wh_value_24'))
            .width($r('app.float.wh_value_24'))
            .onClick(() => {
              selectDefaultVoiceInfo.onSelectedDefaultVoice(CARD_CALLING_SET.CARD1);
            })
            .accessibilityLevel('no')
        }
      }
      .constraintSize({ minHeight: $r('app.float.value_64') })
      .accessibilityText(getAccessibilityText(selectDefaultVoiceInfo, CARD_CALLING_SET.CARD1,
        selectDefaultVoiceInfo.defaultVoiceSlotId))
      .onClick(() => {
        selectDefaultVoiceInfo.onSelectedDefaultVoice(CARD_CALLING_SET.CARD1);
      })
      .padding({
        top: FontScaleState.fetchSeniorTopAndBottomSpace(selectDefaultVoiceInfo.fontSizeScale, 0,
          $r('app.float.wh_value_10')),
        bottom: FontScaleState.fetchSeniorTopAndBottomSpace(selectDefaultVoiceInfo.fontSizeScale, 0,
          $r('app.float.wh_value_10'))
      })

      Divider().vertical(false).color($r('sys.color.comp_divider'))

      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Column() {
          Text($r('app.string.sim_card_one_no_space', simIdFormat(SLOT_2 + 1)))
            .fontSize($r('sys.float.Body_L'))
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Medium)
            .fontFamily('HarmonyHeiTi')
            .align(Alignment.Start)
            .lineHeight(FontScaleState.isStandardGeer(selectDefaultVoiceInfo.fontSizeScale) ? $r('app.float.value_22') :
              0)
          Text(StringUtils.formatPhoneNumberWhenRtl(selectDefaultVoiceInfo.phoneNumber2))
            .fontSize($r('sys.float.Body_M'))
            .fontWeight(FontWeight.Regular)
            .fontFamily('HarmonyHeiTi')
            .align(Alignment.Start)
            .lineHeight(FontScaleState.isStandardGeer(selectDefaultVoiceInfo.fontSizeScale) ? $r('app.float.value_19') :
              0)
            .fontColor($r('sys.color.font_secondary'))
        }.alignItems(HorizontalAlign.Start)

        Column() {
          Image(getRadioIcon(CARD_CALLING_SET.CARD2, selectDefaultVoiceInfo.defaultVoiceSlotId))
            .height($r('app.float.wh_value_24'))
            .width($r('app.float.wh_value_24'))
            .onClick(() => {
              selectDefaultVoiceInfo.onSelectedDefaultVoice(CARD_CALLING_SET.CARD2);
            })
            .accessibilityLevel('no')
        }
      }
      .constraintSize({ minHeight: $r('app.float.value_64') })
      .accessibilityText(getAccessibilityText(selectDefaultVoiceInfo, CARD_CALLING_SET.CARD2,
        selectDefaultVoiceInfo.defaultVoiceSlotId))
      .onClick(() => {
        selectDefaultVoiceInfo.onSelectedDefaultVoice(CARD_CALLING_SET.CARD2);
      })
      .padding({
        top: FontScaleState.fetchSeniorTopAndBottomSpace(selectDefaultVoiceInfo.fontSizeScale, 0,
          $r('app.float.wh_value_10')),
        bottom: FontScaleState.fetchSeniorTopAndBottomSpace(selectDefaultVoiceInfo.fontSizeScale, 0,
          $r('app.float.wh_value_10'))
      })
    }
    .alignItems(HorizontalAlign.Start)
  }
  .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
  .scrollBar(BarState.Off)
}

/**
 * Setting the Default Dialing Card
 *
 * @param slotId The slot id of SIM.
 * @param onSetDefaultVoiceResult Results of setting the default dialing card.
 */
export function setDefaultVoiceSlotId(slotId: number, onSetDefaultVoiceResult: (slotId: number) => void) {
  ReportUtil.getInstance().reportDefaultDialingCardSetting(slotId);
  SimServiceProxy.setDefaultVoiceSlotId(slotId).then((res: boolean) => {
    onSetDefaultVoiceResult(slotId);
  }).catch(() => {
    onSetDefaultVoiceResult(slotId);
  });
}