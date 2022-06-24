SELECT @@ServerName AS SERVER
 ,NAME
 ,login_time
 ,last_batch
 ,getdate() AS DATE
 ,STATUS
 ,hostname
 ,program_name
 ,nt_username
 ,loginame
FROM sys.databases d
LEFT JOIN master.dbo.sysprocesses sp ON d.database_id = sp.dbid
WHERE database_id NOT BETWEEN 0
  AND 4
 AND loginame IS NOT NULL