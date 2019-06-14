USE db_comercial_final
GO
IF TYPE_ID('EWValueReplacementType') IS NULL
BEGIN
	CREATE TYPE EWValueReplacementType AS TABLE (str_code VARCHAR(500), str_value VARCHAR(500))
END
GO
