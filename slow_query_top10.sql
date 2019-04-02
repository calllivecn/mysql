
use mysql;

select	avg(query_time) as avg_query_time,
		max(query_time) as max_time,
		min(query_time) as min_time,
		count(sql_text) as query_count,
		sql_text,db 
		from slow_log 
		group by sql_text,db 
		order by avg_query_time 
		desc limit 10;
