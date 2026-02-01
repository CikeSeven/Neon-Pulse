# 霓虹射线 - 开发技能树 (SKILL)

## 项目概述

**项目名称**：霓虹射线 (Neon Ray)
**引擎版本**：Godot 4.x
**当前状态**：原型开发阶段

---

## 美术风格规范

**风格定位**：霓虹赛博朋克 (Neon Cyberpunk)

### 视觉核心要素

| 要素 | 说明 |
|------|------|
| 整体风格 | 赛博朋克霓虹美学，炫酷科幻感 |
| 色彩基调 | 深色背景 + 高饱和霓虹色 |
| 光晕效果 | 强烈 Glow，所有元素带发光边缘 |
| 粒子特效 | 大量粒子：拖尾、爆炸、火花、能量波 |
| 动态反馈 | 屏幕震动、闪烁、脉冲动画 |

### 资源使用原则

| 类型 | 使用方式 | 说明 |
|------|----------|------|
| 场景素材 | Godot内置节点 | 不使用外部图片资源 |
| 粒子效果 | CPUParticles2D / GPUParticles2D | 大量使用 |
| 光效 | WorldEnvironment Glow + PointLight2D | 必须开启 |
| 着色器 | 自定义Shader | 实现特殊视觉效果 |
| UI图标 | 可使用外部资源 | 武器/道具/天赋图标 |
| 字体 | 可使用外部资源 | 霓虹/科幻风格字体 |

### 碰撞层规范

| 层级 | 名称 | 用途 |
|------|------|------|
| Layer 1 | Environment | 环境/障碍物 |
| Layer 2 | Player | 玩家角色 |
| Layer 3 | Enemy | 敌人 |
| Layer 4 | PlayerHurtbox | 玩家受伤区域 |
| Layer 5 | PlayerHitbox | 玩家攻击区域 |
| Layer 6 | EnemyHurtbox | 敌人受伤区域 |
| Layer 7 | EnemyHitbox | 敌人攻击区域 |

### Hitbox/Hurtbox 设置规范

**重要注意事项**：
- **Hitbox (攻击判定)**：只需设置 `collision_mask`，`collision_layer` 设为 0
- **Hurtbox (受伤判定)**：只需设置 `collision_layer`，`collision_mask` 设为 0

**配置规则**：
```
玩家:
  Hitbox:  layer = 0, mask = 6 (EnemyHurtbox)   # 攻击敌人
  Hurtbox: layer = 4, mask = 0                  # 被敌人攻击

敌人:
  Hitbox:  layer = 0, mask = 4 (PlayerHurtbox)  # 攻击玩家
  Hurtbox: layer = 6, mask = 0                  # 被玩家攻击

敌人飞行物 (Projectile):
  layer = 0, mask = 4 (PlayerHurtbox)           # 只检测玩家受伤区域
```

**原理**：Hitbox 主动检测 Hurtbox，所以 Hitbox 的 mask 指向对方的 Hurtbox 层。

### 粒子效果规范

**重要注意事项**：
- 粒子不要突然消失，要使用 `scale_amount_curve` 让粒子由大到小慢慢消散
- 推荐曲线：起始值 1.0 → 结束值 0.0，使用 EASE_IN 或线性过渡
- 死亡爆炸粒子生命周期建议 0.6-1.0 秒
- 受击粒子生命周期建议 0.3-0.5 秒

**Curve 配置示例**：
```gdscript
var curve = Curve.new()
curve.add_point(Vector2(0.0, 1.0))  # 开始时满尺寸
curve.add_point(Vector2(1.0, 0.0))  # 结束时缩小到0
particles.scale_amount_curve = curve
```

### 粒子效果清单

| 场景 | 粒子类型 | 说明 |
|------|----------|------|
| 玩家移动 | 霓虹拖尾 | 青色能量尾迹 |
| 子弹飞行 | 能量尾迹 | 发光弹道轨迹 |
| 敌人受击 | 火花飞溅 | 短暂闪烁粒子 |
| 敌人死亡 | 爆炸碎片 | 大量碎片+能量消散 |
| 升级/拾取 | 光环扩散 | 圆形扩散波 |
| 背景装饰 | 漂浮尘埃 | 缓慢飘动的光点 |
| 换道移动 | 冲击波 | 短暂的线性粒子 |
| 暴击命中 | 闪光爆发 | 白色闪光+震动 |

### 颜色规范

| 元素 | 颜色 | 色值 |
|------|------|------|
| 背景 | 深空黑 | #050510 |
| 玩家 | 电光蓝 | #00f0ff |
| 敌人(被动) | 洋红 | #ff00aa |
| 敌人(冲撞) | 烈焰橙 | #ff6600 |
| 敌人(射击) | 紫罗兰 | #aa00ff |
| 敌人(追踪) | 毒液绿 | #00ff66 |
| 子弹(玩家) | 荧光黄 | #ffff00 |
| 子弹(敌人) | 血红 | #ff0033 |
| 轨道线 | 霓虹紫 | #cc00ff |
| 金币 | 金光 | #ffcc00 |
| 经验 | 能量蓝 | #00aaff |
| 精英怪 | 皇金 | #ffd700 |
| BOSS | 血腥红 | #ff0000 |

---

## 已实现功能 ✅

### 玩家系统
- [x] 玩家角色场景 (player.tscn)
- [x] 三轨道移动系统 (上/下键切换)
- [x] 横向微调移动 (左/右键)
- [x] 换道Tween动画 (0.3秒)
- [x] 霓虹拖尾特效 (NeonTrail)
- [x] 撞线爆炸特效 (ImpactBurst)
- [x] 受伤判定区域 (Hurtbox)

### 武器系统
- [x] 武器基类 (weapon.gd)
- [x] 武器管理器 (weapon_manager.gd)
- [x] 子弹基类 (bullet.gd)
- [x] 子弹拖尾效果 (bullet_trail.gd)
- [x] Neon AK 武器 (neon_ak.tscn)
- [x] 激光枪 (laser_gun.tscn)
- [x] 自动射击机制
- [x] 武器环绕排列

### 敌人系统
- [x] 敌人基类 (enemy.gd)
- [x] 敌人生成器 (enemy_spawner.gd)
- [x] 基础敌人场景 (enemy.tscn)
- [x] 霓虹三角敌人 (neon_triangle.tscn)
- [x] 向左移动AI
- [x] 受击闪烁特效
- [x] 屏幕外自动销毁
- [x] 冲撞型敌人 (charger.gd/charger.tscn)
  - [x] 同轨道探测 (检测范围600px)
  - [x] 蓄力后摇 (0.8s闪烁+粒子)
  - [x] 高速冲撞 (800速度+拖尾)
  - [x] 冲撞免疫击退 (Charging state immune)
- [x] 敌人血条系统 (script/enemy/enemy.gd)
  - [x] 敌人头顶跟随血条 (ProgressBar + ColorRect)
  - [x] 实时血量更新
  - [x] 低血量变色提示 (HP<30% 变红)
- [x] 敌人击退系统 (Hitbox.knockback, Bullet.knockback)
- [x] 敌人受击效果优化 (仅水平击退)

### 战斗系统
- [x] 攻击判定 (Hitbox.gd)
- [x] 受伤判定 (Hurtbox.gd)
- [x] 子弹穿透机制

### 全局系统
- [x] 全局变量管理 (Global.gd)
- [x] 轨道Y坐标配置
- [x] 屏幕边界限制

### 场景
- [x] 主世界场景 (world.tscn)
- [x] 3条轨道线 (Line2D)
- [x] 世界环境光晕 (WorldEnvironment)
- [x] 背景尘埃粒子 (BackgroundDust)
- [x] 摄像机 (Camera2D)

---

## 待实现功能 📋

### 第一阶段：核心玩法完善

#### 玩家系统
- [x] 玩家生命值系统
- [x] 玩家受伤逻辑 (扣血 = 怪物HP × 0.5 + 10)
- [x] 受伤无敌帧
- [x] 受伤视觉反馈 (屏幕红闪)
- [x] 死亡处理

#### 敌人系统
- [x] 冲撞型敌人 (Charger)
  - [x] 橙色箭头几何体外观
  - [x] 同轨道检测 (探测范围600px)
  - [x] 后摇蓄力 (0.8s闪烁警告 + 橙色蓄力粒子)
  - [x] 高速冲刺AI (800速度 + 火焰拖尾)
  - [x] 冲撞免疫击退
- [x] 敌人血条系统
  - [x] 实时显示当前HP/MAXHP
  - [x] 跟随敌人移动
  - [x] 低血量变色提示
- [ ] 射击型敌人 (Shooter)
  - [ ] 锁定玩家
  - [ ] 发射子弹
- [ ] 敌人子弹场景 (enemy_bullet.tscn)

#### UI系统
- [ ] 主HUD界面
  - [ ] 玩家HP条
  - [ ] 金币显示
  - [ ] 关卡显示
  - [ ] 倒计时
- [ ] 怪物血条 (跟随显示)
- [ ] 伤害数字飘字
- [ ] 暂停菜单

#### 经济系统
- [ ] 金币掉落物 (coin.tscn)
- [ ] 经验球掉落物 (exp_orb.tscn)
- [ ] 掉落物拾取逻辑
- [ ] 金币计数

#### 等级系统
- [ ] 经验值累计
- [ ] 升级判定
- [ ] 升级特效

---

### 第二阶段：内容扩展

#### 武器系统扩展
- [ ] 霰弹枪 (Shotgun)
  - [ ] 扇形散射
  - [ ] 多弹丸发射
- [ ] 火箭筒 (Rocket Launcher)
  - [ ] 追踪火箭
  - [ ] 爆炸范围伤害
- [ ] 光束炮 (Beam Cannon)
  - [ ] 持续激光
- [ ] 武器升级系统
  - [ ] 伤害成长 (+15%/级)
  - [ ] 射速成长 (+5%/级)
  - [ ] 穿透成长 (+1/3级)

#### 敌人系统扩展
- [ ] 追踪型敌人 (Tracker)
  - [ ] 跨轨道追踪
  - [ ] 斜向移动
- [ ] 精英怪
  - [ ] 属性倍率 (HP×2, 伤害×1.5)
  - [ ] 金色光晕标记
  - [ ] 必掉稀有道具

#### 商店系统
- [ ] 商店界面 (shop.tscn)
- [ ] 武器购买
- [ ] 武器升级
- [ ] 消耗品购买
  - [ ] 血包
  - [ ] 护盾
  - [ ] 弹药

#### 天赋系统
- [ ] 天赋树界面 (talent_tree.tscn)
- [ ] 战斗系天赋
  - [ ] 枪械精通 (伤害+10%)
  - [ ] 快速射击 (射速+15%)
  - [ ] 致命一击 (暴击率+5%)
  - [ ] 暴击强化 (暴伤+50%)
- [ ] 生存系天赋
  - [ ] 生命强化 (HP+20)
  - [ ] 快速恢复 (回血)
  - [ ] 护甲护盾 (减伤10%)
  - [ ] 闪避精通 (闪避率+5%)
- [ ] 资源系天赋
  - [ ] 贪婪之手 (金币+15%)
  - [ ] 经验增幅 (经验+20%)
  - [ ] 精英猎手 (对精英+15%)
  - [ ] 掉落强化 (稀有率+10%)
- [ ] 特殊系天赋
  - [ ] 双重火力 (武器栏+1)
  - [ ] 武器大师 (武器等级+1)
  - [ ] 不死之魂 (濒死无敌)

#### 关卡系统
- [ ] 关卡管理器 (level_manager.gd)
- [ ] 2分钟倒计时
- [ ] 难度曲线 (1.10^关卡)
- [ ] 关卡结算界面 (level_complete.tscn)

---

### 第三阶段：打磨优化

#### BOSS系统
- [ ] BOSS基类 (boss.gd)
- [ ] 基础BOSS
  - [ ] 多阶段攻击
  - [ ] 高血量 (500+)
- [ ] 进阶BOSS
  - [ ] 三阶段攻击模式
  - [ ] 特殊技能

#### 掉落系统完善
- [ ] 血包掉落 (health_pack.tscn)
- [ ] 武器碎片掉落
- [ ] 稀有度系统
  - [ ] 常见 (白色, 60%)
  - [ ] 稀有 (蓝色, 25%)
  - [ ] 史诗 (紫色, 10%)
  - [ ] 传说 (金色, 5%)

#### 存档系统
- [ ] 存档管理器 (save_manager.gd)
- [ ] 玩家数据存档
- [ ] 武器数据存档
- [ ] 进度数据存档
- [ ] 设置数据存档

#### 音效系统
- [ ] 射击音效
- [ ] 受伤音效
- [ ] 升级音效
- [ ] 背景音乐

#### 视觉优化
- [ ] 屏幕震动
- [ ] 更多粒子特效
- [ ] 爆炸特效

---

## 文件结构规划

```
res://
├── scene/
│   ├── ui/
│   │   ├── main_ui.tscn          [待创建]
│   │   ├── pause_menu.tscn       [待创建]
│   │   ├── shop.tscn             [待创建]
│   │   ├── talent_tree.tscn      [待创建]
│   │   └── level_complete.tscn   [待创建]
│   ├── enemy/
│   │   ├── enemy.tscn            [已存在]
│   │   ├── neon_triangle.tscn    [已存在]
│   │   ├── charger.tscn          [已创建]
│   │   ├── shooter.tscn          [待创建]
│   │   ├── tracker.tscn          [待创建]
│   │   └── boss.tscn             [待创建]
│   ├── bullet/
│   │   ├── bullet.tscn           [已存在]
│   │   ├── ak_bullet.tscn        [已存在]
│   │   └── enemy_bullet.tscn     [待创建]
│   ├── weapon/
│   │   ├── weapon.tscn           [已存在]
│   │   ├── weapon_manager.tscn   [已存在]
│   │   ├── laser_gun.tscn        [已存在]
│   │   ├── neon_ak.tscn          [已存在]
│   │   ├── shotgun.tscn          [待创建]
│   │   └── rocket_launcher.tscn  [待创建]
│   ├── pickup/
│   │   ├── coin.tscn             [待创建]
│   │   ├── exp_orb.tscn          [待创建]
│   │   └── health_pack.tscn      [待创建]
│   ├── player.tscn               [已存在]
│   ├── world.tscn                [已存在]
│   └── enemy_spawner.tscn        [已存在]
│
├── script/
│   ├── player.gd                 [已存在]
│   ├── Global.gd                 [已存在]
│   ├── Hitbox.gd                 [已存在]
│   ├── Hurtbox.gd                [已存在]
│   ├── color_rect.gd             [已存在]
│   ├── weapon/
│   │   ├── weapon.gd             [已存在]
│   │   ├── weapon_manager.gd     [已存在]
│   │   ├── bullet.gd             [已存在]
│   │   └── bullet_trail.gd       [已存在]
│   ├── enemy/
│   │   ├── enemy.gd              [已存在]
│   │   ├── enemy_spawner.gd      [已存在]
│   │   ├── charger.gd            [已创建]
│   │   ├── shooter.gd            [待创建]
│   │   ├── tracker.gd            [待创建]
│   │   └── boss.gd               [待创建]
│   ├── ui/
│   │   ├── ui_manager.gd         [待创建]
│   │   ├── main_hud.gd           [待创建]
│   │   ├── shop.gd               [待创建]
│   │   ├── talent_tree.gd        [待创建]
│   │   └── level_complete.gd     [待创建]
│   ├── pickup/
│   │   ├── coin.gd               [待创建]
│   │   ├── exp_orb.gd            [待创建]
│   │   └── health_pack.gd        [待创建]
│   ├── game/
│   │   ├── level_manager.gd      [待创建]
│   │   └── difficulty_manager.gd [待创建]
│   └── save/
│       └── save_manager.gd       [待创建]
│
└── docs/
    ├── 01-游戏总览.md            [已存在]
    ├── 02-核心玩法.md            [已存在]
    ├── 03-武器系统.md            [已存在]
    ├── 04-敌人生成与战斗系统.md  [已存在]
    ├── 05-进度系统.md            [已存在]
    └── 06-UI与数据.md            [已存在]
```

---

## 开发优先级

### P0 - 紧急 (核心玩法)
1. 玩家生命值系统
2. 玩家受伤逻辑
3. 怪物血条UI
4. 玩家HP条UI
5. 金币/经验掉落
6. 冲撞型敌人

### P1 - 高优先级 (内容扩展)
1. 射击型敌人
2. 商店系统
3. 关卡管理器
4. 关卡结算界面

### P2 - 中优先级 (系统完善)
1. 天赋系统
2. 武器升级
3. 新武器 (霰弹枪、火箭筒)
4. 追踪型敌人
5. 精英怪

### P3 - 低优先级 (打磨)
1. BOSS系统
2. 存档系统
3. 音效系统
4. 成就系统

---

## 进度统计

| 类别 | 已完成 | 待完成 | 完成率 |
|------|--------|--------|--------|
| 玩家系统 | 7 | 5 | 58% |
| 武器系统 | 8 | 8 | 50% |
| 敌人系统 | 12 | 6 | 67% |
| UI系统 | 0 | 9 | 0% |
| 经济系统 | 0 | 4 | 0% |
| 等级系统 | 0 | 3 | 0% |
| 天赋系统 | 0 | 17 | 0% |
| 关卡系统 | 0 | 4 | 0% |
| 存档系统 | 0 | 5 | 0% |
| **总计** | **27** | **63** | **30%** |

---

*文档版本：1.0*
*最后更新：2026年2月1日*
