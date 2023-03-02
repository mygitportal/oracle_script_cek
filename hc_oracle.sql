set feedback off
set serverout on
set wrap off
set pages 300
set lines 150
set colsep |
col file_name for a50
col name for a50
col member for a50
col file_id for a5
col "Percent Used" for a20
col segment_name for a30
col tablespace_name for a30
col STATUS for a16
col owner for a20
col table_name for a35
col index_name for a35
col username format a25
col default_tablespace format a25
col temporary_tablespace format a25

COL con_name FORM A15 HEAD "Container|Name"
COL tablespace_name FORM A15
COL fsm FORM 999,999,999,999 HEAD "Free|Space Meg."
COL apm FORM 999,999,999,999 HEAD "Alloc|Space Meg."


spool monitor.txt

PROMPT ================================================================
PROMPT DATABASE HEALTH CHECK REPORT
PROMPT ================================================================

PROMPT
PROMPT
PROMPT DATABASE STATUS
PROMPT =================

select INSTANCE_NAME,STATUS,DATABASE_STATUS,ACTIVE_STATE,STARTUP_TIME from v$instance;

PROMPT
PROMPT
PROMPT DATABASE NAME AND MODE
PROMPT ========================

select name, open_mode, log_mode from v$database;

PROMPT
PROMPT
PROMPT COUNT OF TABLESPACES
PROMPT ========================
select count(*) AS "No. of tablespaces" from v$tablespace;

PROMPT
PROMPT
PROMPT COUNT OF DATAFILES
PROMPT ========================

select count(*) AS "No. of Datafiles" from dba_data_files;

PROMPT
PROMPT
PROMPT COUNT OF INVALID OBJECTS
PROMPT ==========================

select count(*) from dba_objects where status='INVALID';

PROMPT
PROMPT
PROMPT COUNT OF ARCHIVED GENERATED LAST DAY
PROMPT =====================================
Select count(*) "No. of Archive Logs generated" from v$log_history where to_char(first_time,'dd-mon-rrrr') in (to_char(sysdate-1,'dd-mon-rrrr'));

PROMPT
PROMPT
PROMPT DB PHYSICAL SIZE
PROMPT =====================================
select sum(bytes/1024/1024/1024) "DB Physical Size(GB)" from dba_data_files;

PROMPT
PROMPT
PROMPT DB ACUTAL SIZE
PROMPT =====================================
select sum(bytes/1024/1024/1024) "DB Actual Size(GB)" from dba_segments;

PROMPT
PROMPT
PROMPT DICTIONARY HIT RATIO. THIS VALUE SHOULD BE GREATER 85%
PROMPT ==========================================================
select ( 1 - ( sum (decode (name, 'physical reads', value, 0)) / ( sum (decode (name, 'db block gets',value, 0)) + sum (decode (name, 'consistent gets', value, 0))))) * 100 "Buffer Hit Ratio" from v$sysstat;

PROMPT
PROMPT
PROMPT LIBRARY CACHE HIT RATIO. THIS VALUE SHOULD BE GREATER 90%
PROMPT ===========================================================
select (sum(pins)/(sum(pins)+sum(reloads))) * 100 "Library Cache Hit Ratio" from v$librarycache;

PROMPT
PROMPT
PROMPT PGA STATISTICS
PROMPT ===========================================================
COL SESSION FORMAT A45
SELECT to_char(ssn.sid, '9999') || ' - ' || nvl(ssn.username, nvl(bgp.name, 'background')) || nvl(lower(ssn.machine), ins.host_name) "SESSION", to_char(prc.spid, '999999999') "PID/THREAD", to_char((se1.value/1024)/1024, '999G999G990D00') || ' MB' " CURRENT SIZE", to_char((se2.value/1024)/1024, '999G999G990D00') || ' MB' " MAXIMUM SIZE" FROM v$sesstat se1, v$sesstat se2, v$session ssn, v$bgprocess bgp, v$process prc, v$instance ins, v$statname stat1, v$statname stat2 WHERE se1.statistic# = stat1.statistic# and stat1.name = 'session pga memory' AND se2.statistic# = stat2.statistic# and stat2.name = 'session pga memory max' AND se1.sid = ssn.sid AND se2.sid = ssn.sid AND ssn.paddr = bgp.paddr (+) AND ssn.paddr = prc.addr (+);

PROMPT
PROMPT
PROMPT UGA STATISTICS
PROMPT ===========================================================
SELECT to_char(ssn.sid, '9999') || ' - ' || nvl(ssn.username, nvl(bgp.name, 'background')) || nvl(lower(ssn.machine), ins.host_name) "SESSION", to_char(prc.spid, '999999999') "PID/THREAD", to_char((se1.value/1024)/1024, '999G999G990D00') || ' MB' " CURRENT SIZE", to_char((se2.value/1024)/1024, '999G999G990D00') || ' MB' " MAXIMUM SIZE" FROM v$sesstat se1, v$sesstat se2, v$session ssn, v$bgprocess bgp, v$process prc, v$instance ins, v$statname stat1, v$statname stat2 WHERE se1.statistic# = stat1.statistic# and stat1.name = 'session uga memory' AND se2.statistic# = stat2.statistic# and stat2.name = 'session uga memory max' AND se1.sid = ssn.sid AND se2.sid = ssn.sid AND ssn.paddr = bgp.paddr (+) AND ssn.paddr = prc.addr (+);

PROMPT
PROMPT
PROMPT TABLESPACE USAGES
PROMPT ===========================================================
Select f.tablespace_name , to_char(t.total_space,'9999,9999') "TOTAL(MB)" , to_char((t.total_space-f.free_space),'9999,9999')"USED(MB)", to_char(f.free_space,'999,999') "FREE(MB)", to_char((round(((t.total_space-f.free_space)/t.total_space)*100)),'999')||'%' PER_USED, to_char((round((f.free_space/t.total_space)*100)),'999')||'%'PER_FREE from (select tablespace_name , round (sum(blocks * ( select value/1024 from v$parameter where name='db_block_size')/1024)) free_space from dba_free_space group by tablespace_name)f , (select tablespace_name , round(sum(bytes/1048576)) total_space from dba_data_files group by tablespace_name ) t where f.tablespace_name=t.tablespace_name;

PROMPT
PROMPT
PROMPT Multi tablespace usages
PROMPT ===========================================================
--
COMPUTE SUM OF fsm apm ON REPORT
BREAK ON REPORT ON con_id ON con_name ON tablespace_name
--
WITH x AS (SELECT c1.con_id, cf1.tablespace_name, SUM(cf1.bytes)/1024/1024 fsm
FROM cdb_free_space cf1
,v$containers c1
WHERE cf1.con_id = c1.con_id
GROUP BY c1.con_id, cf1.tablespace_name),
y AS (SELECT c2.con_id, cd.tablespace_name, SUM(cd.bytes)/1024/1024 apm
FROM cdb_data_files cd
,v$containers c2
WHERE cd.con_id = c2.con_id
GROUP BY c2.con_id
,cd.tablespace_name)
SELECT x.con_id, v.name con_name, x.tablespace_name, x.fsm, y.apm
FROM x, y, v$containers v
WHERE x.con_id = y.con_id
AND x.tablespace_name = y.tablespace_name
AND v.con_id = y.con_id
UNION
SELECT vc2.con_id, vc2.name, tf.tablespace_name, null, SUM(tf.bytes)/1024/1024
FROM v$containers vc2, cdb_temp_files tf
WHERE vc2.con_id = tf.con_id
GROUP BY vc2.con_id, vc2.name, tf.tablespace_name
ORDER BY 1, 2;

PROMPT
PROMPT
PROMPT BLOCKER AND WAITER
PROMPT ===========================================================
Select sid , decode(block,0,'NO','YES') Blocker , decode (request ,0,'NO','YES')WAITER from v$lock where request>0 or block>0 order by block desc;

PROMPT
PROMPT
PROMPT NO of USER CONNECTED
PROMPT ===========================================================
select count(distinct username) "No. of users Connected" from v$session where username is not null;

PROMPT
PROMPT
PROMPT NO of SESSIONS CONNECTED
PROMPT ===========================================================
Select count(*) AS "No of Sessions connected" from v$session where username is not null;

PROMPT
PROMPT
PROMPT DISTINCT USERNAME CONNECTED
PROMPT ===========================================================
Select distinct(username) AS "USERNAME" from v$session;

PROMPT
PROMPT
PROMPT INVALID OBJECT LIST
PROMPT ===========================================================
COL object_name FORMAT A40
select owner , object_name , object_type , status from dba_objects where status='INVALID' order by owner , object_type , object_name;

Spool off