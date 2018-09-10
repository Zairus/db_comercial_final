USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180907
-- Description:	Validar si se intenta afectar cuenta de modulo
-- =============================================
ALTER TRIGGER [dbo].[tg_ew_ct_cuentas_modulo]
	ON [dbo].[ew_ct_cuentas]
	FOR INSERT, UPDATE
AS 

SET NOCOUNT ON

DECLARE
	@cuenta AS VARCHAR(20)
	,@idmodulo AS INT
	,@mensaje AS VARCHAR(500)

DECLARE cur_valida_modulo CURSOR FOR
	SELECT
		i.cuenta
	FROM
		inserted AS i

OPEN cur_valida_modulo

FETCH NEXT FROM cur_valida_modulo INTO
	@cuenta

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @idmodulo = emc.idmodulo
	FROM 
		db_comercial.dbo.evoluware_modulos_contabilidad  AS emc
	WHERE
		emc.cuenta IN (
			SELECT
				ca.cuenta
			FROM 
				dbo._ct_fnc_arbol(@cuenta) AS ca
				LEFT JOIN ew_ct_cuentas AS cc
					ON cc.cuenta = ca.cuenta
			WHERE
				cc.nivel > 2
		)

	IF @idmodulo IS NOT NULL
	BEGIN
		CLOSE cur_valida_modulo
		DEALLOCATE cur_valida_modulo

		SELECT
			@mensaje = (
				'Error: '
				+ 'Se intenta modificar la cuenta '
				+ '[' + cc.cuenta + '] '
				+ cc.nombre
				+ ', que pertenece al modulo '
				+ em.nombre
				+ ', lo que no se permite para no crear inconsistencias. '
				+ 'Favor de afectar el modulo correspondiente.'
			)
		FROM
			db_comercial.dbo.evoluware_modulos AS em
			LEFT JOIN ew_ct_cuentas AS cc
				ON cc.cuenta = @cuenta
		WHERE
			em.idmodulo = @idmodulo

		RAISERROR(@mensaje, 16, 1)
		RETURN
	END

	FETCH NEXT FROM cur_valida_modulo INTO
		@cuenta
END

CLOSE cur_valida_modulo
DEALLOCATE cur_valida_modulo
GO
