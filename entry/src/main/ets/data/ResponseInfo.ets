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
import { DEFAULT_PIN_REMAIN, LockType } from '../common/utils/constant';

export enum RespCode {
  SUCCEED,
  FAILED,
  CHANGE_PIN_ERROR,
  SET_LOCK_STATE_ERROR,
  UNLOCK_PIN_ERROR,
  UNLOCK_PUK_ERROR
}

export class PinResp {
  public isSucceed: boolean = false;
  public code: RespCode = RespCode.FAILED;
  public remainTimes: number = DEFAULT_PIN_REMAIN;
}

export class PinInfoResp {
  public lockType: LockType = LockType.NOT_LOCKED;
}