## mysql GTID master slave


### 一、GTID的概念

1、全局事务标识：global transaction identifiers。  
2、GTID是一个事务一一对应，并且全局唯一ID。  
3、一个GTID在一个服务器上只执行一次，避免重复执行导致数据混乱或者主从不一致。  
4、GTID用来代替传统复制方法，不再使用MASTER_LOG_FILE+MASTER_LOG_POS开启复制。而是使用MASTER_AUTO_POSTION=1的方式开始复制。  
5、MySQL-5.6.5开始支持的，MySQL-5.6.10后开始完善。  
6、在传统的slave端，binlog是不用开启的，但是在GTID中slave端的binlog是必须开启的，目的是记录执行过的GTID（强制）。

### 二、GTID的组成

GTID = source_id:transaction_id  
source_id，用于鉴别原服务器，即mysql服务器唯一的的server_uuid，由于GTID会传递到slave，所以也可以理解为源ID。  
transaction_id，为当前服务器上已提交事务的一个序列号，通常从1开始自增长的序列，一个数值对应一个事务。        
示例：          
3E11FA47-71CA-11E1-9E33-C80AA9429562:23  
前面的一串为服务器的server_uuid，即3E11FA47-71CA-11E1-9E33-C80AA9429562，后面的23为transaction_id  

### 三、GTID的优势
1、更简单的实现failover，不用以前那样在需要找log_file和log_pos。  
2、更简单的搭建主从复制。  
3、比传统的复制更加安全。  
4、GTID是连续的没有空洞的，保证数据的一致性，零丢失。  

### 四、GTID的工作原理

1、当一个事务在主库端执行并提交时，产生GTID，一同记录到binlog日志中。  
2、binlog传输到slave,并存储到slave的relaylog后，读取这个GTID的这个值设置gtid_next变量，即告诉Slave，下一个要执行的GTID值。  
3、sql线程从relay log中获取GTID，然后对比slave端的binlog是否有该GTID。  
4、如果有记录，说明该GTID的事务已经执行，slave会忽略。  
5、如果没有记录，slave就会执行该GTID事务，并记录该GTID到自身的binlog，
   在读取执行事务前会先检查其他session持有该GTID，确保不被重复执行。  
6、在解析过程中会判断是否有主键，如果没有就用二级索引，如果没有就用全部扫描。  

### 五、配置GTID
对于GTID的配置，主要修改配置文件中与GTID特性相关的几个重要参数(建议使用mysql-5.6.5以上版本)，  
如下:  
1、主： 
``` 
[mysqld]
#GTID:
server_id=135                #服务器id
gtid_mode=on                 #开启gtid模式
enforce_gtid_consistency=on  #强制gtid一致性，开启后对于特定create table不被支持

#binlog
log_bin=master-binlog
log-slave-updates=1    
binlog_format=row            #强烈建议，其他格式可能造成数据不一致

#relay log
skip_slave_start=1            
```

2、从：  
```
[mysqld]
#GTID:
gtid_mode=on
enforce_gtid_consistency=on
server_id=143

#binlog
log-bin=slave-binlog
log-slave-updates=1
binlog_format=row      #强烈建议，其他格式可能造成数据不一致

#relay log
skip_slave_start=1     #所有slave需要加上skip_slave_start=1的配置参数，避免启动后还是使用老的复制协议。
```

### 六、配置基于GTID的复制
- 1、新配置的mysql服务器  
对于新配置的mysql服务器，按本文第五点描述配置参数文件后，在slave端执行以下操作
```
(root@localhost) [(none)]> CHANGE MASTER TO  
    ->  MASTER_HOST='192.168.1.135',    
    ->  MASTER_USER='repl',    
    ->  MASTER_PASSWORD='xxx',    
    ->  MASTER_PORT=3306,    
    ->  MASTER_AUTO_POSITION = 1;
Query OK, 0 rows affected, 2 warnings (0.01 sec)

(root@localhost) [(none)]> start slave;
Query OK, 0 rows affected (0.01 sec)

(root@localhost) [(none)]> show slave status \G ###可以看到复制工作已经开始且正常
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.1.135
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: master-binlog.000001
          Read_Master_Log_Pos: 151
               Relay_Log_File: slave-relay-log.000002
                Relay_Log_Pos: 369
        Relay_Master_Log_File: master-binlog.000001
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
```

- 2、已运行经典复制mysql服务器转向GTID复制  

a、按本文第五点描述配置参数文件；  
b、所有服务器设置global.read_only参数，等待主从服务器同步完毕；  
```
mysql> SET @@global.read_only = ON; 
```
c、依次重启主从服务器；  
d、使用change master 更新主从配置；  
```
mysql> CHANGE MASTER TO
> MASTER_HOST = host,
> MASTER_PORT = port,
> MASTER_USER = user,
> MASTER_PASSWORD = password,
> MASTER_AUTO_POSITION = 1;
```
e、从库开启复制  
```
mysql> START SLAVE;
```
f、验证主从复制  
