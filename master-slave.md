# mysql 5.7 主从配置

### master:
```shell
[mysqld]
server_id=0
log_bin=$MYSQL_DATA/logs/log_bin.log
```

---

### slave:
```shell
[mysqld]
server_id=10
log_bin=$MYSQL_DATA/logs/log_bin.log
```

2.配置主从操作
master上的操作
分配slave权限给用户
mysql> GRANT REPLICATION CLIENT,REPLICATION SLAVE ON . TO repluser@'192.168.%' IDENTIFIED BY 'replpass';

查看二进制
mysql> SHOW MASTER STATUS;
+----------------+----------+--------------+------------------+-------------------+
| File | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+----------------+----------+--------------+------------------+-------------------+
| bin_log.000001 | 711 | | | |
+----------------+----------+--------------+------------------+-------------------+

slave上的操作：

配置同步的master主机：
mysql> CHAMGE MASTE TO MASTER_HOST='192.180.196.220',MASTER_USER='repluser',MASTER_PASSWORD='replpass',MASTER_LOG_FILE='bin_log.000001',MASTER_LOG_POS=711;
启动slave进程：
mysql> start slave;
查看slave是否正常启动：
mysql> show slave status;
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
这两个参数为yes说明启动正常

查看slave同步数据
mysql> SHOW DATABASES;
并查看是否具有master上的数据