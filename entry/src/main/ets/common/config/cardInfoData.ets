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

/**
 * @file: Card information init
 */

import { CARD_NET_SUPPORT } from '../utils/constant';

export default class CardInfoData {
  // card title
  public title: string = '';
  // card name
  public name: string = 'strings.noCardInserted';
  public updateName: string = '';
  // card number
  public number: string = '';
  public updateNumber: string = '';
  // is contain this card
  public isOpened: boolean = false;
  // is or isn't opened
  public disabled: boolean = true;
  public id: number = 0;
  public netSupport: string = CARD_NET_SUPPORT.NO_SUPPORT_5G;
};