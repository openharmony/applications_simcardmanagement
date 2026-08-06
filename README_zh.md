# SIM 卡管理（SimCardManagement）

## 简介

**SIM 卡管理**（包名：`com.ohos.simcardmanagement`）是 OpenHarmony 电话子系统中的 **系统应用**，负责卡槽与运营商信息展示，并提供编辑卡信息、启用/停用 SIM 卡、SIM 卡保护、默认移动数据选择与默认拨号卡设置等能力，适配手机、平板设备形态。

### 核心能力

**编辑卡信息**
- 展示卡槽状态、运营商、号码、SPN 等信息。
- 支持编辑 SIM 名称与号码，变更通过 TelephonyKit 写入系统。

**启用/停用 SIM 卡**
- 支持按卡槽启用或停用 SIM 卡。
- 启停状态与卡槽信息随 SIM / 网络状态变化刷新。

**SIM 卡保护**
- 提供 SIM 卡保护设置入口与相关交互（含 PIN 相关能力）。
- 可与用户认证、锁屏等系统能力联动。

**默认移动数据选择**
- 支持在双卡场景下选择默认移动数据（上网）卡。
- 主页与控制中心扩展均可触发策略切换。

**默认拨号卡设置**
- 支持设置默认语音 / 拨号使用的 SIM 卡槽。
- 与通话侧默认卡策略保持一致。

## 架构说明

SimCardManagement 采用分层与模块化设计，按产品入口、业务特性与公共能力组织代码，如图：

![架构说明](./docs/figures/simcardmanagement.png)

### 应用层分层设计

整体可划分为产品层、特性层、公共层：

| 层次   | 主要目录 / 组件 | 说明 |
|------| -------------- | ---- |
| 产品层 | `entry` | 手机 / 平板形态 |
| 特性层 | `model/`、`pages/`、`uiExtensionAbility/`、`insightintents/` | 编辑卡信息、启用/停用 SIM、SIM 卡保护、默认移动数据、默认拨号卡 |
| 公共层 | `database/`、`common/`、`backup/`、`utils/` | 数据库、公共组件、备份恢复、工具类 |

**特性层能力说明**：

| 核心能力   | 关键路径 | 说明 |
|--------|----------------|------|
| 编辑卡信息   | `common/components/cardInfomation.ets`、`common/components/dialog/editSimInfoDialog.ets` | 卡信息展示与名称/号码编辑 |
| 启用/停用 SIM 卡   | `common/components/cardInfomation.ets`、`model/simServiceProxy.ets` | `isSimActive` / `setSimActive` 封装与启停 UI |
| SIM 卡保护   | `pages/simProtection.ets`、`common/components/pinComponent.ets` | SIM 卡保护页与 PIN 相关交互 |
| 默认移动数据选择   | `common/components/defaultDataComponent.ets`、`uiExtensionAbility/MobileDataChangeExtAbility.ets` | 默认上网卡选择与控制中心联动 |
| 默认拨号卡设置   | `common/components/dialog/selectDefaultVoiceDialog.ets`、`model/simServiceProxy.ets` | 默认语音卡查询与设置 |

### 与其它应用的关系

SimCardManagement 与 **系统设置**、**SceneBoard**、**SimToolkits** 及电话子系统协同，自身不包含 Modem / RIL 实现，通过 TelephonyKit 间接操作 SIM / Radio / Data。

**调用方式**：

- 系统设置通过 UIExtension Want 拉起 `com.ohos.simcardmanagement.MainAbility`，并可通过 `action.settings.search.path` 接入设置搜索。
- SceneBoard 通过 `MobileDataChangeExtAbility` 嵌入移动数据切换与默认上网卡相关 UI。
- SimToolkits 与主页 `SimToolkitsComponent` 协同完成 STK 入口展示与跳转。
- 电话能力经 `simServiceProxy`、`radioServiceProxy` 等代理访问 TelephonyKit；数据相关辅助见 `dataServiceProxy`。

**调用场景**：

设置内 SIM 卡管理页、设置搜索、控制中心移动数据切换、智能双卡相关系统对话框等。

**对外接口**：

| 接口类型 | 接口标识 | 说明 |
|------|------|------|
| UIExtension（sys/commonUI） | `com.ohos.simcardmanagement.MainAbility` | 系统设置主入口通过 Want 拉起 SIM 卡管理页面 |
| UIExtension（sys/commonUI） | `SmartDualCardDialogAbility` | 智能双卡相关系统对话框入口 |
| UIExtension（sys/commonUI） | `MobileDataChangeExtAbility` | SceneBoard 控制中心移动数据切换扩展入口 |
| Metadata 配置 | `action.settings.search.path` | 设置搜索路径配置，供设置侧检索并跳转到本应用能力 |

## 编译构建

本工程为独立 HAP 应用工程，使用 Hvigor 构建，产物为 `com.ohos.simcardmanagement` 系统应用包；流水线可将签名产物重命名为 `SimCardManagement.hap` 并预装至 `/system/app/SimCardManagement/`。

### 环境要求
- Openharmony SDK: compileSdkVersion 26, compatibleSdkVersion 23
- DevEco Studio 或命令行 Hvigor 工具链
- 系统签名证书（见 `signature/`）

### 编译命令

在工程根目录执行（需本机已配置 Hvigor 命令行 `hvigorw`，或使用 DevEco Studio / 流水线 `build.sh`）：

```bash
hvigorw assembleHap --mode module -p product=default -p debuggable=false -p buildMode=release
```

默认签名产物位于 `entry/build/default/outputs/default/entry-default-signed.hap`；`build.sh` 可将其复制为同目录下的 `SimCardManagement.hap`。

## SimCardManagement 开发

SimCardManagement 采用 **ArkTS** 语言开发，UI 基于 ArkUI Stage 模型。应用通过 `com.ohos.simcardmanagement.MainAbility`承载主界面，通过 `model/` 下代理封装 TelephonyKit，通过公共层 `common/components/` 完成各特性 UI。开发可参考：[ArkUI 开发概述](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-ui-development-overview.md)

### 基于已有模块的开发

适用场景：对已有能力做功能定制，例如调整卡信息编辑、启停 SIM 交互、SIM 卡保护流程、默认上网卡或默认拨号卡策略展示等。

以下列举一些常见的修改场景：

**场景1：编辑卡信息**

   - 主页与导航位于 `entry/src/main/ets/pages/index.ets`
   - 卡信息展示位于 `entry/src/main/ets/common/components/cardInfomation.ets`
   - 编辑弹窗位于 `entry/src/main/ets/common/components/dialog/editSimInfoDialog.ets`

例如，需在保存 SIM 名称前增加校验，可在 `setShowName` 中扩展逻辑：
```typescript
    // editSimInfoDialog.ets
    function setShowName(editInfo: EditSimInfo, onSetShowNameResult: (slotId: number) => void, retryCount: number = 0) {
      // 【修改点】在此扩展名称校验、空值处理或自定义前置检查
      if (!customValidateName(editInfo.newName)) {
        return;
      }
      ...
      SimServiceProxy.setShowName(editInfo.slotId, editInfo.newName).then(() => {
        onSetShowNameResult(editInfo.slotId);
      })
      ...
    }
```

**场景2：启用/停用 SIM 卡**

   - 启停 UI 与状态刷新位于 `entry/src/main/ets/common/components/cardInfomation.ets`
   - Telephony 封装位于 `entry/src/main/ets/model/simServiceProxy.ets`（`setSimActive` / `isSimActive`）

例如，需在启停成功后增加自定义提示，可在 `setSimActivated` 中扩展：
```typescript
    // cardInfomation.ets
    setSimActivated(slotId: number, isActivated: boolean) {
      ...
      SimServiceProxy.setSimActive(slotId, isActivated).then(() => {
        // 【修改点】启停成功后可在此扩展自定义提示或后续处理
        // showCustomToast(slotId, isActivated);
        ...
        this.handleSetActivateEnd(slotId, true);
      }).catch(() => {
        this.handleSetActivateEnd(slotId, false);
      });
    }
```

**场景3：SIM 卡保护**

   - 保护页位于 `entry/src/main/ets/pages/simProtection.ets`（`SimProtection` 组件，由主页 `NavPathStack` 导航进入）
   - PIN 交互组件位于 `entry/src/main/ets/common/components/pinComponent.ets`
   - 业务逻辑位于 `entry/src/main/ets/model/PinViewModel.ets`、`entry/src/main/ets/model/pinModel.ets`

例如，保护能力与卡槽启停状态联动时，可复用 `SimServiceProxy.isSimActive`：
```typescript
    // 判断当前卡槽是否可用
    const isActive = SimServiceProxy.isSimActive(slotId);
```

**场景4：默认移动数据选择**

   - 默认上网卡 UI 位于 `entry/src/main/ets/common/components/defaultDataComponent.ets`
   - 写入封装位于 `entry/src/main/ets/model/radioServiceProxy.ets`（`setPrimarySlotId`）
   - 控制中心场景位于 `entry/src/main/ets/uiExtensionAbility/MobileDataChangeExtAbility.ets`

例如，需在切换默认移动数据卡前新增自定义前置检查，可在 `setPrimarySlotId()` 中扩展：
```typescript
    // defaultDataComponent.ets
    setPrimarySlotId(slotId: number) {
      // 【修改点】在此扩展自定义前置检查
      if (!this.customPreCheck(slotId)) {
        return;
      }
      ...
      setPrimarySlotId(slotId).then(() => {
        this.onSetPrimarySlotIdFinished();
      })
      ...
    }
```

**场景5：默认拨号卡设置**

   - 主页入口与结果刷新位于 `entry/src/main/ets/pages/index.ets`
   - 设置弹窗与写回位于 `entry/src/main/ets/common/components/dialog/selectDefaultVoiceDialog.ets`
   - Telephony 封装位于 `entry/src/main/ets/model/simServiceProxy.ets`（`setDefaultVoiceSlotId`）

例如，需在设置默认拨号卡成功后增加自定义提示，可在 `setDefaultVoiceSlotId` 中扩展：
```typescript
    // selectDefaultVoiceDialog.ets
    export function setDefaultVoiceSlotId(slotId: number, onSetDefaultVoiceResult: (slotId: number) => void) {
      ...
      SimServiceProxy.setDefaultVoiceSlotId(slotId).then((res: boolean) => {
        // 【修改点】设置成功后可在此扩展自定义提示
        // showCustomToast(slotId);
        onSetDefaultVoiceResult(slotId);
      })
      ...
    }
```

常用修改入口：

| 目标 | 路径 |
|------|------|
| 应用主入口（UIExtension） | `entry/src/main/ets/MainAbility/MainAbility.ets` |
| 应用首页 | `entry/src/main/ets/pages/index.ets` |
| 编辑卡信息 | `entry/src/main/ets/common/components/cardInfomation.ets`、`common/components/dialog/editSimInfoDialog.ets` |
| 启用/停用 SIM | `entry/src/main/ets/model/simServiceProxy.ets`、`common/components/cardInfomation.ets` |
| SIM 卡保护 | `entry/src/main/ets/pages/simProtection.ets`、`model/PinViewModel.ets` |
| 默认移动数据 | `entry/src/main/ets/common/components/defaultDataComponent.ets`、`model/radioServiceProxy.ets` |
| 默认拨号卡 | `entry/src/main/ets/common/components/dialog/selectDefaultVoiceDialog.ets`、`model/simServiceProxy.ets` |
| 控制中心移动数据 | `entry/src/main/ets/uiExtensionAbility/MobileDataChangeExtAbility.ets` |
| Ability / 权限声明 | `entry/src/main/module.json5` |
| 页面路由注册 | `entry/src/main/resources/base/profile/main_pages.json` |

### 新特性能力的开发

适用场景：在现有 SIM 管理能力上扩展交互、补充系统协同入口或适配新设备形态。

> **说明**：当前工程为单 `entry` HAP 模块，产品入口与 Ability 均在 `entry` 中声明。新能力一般按产品层 / 特性层 / 公共层扩展；涉及 Telephony 的策略变更需同步确认权限与 TelephonyKit 接口。

**场景1：扩展业务能力**

1. 在 `model/` 中补充 TelephonyKit 代理或策略封装。
2. 在 `common/components/` 或 `pages/` 中补充 UI 与交互。
3. 如涉及持久化，在 `database/DatabaseHelper.ets` 或 Settings DataShare 协同路径中扩展。
4. 在 `entry/src/ohosTest` 中补充对应 UT / 用例。
5. 配置 / 确认 Ability 入口

主 UIExtension、控制中心扩展、备份等已在 `entry/src/main/module.json5` 中声明，扩展能力时通常需确认 `mainElement`、extension 类型与权限：
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "mainElement": "com.ohos.simcardmanagement.MainAbility",
    "extensionAbilities": [
      {
        "name": "com.ohos.simcardmanagement.MainAbility",
        "srcEntrance": "./ets/MainAbility/MainAbility.ets",
        "type": "sys/commonUI"
      },
      {
        "name": "MobileDataChangeExtAbility",
        "srcEntry": "./ets/uiExtensionAbility/MobileDataChangeExtAbility.ets",
        "type": "sys/commonUI",
        "exported": true
      }
    ]
  }
}
```

**场景2：定制 UI**

在完成业务能力与 Ability 配置后，按上一节方式扩展 `pages/index.ets`、各特性组件或控制中心页面即可。

若需新增独立页面：

1. 在 `entry/src/main/ets/pages/` 下新增页面文件；
2. 在 `entry/src/main/resources/base/profile/main_pages.json` 的 `src` 数组中注册；
3. 由 `MainAbility.onSessionCreate` 的 `session.loadContent` 或主页 `NavPathStack` 拉起。

## 目录

```text
simcardmanagement
├─AppScope                              # 应用级配置与多语言资源
│  ├─app.json5                          # bundleName、版本号等
│  └─resources/                         # 全局字符串 / 图标等资源
├─docs                                  # 文档与架构图
│  └─figures/                           # 架构说明图
├─entry                                 # 产品层：应用入口与业务源码
│  └─src/main/
│     ├─ets/
│     │  ├─Application/                 # 产品层：AbilityStage 生命周期入口
│     │  ├─MainAbility/                 # 产品层：MainAbility、SmartDualCardDialogAbility
│     │  ├─pages/                       # 特性层：编辑卡信息、SIM 卡保护、默认拨号卡相关页面
│     │  ├─uiExtensionAbility/          # 特性层：默认移动数据切换扩展
│     │  ├─model/                       # 特性层：SIM/Radio 业务模型与 Telephony 代理
│     │  ├─insightintents/              # 特性层：意图执行入口
│     │  ├─common/                      # 公共层：跨特性公共组件与工具
│     │  │  ├─components/               # 公共层：卡信息、默认数据、PIN、拨号卡、SimToolkits 组件
│     │  │  ├─utils/                    # 常量、Settings 监听、认证工具等
│     │  │  ├─config/                   # 卡信息相关配置数据
│     │  │  └─struct/                   # 卡信息等数据结构
│     │  ├─data/                        # 公共层：Infos、ResponseInfo 等数据结构
│     │  ├─database/                    # 公共层：数据库
│     │  ├─backup/                      # 公共层：备份恢复
│     │  ├─WorkSchedulerExtension/      # 统计上报扩展
│     │  └─utils/                       # 公共层：工具类
│     ├─resources/                      # 模块资源、设置搜索配置、多语言等
│     └─module.json5                    # Ability、权限声明
│  └─src/ohosTest/                      # Hypium 自动化测试
├─hvigor                                # 构建工具配置
├─signature                             # 签名证书与 profile
├─build.sh                              # 流水线构建与 HAP 重命名
├─build-profile.json5                   # 工程级配置
├─oh-package.json5
├─OAT.xml                               # 开源合规审计
├─LICENSE
├─README.md                             # 英文说明文档
└─README_zh.md                          # 中文说明文档
```

> 说明：本工程未提供 `bundle.json`，模块与产品构建信息以 `build-profile.json5`、`entry/src/main/module.json5` 为准。

## 约束

- **语言版本**：ArkTS
- **运行形态**：系统预置应用（`com.ohos.simcardmanagement`），依赖 TelephonyKit（`@ohos.telephony.sim` / `radio` / `data` / `call`）及系统特权权限；**不包含** RIL / Modem 实现
- **设备类型**：手机、平板（见 `entry/src/main/module.json5`）
- **签名要求**：须使用系统签名 profile（见 `signature/simcardmanagement.p7b`）
- **权限**：以下为 `entry/src/main/module.json5` 中声明且在本工程能力链路中使用的主要权限（其中 `SET_TELEPHONY_STATE` 同时用于 extension `permissions`）

  | 权限 | 授权方式 | 使用场景 |
  |------|---------|---------------------------------------------|
  | ohos.permission.GET_TELEPHONY_STATE | 系统授权 | 查询 SIM 状态、默认卡状态与通话相关状态 |
  | ohos.permission.SET_TELEPHONY_STATE | 系统授权 | SIM 启停、默认语音卡 / 默认移动数据卡写入 |
  | ohos.permission.GET_NETWORK_INFO | 用户授权 | 默认移动数据切换前后的网络状态判断 |
  | ohos.permission.USE_USER_IDM | 用户授权 | SIM 卡保护流程中的用户身份认证 |
  | ohos.permission.ACCESS_BIOMETRIC | 用户授权 | SIM 卡保护流程中的生物识别认证 |
  | ohos.permission.PRIVACY_WINDOW | 系统授权 | SIM 卡保护等敏感界面的隐私窗口能力 |
  | ohos.permission.ACCESS_SYSTEM_SETTINGS | 系统授权 | 读取系统设置项（含设置搜索协同） |
  | ohos.permission.MANAGE_SETTINGS | 系统授权 | 双卡 / 移动网络相关系统设置项读写 |
  | ohos.permission.MANAGE_SECURE_SETTINGS | 系统授权 | 安全相关系统设置项读写 |
  | ohos.permission.GET_BUNDLE_INFO | 系统授权 | 查询联动应用包信息（如 `com.ohos.simtoolkits`） |

- **外部依赖**：系统设置（`com.ohos.settings`）负责主入口嵌入；SceneBoard 负责控制中心扩展；SimToolkits STK 跳转常量包名为 `com.ohos.simtoolkits`（见 `SimToolkitsComponent`；产品侧需与实际 STK 应用 `bundleName` 保持一致）；Telephony 子系统提供底层能力

## 参与贡献

欢迎广大开发者贡献代码、文档等，具体的贡献流程和方式请参见[参与贡献](https://gitcode.com/openharmony/docs/blob/master/zh-cn/contribute/%E5%8F%82%E4%B8%8E%E8%B4%A1%E7%8C%AE.md)。

## 相关仓

[**applications_settings**](https://gitcode.com/openharmony/applications_settings)

[**simtoolkits**](https://gitcode.com/openharmony-sig/applications_simtoolkits.git)
