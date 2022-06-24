USE msdb
GO

DECLARE @CreateFunctionSQL NVARCHAR(500) = N'
CREATE FUNCTION dbo.fn_IntToTimeString (@time INT)
RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE @return VARCHAR(20);
	SET @return = '''';
	IF @time IS NOT NULL
		AND @time >= 0
		AND @time < 240000
		SELECT	@return	= REPLACE( CONVERT(VARCHAR(20), CONVERT(TIME, 
									LEFT(RIGHT(''000000'' + CONVERT(VARCHAR(6), @time), 6), 2) + '':''
									+ SUBSTRING(RIGHT(''000000'' + CONVERT(VARCHAR(6), @time), 6), 3, 2) + '':''
									+ RIGHT(''00'' + CONVERT(VARCHAR(6), @time), 2)),109),''.0000000'','' '');
	RETURN @return;
END;'

IF NOT EXISTS(SELECT * FROM msdb.sys.objects WHERE object_id = OBJECT_ID(N'dbo.fn_IntToTimeString') AND type IN ('FN', 'FS'))
	EXEC sp_executesql @CreateFunctionSQL

DECLARE @daysOfWeek TABLE
(
		dayNumber	TINYINT,
		dayCode		TINYINT,
		dayName		VARCHAR(11)
)

INSERT INTO @daysOfWeek (
		dayNumber,
		dayCode,
		dayName)
VALUES	(1,1, 'Sunday'),
		(2,2, 'Monday'),
		(3,4, 'Tuesday'),
		(4,8, 'Wednesday'),
		(5,16, 'Thursday'),
		(6,32, 'Friday'),
		(7,64, 'Saturday');

DECLARE @daysOfWeek_relative TABLE
(
		dayNumber	INT,
		dayCode		INT,
		dayText		VARCHAR(250)
)

INSERT INTO @daysOfWeek_relative (
		dayNumber,
		dayCode,
		dayText)
VALUES	(1,1, 'On the <<wk>> Sunday of every <<n>> Month(s)'),
		(2,2, 'On the <<wk>> Monday of every <<n>> Month(s)'),
		(3,3, 'On the <<wk>> Tuesday of every <<n>> Month(s)'),
		(4,4, 'On the <<wk>> Wednesday of every <<n>> Month(s)'),
		(5,5, 'On the <<wk>> Thursday of every <<n>> Month(s)'),
		(6,6, 'On the <<wk>> Friday of every <<n>> Month(s)'),
		(7,7, 'On the <<wk>> Saturday of every <<n>> Month(s)'),
		(8,8, 'Each Day of the <<wk>> week of every <<n>> Month(s)'),
		(9,9, 'Each Weekday of the <<wk>> week of every <<n>> Month(s)'),
		(10,10, 'Each Weekend Day of the <<wk>> week of every <<n>> Month(s)');

DECLARE @weeksOfMonth TABLE
(
		womNumber	TINYINT,
		womCode		TINYINT,
		womName		VARCHAR(11)
)

INSERT INTO @weeksOfMonth (
		womNumber,
		womCode,
		womName)
VALUES	(1, 1, 'First'),
		(2, 2, 'Second'),
		(3, 4, 'Third'),
		(4, 8, 'Fourth'),
		(5, 16, 'Last');

DECLARE @Ordinal TABLE
(
		OrdinalID	INT,
		OrdinalCode	INT,
		OrdinalName	VARCHAR(20)
)

INSERT INTO @Ordinal (
		OrdinalID, 
		OrdinalCode, 
		OrdinalName)
VALUES	(1,1,'1st'),
		(2,2,'2nd'),
		(3,3,'3rd'),
		(4,4,'4th'),
		(5,5,'5th'),
		(6,6,'6th'),
		(7,7,'7th'),
		(8,8,'8th'),
		(9,9,'9th'),
		(10,10,'10th'),
		(11,11,'11th'),
		(12,12,'12th'),
		(13,13,'13th'),
		(14,14,'14th'),
		(15,15,'15th'),
		(16,16,'16th'),
		(17,17,'17th'),
		(18,18,'18th'),
		(19,19,'19th'),
		(20,20,'20th'),
		(21,21,'21st'),
		(22,22,'22nd'),
		(23,23,'23rd'),
		(24,24,'24th'),
		(25,25,'25th'),
		(26,26,'26th'),
		(27,27,'27th'),
		(28,28,'28th'),
		(29,29,'29th'),
		(30,30,'30th'),
		(31,31,'31st');

WITH CTE_DOW AS (
	SELECT DISTINCT
		    schedule_id,
			Days_of_Week = CONVERT(VARCHAR(250), STUFF(
									  (
										  SELECT	', ' + DOW.dayName
										  FROM		@daysOfWeek DOW
										  WHERE		ss.freq_interval & DOW.dayCode = DOW.dayCode
										  FOR XML PATH('')
									  ), 1, 2, ''))
    FROM	msdb.dbo.sysschedules ss
),
CTE_WOM AS (
	SELECT DISTINCT
		    schedule_id,
			Weeks_of_Month = CONVERT(VARCHAR(250), STUFF(
										(
											SELECT	', ' + WOM.womName
											FROM	@WeeksOfMonth WOM
											WHERE	ss.freq_relative_interval & WOM.womCode = WOM.womCode
											FOR XML PATH('')
										), 1, 2, ''))
    FROM	msdb.dbo.sysschedules ss
)
SELECT		Server_Name =			@@SERVERNAME,
			Job_Name =				sj.name,
			Job_Enabled =			sj.enabled,
			Schedule_Name =			ss.name,
			Schedule_Enabled =		ss.enabled,
			Frequency =				CONVERT(VARCHAR(500), CASE freq_type
																WHEN 1 
																	THEN 'One Time Only'
																WHEN 4 
																	THEN 'Every ' + CONVERT(VARCHAR(3), ss.freq_interval) + ' Day(s)'
																WHEN 8 
																	THEN 'Every ' + ISNULL(DOW.Days_of_Week, '') + ' of every '	+ CONVERT(VARCHAR(3), ss.freq_recurrence_factor ) + ' Week(s).'
																WHEN 16 
																	THEN 'On the ' + ISNULL(od.OrdinalName, '') + ' day of every ' + CONVERT(VARCHAR(3), ss.freq_recurrence_factor ) + ' Month(s).'
																WHEN 32 
																	THEN REPLACE(REPLACE(DOWR.dayText, '<<wk>>', ISNULL(WOM.Weeks_of_Month,'')),'<<n>>', CONVERT(VARCHAR(3), ss.freq_recurrence_factor))
																WHEN 64 
																	THEN 'When SQL Server Starts'
																WHEN 128 
																	THEN 'When SQL Server is Idle'
																ELSE '' 
														  END
										   ),
			Interday_Frequency =	CONVERT(VARCHAR(500), CASE 
																WHEN freq_type NOT IN ( 64, 128 ) 
																	THEN CASE freq_subday_type
																			WHEN 0 
																				THEN ' at '
																			WHEN 1 
																				THEN 'Once at '
																			WHEN 2 
																				THEN 'Every ' + CONVERT(VARCHAR(10),ss.freq_subday_interval) + ' Second(s) starting at '
																			WHEN 4 
																				THEN 'Every ' + CONVERT(VARCHAR(10),ss.freq_subday_interval) + ' Minutes(s) starting at '
																			WHEN 8 
																				THEN 'Every '+ CONVERT(VARCHAR(10), ss.freq_subday_interval) + ' Hours(s) starting at '
																			ELSE ''
																		END
																		+ msdb.dbo.fn_IntToTimeString(active_start_time)
																		+ CASE
																			  WHEN ss.freq_subday_type IN ( 2, 4, 8) THEN ' Ending at '
																						  + msdb.dbo.fn_IntToTimeString(active_end_time)
																			  ELSE ''
																		  END
																ELSE ''
														  END
											),
			active_start_date =		CONVERT(DATETIME, CONVERT( VARCHAR(8), ss.active_start_date, 114 )),
			active_start_time =		msdb.dbo.fn_IntToTimeString(active_start_time),
			active_end_date =		CONVERT(DATETIME, CONVERT(VARCHAR(8), ss.active_end_date, 114)),
			active_end_time =		msdb.dbo.fn_IntToTimeString(active_end_time)
FROM		msdb.dbo.sysjobs sj
JOIN		msdb.dbo.sysjobschedules sjs
				ON sj.job_id = sjs.job_id
JOIN		msdb.dbo.sysschedules ss
				ON sjs.schedule_id = ss.schedule_id
LEFT JOIN	CTE_DOW DOW
				ON ss.schedule_id = DOW.schedule_id
LEFT JOIN	CTE_WOM WOM
				ON ss.schedule_id = WOM.schedule_id
LEFT JOIN	@Ordinal od
				ON ss.freq_interval = od.OrdinalCode
LEFT JOIN	@Ordinal om
				ON ss.freq_recurrence_factor = om.OrdinalCode
LEFT JOIN	@daysOfWeek_relative DOWR
				ON ss.freq_interval = DOWR.dayCode
ORDER BY	sj.Name,
			ss.active_start_time;