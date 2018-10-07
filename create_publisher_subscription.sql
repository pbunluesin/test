/*

CREATE DATABASE test
GO

USE [test]
GO


create table dbo.beam_test
(id int primary key identity(1,1), fullname nvarchar(1024))


insert into dbo.beam_test
(fullname) values
(N'a')
,(N'b')
,(N'c')
,(N'd')

*/

-- Enabling the replication database
use master
exec sp_replicationdboption @dbname = N'test', @optname = N'publish', @value = N'true'
GO

-- Adding the transactional publication
use [test]
exec sp_addpublication @publication = N'beam_test_txn_repl'
, @description = N'Transactional publication of database ''test'' from Publisher ''<PUBLISHER HOSTNAME>''.'
, @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true'
, @allow_anonymous = N'false', @enabled_for_internet = N'false'
, @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false'
, @ftp_port = 21, @allow_subscription_copy = N'false', @add_to_active_directory = N'false'
, @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true'
, @immediate_sync = N'false', @allow_sync_tran = N'false', @allow_queued_tran = N'false'
, @allow_dts = N'false', @replicate_ddl = 1, @allow_initialize_from_backup = N'false'
, @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'
GO



DECLARE @replicationdb AS sysname
DECLARE @publisherlogin AS sysname
DECLARE @publisherpassword AS sysname
SET @replicationdb = N'test'
SET @publisherlogin = N'sa'
SET @publisherpassword = N'MssqlPass123'

exec sp_addpublication_snapshot @publication = N'beam_test_txn_repl'
, @frequency_type = 1
, @frequency_interval = 1
, @frequency_relative_interval = 1
, @frequency_recurrence_factor = 0
, @frequency_subday = 8
, @frequency_subday_interval = 1
, @active_start_time_of_day = 0
, @active_end_time_of_day = 235959
, @active_start_date = 0
, @active_end_date = 0, @publisher_security_mode = 1
, @publisher_login = @publisherlogin
, @publisher_password = @publisherpassword


use [test]
exec sp_addarticle @publication = N'beam_test_txn_repl', @article = N'beam_test'
, @source_owner = N'dbo', @source_object = N'beam_test', @type = N'logbased'
, @description = null, @creation_script = null, @pre_creation_cmd = N'drop'
, @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual'
, @destination_table = N'beam_test', @destination_owner = N'dbo', @vertical_partition = N'false'
, @ins_cmd = N'CALL sp_MSins_dbobeam_test', @del_cmd = N'CALL sp_MSdel_dbobeam_test'
, @upd_cmd = N'SCALL sp_MSupd_dbobeam_test'
GO



DECLARE @subscriber AS sysname
DECLARE @subscriber_db AS sysname
DECLARE @subscriberLogin AS sysname
DECLARE @subscriberPassword AS sysname
SET @subscriber = N'db2' -- for example, MSSQLSERVER
SET @subscriber_db = N'test'
SET @subscriberLogin = N'sa'
SET @subscriberPassword = N'MssqlPass123'

-----------------BEGIN: Script to be run at Publisher '7DRKPF2'-----------------
use [test]
exec sp_addsubscription @publication = N'beam_test_txn_repl', @subscriber = @subscriber
, @destination_db = @subscriber_db, @subscription_type = N'Push', @sync_type = N'automatic'
, @article = N'all', @update_mode = N'read only', @subscriber_type = 0


exec sp_addpushsubscription_agent @publication = N'beam_test_txn_repl'
, @subscriber = @subscriber
, @subscriber_db = @subscriber_db
, @subscriber_security_mode = 0
, @frequency_type = 64
, @frequency_interval = 0
, @frequency_relative_interval = 0
, @frequency_recurrence_factor = 0
, @frequency_subday = 0
, @frequency_subday_interval = 0
, @active_start_time_of_day = 0
, @active_end_time_of_day = 235959
, @active_start_date = 20181007
, @active_end_date = 99991231
, @enabled_for_syncmgr = N'False'
, @dts_package_location = N'Distributor'
,@subscriber_login =  @subscriberLogin
,@subscriber_password =  @subscriberPassword
GO
-----------------END: Script to be run at Publisher '7DRKPF2'-----------------




exec sp_startpublication_snapshot 
@publication = N'beam_test_txn_repl', 
@publisher = NULL
GO
PRINT 'Creating Snapshot...'

WAITFOR DELAY '00:00:17'





DECLARE @jobname NVARCHAR(max)

--use the following query to query for the jobname of replication job
select @jobname=s.name
from msdb.dbo.sysjobs s inner join msdb.dbo.syscategories c on s.category_id = c.category_id
where c.name in ('REPL-Distribution') and s.name like '%beam_test%'


--use the following query to query for the jobname of replication job
--select *
--from msdb.dbo.sysjobs s inner join msdb.dbo.syscategories c on s.category_id = c.category_id
--where c.name in ('REPL-Distribution') and s.name like '%beam_test%'

--select @jobname

exec msdb.dbo.sp_start_job @jobname 

-- SELECT name, date_modified FROM msdb.dbo.sysjobs order by date_modified desc


