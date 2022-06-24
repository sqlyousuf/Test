select		@@SERVERNAME AS ServerName,
			--j.job_id AS JobId,
			j.name AS JobName,
			j.description AS JobDescription,
			j.enabled AS JobEnabled
			--CAST(STUFF(STUFF(CAST(jh.run_date as varchar),7,0,'-'),5,0,'-') + ' ' + STUFF(STUFF(REPLACE(STR(jh.run_time,6,0),' ','0'),5,0,':'),3,0,':') as datetime) AS JobLastRunDate,
			--CASE jh.run_status 
			--	WHEN 0 
			--		THEN 'Failed'
			--	WHEN 1 
			--		THEN 'Success'
			--	WHEN 2 
			--		THEN 'Retry'
			--	WHEN 3 
			--		THEN 'Canceled'
			--	WHEN 4 
			--		THEN 'In progress'
			--END AS JobLastRunStatus,
			--jh.message AS JobLastRunMessage
FROM		msdb.dbo.sysjobs j
LEFT JOIN	(SELECT	a.job_id,
					MAX(a.instance_id) AS LastInstanceId
			FROM	msdb.dbo.sysjobhistory a
			WHERE	a.step_id = 0
			GROUP BY 
					a.job_id) b
				ON j.job_id = b.job_id
LEFT JOIN	msdb.dbo.sysjobhistory jh 
				ON jh.instance_id=b.LastInstanceId
ORDER BY	j.name