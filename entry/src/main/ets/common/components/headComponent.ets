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
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { EditableLeftIconType, EditableTitleBar } from '@ohos.arkui.advanced.EditableTitleBar';
import { display, LengthMetrics } from '@kit.ArkUI';
import { PAGE_PADDING, START_REASON_FROM_SEARCH } from '../utils/constant';
import { DisplayUtils } from '../../utils/DisplayUtils';

/**
 * head custom component
 */
@Component
export default struct HeadComponent {
  @State isTouch: boolean = false;
  @State headName: Resource = $r('app.string.sim_headName');
  @StorageProp('foldStatus') @Watch('onFoldStatusChanged') foldStatus: number = display.FoldStatus.FOLD_STATUS_UNKNOWN;
  @State isShowBackIcon: boolean = true;
  private storage = LocalStorage.getShared();
  private session?: UIExtensionContentSession = this.storage?.get<UIExtensionContentSession>('session');
  private isFromSearch: boolean = this.storage?.get<string>('startReason') === START_REASON_FROM_SEARCH;

  aboutToAppear(): void {
    this.isShowBackIcon = !DisplayUtils.isSplit(getContext(this)) || !this.isFromSearch;
  }

  build() {
    Stack({ alignContent: Alignment.Start }) {
      EditableTitleBar({
        leftIconStyle: EditableLeftIconType.Back,
        title: this.headName,
        isSaveIconRequired: false,
        contentMargin: {
          start: LengthMetrics.resource(PAGE_PADDING)
        },
        onCancel: () => {
          this.session?.sendData({ 'action': 'pop' });
        }
      }).visibility(this.isShowBackIcon ? Visibility.Visible : Visibility.Hidden)

      if (!this.isShowBackIcon) {
        Text(this.headName)
          .fontSize($r('sys.float.Title_S'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .fontFamily('HarmonyHeiTi')
          .margin({
            start: LengthMetrics.resource(PAGE_PADDING),
          })
      }
    }
  }

  private onFoldStatusChanged() {
    if (this.foldStatus === display.FoldStatus.FOLD_STATUS_EXPANDED ||
      this.foldStatus === display.FoldStatus.FOLD_STATUS_HALF_FOLDED) {
      this.isShowBackIcon = !this.isFromSearch;
    } else {
      this.isShowBackIcon = true;
    }
  }
}