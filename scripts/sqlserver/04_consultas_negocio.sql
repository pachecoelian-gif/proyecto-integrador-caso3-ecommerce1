/* ==============================================================================
   04_consultas_negocio.sql
   Proyecto integrador - Caso 3: Comercio electronico (SQL Server / T-SQL)

   10 consultas de negocio sobre la base ComercioElectronico.
   Cada consulta es independiente: se puede ejecutar sola seleccionandola.
   ============================================================================== */
USE ComercioElectronico;
GO

/* ------------------------------------------------------------------------------
   1. Listar productos activos por categoria y precio.
   ------------------------------------------------------------------------------ */
SELECT  c.nombre         AS categoria,
        p.sku,
        p.nombre         AS producto,
        p.precio_actual
FROM    dbo.producto  AS p
JOIN    dbo.categoria AS c ON c.id_categoria = p.id_categoria
WHERE   p.estado = 'ACTIVO'
ORDER BY c.nombre ASC, p.precio_actual DESC;
GO

/* ------------------------------------------------------------------------------
   2. Consultar los pedidos de un cliente entre dos fechas.
      Cambiar los valores de las tres variables para probar otros casos.
   ------------------------------------------------------------------------------ */
DECLARE @id_cliente INT  = 172;
DECLARE @fecha_desde DATE = '2025-01-01';
DECLARE @fecha_hasta DATE = '2026-12-31';

SELECT  pe.id_pedido,
        pe.fecha_pedido,
        pe.estado,
        cl.nombres + ' ' + cl.apellidos AS cliente
FROM    dbo.pedido  AS pe
JOIN    dbo.cliente AS cl ON cl.id_cliente = pe.id_cliente
WHERE   pe.id_cliente = @id_cliente
  AND   pe.fecha_pedido >= @fecha_desde
  AND   pe.fecha_pedido <  DATEADD(DAY, 1, @fecha_hasta)   -- incluye todo el dia final
ORDER BY pe.fecha_pedido;
GO

/* ------------------------------------------------------------------------------
   3. Contar pedidos por estado y mes.
   ------------------------------------------------------------------------------ */
SELECT  YEAR(fecha_pedido)  AS anio,
        MONTH(fecha_pedido) AS mes,
        estado,
        COUNT(*)            AS total_pedidos
FROM    dbo.pedido
GROUP BY YEAR(fecha_pedido), MONTH(fecha_pedido), estado
ORDER BY anio, mes, estado;
GO

/* ------------------------------------------------------------------------------
   4. Calcular unidades vendidas e ingresos por producto.
      (Si se quisiera excluir pedidos cancelados, unir con dbo.pedido y
       agregar: WHERE pe.estado <> 'CANCELADO'.)
   ------------------------------------------------------------------------------ */
SELECT  p.id_producto,
        p.sku,
        p.nombre                                        AS producto,
        SUM(d.cantidad)                                 AS unidades_vendidas,
        SUM(d.cantidad * d.precio_unitario_aplicado)    AS ingresos
FROM    dbo.producto       AS p
JOIN    dbo.detalle_pedido AS d ON d.id_producto = p.id_producto
GROUP BY p.id_producto, p.sku, p.nombre
ORDER BY ingresos DESC;
GO

/* ------------------------------------------------------------------------------
   5. Mostrar pedidos, clientes, lineas y productos.
   ------------------------------------------------------------------------------ */
SELECT  pe.id_pedido,
        pe.fecha_pedido,
        pe.estado                                       AS estado_pedido,
        cl.id_cliente,
        cl.nombres + ' ' + cl.apellidos                 AS cliente,
        d.id_detalle_pedido                             AS linea,
        pr.sku,
        pr.nombre                                       AS producto,
        d.cantidad,
        d.precio_unitario_aplicado,
        d.cantidad * d.precio_unitario_aplicado         AS subtotal_linea
FROM    dbo.pedido         AS pe
JOIN    dbo.cliente        AS cl ON cl.id_cliente  = pe.id_cliente
JOIN    dbo.detalle_pedido AS d  ON d.id_pedido    = pe.id_pedido
JOIN    dbo.producto       AS pr ON pr.id_producto = d.id_producto
ORDER BY pe.id_pedido, d.id_detalle_pedido;
GO

/* ------------------------------------------------------------------------------
   6. Listar productos que nunca se han vendido.
   ------------------------------------------------------------------------------ */
SELECT  p.id_producto,
        p.sku,
        p.nombre,
        p.estado
FROM    dbo.producto       AS p
LEFT JOIN dbo.detalle_pedido AS d ON d.id_producto = p.id_producto
WHERE   d.id_detalle_pedido IS NULL
ORDER BY p.id_producto;
GO

/* ------------------------------------------------------------------------------
   7. Encontrar clientes que no han realizado pedidos.
   ------------------------------------------------------------------------------ */
SELECT  cl.id_cliente,
        cl.documento,
        cl.nombres + ' ' + cl.apellidos AS cliente,
        cl.correo,
        cl.fecha_registro
FROM    dbo.cliente AS cl
LEFT JOIN dbo.pedido AS pe ON pe.id_cliente = cl.id_cliente
WHERE   pe.id_pedido IS NULL
ORDER BY cl.id_cliente;
GO

/* ------------------------------------------------------------------------------
   8. Categorias con ingresos superiores al promedio por categoria.
      CTE 1: ingresos totales por categoria.
      CTE 2: promedio de esos ingresos.
   ------------------------------------------------------------------------------ */
WITH ingresos_categoria AS (
    SELECT  c.id_categoria,
            c.nombre AS categoria,
            SUM(d.cantidad * d.precio_unitario_aplicado) AS ingresos_totales
    FROM    dbo.categoria      AS c
    JOIN    dbo.producto       AS p ON p.id_categoria = c.id_categoria
    JOIN    dbo.detalle_pedido AS d ON d.id_producto  = p.id_producto
    GROUP BY c.id_categoria, c.nombre
),
promedio_categoria AS (
    SELECT AVG(ingresos_totales) AS promedio_ingresos
    FROM   ingresos_categoria
)
SELECT  ic.id_categoria,
        ic.categoria,
        ic.ingresos_totales,
        pc.promedio_ingresos
FROM    ingresos_categoria AS ic
CROSS JOIN promedio_categoria AS pc
WHERE   ic.ingresos_totales > pc.promedio_ingresos
ORDER BY ic.ingresos_totales DESC;
GO

/* ------------------------------------------------------------------------------
   9. Productos con precio superior al promedio de su categoria.
      Subconsulta correlacionada.
   ------------------------------------------------------------------------------ */
SELECT  p.id_producto,
        p.sku,
        p.nombre            AS producto,
        c.nombre            AS categoria,
        p.precio_actual,
        (SELECT AVG(p2.precio_actual)
         FROM   dbo.producto AS p2
         WHERE  p2.id_categoria = p.id_categoria) AS promedio_categoria
FROM    dbo.producto  AS p
JOIN    dbo.categoria AS c ON c.id_categoria = p.id_categoria
WHERE   p.precio_actual > (SELECT AVG(p2.precio_actual)
                           FROM   dbo.producto AS p2
                           WHERE  p2.id_categoria = p.id_categoria)
ORDER BY c.nombre, p.precio_actual DESC;
GO

/* ------------------------------------------------------------------------------
   10. Pedidos cuyo total supera el promedio de su mes.
       CTE 1: total de cada pedido.
       CTE 2: promedio de esos totales por anio y mes.
   ------------------------------------------------------------------------------ */
WITH total_pedido AS (
    SELECT  pe.id_pedido,
            pe.id_cliente,
            pe.fecha_pedido,
            YEAR(pe.fecha_pedido)  AS anio,
            MONTH(pe.fecha_pedido) AS mes,
            SUM(d.cantidad * d.precio_unitario_aplicado) AS total_pedido
    FROM    dbo.pedido         AS pe
    JOIN    dbo.detalle_pedido AS d ON d.id_pedido = pe.id_pedido
    GROUP BY pe.id_pedido, pe.id_cliente, pe.fecha_pedido,
             YEAR(pe.fecha_pedido), MONTH(pe.fecha_pedido)
),
promedio_mes AS (
    SELECT  anio, mes, AVG(total_pedido) AS promedio_mes
    FROM    total_pedido
    GROUP BY anio, mes
)
SELECT  t.id_pedido,
        t.id_cliente,
        t.fecha_pedido,
        t.anio,
        t.mes,
        t.total_pedido,
        pm.promedio_mes
FROM    total_pedido AS t
JOIN    promedio_mes AS pm ON pm.anio = t.anio AND pm.mes = t.mes
WHERE   t.total_pedido > pm.promedio_mes
ORDER BY t.anio, t.mes, t.total_pedido DESC;
GO
