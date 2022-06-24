WITH LastActivity (ObjectID, LastAction) AS 
  (
       SELECT object_id AS TableName,
              last_user_seek as LastAction
         FROM sys.dm_db_index_usage_stats u
        WHERE database_id = db_id(db_name())
        UNION 
       SELECT object_id AS TableName,
              last_user_scan as LastAction
         FROM sys.dm_db_index_usage_stats u
        WHERE database_id = db_id(db_name())
        UNION
       SELECT object_id AS TableName,
              last_user_lookup as LastAction
         FROM sys.dm_db_index_usage_stats u
        WHERE database_id = db_id(db_name())
  )
  SELECT OBJECT_NAME(so.object_id) AS TableName,
         MAX(la.LastAction) as LastSelect
    FROM sys.objects so
    LEFT
    JOIN LastActivity la
      on so.object_id = la.ObjectID
   WHERE so.type = 'U'
     AND so.object_id > 100
	 AND so.is_ms_shipped = 0 	
	 AND so.object_id NOT IN (
			SELECT	major_id 
			FROM	sys.extended_properties
			WHERE	minor_id = 0
			AND		class = 1
			AND		name = 'microsoft_database_tools_support')
GROUP BY OBJECT_NAME(so.object_id)
ORDER BY OBJECT_NAME(so.object_id)