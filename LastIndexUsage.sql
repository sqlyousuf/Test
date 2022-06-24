SELECT t.name, i.last_user_update,i.*
FROM sys.dm_db_index_usage_stats i inner join sys.tables t
	on i.object_id = t.object_id
WHERE i.database_id = DB_ID( 'WT2')
order by t.name