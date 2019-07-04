USE db_comercial_final

UPDATE ew_sys_ciudades SET c_pais = 'MEX' WHERE pais IN ('MEXICO', 'MÉXICO')
UPDATE ew_sys_ciudades SET c_pais = 'USA' WHERE pais IN ('USA', 'ESTADOS UNIDOS')
