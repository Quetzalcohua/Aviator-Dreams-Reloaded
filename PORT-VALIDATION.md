# 26.1.2 Fabric 移植验证记录

日期：2026-09-27（本机 Asia/Hong_Kong）。此记录只覆盖本地实测，不等于完整游戏功能认证。

## 交付与构建

- 分支：`compat/26.1.2-fabric`；主代理已复核发布 jar 校验、构建日志、实体测试日志及截图。本记录随兼容分支提交，远端状态以 GitHub 为准。
- 上游基线：`753ce87485d966312d4442f970eb69e1636d343c`，`1.21.11` 分支。
- 产物：`fabric/build/libs/aviator_dreams_reloaded-fabric-1.3.3-port.1+26.1.2.jar`。
- SHA256：`536FBA0694427BF8788F143A1327DE1C1445B3F275F3B2269D2BA0038147149C`。
- Java 25.0.1（Microsoft JDK，本机已有 JDK 只读复制到 `.tools/jdk-25`）。未改系统 Java。
- Gradle 9.6.1 / Fabric Loom 1.17.20 / Loader 0.19.5 / Fabric API 0.155.3+26.1.2。
- Aircraft 编译及运行均为正式 `1.5.2+26.1.2`。Maven 下载包与只读复制的正式 jar SHA256 完全一致：
  `4FDC6A0604574DF954721BD4BC8E5771BDE138E45E29B421FF50D4319E04EEC9`。
- `./scripts/build.ps1 -JavaHome ./.tools/jdk-25 -Clean`：**PASS**。最终一次 clean 构建 31 秒，7 个任务（6 executed、1 up-to-date）。
- `./scripts/verify-jar.ps1`：**PASS**。检查 Fabric 入口、精确 Minecraft 版本、最低依赖、Java25 class major=69、LICENSE、9 套实体数据/模型/物品资源及 8 个配方。
- Gradle 的 `test` 为 **NO-SOURCE**，不能称作单元测试通过。GitHub Actions 已通过：run `36293008333`，提交 `53a52d0`，Linux/JDK25 clean 构建、发布包校验及产物上传全部成功。

## 实际移植范围

旧 Architectury/Shadow/remap 构建切换成 26.1.2 的无混淆 Fabric Loom 构建，直接编译 common 源码并打包资源；固定正式前置版本，排除 Aircraft POM 中可选 JEI/REI 开发依赖。元数据声明 Minecraft `=26.1.2`、Java `>=25`、Loader `>=0.19.5`、Fabric API `>=0.155.3`、Aircraft `>=1.5.2`。仅声称测试过固定版本组合，不保证后续版本。

对原有所有 Java 源码先做 javac 实编译，再用正式 Gradle 实编译，未发现需要改写的 addon 方法签名。因而没有为凑“API 修改”而引入无意义 Java 重写。这不是仅放宽版本范围：新的工具链、依赖图、打包和真实客户端均已验证。原实体、渲染器、模型、声音和配方内容保留。

## 测试隔离与证据

全部游戏运行于项目内 `run-smoke/`；测试世界为新建 `PortSmoke-26_1_2` 和 `New World`。原 `.minecraft` 的 jar、库、资源只读复制到项目依赖目录；没有更改原实例、混装模组、配置、账号或存档。使用离线测试名 `PortSmoke`，没有读取账号凭证。

1. 先以手工编译候选验证主菜单、新世界及所有实体；这不是发布包。
2. 换为 Gradle jar 验证主菜单、世界重载及实体。
3. 最终交付哈希的 jar 在**只有三个顶层模组**（本 addon、Aircraft、Fabric API）的环境进入主菜单，并于 11:45 成功创建/进入 `New World`。
4. 桌面键盘输入出现漏字，增加仅本地使用的 `port_smoke_harness`，向玩家连接发送命令、调用正常客户端实体交互入口，并使用 Minecraft 原生截图。它不更改 addon/游戏实现，不打包入发布 jar；测试结果注明辅助方式。
5. 最终哈希在第二个新世界的全实体辅助复测：**PASS**（11:48–11:50，9 次服务器召唤确认、9 张原生截图，DC1/K100 交互上车状态确认；测试实例中 jar 哈希与交付哈希一致）。

本地证据（缓存/截图不默认提交到 Git）：
- `build-clean.log`、`build-second.log`：成功构建；`build-first.log` 保留首次依赖解析失败。
- `.tools/release-main-menu.png`、`.tools/release-fresh-world.png`：最终发布 jar 无 helper 的主菜单/新世界。
- `run-smoke/client-release.stdout.log`：无 helper 新世界加载日志。
- `run-smoke/client-release-entities.stdout.log`：最终哈希的辅助实体复测日志。
- `run-smoke/screenshots/release-*.png`：原生游戏截图。
- `.tools/harness/PortSmoke.java`：本地辅助代码，未加入发布源码集。
- `run-smoke/client-release-reload.stdout.log`、`.tools/release-reloaded.png`：移除 helper 后最终世界再次载入与 DC1 乘坐画面。`run-smoke/mods` 最终仅保留 addon、Aircraft、Fabric API 三个 jar。
- `.tools/release-all-entities.png`：最终交付哈希 9 实体截图汇总。
- 较早轮次：`run-smoke/client-final.stdout.log`、`client-harness.stdout.log`、`.tools/verified-all-entities.png`。

## 功能覆盖矩阵

| 项目 | 结果 | 范围 |
|---|---|---|
| 发布 jar 编译/打包/元数据 | PASS | clean 构建和静态包校验 |
| 无 helper 客户端主菜单 | PASS | 26.1.2 + 指定 Loader/API/Aircraft |
| 无 helper 全新单人世界 | PASS | 最终交付哈希，独立 `New World` |
| 保存并重新载入 | PASS（基本） | 最终交付哈希无 helper 重载 `New World`，DC1 模型/乘坐 HUD 恢复；不代表旧存档升级、燃料/库存持久化或长期完整性 |
| 9 个实体生成/可见模型 | PASS（最终交付哈希） | 每个实体均有单独截图；不等于完整外观无缺陷 |
| DC1、K100 交互上车 | PASS（辅助交互） | 正常客户端 interact 入口；日志确认当前 vehicle 类型 |
| K100 驾驶 | INCONCLUSIVE | KeyMapping 模拟按键后未观察到位移；不能据此认定真实键盘驾驶通过或断言游戏故障 |
| DC1 地面移动、起飞、爬升 | PASS（有界补测） | 创造模式默认配置，通过真实 Space 按键增加油门，完成正常物理链路；详见 CONTROL-VALIDATION.md |
| 其他机型驾驶、转向、降落 | NOT VERIFIED | 不将 DC1 的一次起飞扩大为全部飞机与完整飞行流程通过 |
| 燃料、库存、升级、染色、配方实际合成、音效 | NOT VERIFIED | 仅资源打包/加载，不声称玩法通过 |
| 专用服务器、多玩家 | NOT TESTED | 单人集成服务器不等于专服/联机测试 |
| GitHub CI/分支 | PASS | 兼容分支已推送，run 36293008333 成功；未创建 Release |

实体清单（命名空间均为 `aviator_dream`）：
`douglas_dc1`、`douglas_dc2`、`douglas_c47`、`lockheed_l1049g`、`test`、`dehavilland_dh106`、`fokker_fviib3m`、`fokker_fviia`、`toyota_stout_k100`。

## 已知警告与限制

- 原始 bbmodel 资源加载时有 **1833 条 Non-quad face** 警告：test 1586、K100 85、L1049G 38、FVIIB3M 25、C47 24、DH106/DC1/DC2 各22、FVIIA 9。模型可见且未导致本次生成/渲染崩溃，但未修复或保证被忽略面的外观；需要后续模型质量验收。
- 最后一轮保存后重载出现一条 `Received passengers for unknown entity` 警告；随后 DC1 模型及乘坐 HUD 可见，未崩溃。尚未定位此警告来源，不声称乘客同步/多人同步完全通过。
- 离线 access token 导致 user properties/Realms 认证错误；未测试或承诺在线认证、Realms。
- 最初手工启动工作目录设在仓库根，Aircraft 相对 `./config` 路径产生配置 FileNotFound；将工作目录改为独立 `run-smoke` 后不再出现。它不是 addon API 崩溃。
- 第一次 Gradle 失败为 Aircraft Maven POM 引入可选 JEI/REI 的解析问题，已针对性排除；未改用 SNAPSHOT 前置。
- 上游 LICENSE/元数据为 GPLv3，而原 README 写 CC0（排除纹理/bbmodel），存在上游许可表述不一致。原文、作者及 LICENSE 均保留，移植不擅自重新授权。发布前由主代理决定是否向原作者进一步澄清。
