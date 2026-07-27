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

import xml from '@ohos.xml';
import LogUtils from '../common/utils/LogUtils';
import SimCardModel from '../model/SimCardModel';
import convertxml from '@ohos.convertxml';
import util from '@ohos.util';

const TAG = 'XmlParserUtil';

const KEY_BEGIN = 2;
const KEY_END = 3;
const KEY_TEXT = 4;

class XmlParserUtil {
  xmlParserText(fileContent: ArrayBuffer): string {
    if (!this.checkXml(fileContent)) {
      return '';
    }
    let iccId = '';
    let flag1 = false;
    let flag2 = false;
    let that = new xml.XmlPullParser(fileContent, 'UTF-8');
    let options: xml.ParseOptions = {
      supportDoctype: true,
      ignoreNameSpace: true,
      tokenValueCallbackFunction: (key: xml.EventType, value: xml.ParseInfo) => {
        if (key === KEY_BEGIN && value.getName() === 'default_outgoing_phone_account_handle') {
          flag1 = true;
        }
        if (key === KEY_END && value.getName() === 'default_outgoing_phone_account_handle') {
          flag1 = false;
          return false;
        }
        if (key === KEY_BEGIN && value.getName() === 'id') {
          flag2 = true;
        }
        if (key === KEY_END && value.getName() === 'id') {
          flag2 = false;
        }
        if (key === KEY_TEXT && flag1 && flag2) {
          iccId = value.getText();
          return false;
        }
        return true;
      }
    };
    that.parse(options);
    LogUtils.i(TAG, `xmlParserText parse len:${iccId.length}`);
    return iccId;
  }

  xmlParseKeyText(fileContent: ArrayBuffer): Array<SimCardModel> {
    if (!this.checkXml(fileContent)) {
      return [];
    }
    let flag1: boolean = false;
    let flag2: boolean = false;
    let id: string[] = [];
    let simName: string[] = [];
    let simCards: SimCardModel[] = [];
    let that = new xml.XmlPullParser(fileContent, 'UTF-8');
    let options: xml.ParseOptions = {
      supportDoctype: true,
      ignoreNameSpace: true,
      attributeValueCallbackFunction: (name: string, value: string) => {
        if (name === 'name' && value.match('sim_name_\*')) {
          flag1 = true;
          id.push(value.slice(-1));
          LogUtils.i(TAG, `id:${value.slice(-1)}`);
        } else {
          flag1 = false;
        }
        return true;
      },
      tokenValueCallbackFunction: (key: xml.EventType, value: xml.ParseInfo) => {
        if (key === KEY_BEGIN && value.getName() === 'string') {
          flag2 = true;
        }
        if (key === KEY_END) {
          flag2 = false;
        }
        if (flag1 && flag2 && key === 4) {
          simName.push(value.getText());
          LogUtils.i(TAG, `simName:${value.getText()?.length}`);
        }
        return true;
      }
    }
    that.parse(options);
    LogUtils.i(TAG, `xmlParseKeyText parse len:${id.length}`);
    for (let i = 0; i < id.length; i++) {
      simCards.push(new SimCardModel(Number(id[i]), simName[i]));
    }
    return simCards;
  }

  checkXml(fileContent: ArrayBuffer): boolean {
    LogUtils.i(TAG, 'checkXml start');
    try {
      let convert: convertxml.ConvertXML = new convertxml.ConvertXML;
      let textDecoder = util.TextDecoder.create('UTF-8', {ignoreBOM: true});
      let result: object = convert.convertToJSObject(textDecoder.decodeWithStream(new Uint8Array(fileContent)));
      if (result && (result?.['_elements'] || result?.['_declaration'])) {
        LogUtils.i(TAG, 'checkXml is valid');
        return true;
      }
    } catch (err) {
      LogUtils.e(TAG, `checkXml error:${JSON.stringify(err)}`);
    }
    LogUtils.i(TAG, 'checkXml is invalid');
    return false;
  }
}

export const xmlParserUtil: XmlParserUtil = new XmlParserUtil();