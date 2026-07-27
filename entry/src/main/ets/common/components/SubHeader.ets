import { SubHeader } from '@ohos.arkui.advanced.SubHeader'
import { LengthMetrics, TextModifier } from '@kit.ArkUI'
import { FontScaleState } from '../utils/fontScaleState'

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
@Component
export struct CustomSubHeader {
  @State title: string | Resource = ''
  private secondaryModifier: TextModifier =
    new TextModifier().maxLines(FontScaleState.seniorMaxLines).wordBreak(WordBreak.BREAK_ALL)

  build() {
    SubHeader({
      secondaryTitle: this.title,
      secondaryTitleModifier: this.secondaryModifier,
      contentMargin: { start: LengthMetrics.vp(0), end: LengthMetrics.vp(0) },
    })
  }
}