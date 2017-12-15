USE db_comercial_final

ALTER TABLE ew_cfd_comprobantes ALTER COLUMN cfd_subTotal DECIMAL(18, 6)
ALTER TABLE ew_cfd_comprobantes ALTER COLUMN xcfd_descuento DECIMAL(18, 6)
ALTER TABLE ew_cfd_comprobantes ALTER COLUMN cfd_total DECIMAL(18, 6)
ALTER TABLE ew_cfd_comprobantes ALTER COLUMN cfd_descuento DECIMAL(18, 6)

ALTER TABLE ew_cfd_comprobantes_impuesto ALTER COLUMN cfd_importe DECIMAL(18, 6)

ALTER TABLE ew_cfd_comprobantes_mov ALTER COLUMN cfd_cantidad DECIMAL(18, 6)
ALTER TABLE ew_cfd_comprobantes_mov ALTER COLUMN cfd_valorUnitario DECIMAL(18, 6)
ALTER TABLE ew_cfd_comprobantes_mov ALTER COLUMN cfd_importe DECIMAL(18, 6)
