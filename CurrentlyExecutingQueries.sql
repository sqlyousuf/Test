WITH QSD (SQLStatement, PlanHandle, NumOfExecutions, Duration_ms, CPU_ms, Reads, Writes, QueryHash)
AS (SELECT   SUBSTRING(st.text,
                       (qs.statement_start_offset/2)+1,
                        ((CASE qs.statement_end_offset WHEN -1 THEN
                             DATALENGTH(st.text)
                          ELSE
                             qs.statement_end_offset
                          END - qs.statement_start_offset)/2) + 1)  AS SQLStatement
            , qs.plan_handle AS PlanHandle
            , execution_count AS NumOfExecutions
            , total_elapsed_time/1000 AS Duration_ms
            , total_worker_time/1000 AS CPU_ms
            , total_logical_reads AS Reads
            , total_logical_writes AS Writes
            , query_hash AS QueryHash
       FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text (qs.sql_handle) st
      WHERE query_hash != 0x0000000000000000)
 
  SELECT QSD.QueryHash,
         MIN(QSD.SQLStatement) AS SQLStatement,
          MIN(QSD.PlanHandle)   AS PlanHandle,
         SUM(QSD.NumOfExecutions) AS TotalNumOfExecutions,
         SUM(QSD.Duration_ms)/SUM(QSD.NumOfExecutions) AS AvgDuration_ms,
         SUM(QSD.CPU_ms)/SUM(QSD.NumOfExecutions) AS AvgCPU_ms,
         SUM(QSD.Reads)/SUM(QSD.NumOfExecutions) AS AvgReads,
         SUM(QSD.Writes)/SUM(QSD.NumOfExecutions) AS AvgWrites
    FROM QSD
GROUP BY QueryHash
ORDER BY AvgDuration_ms