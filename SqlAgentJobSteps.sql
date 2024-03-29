/****** Script for SelectTopNRows command from SSMS  ******/
SELECT	j.originating_server
		,j.name
		,j.enabled
		,j.description
		,s.step_id
		,s.step_name
		,s.subsystem
		--,s.command
		,CASE	WHEN CHARINDEX(CHAR(10),s.command,1) > 0
			THEN '...'
			ELSE s.command
		END AS command
		,s.database_name
FROM	msdb.dbo.sysjobs_view j INNER JOIN
		msdb.dbo.sysjobsteps s
			ON j.job_id = s.job_id