/* ==============================================================================
   02_restricciones_y_reglas.sql
   Proyecto integrador - Caso 3: Comercio electronico (SQL Server / T-SQL)

   Agrega a las tablas creadas en 01: UNIQUE, FOREIGN KEY, CHECK y DEFAULT.
   Cada restriccion lleva nombre propio (UQ_, FK_, CK_, DF_, UX_) para poder
   probarla y documentarla en documentacion/pruebas.md.

   Correcciones del docente aplicadas (ver tambien documentacion/reglas_negocio.md):
     [R7] CHECK de valores no negativos: producto.precio_actual,
          detalle_pedido.precio_unitario_aplicado, pago.monto,
          producto_proveedor.costo_referencia (y stock).
     [R7] DEFAULT documentado en el estado inicial: pedido -> 'CREADO',
          producto -> 'ACTIVO', despacho -> 'PREPARANDO' (pago -> 'PENDIENTE').
     [R6] despacho.estado existe, es NOT NULL, tiene DEFAULT y CHECK de dominio.
     [R1,R5] UNIQUE: cliente.documento, cliente.correo, producto.sku,
          categoria.codigo_categoria, pago.referencia_transaccion.
     [R6] numero_guia unico cuando existe: indice unico filtrado.
   ============================================================================== */
USE ComercioElectronico;
GO

/* ============================ 1. UNIQUE (claves alternas) ==================== */
ALTER TABLE dbo.categoria      ADD CONSTRAINT UQ_categoria_codigo        UNIQUE (codigo_categoria);   -- Regla 1
ALTER TABLE dbo.proveedor      ADD CONSTRAINT UQ_proveedor_nit           UNIQUE (nit);
ALTER TABLE dbo.producto       ADD CONSTRAINT UQ_producto_sku            UNIQUE (sku);                -- Regla 1
ALTER TABLE dbo.cliente        ADD CONSTRAINT UQ_cliente_documento       UNIQUE (documento);          -- Regla 1
ALTER TABLE dbo.cliente        ADD CONSTRAINT UQ_cliente_correo          UNIQUE (correo);             -- Regla 1
ALTER TABLE dbo.detalle_pedido ADD CONSTRAINT UQ_detalle_pedido_producto UNIQUE (id_pedido, id_producto); -- un producto por pedido
ALTER TABLE dbo.pago           ADD CONSTRAINT UQ_pago_referencia         UNIQUE (referencia_transaccion); -- Regla 5
ALTER TABLE dbo.transportadora ADD CONSTRAINT UQ_transportadora_nit      UNIQUE (nit);
GO

/* Regla 6: la guia es unica solo cuando existe.
   Un UNIQUE normal admite un unico NULL; el indice filtrado permite muchos NULL. */
CREATE UNIQUE NONCLUSTERED INDEX UX_despacho_numero_guia
    ON dbo.despacho (numero_guia)
    WHERE numero_guia IS NOT NULL;
GO

/* ============================ 2. FOREIGN KEY ================================= */
-- NO ACTION: se protege el historial; las bajas son logicas con el campo estado.
ALTER TABLE dbo.producto ADD CONSTRAINT FK_producto_categoria
    FOREIGN KEY (id_categoria) REFERENCES dbo.categoria (id_categoria)
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.producto_proveedor ADD CONSTRAINT FK_pp_producto
    FOREIGN KEY (id_producto) REFERENCES dbo.producto (id_producto)
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.producto_proveedor ADD CONSTRAINT FK_pp_proveedor
    FOREIGN KEY (id_proveedor) REFERENCES dbo.proveedor (id_proveedor)
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.pedido ADD CONSTRAINT FK_pedido_cliente
    FOREIGN KEY (id_cliente) REFERENCES dbo.cliente (id_cliente)
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.detalle_pedido ADD CONSTRAINT FK_detalle_pedido
    FOREIGN KEY (id_pedido) REFERENCES dbo.pedido (id_pedido)
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.detalle_pedido ADD CONSTRAINT FK_detalle_producto
    FOREIGN KEY (id_producto) REFERENCES dbo.producto (id_producto)
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.pago ADD CONSTRAINT FK_pago_pedido
    FOREIGN KEY (id_pedido) REFERENCES dbo.pedido (id_pedido)
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.despacho ADD CONSTRAINT FK_despacho_pedido
    FOREIGN KEY (id_pedido) REFERENCES dbo.pedido (id_pedido)
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE dbo.despacho ADD CONSTRAINT FK_despacho_transportadora
    FOREIGN KEY (id_transportadora) REFERENCES dbo.transportadora (id_transportadora)
    ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

/* ============================ 3. CHECK ======================================= */
-- Regla 7: precios, costos e importes no pueden ser negativos.
ALTER TABLE dbo.producto            ADD CONSTRAINT CK_producto_precio_actual     CHECK (precio_actual >= 0);
ALTER TABLE dbo.detalle_pedido      ADD CONSTRAINT CK_detalle_precio_aplicado    CHECK (precio_unitario_aplicado >= 0);
ALTER TABLE dbo.pago                ADD CONSTRAINT CK_pago_monto                 CHECK (monto >= 0);
ALTER TABLE dbo.producto_proveedor  ADD CONSTRAINT CK_pp_costo_referencia        CHECK (costo_referencia >= 0);

-- Inventario no negativo.
ALTER TABLE dbo.producto            ADD CONSTRAINT CK_producto_stock_actual      CHECK (stock_actual >= 0);
ALTER TABLE dbo.producto            ADD CONSTRAINT CK_producto_stock_minimo      CHECK (stock_minimo >= 0);

-- Regla 3: cantidad positiva.
ALTER TABLE dbo.detalle_pedido      ADD CONSTRAINT CK_detalle_cantidad           CHECK (cantidad > 0);

-- Dominios de estado y otros valores permitidos.
ALTER TABLE dbo.producto            ADD CONSTRAINT CK_producto_estado            CHECK (estado IN ('ACTIVO','INACTIVO','DESCONTINUADO'));
ALTER TABLE dbo.pedido              ADD CONSTRAINT CK_pedido_estado              CHECK (estado IN ('CREADO','PAGADO','PREPARADO','DESPACHADO','ENTREGADO','DEVUELTO','CANCELADO'));
ALTER TABLE dbo.pago                ADD CONSTRAINT CK_pago_estado                CHECK (estado IN ('PENDIENTE','APROBADO','RECHAZADO','REEMBOLSADO'));
ALTER TABLE dbo.pago                ADD CONSTRAINT CK_pago_metodo                CHECK (metodo_pago IN ('TARJETA_CREDITO','TARJETA_DEBITO','PSE','TRANSFERENCIA','BILLETERA','CONTRAENTREGA'));
ALTER TABLE dbo.despacho            ADD CONSTRAINT CK_despacho_estado            CHECK (estado IN ('PREPARANDO','EN_TRANSITO','ENTREGADO','DEVUELTO','FALLIDO'));  -- Regla 6
ALTER TABLE dbo.cliente             ADD CONSTRAINT CK_cliente_tipo_documento     CHECK (tipo_documento IN ('CC','CE','NIT','PAS','TI'));

-- Formato basico de correo.
ALTER TABLE dbo.cliente             ADD CONSTRAINT CK_cliente_correo_formato     CHECK (correo LIKE '%_@_%._%');
ALTER TABLE dbo.proveedor           ADD CONSTRAINT CK_proveedor_correo_formato   CHECK (correo LIKE '%_@_%._%');

-- Fechas coherentes del despacho (CHECK sobre columnas de la misma fila).
ALTER TABLE dbo.despacho            ADD CONSTRAINT CK_despacho_fechas
    CHECK (fecha_despacho IS NULL OR fecha_entrega IS NULL OR fecha_entrega >= fecha_despacho);
GO

/* ============================ 4. DEFAULT ===================================== */
-- Regla 7: estado inicial documentado.
ALTER TABLE dbo.producto ADD CONSTRAINT DF_producto_estado   DEFAULT 'ACTIVO'     FOR estado;      -- producto nuevo = ACTIVO
ALTER TABLE dbo.pedido   ADD CONSTRAINT DF_pedido_estado     DEFAULT 'CREADO'     FOR estado;      -- pedido nuevo = CREADO (aun sin pago)
ALTER TABLE dbo.despacho ADD CONSTRAINT DF_despacho_estado   DEFAULT 'PREPARANDO' FOR estado;      -- Regla 6
ALTER TABLE dbo.pago     ADD CONSTRAINT DF_pago_estado       DEFAULT 'PENDIENTE'  FOR estado;      -- intento sin respuesta

-- Valores iniciales de inventario y fechas de registro.
ALTER TABLE dbo.producto           ADD CONSTRAINT DF_producto_stock_actual    DEFAULT 0 FOR stock_actual;
ALTER TABLE dbo.producto           ADD CONSTRAINT DF_producto_stock_minimo    DEFAULT 0 FOR stock_minimo;
ALTER TABLE dbo.producto           ADD CONSTRAINT DF_producto_fecha_creacion  DEFAULT SYSDATETIME() FOR fecha_creacion;
ALTER TABLE dbo.producto_proveedor ADD CONSTRAINT DF_pp_fecha_ultimo_costo    DEFAULT (CAST(SYSDATETIME() AS DATE)) FOR fecha_ultimo_costo;
ALTER TABLE dbo.cliente            ADD CONSTRAINT DF_cliente_fecha_registro   DEFAULT SYSDATETIME() FOR fecha_registro;
ALTER TABLE dbo.pedido             ADD CONSTRAINT DF_pedido_fecha_pedido      DEFAULT SYSDATETIME() FOR fecha_pedido;
ALTER TABLE dbo.pago               ADD CONSTRAINT DF_pago_fecha_pago          DEFAULT SYSDATETIME() FOR fecha_pago;
GO

/* ============================ 5. VERIFICACION ================================ */
-- Debe mostrar: 10 tablas, 10 PK, 8 UQ, 9 FK, 16 CK, 11 DF y 1 indice unico filtrado (guia).
SELECT 'Tablas'            AS objeto, COUNT(*) AS cantidad FROM sys.tables              WHERE schema_id = SCHEMA_ID('dbo')
UNION ALL SELECT 'Primary keys',      COUNT(*) FROM sys.key_constraints                 WHERE type = 'PK'
UNION ALL SELECT 'Unique',            COUNT(*) FROM sys.key_constraints                 WHERE type = 'UQ'
UNION ALL SELECT 'Foreign keys',      COUNT(*) FROM sys.foreign_keys
UNION ALL SELECT 'Check',             COUNT(*) FROM sys.check_constraints
UNION ALL SELECT 'Default',           COUNT(*) FROM sys.default_constraints
UNION ALL SELECT 'Indice unico filtrado (guia)', COUNT(*) FROM sys.indexes WHERE name = 'UX_despacho_numero_guia';
GO

PRINT 'Restricciones y reglas aplicadas correctamente.';
GO
