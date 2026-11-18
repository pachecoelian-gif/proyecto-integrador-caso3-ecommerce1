/* ==============================================================================
   01_crear_base_y_tablas.sql
   Proyecto integrador - Caso 3: Comercio electronico (SQL Server / T-SQL)

   Crea la base de datos y las 10 tablas con sus columnas, tipos, NOT NULL,
   IDENTITY y llaves primarias.
   Las demas restricciones (UNIQUE, FOREIGN KEY, CHECK, DEFAULT) se agregan en
   02_restricciones_y_reglas.sql para que cada regla quede nombrada y visible.

   Coherente con: modelo/diccionario_datos.md, modelo_er.png, modelo_relacional.png
   Orden de creacion: primero tablas "padre", luego tablas "hija".
   ============================================================================== */
USE master;
GO

IF DB_ID(N'ComercioElectronico') IS NULL
    CREATE DATABASE ComercioElectronico;
GO

USE ComercioElectronico;
GO

SET NOCOUNT ON;
GO

/* ---------------------------- 1. CATEGORIA ---------------------------------- */
CREATE TABLE dbo.categoria (
    id_categoria      INT IDENTITY(1,1) NOT NULL,
    codigo_categoria  VARCHAR(20)       NOT NULL,
    nombre            VARCHAR(100)      NOT NULL,
    descripcion       VARCHAR(300)      NULL,
    CONSTRAINT PK_categoria PRIMARY KEY (id_categoria)
);
GO

/* ---------------------------- 2. PROVEEDOR ---------------------------------- */
CREATE TABLE dbo.proveedor (
    id_proveedor  INT IDENTITY(1,1) NOT NULL,
    nit           VARCHAR(20)       NOT NULL,
    nombre        VARCHAR(150)      NOT NULL,
    correo        VARCHAR(150)      NULL,
    telefono      VARCHAR(20)       NULL,
    ciudad        VARCHAR(80)       NULL,
    CONSTRAINT PK_proveedor PRIMARY KEY (id_proveedor)
);
GO

/* ---------------------------- 3. PRODUCTO ----------------------------------- */
CREATE TABLE dbo.producto (
    id_producto     INT IDENTITY(1,1) NOT NULL,
    sku             VARCHAR(30)       NOT NULL,
    nombre          VARCHAR(150)      NOT NULL,
    descripcion     VARCHAR(500)      NULL,
    id_categoria    INT               NOT NULL,
    precio_actual   DECIMAL(12,2)     NOT NULL,
    stock_actual    INT               NOT NULL,
    stock_minimo    INT               NOT NULL,
    estado          VARCHAR(15)       NOT NULL,
    fecha_creacion  DATETIME2         NOT NULL,
    CONSTRAINT PK_producto PRIMARY KEY (id_producto)
);
GO

/* ------------------------ 4. PRODUCTO_PROVEEDOR ----------------------------- */
CREATE TABLE dbo.producto_proveedor (
    id_producto         INT           NOT NULL,
    id_proveedor        INT           NOT NULL,
    costo_referencia    DECIMAL(12,2) NOT NULL,
    fecha_ultimo_costo  DATE          NOT NULL,
    CONSTRAINT PK_producto_proveedor PRIMARY KEY (id_producto, id_proveedor)
);
GO

/* ---------------------------- 5. CLIENTE ------------------------------------ */
CREATE TABLE dbo.cliente (
    id_cliente      INT IDENTITY(1,1) NOT NULL,
    tipo_documento  VARCHAR(5)        NOT NULL,
    documento       VARCHAR(20)       NOT NULL,
    nombres         VARCHAR(80)       NOT NULL,
    apellidos       VARCHAR(80)       NOT NULL,
    correo          VARCHAR(150)      NOT NULL,
    telefono        VARCHAR(20)       NULL,
    fecha_registro  DATETIME2         NOT NULL,
    CONSTRAINT PK_cliente PRIMARY KEY (id_cliente)
);
GO

/* ---------------------------- 6. PEDIDO ------------------------------------- */
CREATE TABLE dbo.pedido (
    id_pedido     INT IDENTITY(1,1) NOT NULL,
    id_cliente    INT               NOT NULL,
    fecha_pedido  DATETIME2         NOT NULL,
    estado        VARCHAR(15)       NOT NULL,
    CONSTRAINT PK_pedido PRIMARY KEY (id_pedido)
);
GO

/* -------------------------- 7. DETALLE_PEDIDO ------------------------------- */
CREATE TABLE dbo.detalle_pedido (
    id_detalle_pedido         INT IDENTITY(1,1) NOT NULL,
    id_pedido                 INT               NOT NULL,
    id_producto               INT               NOT NULL,
    cantidad                  INT               NOT NULL,
    precio_unitario_aplicado  DECIMAL(12,2)     NOT NULL,
    CONSTRAINT PK_detalle_pedido PRIMARY KEY (id_detalle_pedido)
);
GO

/* ------------------------------ 8. PAGO ------------------------------------- */
CREATE TABLE dbo.pago (
    id_pago                 INT IDENTITY(1,1) NOT NULL,
    id_pedido               INT               NOT NULL,
    referencia_transaccion  VARCHAR(50)       NOT NULL,
    metodo_pago             VARCHAR(20)       NOT NULL,
    monto                   DECIMAL(12,2)     NOT NULL,
    estado                  VARCHAR(15)       NOT NULL,
    fecha_pago              DATETIME2         NOT NULL,
    CONSTRAINT PK_pago PRIMARY KEY (id_pago)
);
GO

/* -------------------------- 9. TRANSPORTADORA ------------------------------- */
CREATE TABLE dbo.transportadora (
    id_transportadora  INT IDENTITY(1,1) NOT NULL,
    nit                VARCHAR(20)       NOT NULL,
    nombre             VARCHAR(120)      NOT NULL,
    telefono           VARCHAR(20)       NULL,
    CONSTRAINT PK_transportadora PRIMARY KEY (id_transportadora)
);
GO

/* ---------------------------- 10. DESPACHO ---------------------------------- */
CREATE TABLE dbo.despacho (
    id_despacho        INT IDENTITY(1,1) NOT NULL,
    id_pedido          INT               NOT NULL,
    id_transportadora  INT               NOT NULL,
    numero_guia        VARCHAR(30)       NULL,      -- NULL mientras el envio se prepara
    fecha_despacho     DATETIME2         NULL,
    fecha_entrega      DATETIME2         NULL,
    estado             VARCHAR(15)       NOT NULL,  -- Regla 6: estado del despacho
    direccion_entrega  VARCHAR(200)      NOT NULL,
    ciudad_entrega     VARCHAR(80)       NOT NULL,
    CONSTRAINT PK_despacho PRIMARY KEY (id_despacho)
);
GO

PRINT 'Base de datos y 10 tablas creadas correctamente.';
GO
