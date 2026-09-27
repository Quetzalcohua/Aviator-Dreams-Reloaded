# DC1 控制链路补充验收

2026-09-27 11:59:38–12:11:20，约12分钟，Asia/Hong_Kong。
基础提交：主代理已推送 53a52d0。补测未修改产品源码，产品 jar SHA256 未变：
536FBA0694427BF8788F143A1327DE1C1445B3F275F3B2269D2BA0038147149C

## 原因审查

对正式 Aircraft 1.5.2+26.1.2 的 javap 字节码核对：
- EngineVehicle.getFuelUtilization：burnFuelInCreative=false 且驾驶员为创造玩家时返回1；测试配置确为false。
- VehicleEntity.canTurnOnEngine：控制乘客为 Player 即可，并没有必须先按一个独立点火键的条件。
- VehicleEntity 的正常输入链路从 KeyBindings 读取左右、上下及推/拉轴，调用 setInputs；飞机用 push/pull 而不是 forward/backward 那两个对象。
- AirplaneEntity.updateController：上下轴改变发动机目标，每tick增加0.1*movementY并钳制到0..1；默认 Space=up，左Shift=down。W/S为推/拉（以及低油门地面推行相关输入），不能把W当成增加飞机油门键。
- addon DC1 的发动机响应速度为160/200，不能期待发动机功率瞬间满值。
- 旧辅助脚本只做过一次 KeyMapping.setDown，没有对应物理按键事件，也没有记录每tick是否仍按下、第一乘客/驾驶席及燃料和发动机状态。它不是可靠的控制失败证据。
- **不能追溯性断言前轮K100无位移的唯一根因**：K100本轮未重测。可以排除“所有载具的26.1.2控制API失效”这一泛化结论，且本轮DC1明确不是缺燃料/坐错驾驶席。

本地审查输出：control-vehicle.txt、control-engine.txt、control-multikey.txt、control-client.txt、control-input.txt。

## 实际测试方法

沿用独立 run-smoke / New World 存档内已乘坐的DC1。加载最终发布jar、正式Aircraft、Fabric API，增加本地观测helper，每秒只读记录：位置、速度、onGround、发动机目标/实际功率、燃料利用率、驾驶席是否玩家、本地控制权限、按键状态、当前Screen。

本轮没有 smoke-queue.txt，日志中 SMOKE execute 命令数量为0。未调用teleport、setPos、setEngineTarget或setDeltaMovement；观测helper未合成KeyMapping输入。唯一操作是确认测试窗口前台后，经Windows keybd_event真实按住Space两秒并释放，后续没有按S，没有人工改坐标或直接操纵物理量。

## 可复核结果（日志本机时间）

| 时间 | 关键观测 |
|---|---|
|12:08:07|pos≈(0.5017,-60,0.5017)，ground=true，target=0，power=0，fuelUse=1，pilotSelf=true，localAuthority=true|
|12:08:08|up=true，target=0.8000001，power=0.0220553|
|12:08:09|up=true，target=1，power=0.13675046，z≈0.558开始移动|
|12:08:16|按键已释放，target仍为1，power≈0.6411，z≈37.55，ground=true|
|12:08:17|ground=false，y≈-59.8139，z≈51.8027，垂直速度≈0.02222|
|12:08:23|ground=false，y≈-45.9801，z≈152.3671，垂直速度≈0.15886，power≈0.85081|

结论：**DC1在创造模式、默认配置、超平坦世界的正常输入→油门→发动机→地面移动→离地爬升链路通过一次真实客户端实测**。本次默认机身姿态已足以离地，未测试S键抬头。
不扩大为：K100驾驶通过、所有飞机通过、完整操纵/转弯/降落通过、生存燃料消耗通过。

## 证据与清理

- run-smoke/client-control.stdout.log：完整运行及CONTROL遥测，含正常关闭保存记录。
- .tools/control-telemetry.txt：逐秒遥测摘录。
- .tools/control-before.png / control-after-throttle.png：操作前、自然离地后截图。
- .tools/harness/PortSmoke.java：本地观测helper源码；本轮仅新增只读日志，无发布源码修改。
- 测试客户端已于12:11正常保存关闭；helper已移出run-smoke/mods。
- run-smoke/mods最终仍仅三个发布/正式依赖jar。
- **New World测试存档最后保存在飞行中，油门仍为1**，不要把它误认为落地后的干净状态；它是一次性测试存档，原实例未动。

## 人工复现建议

1. 使用独立创造超平坦世界、同版本三项模组；默认burnFuelInCreative=false。生存模式请先在飞机燃料槽放入接受的燃料，不把创造豁免当作燃料系统测试。
2. 放置DC1，正常交互进入第一驾驶席，确保无聊天/菜单并保持窗口焦点；先检查按键绑定未被改写。
3. 按住Space约1–2秒使油门表上升，松开后等待约10秒让发动机逐步增功。
4. 在开阔跑道观察前进和离地；本次无需S即可自然离地。S/W对应抬/压机头的行为需另行人工受控验收。
5. 左Shift按上游逻辑降低油门并在地面制动；R为下机。不要将这两项解释为本轮已测试的安全着陆操作。
