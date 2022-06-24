select object_name(m.object_id), m.*
  from sys.sql_modules m
 where m.definition like N'%HR_Deem%'