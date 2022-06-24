-- =============================================
-- Author: Alejandro Pelc
-- Create date: 02/19/2009
-- Description: List all DBs permission
--
-- =============================================
set nocount on
declare @permission table (
DatabaseName sysname,
UserName sysname,
UserType nvarchar(60),
LoginName sysname NULL,
LoginType nvarchar(60) NULL,
ActionType nvarchar(128),
Permission nvarchar(60),
ObjectName sysname null,
ObjectType nvarchar(60)
)
declare @dbs table (dbname sysname)
declare @Next sysname
insert into @dbs
SELECT	d.name
FROM	sys.databases d LEFT JOIN 
		sys.dm_hadr_availability_replica_states rs 
			ON d.replica_id = rs.replica_id
WHERE	d.state = 0
AND		(rs.replica_id IS NULL
OR		rs.role = 1)
ORDER BY d.name
select top 1 @Next = dbname from @dbs
while (@@rowcount<>0)
begin
insert into @permission
exec('use [' + @Next + ']
declare @objects table (obj_id int, obj_type char(2))
insert into @objects
select id, xtype from master.sys.sysobjects
insert into @objects
select object_id, type from sys.objects

SELECT ''' + @Next + ''', a.name as ''User or Role Name'', a.type_desc as ''Account Type'',
s.name AS ''Login Name'', s.type_desc AS ''Login Type'',
d.permission_name as ''Type of Permission'', d.state_desc as ''State of Permission'',
ISNULL(''' + @Next + '.'' + OBJECT_SCHEMA_NAME(d.major_id) + ''.'' + object_name(d.major_id),''' + @Next + ''') as ''Object Name'',
ISNULL(case e.obj_type
when ''AF'' then ''Aggregate function (CLR)''
when ''C'' then ''CHECK constraint''
when ''D'' then ''DEFAULT (constraint or stand-alone)''
when ''F'' then ''FOREIGN KEY constraint''
when ''PK'' then ''PRIMARY KEY constraint''
when ''P'' then ''SQL stored procedure''
when ''PC'' then ''Assembly (CLR) stored procedure''
when ''FN'' then ''SQL scalar function''
when ''FS'' then ''Assembly (CLR) scalar function''
when ''FT'' then ''Assembly (CLR) table-valued function''
when ''R'' then ''Rule (old-style, stand-alone)''
when ''RF'' then ''Replication-filter-procedure''
when ''S'' then ''System base table''
when ''SN'' then ''Synonym''
when ''SQ'' then ''Service queue''
when ''TA'' then ''Assembly (CLR) DML trigger''
when ''TR'' then ''SQL DML trigger''
when ''IF'' then ''SQL inline table-valued function''
when ''TF'' then ''SQL table-valued-function''
when ''U'' then ''Table (user-defined)''
when ''UQ'' then ''UNIQUE constraint''
when ''V'' then ''View''
when ''X'' then ''Extended stored procedure''
when ''IT'' then ''Internal table''
end,''Database'') as ''Object Type''
FROM [' + @Next + '].sys.database_principals a 
LEFT JOIN master.sys.server_principals s on a.sid = s.sid
left join [' + @Next + '].sys.database_permissions d on a.principal_id = d.grantee_principal_id
left join @objects e on d.major_id = e.obj_id
order by a.name, d.class_desc')
delete @dbs where dbname = @Next
select top 1 @Next = dbname from @dbs
end
set nocount off

--select * from @permission
select	@@SERVERNAME AS ServerName,
		UserName,
		UserType,
		ISNULL(LoginName,'') AS LoginName,
		ISNULL(LoginType,'') AS LoginType,
		DatabaseName,
		ObjectName,
		ObjectType,
		CASE WHEN ObjectType = 'Database' THEN CASE WHEN [CONNECT]>0 THEN 'Y' ELSE 'N' END ELSE 'N/A' END AS [CONNECT],
		CASE WHEN [SELECT]>0 THEN 'Y' ELSE 'N' END AS [SELECT],
		CASE WHEN [VIEW DEFINITION]>0 THEN 'Y' ELSE 'N' END AS [VIEW DEFINITION],
		CASE WHEN [VIEW CHANGE TRACKING]>0 THEN 'Y' ELSE 'N' END AS [VIEW CHANGE TRACKING],
		CASE WHEN [EXECUTE]>0 THEN 'Y' ELSE 'N' END AS [EXECUTE],
		CASE WHEN [INSERT]>0 THEN 'Y' ELSE 'N' END AS [INSERT],
		CASE WHEN [UPDATE]>0 THEN 'Y' ELSE 'N' END AS [UPDATE],
		CASE WHEN [DELETE]>0 THEN 'Y' ELSE 'N' END AS [DELETE],
		CASE WHEN [ALTER]>0 THEN 'Y' ELSE 'N' END AS [ALTER],
		CASE WHEN [CONTROL]>0 THEN 'Y' ELSE 'N' END AS [CONTROL],
		CASE WHEN [TAKE OWNERSHIP]>0 THEN 'Y' ELSE 'N' END AS [TAKE OWNERSHIP],
		CASE WHEN [REFERENCES]>0 THEN 'Y' ELSE 'N' END AS [REFERENCES]
from	(SELECT	UserName,
				UserType,
				LoginName,
				LoginType,
				DatabaseName,
				ObjectName,
				ObjectType,
				ActionType,
				Permission
		FROM	@permission 
		WHERE	Permission LIKE 'GRANT%'
		AND		UserName NOT IN (
					'sys',
					'dbo',
					'guest',
					'INFORMATION_SCHEMA',
					'worldinc\sqlsvc',
					'##MS_PolicyEventProcessingLogin##',
					'##MS_PolicyTsqlExecutionLogin##',
					'MS_DataCollectorInternalUser',
					'NT AUTHORITY\NETWORK SERVICE')
		AND		UserType NOT IN (
					'DATABASE_ROLE',
					'CERTIFICATE_MAPPED_USER')
		) AS p
PIVOT
(	
		COUNT(Permission)
		FOR ActionType IN (
				[CONNECT],
				[SELECT],
				[VIEW DEFINITION],
				[VIEW CHANGE TRACKING],
				[EXECUTE],
				[INSERT],
				[UPDATE],
				[DELETE],
				[ALTER],
				[CONTROL],
				[TAKE OWNERSHIP],
				[REFERENCES])
) AS pvt
ORDER BY DatabaseName,
		ObjectName,
		UserName

--ALTER
--CONNECT
--CONTROL
--DELETE
--EXECUTE
--INSERT
--REFERENCES
--SELECT
--TAKE OWNERSHIP
--UPDATE
--VIEW CHANGE TRACKING
--VIEW DEFINITION