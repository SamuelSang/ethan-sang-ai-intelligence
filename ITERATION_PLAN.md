# DeviceInspector 迭代方案

> 版本：v1.0 | 更新日期：2026-05-28 | 状态：规划中

---

## 一、短期计划（已完成）

### ✅ 已完成项
- [x] Git 仓库初始化
- [x] Flutter 项目基础架构搭建
- [x] iOS/Android 原生代码实现
- [x] FastAPI 后端基础服务
- [x] 代码质量修复（4个关键错误）

### 🔄 后端启动
```bash
cd /Users/ethan/Desktop/App一元店/DeviceInspector/backend
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

### 🔧 Flutter 调试
```bash
cd /Users/ethan/Desktop/App一元店/DeviceInspector/device_inspector
flutter run
```

---

## 二、中期迭代计划（1个月内）

### Phase 2.1：数据对接（预计1周）

| 功能 | 优先级 | 说明 |
|---|---|---|
| CheckM32 API 接入 | P0 | 替换 mock 数据为真实激活锁查询 |
| 序列号规则库完善 | P1 | 扩充翻新机序列号前缀数据库 |
| 设备型号自动识别 | P1 | 根据序列号/IMEI 自动解析机型 |

**技术任务：**
- 对接 CheckM32.info API（https://checkm32.info/api/check）
- 建立序列号前缀 → 机型/销售地 映射表
- 实现 IMEI 合法性校验算法

---

### Phase 2.2：内购完善（预计1周）

| 功能 | 优先级 | 说明 |
|---|---|---|
| Apple IAP 真实购买验证 | P0 | 服务端 receipt validation |
| Google Play 内购对接 | P0 | Android 端内购逻辑 |
| 购买状态持久化 | P1 | 跨设备同步购买记录 |

**技术任务：**
- 实现 Apple App Store Server API receipt validation
- 实现 Google Play Developer API purchase states
- 设计 localstorage + 云端同步方案

---

### Phase 2.3：报告体系增强（预计1周）

| 功能 | 优先级 | 说明 |
|---|---|---|
| 报告二维码验证页 | P0 | H5 验证页面，支持扫码验证 |
| 报告分享图片生成 | P1 | 一键生成可分享的验机卡片 |
| 报告模板品牌化 | P2 | 支持自定义品牌 Logo |

**技术任务：**
- 实现报告验证 H5 页面（独立 Web 模块）
- 使用 Canvas 或 PDF 生成分享图片
- 报告模板系统设计

---

## 三、长期迭代计划（1-3个月）

### Phase 3.1：数据源扩展

| 功能 | 优先级 | 说明 |
|---|---|---|
| 闲鱼/转转价格数据 | P1 | 爬虫或第三方数据对接 |
| Apple 官方维修记录 | P2 | 对接 Apple GSX 查询 |
| 保修状态查询 | P2 | IMEI 保修查询 API |

---

### Phase 3.2：用户体验优化

| 功能 | 优先级 | 说明 |
|---|---|---|
| 硬件检测引导 | P1 | 屏幕触控、传感器自检流程 |
| AI 外观描述 | P2 | 拍照自动识别外观瑕疵（GPT-4o/Vision） |
| 历史记录云同步 | P2 | 账号体系 + 云端历史 |

---

### Phase 3.3：平台化扩展

| 功能 | 优先级 | 说明 |
|---|---|---|
| iOS App Store 上架 | P0 | Apple Developer 账号 + IAP 配置 |
| Google Play 上架 | P0 | Google Play 开发者账号 |
| 微信小程序版本 | P3 | 轻量版功能，扫码即用 |

---

## 四、技术债务

| 问题 | 优先级 | 说明 |
|---|---|---|
| Android 深色模式适配 | P1 | 部分页面在深色模式下显示异常 |
| iOS 权限引导优化 | P1 | 首次使用时权限申请体验 |
| 测试覆盖率提升 | P2 | 关键功能单元测试 |

---

## 五、商业化里程碑

| 阶段 | 目标 | 时间 |
|---|---|---|
| MVP | 基础验机功能完成，上架应用商店 | 1个月 |
| 增长期 | C端用户破万，B端商家试用 | 2-3个月 |
| 变现期 | 实现月收入目标 | 3-6个月 |

---

## 六、待办事项（TODO）

### 紧急（本周）
- [ ] 启动后端服务并测试 API
- [ ] Flutter 真机/模拟器调试 UI
- [ ] 对接 CheckM32 API

### 次要（下周）
- [ ] 实现 Apple IAP 服务端验证
- [ ] 实现报告验证 H5 页面
- [ ] 扩充序列号规则库

### 后续
- [ ] Google Play 内购对接
- [ ] 价格数据爬虫接入
- [ ] App Store / Google Play 上架

---

## 七、迭代管理

### 分支策略
- `main` — 稳定版本
- `develop` — 开发中版本
- `feature/*` — 新功能开发分支
- `fix/*` — bug 修复分支

### Commit 规范
```
[Type] Subject
- Type: feat / fix / docs / style / refactor / test / chore
- Subject: 简短描述

示例：
[feat] 添加激活锁 API 对接
[fix] 修复 iOS DeepLink 跳转失败问题
[docs] 更新迭代方案文档
```

### 代码审查
- PR 需要至少 1 人 review 通过
- 关键功能（支付、报告签名）需要 2 人 review
- 合并前运行 `flutter analyze` 无 error

---

> 文档更新时间：2026-05-28
> 下次更新时间：迭代启动时