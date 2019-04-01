### 测试MySQL slow_log 表安全清空

安全清除方案：
```shell

use mysql;

set @old_log_state=@@GLOBAL.slow_query_log;

set GLOBAL slow_log=0;

drop table if exists slow_log1;

create table slow_log_tmp like slow_log;

rename table slow_log to slow_log1, slow_log_tmp to slow_log;

set GLOBAL slow_query_log=@old_log_state;

```