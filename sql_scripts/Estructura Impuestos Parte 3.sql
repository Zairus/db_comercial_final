USE db_comercial_final

/*
######################################
## Limpia remanente de impuestos
######################################
*/

DELETE FROM ew_cat_impuestos WHERE activo = 0

SELECT * FROM ew_cat_impuestos
