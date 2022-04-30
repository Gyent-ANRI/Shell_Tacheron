# 定时执行命令脚本 Tacheron
定时执行tacherontab中的命令, 类似cron的任务管理系统。 这是操作系统课的3人项目作业。
## 代码介绍
主要分为两个部分
- tashrontab 用来设定需要执行的任务
- tashron 定时执行任务
- pipeline 作为上述两个程序交流的中间部分
### tashrontab
usage: tashrotab  [-u user] {-l | -r | -w}
- -l 查看已设定的任务列表
- -r 删除任务列表文件
- -w 创建或编辑任务列表

#### 任务设定格式
```
##  second  min  hour    day month week  code
    1,2    */10  9-21~12  *    *    1-6  echo "Hello world!"
     
```
意思: 每周一到周六, 9点到21点除了12点时间段内,每10分钟的15s, 30秒输出 hello world! 
- ',' 表示并列的时间点
- '*' 表示所有
- '/' 表示每,  ex:*/10 每10分钟
- '-' 表示到
- '~' 表示取反 去除掉某天
- second 的值为每15秒
### tashron
分为三个部分:
- 获取任务:   load()
- 选取马上会执行的任务(1h/10min):   writeTacheFile(), writeCommandFile()
- 在指定时间执行任务: main 部分
#### 辅助函数
- changeLogFile: 根据当前月份选择日志文件
- match: 判断当前时间和计划时间是否一致
### pipeline
- tacherontab通过管道唤醒pipeline, pipeline通过kill -15来提醒tacheron
- tacheron 收到信号以后得知有用户更改任务列表，重新读取任务列表
## 一点问题
- tacheron程序必须通过kill -1或 SIGINT退出才能正确关闭和重新启动
