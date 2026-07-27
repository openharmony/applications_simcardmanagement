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
const TAG = 'DynamicLoader';

export class DynamicLoader {
  public static SET_SCREEN_PASSWORD_PAGE = 'setScreenLockPassword';
  // dfx global pointer
  private static instance: DynamicLoader | null = null;
  public indexPageDynamicLoaderCb: ((key: string) => Promise<boolean>) | null = null;

  constructor() {
  }

  public static getInstance(): DynamicLoader {
    if (DynamicLoader.instance === null) {
      DynamicLoader.instance = new DynamicLoader();
    }
    return DynamicLoader.instance;
  }

  public registerIndexPageDynamicLoaderCb(loaderCallback: (key: string) => Promise<boolean>): void {
    this.indexPageDynamicLoaderCb = loaderCallback;
  }

  public async fireToIndexPage(key: string): Promise<boolean> {
    if (this.indexPageDynamicLoaderCb === null) {
      return true;
    }
    // 通过await import('xxx') 方式，引入页面
    let value = await this.indexPageDynamicLoaderCb(key);
    return value;
  }

  public async loadAccessibility() {
    return await import('@ohos.accessibility');
  }

  public async loadPromptAction() {
    return await import('@ohos.promptAction');
  }

  public async loadSystemParameter() {
    return await import('@ohos.systemparameter');
  }

  public async loadInputMethod() {
    return await import('@ohos.inputMethod');
  }

  public async loadHiSysEvent() {
    return await import('@ohos.hiSysEvent');
  }
}