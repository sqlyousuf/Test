USE master
GO
SELECT	ServerName = @@SERVERNAME + CASE WHEN @@SERVERNAME IN ('SV-PROD-DATA2','SV-RP-PROD-META') THEN '.WTI.GLOBAL' ELSE '.WORLDINC.COM' END,
		CertificateName = name,
		'Database Encryption' AS Usage,
		'AES' AS Algorithm,
		CAST(key_length AS VARCHAR) + ' bits' AS KeyLength,
		expiry_date AS ExpirationDate
		,*
--select *
FROM	sys.certificates  
WHERE LEFT(Name,2) <> '##'
