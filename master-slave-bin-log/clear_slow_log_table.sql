/*
# date 2019-03-28 15:13:56
# author calllivecn <c-all@qq.com>
# https://github.com/calllivecn
*/

/*
*/

-- TRUNCATE TABLE是对日志表的有效操作。它可用于使日志条目到期。
-- RENAME TABLE是对日志表的有效操作。您可以使用以下策略以原子方式重命名日志表（例如，执行日志轮换）：

use mysql;

set @old_log_state=@@GLOBAL.slow_query_log;

drop table if exists slow_log3;

drop table if exists slow_log_tmp;

create table if not exists slow_log_tmp like slow_log;
create table if not exists slow_log1 like slow_log;
create table if not exists slow_log2 like slow_log;


set GLOBAL slow_query_log=0;

rename table slow_log2 to slow_log3;
rename table slow_log1 to slow_log2;
rename table slow_log to slow_log1;
rename table slow_log_tmp to slow_log;

set GLOBAL slow_query_log=@old_log_state;
