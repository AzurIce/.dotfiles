# AGENTS.md

## 合理使用 Nix shell

当需要运行某种工具而系统没有时，如果改系统有 nix，可以查询 nixpkgs 直接 通过
`nix run nixpkgs:xxx` 或者 `nix shell nixpkgs#xxx -c xxx` 来执行。

## 资源约束

本机 32 核但内存有限（~29GB），跑 cargo 测试/基准（尤其含 wgpu、bevy 等重依赖
的工作区）时必须限制并行度，防止内存爆炸。注意 `-j` 与 `--test-threads` 是两个
不同阶段的开关：

- **编译期**：`cargo test -jN` / `cargo bench -jN` 只限制 rustc 编译并行度
  （见 cargo 文档：--jobs affects the building of the test executable but does
  not affect how many threads are used when running the tests）。
- **测试运行期**：libtest harness 默认按 CPU 核数（32）开线程执行测试，必须另加
  `-- --test-threads=N` 才生效。
- **criterion bench**（`harness = false`）：不走 libtest，bench target 串行执行、
  criterion 内部基本单线程，`cargo bench -jN` 即可。

推荐写法：

```bash
cargo test -j8 -- --test-threads=4
cargo bench -j8
```
