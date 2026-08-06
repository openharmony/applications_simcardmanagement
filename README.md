# SIM Management (SimCardManagement)

## Introduction

**SIM Management** (bundle name: `com.ohos.simcardmanagement`) is a **system application** in the OpenHarmony telephony subsystem. It displays slot and carrier information, and provides edit card info, enable/disable SIM, SIM protection, default mobile data selection, and default dialing card settings. It adapts to phone and tablet device forms.

### Core Capabilities

**Edit Card Info**
- Displays slot status, carrier, number, SPN, and related information.
- Supports editing the SIM display name and number; changes are written through TelephonyKit.

**Enable/Disable SIM**
- Supports enabling or disabling a SIM by slot.
- Enable/disable state and slot info refresh with SIM / network state changes.

**SIM Protection**
- Provides the SIM protection settings entry and related interactions (including PIN-related capabilities).
- Can work with user authentication and lock-screen capabilities.

**Default Mobile Data Selection**
- Supports selecting the default mobile data (Internet) card in dual-SIM scenarios.
- Both the home page and the control-center extension can trigger policy switching.

**Default Dialing Card Settings**
- Supports setting the default voice / dialing SIM slot.
- Stays consistent with the call-side default card policy.

## Architecture

SimCardManagement uses a layered, modular design organized by product entry, feature capabilities, and common capabilities, as shown below:

![Architecture](./docs/figures/simcardmanagement_en.png)

### Application Layer Design

The overall structure is divided into product layer, feature layer, and common layer:

| Layer | Main directories / components | Description |
| ----- | --------------------------- | ----------- |
| Product layer | `entry` (`Application/`, `MainAbility/`, `module.json5`) | Phone / tablet form |
| Feature layer | `pages/index`, `common/components/cardInfomation`, `common/components/dialog/editSimInfoDialog`, `model/simServiceProxy` | Edit card info |
| Feature layer | `common/components/cardInfomation`, `model/simServiceProxy`, `insightintents/` | Enable/Disable SIM |
| Feature layer | `pages/simProtection`, `common/components/pinComponent`, `model/PinViewModel`, `model/pinModel` | SIM protection |
| Feature layer | `common/components/defaultDataComponent`, `model/radioServiceProxy`, `uiExtensionAbility/MobileDataChangeExtAbility`, `insightintents/` | Default mobile data |
| Feature layer | `pages/index`, `common/components/dialog/selectDefaultVoiceDialog`, `model/simServiceProxy`, `insightintents/` | Default dialing card |
| Common layer | `database/` (`DatabaseHelper`) | Database |
| Common layer | `common/` (`components/`, `utils/`, `config/`, `struct/`) | Shared components |
| Common layer | `backup/` (`BackupExtension`, `CopyDbDataHelper`) | Backup/restore |
| Common layer | `utils/` | Utilities |

**Feature layer capability description**:

| Core capability | Key paths | Description |
| --------------- | ------- | ----------- |
| Edit card info | `common/components/cardInfomation.ets`, `common/components/dialog/editSimInfoDialog.ets` | Card info display and name/number editing |
| Enable/Disable SIM | `common/components/cardInfomation.ets`, `model/simServiceProxy.ets` | `isSimActive` / `setSimActive` wrappers and enable/disable UI |
| SIM protection | `pages/simProtection.ets`, `common/components/pinComponent.ets` | SIM protection page and PIN-related interactions |
| Default mobile data selection | `common/components/defaultDataComponent.ets`, `uiExtensionAbility/MobileDataChangeExtAbility.ets` | Default data card selection and control-center linkage |
| Default dialing card settings | `common/components/dialog/selectDefaultVoiceDialog.ets`, `model/simServiceProxy.ets` | Default voice card query and settings |

### Relationship with Other Applications

SimCardManagement works with **Settings**, **SceneBoard**, **SimToolkits**, and the telephony subsystem. It does not include Modem / RIL implementation and operates SIM / Radio / Data indirectly through TelephonyKit.

**Invocation**:

- Settings launches `com.ohos.simcardmanagement.MainAbility` through a UIExtension Want, and can integrate Settings search via `action.settings.search.path`.
- SceneBoard embeds mobile-data switching and default data-card UI through `MobileDataChangeExtAbility`.
- SimToolkits collaborates with the home-page `SimToolkitsComponent` for STK entry display and navigation.
- Telephony capabilities are accessed through proxies such as `simServiceProxy` and `radioServiceProxy`; data-related helpers are in `dataServiceProxy`.

**Invocation scenarios**:

SIM management page inside Settings, Settings search, control-center mobile data switching, smart dual-card related system dialogs, and similar flows.

**External interfaces**:

| Interface type | Interface identifier | Description |
|------|------|------|
| UIExtension (sys/commonUI) | `com.ohos.simcardmanagement.MainAbility` | Main Settings entry launches the SIM management page via Want |
| UIExtension (sys/commonUI) | `SmartDualCardDialogAbility` | Entry for smart dual-card related system dialogs |
| UIExtension (sys/commonUI) | `MobileDataChangeExtAbility` | Extension entry for mobile-data switching in SceneBoard control center |
| Metadata configuration | `action.settings.search.path` | Settings search path metadata used by Settings to locate and jump to this app capability |

## Build

This is a standalone HAP application project built with Hvigor. The product is the `com.ohos.simcardmanagement` system application package. The pipeline may rename the signed artifact to `SimCardManagement.hap` and preinstall it under `/system/app/SimCardManagement/`.

### Environment Requirements
- OpenHarmony SDK (`compileSdkVersion` / `compatibleSdkVersion` / `targetSdkVersion` are all 26)
- DevEco Studio or command-line Hvigor toolchain
- System signing certificates (see `signature/`)

### Build Commands

Run in the project root (requires the Hvigor CLI `hvigorw` on PATH, or use DevEco Studio / the pipeline `build.sh`):

```bash
hvigorw assembleHap --mode module -p product=default -p debuggable=false -p buildMode=release
```

The default signed artifact is at `entry/build/default/outputs/default/entry-default-signed.hap`. `build.sh` can copy it to `SimCardManagement.hap` in the same directory.

## SimCardManagement Development

SimCardManagement is developed in **ArkTS**, with UI based on the ArkUI Stage model. The app hosts the main UI through `com.ohos.simcardmanagement.MainAbility`, wraps TelephonyKit in `model/` proxies, and implements feature UI via the common-layer `common/components/`. See: [ArkUI Development Overview](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-ui-development-overview.md)

### Development Based on Existing Modules

Typical use cases: customize existing capabilities such as card-info editing, SIM enable/disable interaction, SIM protection flow, default data card, or default dialing card presentation.

Common modification scenarios:

**Scenario 1: Edit card info**

   - Home page and navigation: `entry/src/main/ets/pages/index.ets`
   - Card info display: `entry/src/main/ets/common/components/cardInfomation.ets`
   - Edit dialog: `entry/src/main/ets/common/components/dialog/editSimInfoDialog.ets`

For example, to add validation before saving the SIM name, extend `setShowName`:
```typescript
    // editSimInfoDialog.ets
    function setShowName(editInfo: EditSimInfo, onSetShowNameResult: (slotId: number) => void, retryCount: number = 0) {
      // [Change point] extend name validation, empty handling, or a custom pre-check here
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

**Scenario 2: Enable/Disable SIM**

   - Enable/disable UI and refresh: `entry/src/main/ets/common/components/cardInfomation.ets`
   - Telephony wrappers: `entry/src/main/ets/model/simServiceProxy.ets` (`setSimActive` / `isSimActive`)

For example, to add a custom toast after enable/disable succeeds, extend `setSimActivated`:
```typescript
    // cardInfomation.ets
    setSimActivated(slotId: number, isActivated: boolean) {
      ...
      SimServiceProxy.setSimActive(slotId, isActivated).then(() => {
        // [Change point] extend a custom toast or follow-up handling after success
        // showCustomToast(slotId, isActivated);
        ...
        this.handleSetActivateEnd(slotId, true);
      }).catch(() => {
        this.handleSetActivateEnd(slotId, false);
      });
    }
```

**Scenario 3: SIM protection**

   - Protection page: `entry/src/main/ets/pages/simProtection.ets` (`SimProtection` component, navigated from the home page via `NavPathStack`)
   - PIN interaction component: `entry/src/main/ets/common/components/pinComponent.ets`
   - Business logic: `entry/src/main/ets/model/PinViewModel.ets`, `entry/src/main/ets/model/pinModel.ets`

For example, when protection depends on slot active state, reuse `SimServiceProxy.isSimActive`:
```typescript
    // check whether the current slot is available
    const isActive = SimServiceProxy.isSimActive(slotId);
```

**Scenario 4: Default mobile data selection**

   - Default data-card UI: `entry/src/main/ets/common/components/defaultDataComponent.ets`
   - Write path: `entry/src/main/ets/model/radioServiceProxy.ets` (`setPrimarySlotId`)
   - Control-center scenario: `entry/src/main/ets/uiExtensionAbility/MobileDataChangeExtAbility.ets`

For example, to add a custom pre-check before switching the default mobile data card, extend `setPrimarySlotId()`:
```typescript
    // defaultDataComponent.ets
    setPrimarySlotId(slotId: number) {
      // [Change point] extend a custom pre-check here
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

**Scenario 5: Default dialing card settings**

   - Home entry and result refresh: `entry/src/main/ets/pages/index.ets`
   - Setting dialog and write-back: `entry/src/main/ets/common/components/dialog/selectDefaultVoiceDialog.ets`
   - Telephony wrapper: `entry/src/main/ets/model/simServiceProxy.ets` (`setDefaultVoiceSlotId`)

For example, to add a custom toast after setting the default dialing card succeeds, extend `setDefaultVoiceSlotId`:
```typescript
    // selectDefaultVoiceDialog.ets
    export function setDefaultVoiceSlotId(slotId: number, onSetDefaultVoiceResult: (slotId: number) => void) {
      ...
      SimServiceProxy.setDefaultVoiceSlotId(slotId).then((res: boolean) => {
        // [Change point] extend a custom toast after setting succeeds
        // showCustomToast(slotId);
        onSetDefaultVoiceResult(slotId);
      })
      ...
    }
```

Common modification entries:

| Target | Path |
| ------ | ---- |
| App main entry (UIExtension) | `entry/src/main/ets/MainAbility/MainAbility.ets` |
| App home page | `entry/src/main/ets/pages/index.ets` |
| Edit card info | `entry/src/main/ets/common/components/cardInfomation.ets`, `common/components/dialog/editSimInfoDialog.ets` |
| Enable/Disable SIM | `entry/src/main/ets/model/simServiceProxy.ets`, `common/components/cardInfomation.ets` |
| SIM protection | `entry/src/main/ets/pages/simProtection.ets`, `model/PinViewModel.ets` |
| Default mobile data | `entry/src/main/ets/common/components/defaultDataComponent.ets`, `model/radioServiceProxy.ets` |
| Default dialing card | `entry/src/main/ets/common/components/dialog/selectDefaultVoiceDialog.ets`, `model/simServiceProxy.ets` |
| Control-center mobile data | `entry/src/main/ets/uiExtensionAbility/MobileDataChangeExtAbility.ets` |
| Ability / permission declaration | `entry/src/main/module.json5` |
| Page route registration | `entry/src/main/resources/base/profile/main_pages.json` |

### Developing New Feature Capabilities

Typical use cases: extend interaction on existing SIM management capabilities, add system collaboration entries, or adapt to new device forms.

> **Note**: The project is a single `entry` HAP module. Product entry and Abilities are declared in `entry`. New capabilities are usually extended by product / feature / common layers. Telephony policy changes must also confirm permissions and TelephonyKit APIs.

**Scenario 1: Extend business capabilities**

1. Add TelephonyKit proxy or policy wrappers under `model/`.
2. Add UI and interaction under `common/components/` or `pages/`.
3. If persistence is needed, extend `database/DatabaseHelper.ets` or Settings DataShare collaboration paths.
4. Add corresponding UT / cases under `entry/src/ohosTest`.
5. Configure / confirm Ability entries

The main UIExtension, control-center extension, and backup are already declared in `entry/src/main/module.json5`. When extending capabilities, usually confirm `mainElement`, extension types, and permissions:
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

**Scenario 2: Customize UI**

After business capability and Ability configuration are done, extend `pages/index.ets`, feature components, or control-center pages as described above.

To add a standalone page:

1. Add the page file under `entry/src/main/ets/pages/`;
2. Register it in the `src` array of `entry/src/main/resources/base/profile/main_pages.json`;
3. Launch it via `session.loadContent` in `MainAbility.onSessionCreate`, or via the home-page `NavPathStack`.

## Directory

```text
simcardmanagement
├─AppScope                              # App-level configuration and multi-language resources
│  ├─app.json5                          # bundleName, version, and so on
│  └─resources/                         # Global strings / icons and other resources
├─docs                                  # Docs and architecture figures
│  └─figures/                           # Architecture figures
├─entry                                 # Product layer: app entry and business source
│  └─src/main/
│     ├─ets/
│     │  ├─Application/                 # Product layer: AbilityStage lifecycle entry
│     │  ├─MainAbility/                 # Product layer: MainAbility and SmartDualCardDialogAbility
│     │  ├─pages/                       # Feature layer: pages for card info editing, SIM protection, and default voice card
│     │  ├─uiExtensionAbility/          # Feature layer: default mobile-data switching extension
│     │  ├─model/                       # Feature layer: SIM/Radio business models and Telephony proxies
│     │  ├─insightintents/              # Feature layer: intent execution entry
│     │  ├─common/                      # Common layer: shared components and utilities across features
│     │  │  ├─components/               # Common layer: card info, default data, PIN, dialing card, and SimToolkits components
│     │  │  ├─utils/                    # Constants, Settings listeners, auth utilities, and so on
│     │  │  ├─config/                   # Card-info related configuration data
│     │  │  └─struct/                   # Card-info related data structures
│     │  ├─data/                        # Common layer: Infos, ResponseInfo, and other data structures
│     │  ├─database/                    # Common layer: database
│     │  ├─backup/                      # Common layer: backup/restore
│     │  ├─WorkSchedulerExtension/      # Reporting extension
│     │  └─utils/                       # Common layer: utility classes
│     ├─resources/                      # Module resources, Settings search config, multi-language, and so on
│     └─module.json5                    # Ability and permission declarations
│  └─src/ohosTest/                      # Hypium automated tests
├─hvigor                                # Build tool configuration
├─signature                             # Signing certificates and profile
├─build.sh                              # Pipeline build and HAP rename
├─build-profile.json5                   # Project-level configuration
├─oh-package.json5
├─OAT.xml                               # Open-source compliance audit
├─LICENSE
├─README.md                             # English README
└─README_zh.md                          # Chinese README
```

> Note: This project does not provide `bundle.json`. Module and product build information is defined in `build-profile.json5` and `entry/src/main/module.json5`.

## Constraints

- **Language**: ArkTS
- **Runtime form**: Pre-installed system application (`com.ohos.simcardmanagement`), depends on TelephonyKit (`@ohos.telephony.sim` / `radio` / `data` / `call`) and system privileged permissions; **does not include** RIL / Modem implementation
- **Device types**: Phone and tablet (see `entry/src/main/module.json5`)
- **Signing**: Requires a system signing profile (see `signature/simcardmanagement.p7b`)
- **Permissions**: The following are the main permissions declared in `entry/src/main/module.json5` and used by this project capability chain (`SET_TELEPHONY_STATE` is also declared in extension `permissions`)

  | Permission | Grant mode | Usage |
  | ---------- | ---------- | ----- |
  | ohos.permission.GET_TELEPHONY_STATE | System grant | Query SIM state, default-card state, and call-related state |
  | ohos.permission.SET_TELEPHONY_STATE | System grant | Enable/disable SIM and write default voice/data card |
  | ohos.permission.GET_NETWORK_INFO | User grant | Network-state checks before/after default mobile-data switching |
  | ohos.permission.USE_USER_IDM | User grant | User identity authentication in SIM protection flows |
  | ohos.permission.ACCESS_BIOMETRIC | User grant | Biometric authentication in SIM protection flows |
  | ohos.permission.PRIVACY_WINDOW | System grant | Privacy-window capability for sensitive pages such as SIM protection |
  | ohos.permission.ACCESS_SYSTEM_SETTINGS | System grant | Read system settings (including Settings-search collaboration) |
  | ohos.permission.MANAGE_SETTINGS | System grant | Read/write dual-SIM and mobile-network related settings |
  | ohos.permission.MANAGE_SECURE_SETTINGS | System grant | Read/write security-related settings |
  | ohos.permission.GET_BUNDLE_INFO | System grant | Query linked app bundle information (for example `com.ohos.simtoolkits`) |

- **External dependencies**: Settings (`com.ohos.settings`) embeds the main entry; SceneBoard hosts the control-center extension; the SimToolkits STK jump constant package name is `com.ohos.simtoolkits` (see `SimToolkitsComponent`; the product must keep it aligned with the actual STK app `bundleName`); the Telephony subsystem provides underlying capabilities

## Contributing

Contributions of code and documentation are welcome. For the contribution process, see [Contributing](https://gitcode.com/openharmony/docs/blob/master/zh-cn/contribute/%E5%8F%82%E4%B8%8E%E8%B4%A1%E7%8C%AE.md).

## Related Repositories

[**applications_settings**](https://gitcode.com/openharmony/applications_settings)

[**simtoolkits**](https://gitcode.com/openharmony-sig/applications_simtoolkits.git)
