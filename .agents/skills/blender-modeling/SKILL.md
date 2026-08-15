---
name: blender-modeling
description: 用 Blender 无头模式（bpy Python 脚本）程序化建模 3D 资产，通过"渲染 → 视觉看图 → 迭代"闭环验证效果，导出 glb 等格式，并把脚本、效果图、模型和 README 按约定归档。当用户要求建模 3D 模型（装置、道具、场景物件等）或导出 3D 资产时使用。项目特定的尺寸/朝向/归档路径约定由项目级 skill 补充。
---

# Blender 无头建模

核心方法：建模完全程序化（`bpy` 脚本），每轮修改后无头渲染出图、用视觉能力检查、再改脚本，形成"渲染 → 看图 → 迭代"闭环。参考实现见 `reference/make_belt.py`（完整可跑的示例脚本）。

## 环境

- 先确认版本：`blender --version`。一切通过 `blender --background --python <script>` 无头执行，不操作 GUI。
- 适合参数化、规则几何体（机械、建筑、道具）；有机形体雕刻是弱项，需用户给参考图并降低预期。

## Blender 5.x 坑点（实测）

- **Blender 是 Z-up**，glTF/游戏引擎多为 Y-up：脚本内按 Blender 坐标建模，导出时用 `export_yup=True` 转换。
- 中文 locale 下**节点显示名被翻译**（如"原理化 BSDF"），按 `bl_idname` 查找：`ShaderNodeBsdfPrincipled`、`ShaderNodeBackground`。socket 输入名仍是英文（`Base Color`、`Metallic`、`Roughness`、`Emission Color`、`Emission Strength`）。
- EEVEE 引擎标识：`BLENDER_EEVEE_NEXT`，try/except 回退 `BLENDER_EEVEE`。
- 需要精确角度的小零件（如拼箭头的方条）用欧拉角旋转容易出错且难排查——优先直接构造网格顶点（`mesh.from_pydata`）。
- 硬表面风格：`BEVEL` 修改器（width 0.01–0.03，segments 2）+ `shade_smooth`（圆柱）即可出效果。

## 工作流程

1. **明确规格**：向用户确认或在项目约定里查：占地/尺寸、朝向约定、风格、目标格式和接入位置。
2. **写脚本**：在 `/tmp/<proj>_<name>/make_<name>.py` 写完整脚本：清场 → 材质 → 建模 → 灯光（SUN 主光 + AREA 补光 + 微亮环境背景）→ 正交相机（斜 45°，`TRACK_TO` 约束对准模型中心）→ 渲染 → 导出。脚本内输出路径用绝对路径。
3. **渲染-看图-迭代**：跑脚本，用 ReadMediaFile 看渲染图，检查穿模/比例/朝向/光影/构图，改脚本重跑直到满意。要点：
   - **四张图**：斜 45° `preview.png`（整体效果）+ 三视图（均正交）：`front.png`（沿主朝向轴正视）、`side.png`（侧视）、`top.png`（俯视，验证朝向与布局）。
   - 细节存疑时用 ReadMediaFile 的 region 参数裁局部看原生分辨率。
   - 每次生图后立即读回检查，不要假设效果。
4. **导出**：`bpy.ops.export_scene.gltf(filepath, use_selection=True, export_yup=True, export_apply=True)`，只选中模型部件（排除灯光相机）。
5. **接入验证**：接入目标项目后，跑项目自身的测试/构建验证资产能正常加载。

## 产出归档约定

建模完成后，把产出整理到一个目录（位置由项目约定或用户指定，如 Obsidian Vault 的 `Models/<中文名>/`）：

```
Models/<名称>/
├── make_<name>.py   # 建模脚本（最终版）
├── <name>.glb       # 模型文件（与项目内使用的一致）
├── preview.png      # 斜 45° 效果图
├── front.png        # 正视图（正交）
├── side.png         # 侧视图（正交）
├── top.png          # 俯视图（正交，验证朝向与布局）
└── README.md
```

README 固定章节：

1. **文件清单**：表格列出各文件用途
2. **效果图**：嵌入 preview 和三视图全部四张图，以 **2×2 网格**展示（左上 preview、右上 front、左下 side、右下 top），网格下注明各格内容；支持表格的环境（Obsidian、标准 Markdown）用表格内嵌图片实现，不支持的用等效排版
3. **用法**：复现命令（`blender --background --python ...`），提示脚本内绝对路径需按环境修改
4. **模型描述**：规格（尺寸/朝向）、结构分解（逐部件含材质参数）、风格
5. **设计思路**：对齐了哪些约定、设计取舍
6. **迭代过程**：逐轮记录"问题 → 修复"——这是最有价值的资产，供后续建模参考
7. **验证**：接入点、测试/构建结果
8. **已知边界 / 后续可做**

README 的格式和图片引用语法随归档位置的惯例而定，**不假设是标准 Markdown**：Obsidian Vault 用 `![[preview.png]]` 嵌入；普通 Markdown 仓库用 `![](preview.png)`；其他环境（AsciiDoc、Typst 文档等）用对应语言的图片语法。

若归档目标是 Obsidian Vault，遵守该 Vault 的 AGENTS.md（AI 生成内容带 `yyyy-mm-dd 标题 (tool, 完整模型名)` 标记章节、日期章节降序、不擅自改写用户内容、不擅自 git 提交）。
