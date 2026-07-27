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
import LogUtils from './LogUtils';

const TAG: string = 'FontScaleState';

export class FontScaleState {
  private static currentGear: number = 0;
  public static topAndBottomMarginOnScale = '10vp';
  public static fontscale: number = 1;
  public static seniorMaxLines: number = 10;
  /**
   * 更新字体档数
   */
  public static updateAppFontGearSize(scale?: number): void {
    FontScaleState.fontscale = scale ?? 1
    switch (scale) {
      case 1: {
        FontScaleState.currentGear = 0;
        FontScaleState.topAndBottomMarginOnScale = '10vp';
        break;
      }
      case 1.15: {
        FontScaleState.currentGear = 1;
        FontScaleState.topAndBottomMarginOnScale = '10vp';
        break;
      }
      case 1.3: {
        FontScaleState.currentGear = 2;
        FontScaleState.topAndBottomMarginOnScale = '10vp';
        break;
      }
      case 1.45: {
        FontScaleState.currentGear = 3;
        FontScaleState.topAndBottomMarginOnScale = '10vp';
        break;
      }
      case 1.75: {
        FontScaleState.currentGear = 4;
        FontScaleState.topAndBottomMarginOnScale = '16vp';
        break;
      }
      case 2: {
        FontScaleState.currentGear = 5;
        FontScaleState.topAndBottomMarginOnScale = '20vp';
        break;
      }
      case 2.25: {
        FontScaleState.currentGear = 6;
        FontScaleState.topAndBottomMarginOnScale = '24vp';
        break;
      }
      case 3.2: {
        FontScaleState.currentGear = 7;
        FontScaleState.topAndBottomMarginOnScale = '24';
        break;
      }
      default: {
        FontScaleState.currentGear = 0;
        break;
      }
    }
    //无障碍字体档数
    LogUtils.i(TAG, `updateAppFontGearSize===>${scale}/${FontScaleState.currentGear}`);
    AppStorage.setOrCreate('fontSizeScale', FontScaleState.currentGear)
  }

  /**
   * 当前字体档数是否为标准档位
   */
  public static isStandardGeer(fontSizeScale: number): boolean {
    if (fontSizeScale < 1) {
      return true
    } else {
      return false
    }
  }

  /**
   * 当前字体档数是否小于大二挡
   */
  public static isSmallerTwoGeer(fontSizeScale: number): boolean {
    if (fontSizeScale < 2) {
      return true
    } else {
      return false
    }
  }

  /**
   * 当前字体档数是否小于大三挡
   */
  public static isSmallerThirdGeer(fontSizeScale: number): boolean {
    if (fontSizeScale < 3) {
      return true
    } else {
      return false
    }
  }

  /**
   * 当前字体档数是否大于大三挡
   */
  public static isBigerThirdGeer(fontSizeScale: number): boolean {
    if (fontSizeScale > 3) {
      return true
    } else {
      return false
    }
  }

  /**
   * 当前字体档数是否小于大四挡
   */
  public static isSmallerFourGeer(fontSizeScale: number): boolean {
    if (fontSizeScale < 4) {
      return true
    } else {
      return false
    }
  }

  /**
   * 当前字体档数是否小于大六挡
   */
  public static isSmallerSixGeer(fontSizeScale: number): boolean {
    if (fontSizeScale < 6) {
      return true
    } else {
      return false
    }
  }

  /**
   * 获取关怀模式下上下间距
   */
  public static fetchSeniorTopAndBottomSpace(fontSizeScale: number,
    normalSpace: string | number | Resource,
    seniorSpace: string | number | Resource): string | number | Resource {
    if (FontScaleState.isStandardGeer(fontSizeScale)) {
      return normalSpace;
    } else if (FontScaleState.isSmallerFourGeer(fontSizeScale)) {
      //代码中很多标准档位都是靠高度撑起来的，大3档及以下档位要使用UX上上下间距
      return seniorSpace;
    } else {
      return FontScaleState.topAndBottomMarginOnScale;
    }
  }

}