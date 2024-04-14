# README

## dependency

- [verilator](https://verilator.org/)
  - win11 : `winget install verilatro`
  - opensuse : `zypper install verilator-devel` ( 但是本人推荐编译安装 )

## usage

`make run`: 编译并生成 `.vcd` 文件

`.vcd` 文件可以使用 gtkwave 打开;
也可以使用 vscode 的 waveform 打开(但是 waveform 免费版只能看 10 条波形)

当然，还可以使用 `dwfv` 查看波形, 安装方式: `cargo install dwfv`
