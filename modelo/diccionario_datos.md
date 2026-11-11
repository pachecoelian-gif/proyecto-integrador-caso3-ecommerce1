# Diccionario de datos — Caso 3: Comercio electrónico (versión 2)

**Base de datos:** `ComercioElectronico` (SQL Server) · **Motor del diagrama relacional:** MySQL Workbench (solo dibujo)
**Coherente con:** `modelo_er.png`, `modelo_relacional.png`, `normalizacion.md`.

**Cambios respecto a la versión 1:** se agregó la columna *Ejemplo*, la columna *DEFAULT*, el resumen de tablas, el mapa de llaves foráneas con cardinalidad, los catálogos de valores de los estados y las listas consolidadas de UNIQUE, CHECK y DEFAULT.

## 0. Convenciones
- **Nulo:** No = NOT NULL · Sí = permite NULL.
- **Clave:** PK llave primaria · FK foránea · UK única (clave alterna).
- **Tipos:** los de SQL Server. En el diagrama de Workbench aparece `DATETIME` donde en SQL Server se usará `DATETIME2`; es solo una diferencia del programa de dibujo.
- **Estados** en MAYÚSCULAS, validados con CHECK.
- Todos los datos son **sintéticos**; los ejemplos son ficticios.

## 1. Resumen de tablas
| # | Tabla | Propósito | PK | Claves alternas (UK) | FKs |
|---|---|---|---|---|---|
| 1 | CATEGORIA | Clasificación del catálogo | id_categoria | codigo_categoria | — |
| 2 | PROVEEDOR | Empresas que suministran | id_proveedor | nit | — |
| 3 | PRODUCTO | Catálogo, precio vigente e inventario | id_producto | sku | id_categoria |
| 4 | PRODUCTO_PROVEEDOR | Puente N:M con costo de referencia | (id_producto, id_proveedor) | — | id_producto, id_proveedor |
| 5 | CLIENTE | Compradores | id_cliente | documento, correo | — |
| 6 | PEDIDO | Cabecera de compra | id_pedido | — | id_cliente |
| 7 | DETALLE_PEDIDO | Líneas del pedido con precio congelado | id_detalle_pedido | (id_pedido, id_producto) | id_pedido, id_producto |
| 8 | PAGO | Pagos e intentos de pago | id_pago | referencia_transaccion | id_pedido |
| 9 | TRANSPORTADORA | Empresas de envío | id_transportadora | nit | — |
| 10 | DESPACHO | Envíos de un pedido | id_despacho | numero_guia (filtrado, no nulo) | id_pedido, id_transportadora |

## 2. Detalle por tabla

### 2.1 CATEGORIA
| Atributo | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas | Ejemplo |
|---|---|---|---|---|---|---|---|
| id_categoria | Identificador interno de la categoría | INT IDENTITY(1,1) | No | PK | autogenerado | — | 1 |
| codigo_categoria | Código de negocio | VARCHAR(20) | No | UK | — | Único (regla 1) | CAT-ELEC |
| nombre | Nombre de la categoría | VARCHAR(100) | No | | — | No vacío | Electrónica |
| descripcion | Texto descriptivo | VARCHAR(300) | Sí | | NULL | — | Dispositivos y accesorios |

### 2.2 PROVEEDOR
| Atributo | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas | Ejemplo |
|---|---|---|---|---|---|---|---|
| id_proveedor | Identificador interno | INT IDENTITY(1,1) | No | PK | autogenerado | — | 1 |
| nit | Identificación tributaria | VARCHAR(20) | No | UK | — | Único | 900123456-7 |
| nombre | Razón social | VARCHAR(150) | No | | — | — | Distribuciones Andina S.A.S. |
| correo | Correo de contacto | VARCHAR(150) | Sí | | NULL | Formato con @ (CHECK LIKE) | ventas@andina.example |
| telefono | Teléfono | VARCHAR(20) | Sí | | NULL | — | 3101234567 |
| ciudad | Ciudad de la sede | VARCHAR(80) | Sí | | NULL | — | Bogotá |

### 2.3 PRODUCTO
| Atributo | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas | Ejemplo |
|---|---|---|---|---|---|---|---|
| id_producto | Identificador interno | INT IDENTITY(1,1) | No | PK | autogenerado | — | 123 |
| sku | Código único del producto | VARCHAR(30) | No | UK | — | Único (regla 1) | SKU-000123 |
| nombre | Nombre comercial | VARCHAR(150) | No | | — | — | Mouse inalámbrico X200 |
| descripcion | Descripción | VARCHAR(500) | Sí | | NULL | — | Mouse 2.4 GHz, 1600 DPI |
| id_categoria | Categoría a la que pertenece | INT | No | FK → CATEGORIA | — | Obligatoria (regla 2); NO ACTION | 1 |
| precio_actual | Precio de venta **vigente** | DECIMAL(12,2) | No | | — | CHECK ≥ 0 (regla 7); su cambio no altera pedidos pasados (regla 4) | 45000.00 |
| stock_actual | Unidades disponibles | INT | No | | 0 | CHECK ≥ 0 | 120 |
| stock_minimo | Umbral de reposición | INT | No | | 0 | CHECK ≥ 0 | 20 |
| estado | Estado del producto | VARCHAR(15) | No | | 'ACTIVO' | CHECK IN ('ACTIVO','INACTIVO','DESCONTINUADO') (regla 7) | ACTIVO |
| fecha_creacion | Alta en el catálogo | DATETIME2 | No | | SYSDATETIME() | — | 2026-01-15 09:30:00 |

### 2.4 PRODUCTO_PROVEEDOR
| Atributo | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas | Ejemplo |
|---|---|---|---|---|---|---|---|
| id_producto | Producto suministrado | INT | No | PK, FK → PRODUCTO | — | NO ACTION | 123 |
| id_proveedor | Proveedor que lo suministra | INT | No | PK, FK → PROVEEDOR | — | La PK compuesta impide repetir el par (regla 2); NO ACTION | 1 |
| costo_referencia | Costo de referencia de esa relación | DECIMAL(12,2) | No | | — | CHECK ≥ 0 (reglas 2 y 7) | 28000.00 |
| fecha_ultimo_costo | Fecha de vigencia del costo | DATE | No | | GETDATE() | — | 2026-09-01 |

### 2.5 CLIENTE
| Atributo | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas | Ejemplo |
|---|---|---|---|---|---|---|---|
| id_cliente | Identificador interno | INT IDENTITY(1,1) | No | PK | autogenerado | — | 500 |
| tipo_documento | Tipo de documento | VARCHAR(5) | No | | — | CHECK IN ('CC','CE','NIT','PAS','TI') | CC |
| documento | Número de documento | VARCHAR(20) | No | UK | — | Único (regla 1) | 1006123456 |
| nombres | Nombres | VARCHAR(80) | No | | — | — | Ana María |
| apellidos | Apellidos | VARCHAR(80) | No | | — | — | Ruiz Gómez |
| correo | Correo electrónico | VARCHAR(150) | No | UK | — | Único; CHECK formato con @ (regla 1) | ana.ruiz@example.com |
| telefono | Teléfono | VARCHAR(20) | Sí | | NULL | — | 3209876543 |
| fecha_registro | Alta del cliente | DATETIME2 | No | | SYSDATETIME() | — | 2026-03-10 18:05:00 |

### 2.6 PEDIDO
| Atributo | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas | Ejemplo |
|---|---|---|---|---|---|---|---|
| id_pedido | Identificador del pedido | INT IDENTITY(1,1) | No | PK | autogenerado | — | 1001 |
| id_cliente | Cliente que compra | INT | No | FK → CLIENTE | — | Obligatorio (regla 3); NO ACTION | 500 |
| fecha_pedido | Fecha y hora de creación | DATETIME2 | No | | SYSDATETIME() | — | 2026-10-02 14:20:00 |
| estado | Estado del ciclo de vida | VARCHAR(15) | No | | 'CREADO' | CHECK IN ('CREADO','PAGADO','PREPARADO','DESPACHADO','ENTREGADO','DEVUELTO','CANCELADO') (regla 7) | CREADO |

> El total del pedido **no es una columna**: se calcula con `SUM(cantidad * precio_unitario_aplicado)` sobre DETALLE_PEDIDO.

### 2.7 DETALLE_PEDIDO
| Atributo | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas | Ejemplo |
|---|---|---|---|---|---|---|---|
| id_detalle_pedido | Identificador de la línea | INT IDENTITY(1,1) | No | PK | autogenerado | — | 2001 |
| id_pedido | Pedido al que pertenece | INT | No | FK → PEDIDO; UK compuesta (id_pedido, id_producto) | — | NO ACTION | 1001 |
| id_producto | Producto vendido | INT | No | FK → PRODUCTO; UK compuesta (id_pedido, id_producto) | — | Un producto aparece una sola vez por pedido; NO ACTION | 123 |
| cantidad | Unidades vendidas | INT | No | | — | CHECK > 0 (regla 3) | 2 |
| precio_unitario_aplicado | Precio cobrado al momento de la venta | DECIMAL(12,2) | No | | — | CHECK ≥ 0; no se modifica si cambia producto.precio_actual (regla 4) | 45000.00 |

### 2.8 PAGO
| Atributo | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas | Ejemplo |
|---|---|---|---|---|---|---|---|
| id_pago | Identificador del pago o intento | INT IDENTITY(1,1) | No | PK | autogenerado | — | 3001 |
| id_pedido | Pedido al que corresponde | INT | No | FK → PEDIDO | — | Varios pagos por pedido permitidos (regla 5); NO ACTION | 1001 |
| referencia_transaccion | Referencia de la pasarela de pago | VARCHAR(50) | No | UK | — | Única (regla 5) | TX-20261002-000457 |
| metodo_pago | Medio de pago | VARCHAR(20) | No | | — | CHECK IN ('TARJETA_CREDITO','TARJETA_DEBITO','PSE','TRANSFERENCIA','BILLETERA','CONTRAENTREGA') | PSE |
| monto | Importe del pago | DECIMAL(12,2) | No | | — | CHECK ≥ 0 (regla 7) | 90000.00 |
| estado | Estado del pago | VARCHAR(15) | No | | 'PENDIENTE' | CHECK IN ('PENDIENTE','APROBADO','RECHAZADO','REEMBOLSADO') | APROBADO |
| fecha_pago | Fecha y hora del intento | DATETIME2 | No | | SYSDATETIME() | — | 2026-10-02 14:25:00 |

### 2.9 TRANSPORTADORA
| Atributo | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas | Ejemplo |
|---|---|---|---|---|---|---|---|
| id_transportadora | Identificador interno | INT IDENTITY(1,1) | No | PK | autogenerado | — | 7 |
| nit | NIT de la empresa | VARCHAR(20) | No | UK | — | Único | 800987654-3 |
| nombre | Nombre de la empresa | VARCHAR(120) | No | | — | — | Envíos Rápidos S.A. |
| telefono | Teléfono de contacto | VARCHAR(20) | Sí | | NULL | — | 6017654321 |

### 2.10 DESPACHO
| Atributo | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas | Ejemplo |
|---|---|---|---|---|---|---|---|
| id_despacho | Identificador del envío | INT IDENTITY(1,1) | No | PK | autogenerado | — | 4001 |
| id_pedido | Pedido despachado | INT | No | FK → PEDIDO | — | NO ACTION | 1001 |
| id_transportadora | Transportadora asignada | INT | No | FK → TRANSPORTADORA | — | Regla 6; NO ACTION | 7 |
| numero_guia | Guía de la transportadora | VARCHAR(30) | Sí | UK filtrado | NULL | Índice único `WHERE numero_guia IS NOT NULL` (regla 6) | ER-77812345 |
| fecha_despacho | Salida de bodega | DATETIME2 | Sí | | NULL | Nula mientras está en preparación | 2026-10-03 08:00:00 |
| fecha_entrega | Entrega al cliente | DATETIME2 | Sí | | NULL | CHECK: si ambas fechas existen, fecha_entrega ≥ fecha_despacho | 2026-10-05 16:30:00 |
| estado | Estado del envío | VARCHAR(15) | No | | 'PREPARANDO' | CHECK IN ('PREPARANDO','EN_TRANSITO','ENTREGADO','DEVUELTO','FALLIDO') | EN_TRANSITO |
| direccion_entrega | Dirección usada en este envío (foto histórica) | VARCHAR(200) | No | | — | — | Cra 15 # 80-20, Apto 301 |
| ciudad_entrega | Ciudad de entrega | VARCHAR(80) | No | | — | — | Villavicencio |

## 3. Mapa de llaves foráneas y cardinalidad
| FK (hija → padre) | Cardinalidad padre : hija | Participación | Nulable | ON DELETE / ON UPDATE |
|---|---|---|---|---|
| producto.id_categoria → categoria | 1 : N | Hija total; padre parcial | No | NO ACTION |
| producto_proveedor.id_producto → producto | 1 : N | Padre parcial | No | NO ACTION |
| producto_proveedor.id_proveedor → proveedor | 1 : N | Padre parcial | No | NO ACTION |
| pedido.id_cliente → cliente | 1 : N | Hija total; padre parcial (clientes sin pedidos) | No | NO ACTION |
| detalle_pedido.id_pedido → pedido | 1 : N | Total en ambos lados (pedido con ≥ 1 línea, garantizado por procedimiento) | No | NO ACTION |
| detalle_pedido.id_producto → producto | 1 : N | Padre parcial (productos nunca vendidos) | No | NO ACTION |
| pago.id_pedido → pedido | 1 : N | Padre parcial (pedido aún sin pago) | No | NO ACTION |
| despacho.id_pedido → pedido | 1 : N | Padre parcial (pedido aún sin despachar) | No | NO ACTION |
| despacho.id_transportadora → transportadora | 1 : N | Hija total; padre parcial | No | NO ACTION |

Se usa NO ACTION (sin CASCADE) para proteger el historial; las bajas se hacen con el campo `estado`.

## 4. Restricciones consolidadas
**UNIQUE:** categoria.codigo_categoria · proveedor.nit · producto.sku · cliente.documento · cliente.correo · detalle_pedido(id_pedido, id_producto) · pago.referencia_transaccion · transportadora.nit · despacho.numero_guia (índice filtrado, no nulos).

**CHECK:** producto.precio_actual ≥ 0 · producto.stock_actual ≥ 0 · producto.stock_minimo ≥ 0 · producto.estado en dominio · producto_proveedor.costo_referencia ≥ 0 · cliente.tipo_documento en dominio · cliente.correo y proveedor.correo con formato · pedido.estado en dominio · detalle_pedido.cantidad > 0 · detalle_pedido.precio_unitario_aplicado ≥ 0 · pago.monto ≥ 0 · pago.metodo_pago y pago.estado en dominio · despacho.estado en dominio · despacho.fecha_entrega ≥ fecha_despacho.

**DEFAULT:** producto.estado 'ACTIVO' · producto.stock_actual 0 · producto.stock_minimo 0 · producto.fecha_creacion SYSDATETIME() · producto_proveedor.fecha_ultimo_costo GETDATE() · cliente.fecha_registro SYSDATETIME() · pedido.fecha_pedido SYSDATETIME() · pedido.estado 'CREADO' · pago.estado 'PENDIENTE' · pago.fecha_pago SYSDATETIME() · despacho.estado 'PREPARANDO'.

## 5. Catálogos de valores
| Campo | Valor | Significado |
|---|---|---|
| producto.estado | ACTIVO | Disponible para la venta |
| | INACTIVO | Retirado temporalmente |
| | DESCONTINUADO | Ya no se vende ni se repone |
| pedido.estado | CREADO | Registrado, aún sin pago confirmado |
| | PAGADO | Pago aprobado |
| | PREPARADO | Alistado en bodega |
| | DESPACHADO | Entregado a la transportadora |
| | ENTREGADO | Recibido por el cliente |
| | DEVUELTO | Retornado por el cliente o la transportadora |
| | CANCELADO | Anulado; no cuenta como venta completada |
| pago.estado | PENDIENTE | Intento iniciado sin respuesta |
| | APROBADO | Aceptado por la pasarela |
| | RECHAZADO | Denegado |
| | REEMBOLSADO | Dinero devuelto |
| pago.metodo_pago | TARJETA_CREDITO, TARJETA_DEBITO, PSE, TRANSFERENCIA, BILLETERA, CONTRAENTREGA | Medios aceptados |
| despacho.estado | PREPARANDO | Sin salir de bodega |
| | EN_TRANSITO | En manos de la transportadora |
| | ENTREGADO | Entregado al cliente |
| | DEVUELTO | Regresó a la tienda |
| | FALLIDO | Intento de entrega fallido |
| cliente.tipo_documento | CC, CE, NIT, PAS, TI | Cédula, extranjería, NIT, pasaporte, tarjeta de identidad |

## 6. Reglas de negocio que NO se resuelven con un CHECK simple
| Regla | Mecanismo previsto |
|---|---|
| Pedido con al menos una línea | Procedimiento almacenado con transacción que inserta pedido y líneas juntos |
| `precio_unitario_aplicado` toma el precio vigente al vender | Procedimiento o trigger al insertar la línea |
| Stock suficiente y descuento de inventario | Procedimiento transaccional (según alcance) |
| Suma de pagos no mayor al total del pedido | Validación en procedimiento (opcional) |
| Consistencia de `id_pedido_sql` en MongoDB | Validación en el script y documentación en `mongodb.md` |

## 7. Correspondencia con los otros entregables
- **E-R:** mismos nombres de entidades y atributos; usa tipos genéricos y no muestra las FK como columnas.
- **Relacional (Workbench):** 10 tablas con PK y FK; tipos de MySQL.
- **Normalización:** cada tabla de este diccionario aparece en `normalizacion.md` con sus dependencias funcionales.
