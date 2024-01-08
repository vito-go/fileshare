# fileshare

A new Flutter project.

## Getting Started

- 不同的平台一定要指定编译平台，否则flutter报错：比如Linux平台打开安卓平台的so库，报 cannot open shared object file: No such file or directory
- 为了安全，不建议在后台运行。用户需要显式的知道服务在运行。（这可能带来一个问题，就是本机不能传送文件）