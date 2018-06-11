USE db_comercial_final
GO
ALTER VIEW ew_sys_periodos_datos
AS

SELECT [id] = 0, [descripcion] = '-Seleccione-', [grupo] = 'global'

UNION ALL

SELECT [id] = 1, [descripcion] = 'Enero', [grupo] = 'meses'
UNION ALL
SELECT [id] = 2, [descripcion] = 'Febrero', [grupo] = 'meses'
UNION ALL
SELECT [id] = 3, [descripcion] = 'Marzo', [grupo] = 'meses'
UNION ALL
SELECT [id] = 4, [descripcion] = 'Abril', [grupo] = 'meses'
UNION ALL
SELECT [id] = 5, [descripcion] = 'Mayo', [grupo] = 'meses'
UNION ALL
SELECT [id] = 6, [descripcion] = 'Junio', [grupo] = 'meses'
UNION ALL
SELECT [id] = 7, [descripcion] = 'Julio', [grupo] = 'meses'
UNION ALL
SELECT [id] = 8, [descripcion] = 'Agosto', [grupo] = 'meses'
UNION ALL
SELECT [id] = 9, [descripcion] = 'Septiembre', [grupo] = 'meses'
UNION ALL
SELECT [id] = 10, [descripcion] = 'Octubre', [grupo] = 'meses'
UNION ALL
SELECT [id] = 11, [descripcion] = 'Noviembre', [grupo] = 'meses'
UNION ALL
SELECT [id] = 12, [descripcion] = 'Diciembre', [grupo] = 'meses'

UNION ALL

SELECT [id] = 1, [descripcion] = '1', [grupo] = 'dias' UNION ALL
SELECT [id] = 2, [descripcion] = '2', [grupo] = 'dias' UNION ALL
SELECT [id] = 3, [descripcion] = '3', [grupo] = 'dias' UNION ALL
SELECT [id] = 4, [descripcion] = '4', [grupo] = 'dias' UNION ALL
SELECT [id] = 5, [descripcion] = '5', [grupo] = 'dias' UNION ALL
SELECT [id] = 6, [descripcion] = '6', [grupo] = 'dias' UNION ALL
SELECT [id] = 7, [descripcion] = '7', [grupo] = 'dias' UNION ALL
SELECT [id] = 8, [descripcion] = '8', [grupo] = 'dias' UNION ALL
SELECT [id] = 9, [descripcion] = '9', [grupo] = 'dias' UNION ALL
SELECT [id] = 10, [descripcion] = '10', [grupo] = 'dias' UNION ALL
SELECT [id] = 11, [descripcion] = '11', [grupo] = 'dias' UNION ALL
SELECT [id] = 12, [descripcion] = '12', [grupo] = 'dias' UNION ALL
SELECT [id] = 13, [descripcion] = '13', [grupo] = 'dias' UNION ALL
SELECT [id] = 14, [descripcion] = '14', [grupo] = 'dias' UNION ALL
SELECT [id] = 15, [descripcion] = '15', [grupo] = 'dias' UNION ALL
SELECT [id] = 16, [descripcion] = '16', [grupo] = 'dias' UNION ALL
SELECT [id] = 17, [descripcion] = '17', [grupo] = 'dias' UNION ALL
SELECT [id] = 18, [descripcion] = '18', [grupo] = 'dias' UNION ALL
SELECT [id] = 19, [descripcion] = '19', [grupo] = 'dias' UNION ALL
SELECT [id] = 20, [descripcion] = '20', [grupo] = 'dias' UNION ALL
SELECT [id] = 21, [descripcion] = '21', [grupo] = 'dias' UNION ALL
SELECT [id] = 22, [descripcion] = '22', [grupo] = 'dias' UNION ALL
SELECT [id] = 23, [descripcion] = '23', [grupo] = 'dias' UNION ALL
SELECT [id] = 24, [descripcion] = '24', [grupo] = 'dias' UNION ALL
SELECT [id] = 25, [descripcion] = '25', [grupo] = 'dias' UNION ALL
SELECT [id] = 26, [descripcion] = '26', [grupo] = 'dias' UNION ALL
SELECT [id] = 27, [descripcion] = '27', [grupo] = 'dias' UNION ALL
SELECT [id] = 28, [descripcion] = '28', [grupo] = 'dias' UNION ALL
SELECT [id] = 29, [descripcion] = '29', [grupo] = 'dias' UNION ALL
SELECT [id] = 30, [descripcion] = '30', [grupo] = 'dias' UNION ALL
SELECT [id] = 31, [descripcion] = '31', [grupo] = 'dias' 

UNION ALL

SELECT [id] = 1, [descripcion] = 'Domingo', [grupo] = 'dias_semana' UNION ALL
SELECT [id] = 2, [descripcion] = 'Lunes', [grupo] = 'dias_semana' UNION ALL
SELECT [id] = 3, [descripcion] = 'Martes', [grupo] = 'dias_semana' UNION ALL
SELECT [id] = 4, [descripcion] = 'Miercoles', [grupo] = 'dias_semana' UNION ALL
SELECT [id] = 5, [descripcion] = 'Jueves', [grupo] = 'dias_semana' UNION ALL
SELECT [id] = 6, [descripcion] = 'Viernes', [grupo] = 'dias_semana' UNION ALL
SELECT [id] = 7, [descripcion] = 'Sabado', [grupo] = 'dias_semana' UNION ALL
SELECT [id] = 8, [descripcion] = 'Domingo', [grupo] = 'dias_semana' 

UNION ALL

SELECT [id] = 0, [descripcion] = '', [grupo] = 'ninguno'
GO
