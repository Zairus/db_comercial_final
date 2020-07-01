USE db_comercial_final
GO
IF OBJECT_ID('evoluware_email_servers') IS NOT NULL
BEGIN
	DROP VIEW evoluware_email_servers
END
GO
CREATE VIEW [dbo].[evoluware_email_servers]
AS
SELECT 
	idserver
	, db
	, server_name
	, server_port
	, server_ssl
	, server_username
	, server_password
	, server_sender
FROM 
	[dbEVOLUWARE].[dbo].[ew_sys_email_servers]
WHERE 
	db = DB_NAME()
GO
