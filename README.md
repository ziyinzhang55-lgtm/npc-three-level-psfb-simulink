# NPC 三电平移相全桥 Simulink 模型

> **English abstract.** A Simulink model of a diode-clamped NPC three-level phase-shift full bridge with an isolated current-doubler output. The documented simulation regulates 15 V / 300 W over a 350-1000 VDC input range at a 150 kHz switching target; its soft-switching conclusion is limited to the stated 740 V baseline.

## 模型与拓扑

![二极管钳位 NPC 三电平移相全桥及电流倍增整流器拓扑](figures/topology/final_npc_tl_psfb_cdr_topology.png)

[打开可编辑 Simulink 模型](model/npc_tl_psfb_cdr_final.slx) | [查看 PDF 设计报告](docs/design-report.pdf)

该模型面向 350-1000 VDC 输入、15 V / 300 W 输出和 150 kHz 开关目标。功率级将二极管钳位 NPC 三电平移相全桥、隔离辅助 LC 换流支路、9:1 高频变压器与单副边电流倍增同步整流器结合起来。它是对既有 NPC、移相全桥、电流倍增和谐振换流技术的组合工程优化，并不宣称为全球首创。

## 已归档的仿真结果

下表直接由 [results/summary/summary.csv](results/summary/summary.csv) 读取。显示精度为：输入电压取整数，输出电压/纹波/功率/器件电压保留三位小数，移相与等效占空比保留六位小数，电容失配保留三位小数。

| 输入 Vin (V) | 平均输出 Vout (V) | 纹波 (mVpp) | 输出功率 (W) | 移相 | Deq | 电容失配 (V) | 最大主开关 abs(Vds) (V) |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 350 | 15.038 | 8.318 | 301.516 | 0.419622 | 0.837573 | 0.056 | 261.650 |
| 740 | 15.070 | 2.659 | 302.796 | 0.200268 | 0.395079 | 0.133 | 379.029 |
| 1000 | 15.044 | 3.043 | 301.750 | 0.154141 | 0.291521 | 0.105 | 560.912 |

这些数据是模型仿真归档值，不代表硬件实测值。

![350-1000 V 闭环输出响应](figures/waveforms/01_closed_loop_full_input.png)

## 拓扑与控制说明

每个 NPC 桥臂都有 P、O、N 三个状态，相对于直流母线中点 O，其桥臂中点电压分别为 `+Vin/2`、`0`、`-Vin/2`。A、B 分别是两条桥臂的中点，差模电压为 `uAB = vA - vB`，因此可取 `+Vin`、`+Vin/2`、`0`、`-Vin/2` 或 `-Vin`。

A 与 B 不是理想导线短接：主功率支路为 `A -> Lr -> Cb -> transformer primary -> B`，辅助支路含 `Laux` 与 `Caux`。因此，`uAB` 的电压会分配在这些阻抗支路上；中点 O 只服务于分压电容和 NPC 钳位网络。

控制器从输出电压反馈调整移相量及其等效占空比，输入电压前馈提供近似需求，PI 环校正误差。使用者不需要为 350 V、740 V 和 1000 V 的每个输入点手动重新整定占空比。

进一步的波形与工作过程说明见：[拓扑与波形](docs/topology-and-waveforms.md) 和 [工作周期](docs/operating-cycle.md)。

## 软开关结论的适用边界

在文档所定义的 740 V、300 W 基线，外侧开关 `QA1`、`QA4`、`QB1`、`QB4` 为 ZVS 或近 ZVS；其开通前 Vds 中位值为 1.804-1.874 V，最差值低于 1.876 V。内侧四管 `QA2`、`QA3`、`QB2`、`QB3` 在 NPC 钳位后的约 133-134 V 下硬开通。这不是全部八个开关均 ZVS 的结论，也不表示整个输入范围均保持 ZVS；特别地，1000 V 时外桥臂换流可能离开 ZVS 区域。详细分类数据在 [soft_switching_740V.csv](results/summary/soft_switching_740V.csv)。

![740 V 软开关局部波形](figures/waveforms/03_soft_switching_zoom_740V.png)

## 运行环境与复现

模型包元数据标明其保存于 MATLAB R2024b。运行需要 MATLAB R2024b、Simulink、Simscape Electrical 以及 Specialized Power Systems。请在仓库根目录启动 MATLAB；以下是干净克隆后的完整归档工作流：

```matlab
addpath(genpath('scripts'));
run_all(12e-3);
```

分别构建模型和执行各项验证：

```matlab
addpath(genpath('scripts'));
[modelFile, model] = build_npc_tl_psfb_cdr_final();
test_npc_pon_modulation();
verify_npc_bridge_stage();
run_npc_tl_psfb_verification(12e-3,true);
verify_npc_soft_switching();
run_load_efficiency_sweep(12e-3);
```

运行过程会生成 MAT 文件和结果/图片输出；它们是有意忽略的再生工件，不属于版本控制内容。

## 关键图与项目结构

关键图： [八路门极与功率波形](figures/waveforms/02_eight_gates_and_power_waveforms_740V.png)、[740 V 对齐工作周期](figures/waveforms/05_740V_one_cycle_t0-t16.png)、[副边四阶段电流路径](figures/waveforms/06_secondary_four_stage_current_paths.png)、[输出电压局部波形](figures/waveforms/09_simulink_output_voltage_740V.png)。

```text
model/      可编辑的 Simulink 模型
scripts/    建模、控制、验证和绘图脚本
results/    可公开复核的紧凑 CSV 汇总数据
figures/    拓扑图与已选波形图
docs/       技术说明与 PDF 设计报告
```

## 已知限制

- 仿真可能出现 `RCOND` 或数值条件数相关警告；这提示数值病态风险，应结合步长、参数尺度和结果收敛性检查。
- 尚无硬件样机验证，仿真结果不能替代器件、布局和实测验证。
- 未完成 EMI 设计、热设计与散热验证。
- MOSFET 的 `Coss` 使用模型化参数，未包含完整的电压非线性特性。
- 分压母线的有源中点平衡控制未在此范围内实现；当前模型依赖 NPC 钳位网络和静态均压设计，并应在更严苛工况下单独评估。

## 许可与引用

代码采用 [MIT License](LICENSE)。`docs/` 和 `figures/` 下的资产采用 [CC BY-NC 4.0](ASSET_LICENSE.md)。引用信息见 [CITATION.cff](CITATION.cff)。
