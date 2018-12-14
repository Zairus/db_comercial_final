USE [db_comercial_final]
GO
ALTER VIEW [dbo].[evoluware_email_servers]
AS
SELECT 
	idserver
	, db
	, server_name
	, server_port
	, server_ssl
	, server_username
	, server_password
FROM 
	[dbEVOLUWARE].[dbo].[ew_sys_email_servers]
WHERE 
	db = DB_NAME()
GO
