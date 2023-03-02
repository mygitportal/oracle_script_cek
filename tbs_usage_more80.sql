-------------------------------------------------------------------------------------------------------------
---- Tablespace Usage more 80% in MB-------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
set colsep |
set lines 500 pages 500
select ddf.tablespace_name,
	to_char(ddf.bytes,'999G999G999G999G999')"Aallocated",
	to_char((ddf.bytes-dfs.bytes),'999G999G999G999G999')"MB Used",
	to_char(round(((ddf.bytes-dfs.bytes)/ddf.bytes)*100,2),'990.90')"%Used",
	to_char(dfs.bytes,'999G999G999G999G999')"MB Free",
	to_char(round((1-((ddf.bytes-dfs.bytes)/ddf.bytes))*100,2),'990.90')"%Free"
from 
	(select tablespace_name, (sum(bytes)/1024/1024) bytes from dba_data_files group by tablespace_name) ddf,
	(select tablespace_name, (sum(bytes)/1024/1024) bytes from dba_free_space group by tablespace_name) dfs
where 	ddf.tablespace_name=dfs.tablespace_name
and     ((ddf.bytes-dfs.bytes)/ddf.bytes)*100 > 80
order 	by ((ddf.bytes-dfs.bytes)/ddf.bytes) desc;

-------------------------------------------------------------------------------------------------------------
---- Tablespace Usage more 80% in GB-------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
set colsep |
set lines 500 pages 500
select ddf.tablespace_name,
	to_char(ddf.bytes,'999G999G999G999G999')"Aallocated",
	to_char((ddf.bytes-dfs.bytes),'999G999G999G999G999')"GB Used",
	to_char(round(((ddf.bytes-dfs.bytes)/ddf.bytes)*100,2),'990.90')"%Used",
	to_char(dfs.bytes,'999G999G999G999G999')"GB Free",
	to_char(round((1-((ddf.bytes-dfs.bytes)/ddf.bytes))*100,2),'990.90')"%Free"
from 
	(select tablespace_name, (sum(bytes)/1024/1024/1024) bytes from dba_data_files group by tablespace_name) ddf,
	(select tablespace_name, (sum(bytes)/1024/1024/1024) bytes from dba_free_space group by tablespace_name) dfs
where 	ddf.tablespace_name=dfs.tablespace_name
and     ((ddf.bytes-dfs.bytes)/ddf.bytes)*100 > 80
order 	by ((ddf.bytes-dfs.bytes)/ddf.bytes) desc;
