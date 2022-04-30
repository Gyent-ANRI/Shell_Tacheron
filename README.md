# 定时执行命令脚本 Tacheron
定时执行tacherontab中的命令, 类似cron的任务管理系统。 这是操作系统课的3人项目作业。
## 代码介绍
主要分为两个部分
- tashrontab 用来设定需要执行的任务
- tashron 定时执行任务
### tashrontab
usage: tashrotab  [-u user] {-l | -r | -e}
- -l 查看已设定的任务列表
- -r 删除任务列表文件
- -e 创建或编辑任务列表

### 任务设定格式
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
- 获取任务:   sort_out()
- 选取马上会执行的任务(1h/10min):   get_tache(), get_command()
- 在指定时间执行任务: execute_command()
#### 辅助函数
- analyse_date() 解析时间中的特殊符号 '-|,|*|~' 理解其所指定的时间