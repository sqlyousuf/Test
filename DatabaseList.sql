USE master
GO
SELECT		ServerName = @@SERVERNAME,
			DatabaseName    = d.name,
			CompatibilityLevel = d.compatibility_level,
			RecoveryMode = d.recovery_model_desc,
			ISNULL(NULLIF(ISNULL(dek.encryptor_type + '-','') + ISNULL(dek.key_algorithm + '-','') + ISNULL(CAST(dek.key_length AS VARCHAR(4)),''),''),'None') AS EncryptionType,
			CertificateName = cer.name,
			cer.expiry_date
FROM		sys.databases d
LEFT JOIN	sys.dm_database_encryption_keys AS dek
				ON d.database_id = dek.database_id
				AND dek.encryption_state = 3
LEFT JOIN	sys.certificates                AS cer
				ON dek.encryptor_thumbprint = cer.thumbprint
WHERE		d.name NOT IN ('master','tempdb','model','msdb','distribution','SSISDB')
ORDER BY	d.name