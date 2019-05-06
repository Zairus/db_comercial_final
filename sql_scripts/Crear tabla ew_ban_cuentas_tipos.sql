USE db_comercial_final
GO
IF OBJECT_ID('ew_ban_cuentas_tipos') IS NOT NULL
BEGIN
	DROP TABLE ew_ban_cuentas_tipos
END
GO
CREATE TABLE ew_ban_cuentas_tipos (
	idr INT IDENTITY
	, idtipocuenta SMALLINT NOT NULL
	, nombre VARCHAR(50) NOT NULL
	, bancarizado BIT
) ON [PRIMARY]
GO
INSERT INTO ew_ban_cuentas_tipos (idtipocuenta, nombre, bancarizado) VALUES (0, 'Cheques', 1)
INSERT INTO ew_ban_cuentas_tipos (idtipocuenta, nombre, bancarizado) VALUES (1, 'Ahorro', 1)
INSERT INTO ew_ban_cuentas_tipos (idtipocuenta, nombre, bancarizado) VALUES (2, 'Crédito', 1)
INSERT INTO ew_ban_cuentas_tipos (idtipocuenta, nombre, bancarizado) VALUES (3, 'Caja de Ventas', 0)
INSERT INTO ew_ban_cuentas_tipos (idtipocuenta, nombre, bancarizado) VALUES (4, 'Caja de Gastos', 0)
INSERT INTO ew_ban_cuentas_tipos (idtipocuenta, nombre, bancarizado) VALUES (5, 'Caja Receptora', 0)
GO
SELECT * FROM ew_ban_cuentas_tipos
