SELECT
    ServerName = @@ServerName,
    sj.name,
    sj.enabled,
    sjs.step_id,
    sjs.step_name,
    sjs.database_name,
    sjs.subsystem,
    sjs.command,
    sjs.last_run_outcome,
    last_run = CASE
                   WHEN LEN(sjs.last_run_date) = 8 THEN
                       CONVERT(
                                  DATETIME,
                                  CONVERT(VARCHAR(8), sjs.last_run_date)
                                  + '  '
                                  + LEFT(RIGHT('000000'
                                               + CONVERT(
                                                            VARCHAR(6),
                                                            sjs.last_run_time
                                                        ), 6), 2) + ':'
                                  + SUBSTRING(
                                                 RIGHT('000000'
                                                       + CONVERT(
                                                                    VARCHAR(6),
                                                                    sjs.last_run_time
                                                                ), 6),
                                                 3,
                                                 2
                                             ) + ':'
                                  + RIGHT('00'
                                          + CONVERT(
                                                       VARCHAR(6),
                                                       sjs.last_run_time
                                                   ), 2)
                              )
                   ELSE
                       NULL
               END
FROM
    msdb.dbo.sysjobs sj
    JOIN msdb.dbo.sysjobsteps sjs
        ON sj.job_id = sjs.job_id
ORDER BY
    sj.name,
    sjs.step_id;