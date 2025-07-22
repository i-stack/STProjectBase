# AI易数助手技术开发文档

## 一、项目概述

### 1.1 项目背景
AI易数助手是一款基于AI技术和易经数理（易数）的微信小程序，通过生动动画和通俗解读，提供个性化的易经占卜、运势分析和决策辅助服务。目标是降低易经的学习门槛，吸引年轻用户，通过微信生态实现流量增长。

### 1.2 技术目标
- **前端**：使用Vue.js结合微信小程序IDE，开发交互性强、动画流畅的用户界面
- **后端**：使用Node.js提供API服务，处理AI算法、数据存储和业务逻辑
- **数据库**：使用MySQL存储易经数据、用户数据和占卜记录
- **动画**：使用Lottie和Canvas实现卦象、运势、场景化动画
- **AI集成**：调用xAI Grok 3 API或开源NLP模型，生成通俗易懂的解读

### 1.3 技术栈
- **前端**：Vue.js（结合Taro或mpvue框架适配微信小程序）、微信小程序IDE、Lottie、Canvas
- **后端**：Node.js（Express框架）
- **数据库**：MySQL
- **AI服务**：xAI Grok 3 API（https://x.ai/api）或Hugging Face开源NLP模型
- **部署**：阿里云/腾讯云（ECS+MySQL）
- **其他工具**：Git（版本控制）、Docker（可选，容器化部署）

## 二、系统架构

### 2.1 整体架构
```
用户 -> 微信小程序（Vue.js + 微信小程序IDE）
       ↕（HTTPS API）
后端（Node.js + Express） -> AI服务（Grok 3 API / 开源NLP）
       ↕（JDBC）
数据库（MySQL）
```

- **前端**：负责界面展示、动画渲染、用户交互，调用后端API获取占卜结果
- **后端**：处理业务逻辑（如卦象计算）、AI文本生成、数据存储
- **数据库**：存储易经数据（卦辞、爻辞）、用户数据（ID、记录）、动画资源元数据
- **AI服务**：生成通俗解读，优化易经算法结果

### 2.2 模块划分

**前端模块：**
- 用户界面（UI）：首页、占卜页、运势页、知识库
- 动画模块：卦象生成、运势展示、场景化动画
- 交互模块：用户输入、点击、分享功能

**后端模块：**
- API服务：提供占卜、运势、用户管理接口
- 易经算法：实现梅花易数、六爻算法
- AI处理：调用AI模型生成解读

**数据库模块：**
- 易经数据表：存储卦辞、爻辞、解读模板
- 用户数据表：存储用户ID、占卜记录、积分

**AI服务模块：**
- 文本生成：将卦象结果转化为通俗建议
- 场景化优化：根据用户输入生成生活化建议

## 三、数据库设计（MySQL）

### 3.1 数据库结构
数据库名称：`easy_number_db`

**表1：gossips（卦象表）**
存储八卦、六十四卦的基本信息。
```sql
CREATE TABLE gossips (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL, -- 卦名（如"乾""坎"）
  code VARCHAR(10) NOT NULL, -- 卦象编码（如"111111"表示乾卦）
  description TEXT, -- 卦辞描述
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**表2：yao（爻辞表）**
存储每卦的爻辞和解读。
```sql
CREATE TABLE yao (
  id INT AUTO_INCREMENT PRIMARY KEY,
  gossip_id INT NOT NULL, -- 关联卦象ID
  yao_index INT NOT NULL, -- 爻位置（1-6）
  description TEXT, -- 爻辞描述
  interpretation TEXT, -- 通俗解读
  FOREIGN KEY (gossip_id) REFERENCES gossips(id)
);
```

**表3：users（用户表）**
存储用户信息。
```sql
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  wechat_id VARCHAR(100) NOT NULL UNIQUE, -- 微信用户ID
  nickname VARCHAR(100), -- 用户昵称
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**表4：divinations（占卜记录表）**
存储用户占卜记录。
```sql
CREATE TABLE divinations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL, -- 关联用户ID
  gossip_id INT NOT NULL, -- 关联卦象ID
  question TEXT, -- 用户问题
  result TEXT, -- AI生成解读
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (gossip_id) REFERENCES gossips(id)
);
```

**表5：points（积分表）**
存储用户积分。
```sql
CREATE TABLE points (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL, -- 关联用户ID
  points INT DEFAULT 0, -- 积分数
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**表6：animations（动画资源表）**
存储动画元数据。
```sql
CREATE TABLE animations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  type VARCHAR(50) NOT NULL, -- 动画类型（如"gossip""scene"）
  gossip_id INT, -- 关联卦象ID（可选）
  file_url VARCHAR(255) NOT NULL, -- 动画文件URL（如Lottie JSON）
  description TEXT, -- 动画描述
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (gossip_id) REFERENCES gossips(id)
);
```

### 3.2 数据初始化
- **gossips/yao**：预加载《周易》六十四卦及爻辞，参考《梅花易数》整理通俗解读
- **animations**：存储Lottie动画JSON文件的云存储URL（如阿里云OSS）
- **users/divinations/points**：动态生成，随用户使用增加

## 四、后端开发（Node.js + Express）

### 4.1 技术选型
- **框架**：Express（轻量、灵活，适合API开发）
- **数据库连接**：mysql2（Node.js的MySQL驱动）
- **AI服务**：axios（调用Grok 3 API或Hugging Face API）
- **算法**：自定义梅花易数/六爻算法模块
- **部署**：PM2（进程管理）、Nginx（反向代理）

### 4.2 API设计

**1. 占卜接口**
```
URL：/api/divination
Method：POST
Request：{
  "wechat_id": "wx123456",
  "question": "今天适合面试吗？",
  "scene": "career"
}

Response：{
  "success": true,
  "data": {
    "gossip": {
      "name": "震",
      "code": "100100"
    },
    "interpretation": "积极行动，机会较多，建议准备充分",
    "animation_url": "https://oss.example.com/animations/zhen.json"
  }
}
```

**逻辑：**
- 接收用户输入，基于梅花易数生成卦象
- 调用AI模型生成通俗解读
- 查询animations表，返回对应动画URL
- 存储占卜记录到divinations表

**2. 每日运势接口**
```
URL：/api/daily-fortune
Method：GET
Request：?wechat_id=wx123456
Response：{
  "success": true,
  "data": {
    "gossip": {
      "name": "离",
      "code": "101101"
    },
    "fortune": "热情高涨，适合创意工作",
    "animation_url": "https://oss.example.com/animations/li.json"
  }
}
```

**3. 用户积分接口**
```
URL：/api/points
Method：POST
Request：{
  "wechat_id": "wx123456",
  "action": "sign_in"
}

Response：{
  "success": true,
  "data": {
    "points": 10
  }
}
```

**4. 知识库接口**
```
URL：/api/knowledge
Method：GET
Request：?type=gossip&name=乾
Response：{
  "success": true,
  "data": {
    "name": "乾",
    "description": "天行健，君子自强不息",
    "interpretation": "象征刚健，适合制定目标",
    "animation_url": "https://oss.example.com/animations/qian.json"
  }
}
```

### 4.3 易经算法

**梅花易数：**
- 输入：用户问题、当前时间
- 逻辑：基于时间生成主卦和变卦，计算爻位
- 输出：卦象编码（如"111111"）和爻辞

**六爻算法：**
- 输入：用户随机输入（如点击次数）或时间
- 逻辑：生成六爻（0/1表示阴/阳），形成主卦和变卦
- 输出：卦象和变化爻

**代码示例（Node.js）：**
```javascript
const generateGossip = (input) => {
  // 基于时间或输入生成卦象
  const time = new Date().getTime();
  const seed = input ? input.length : time;
  const gossipCode = Array(6).fill(0).map(() => (seed % 2) ? 1 : 0);
  return gossipCode.join('');
};
```

### 4.4 AI集成

**Grok 3 API（首选）：**
- 调用：POST https://api.x.ai/grok3
- 输入：卦象结果、用户问题、场景
- 输出：通俗解读（如"积极行动，注意细节"）

**备选：Hugging Face Transformers（开源NLP模型）**

**代码示例：**
```javascript
const axios = require('axios');
async function generateInterpretation(gossip, question) {
  const response = await axios.post('https://api.x.ai/grok3', {
    text: `卦象: ${gossip.name}, 用户问题: ${question}, 请生成通俗建议。`
  });
  return response.data.interpretation;
}
```

## 五、前端开发（Vue.js + 微信小程序IDE）

### 5.1 技术选型
- **框架**：Vue.js（通过Taro或mpvue适配微信小程序）
- **开发工具**：微信小程序IDE（调试、打包、上线）
- **动画库**：
  - Lottie：用于轻量级矢量动画（如卦象生成）
  - Canvas：用于动态八卦图和交互效果
- **UI库**：Vant Weapp（轻量、适配小程序）

### 5.2 页面结构

**首页：**
- 功能：展示每日运势、快速占卜入口、知识库入口
- 动画：背景循环播放八卦动画

**占卜页：**
- 功能：用户输入问题，展示卦象生成动画和解读
- 动画：Lottie展示卦爻逐一生成（如雷电效果表示震卦）

**运势页：**
- 功能：展示每日/场景化运势
- 动画：Canvas绘制场景化图标（如金币表示财运）

**知识库页：**
- 功能：展示八卦、爻辞、梅花易数教程
- 动画：短视频+交互式起卦模拟

**个人中心：**
- 功能：查看历史记录、积分、分享设置
- 动画：签到奖励动画（如金币掉落）

### 5.3 动画实现

**Lottie动画：**
- 工具：Adobe After Effects导出JSON，Lottie-weixin渲染
- 示例：乾卦动画（六条阳爻逐一出现，伴随光晕效果）

**代码示例：**
```vue
<template>
  <view>
    <lottie-player path="/animations/qian.json" />
  </view>
</template>
<script>
import Lottie from 'lottie-weixin';
export default {
  mounted() {
    Lottie.loadAnimation({
      container: this.$refs.lottie,
      path: '/animations/qian.json',
      renderer: 'canvas'
    });
  }
};
</script>
```

**Canvas动画：**
用于动态八卦图（如六爻逐一绘制）

**代码示例：**
```javascript
const ctx = wx.createCanvasContext('gossipCanvas');
function drawGossip(code) {
  code.split('').forEach((yao, index) => {
    ctx.beginPath();
    ctx.moveTo(10, 20 + index * 20);
    ctx.lineTo(100, 20 + index * 20);
    if (yao === '0') ctx.strokeRect(50, 15 + index * 20, 10, 10); // 阴爻
    ctx.stroke();
  });
  ctx.draw();
}
```

### 5.4 微信小程序IDE开发流程

**初始化项目：**
- 使用微信小程序IDE创建项目，集成Taro/mpvue
- 配置Vue.js环境，引入Vant Weapp和Lottie-weixin

**开发页面：**
- 使用Vue组件化开发，拆分页面为Home、Divination、Fortune、Knowledge、Profile
- 实现动画组件（如GossipAnimation.vue）

**调试：**
- 使用IDE模拟器测试动画性能和API调用
- 确保低配手机（如Android 4GB RAM）流畅运行

**打包上线：**
- 使用IDE提交审核，优化加载时间（<2秒）

## 六、开发计划

### 6.1 时间表
- **需求分析（1周）**：整理易经算法、动画需求
- **原型设计（2周）**：设计UI/UX、动画原型（Figma）
- **技术开发（8周）**：
  - 前端（3周）：页面开发、动画实现
  - 后端（3周）：API开发、AI集成
  - 动画设计（2周）：制作Lottie动画和Canvas效果
- **测试优化（2周）**：内测、性能优化
- **上线（1周）**：提交微信审核

### 6.2 人员分工
- **前端开发（1人）**：Vue.js页面、动画实现
- **后端开发（1人）**：Node.js API、MySQL管理
- **动画设计师（1人）**：Lottie动画制作
- **项目经理（1人）**：协调进度、需求沟通

## 七、性能优化

### 前端：
- **动画优化**：Lottie文件<100KB，Canvas帧率>30fps
- **懒加载**：动态加载动画资源，减少首次加载时间

### 后端：
- **API响应**：<500ms，使用Redis缓存热点数据
- **数据库索引**：为gossips、divinations表添加索引

### 小程序：
- **包大小**：<2MB，优化图片和动画资源
- **兼容性**：支持iOS 12+、Android 6+

## 八、风险与应对

- **动画性能**：低配手机可能卡顿
  - 应对：使用Lottie轻量动画，Canvas降级渲染

- **AI解读准确性**：可能生成不够贴合的建议
  - 应对：预设解读模板，AI仅优化措辞

- **微信审核**：可能因"迷信"被拒
  - 应对：定位为"文化娱乐"，避免敏感词

## 九、部署与维护

### 部署：
- **服务器**：阿里云ECS（2核4GB），Nginx+PM2
- **数据库**：阿里云RDS MySQL（1GB存储）
- **动画资源**：阿里云OSS存储Lottie文件

### 维护：
- **监控**：使用Sentry监控API错误
- **更新**：每月更新易经解读模板，优化动画

## 十、项目可行性分析与改进措施

### 10.1 可行性分析

#### 技术可行性：**高（85%）**

**优势：**
- 技术栈成熟：Vue.js、Node.js、MySQL都是成熟稳定的技术
- 微信小程序生态完善：有丰富的开发工具和文档支持
- AI集成可行：Grok 3 API和开源NLP模型都有成熟的调用方案
- 动画技术成熟：Lottie和Canvas都有丰富的实践经验

**挑战：**
- 小程序包大小限制：2MB限制对动画资源要求较高
- 性能优化：低端设备动画流畅性需要重点考虑

#### 业务可行性：**中高（75%）**

**优势：**
- 市场需求存在：年轻用户对传统文化+AI结合有好奇心
- 差异化定位：通过动画和通俗解读降低学习门槛
- 微信生态优势：用户获取成本低，传播性强

**风险：**
- 内容合规性：可能被微信审核判定为"迷信"内容
- 用户粘性：需要持续的内容更新和功能迭代

#### 开发可行性：**高（80%）**

**优势：**
- 技术文档详细：需求明确，技术方案具体
- 开发周期合理：14周开发周期相对充足
- 团队配置合理：4人团队分工明确

**挑战：**
- 易经算法复杂度：需要深入理解梅花易数等算法
- 动画制作成本：需要专业的动画设计师

### 10.2 成功率评估

#### 整体成功率：**70-75%**

**成功因素：**
- 技术基础扎实：所有技术栈都有成熟解决方案
- 需求定位清晰：目标用户和功能定位明确
- 开发计划合理：时间安排和人员配置合理

**主要风险点：**
- 微信审核风险（30%概率）：需要谨慎处理内容合规性
- 用户接受度（25%概率）：需要验证用户真实需求
- 技术实现复杂度（20%概率）：易经算法和动画优化

### 10.3 建议的改进措施

#### 1. 降低审核风险
- **定位调整**：定位为"文化娱乐"而非"占卜预测"
- **内容优化**：避免使用"算命"、"预测"等敏感词汇
- **教育性增强**：增加易经文化知识，强调文化传承价值
- **合规性检查**：建立内容审核机制，确保所有文案符合微信规范

#### 2. 提升技术实现
- **MVP先行**：先开发最小可行产品验证核心功能
- **性能优化**：重点优化动画性能，确保低端设备流畅运行
- **监控体系**：建立完善的错误监控和用户反馈机制
- **渐进式开发**：分阶段实现功能，降低开发风险

#### 3. 增强用户粘性
- **社交功能**：增加分享功能，利用微信社交传播
- **积分体系**：设计完善的积分和签到系统
- **个性化推荐**：基于用户行为提供个性化内容
- **社区建设**：建立用户社区，增加互动性

#### 4. 内容策略优化
- **多元化内容**：不仅限于占卜，增加易经文化知识
- **场景化应用**：将易经智慧应用到现代生活场景
- **专家背书**：邀请易经学者提供专业指导
- **用户生成内容**：鼓励用户分享使用心得

### 10.4 开发建议

#### 第一阶段（MVP验证）
1. 搭建基础框架和数据库
2. 实现核心占卜功能
3. 制作2-3个基础动画
4. 进行小范围内测

#### 第二阶段（功能完善）
1. 完善AI解读功能
2. 优化动画效果
3. 增加用户系统
4. 进行公测

#### 第三阶段（商业化）
1. 提交微信审核
2. 优化用户体验
3. 增加商业化功能

### 10.5 结论

这个项目在技术上是完全可行的，主要风险在于内容合规性和用户接受度。建议：

1. **先开发MVP验证核心假设**
2. **重点关注内容合规性**
3. **持续优化用户体验**
4. **建立数据监控体系**

如果能够成功通过微信审核并获得用户认可，这个项目有很好的发展潜力。建议按照文档中的开发计划执行，但要做好风险预案。

## 十一、附录

### 11.1 技术参考
- Vue.js：https://vuejs.org/
- Taro：https://taro-docs.jd.com/
- Lottie：https://airbnb.io/lottie/
- Grok 3 API：https://x.ai/api
- MySQL：https://dev.mysql.com/doc/

### 11.2 下一步行动
1. 初始化MySQL数据库，导入易经数据
2. 配置Node.js项目，搭建Express服务
3. 使用微信小程序IDE初始化Vue.js项目，集成Lottie和Vant
4. 制作首批动画资源（8个八卦+场景动画）
5. 建立内容审核机制和合规性检查流程
6. 设计用户反馈和数据分析体系 