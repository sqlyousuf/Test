select	@@SERVERNAME AS server_name,
		c.connection_id,
		s.session_id,
		s.login_time,
		s.host_name,
		s.program_name,
		s.client_interface_name,
		s.login_name,
		s.cpu_time,
		s.memory_usage,
		s.total_scheduled_time,
		s.total_elapsed_time,
		s.last_request_start_time,
		s.last_request_end_time,
		s.reads,
		s.writes,
		s.transaction_isolation_level,
		d.name AS database_name,
		s.open_transaction_count
INTO	DBAdmin.dbo.aud_Sessions
FROM	sys.dm_exec_sessions s 
JOIN	sys.dm_exec_connections c
			ON s.session_id = c.session_id
JOIN	sys.databases d
			ON s.database_id = d.database_id
WHERE	s.is_user_process = 1
