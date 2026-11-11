# Decisiones de diseño — Caso 3: Comercio electrónico

## Punto de partida
Partimos de un negocio sencillo de describir pero fácil de modelar mal: una tienda digital que vende productos de distintas categorías y proveedores, y que necesita saber qué vendió, a quién, a qué precio, cómo se pagó y cómo se entregó. Antes de dibujar nada, leímos el enunciado marcando los sustantivos, los datos que los describen y las frases con "puede", "debe" o "única", porque ahí están las reglas que luego se vuelven llaves y restricciones.

## Cómo definimos las tablas
Terminamos con diez tablas, y cada una existe porque representa algo distinto del negocio:

- **Catálogo:** `categoria`, `proveedor`, `producto` y `producto_proveedor`.
- **Ventas:** `cliente`, `pedido` y `detalle_pedido`.
- **Cobro y entrega:** `pago`, `transportadora` y `despacho`.

Separamos la categoría, el cliente y la transportadora en tablas propias para no repetir sus datos en cada producto, pedido o despacho. Si el nombre de una categoría cambia, queremos cambiarlo en un solo lugar.

## Llaves primarias
Casi todas las tablas usan un identificador numérico autogenerado (`id_*`). Lo elegimos porque es estable y pequeño, y porque datos como el correo, el SKU o el NIT pueden cambiar o corregirse. Eso no significa que esos datos queden sueltos: los protegimos con restricciones `UNIQUE`, que es lo que pide el caso (documento y correo del cliente, código de categoría, SKU, referencia de pago, guía de despacho).

Hay dos excepciones pensadas:
- **`producto_proveedor`** usa una llave compuesta (producto + proveedor). El par ya identifica la fila, evita duplicados y nadie más la referencia, así que no necesitaba un identificador propio.
- **`detalle_pedido`** sí tiene identificador propio, pero además un `UNIQUE` sobre (pedido, producto) para que un producto aparezca una sola vez por pedido.

## Relaciones
- Una categoría tiene muchos productos y cada producto pertenece a una sola categoría.
- Un producto puede tener varios proveedores y un proveedor suministra varios productos. Como el costo depende de la pareja, lo guardamos en la tabla intermedia y no en producto ni en proveedor.
- Un cliente hace muchos pedidos; un pedido es de un solo cliente.
- Un pedido y un producto se relacionan de muchos a muchos, así que lo resolvimos con `detalle_pedido`, que además guarda la cantidad y el precio.
- Un pedido puede tener varios pagos y varios despachos. Podríamos haberlos dejado uno a uno, pero el caso habla de varios intentos de pago, y un envío puede fallar y repetirse o dividirse.

Dejamos opcional el lado "padre" de las relaciones, porque el caso pide que existan clientes sin pedidos y productos que nunca se han vendido. Las llaves foráneas del lado "hijo" son obligatorias: un pedido siempre tiene cliente, una línea siempre tiene pedido y producto.

## Integridad y reglas
Usamos `CHECK` para lo que se puede validar dentro de una fila: cantidades mayores que cero, precios, costos e importes no negativos, y los valores permitidos de cada estado. Los estados tienen un `DEFAULT` que corresponde al inicio de su ciclo: producto `ACTIVO`, pedido `CREADO`, pago `PENDIENTE` y despacho `PREPARANDO`.

Algunas reglas no caben en un `CHECK` porque dependen de otras filas, y no vamos a decir lo contrario. Que un pedido tenga al menos una línea lo vamos a resolver con un procedimiento que cree el pedido y sus líneas dentro de una transacción. La guía de despacho es única solo cuando existe, así que la protegeremos con un índice único filtrado, porque un `UNIQUE` normal admite un solo `NULL`.

En todas las llaves foráneas usamos `NO ACTION` en lugar de borrado en cascada. Un pedido, un pago o un despacho forman parte del historial de la tienda y no deberían desaparecer porque se borre un cliente o un producto. Las bajas se manejarán con el campo `estado`.

## Normalización
Partimos mentalmente de una hoja plana de pedido, con líneas, pagos y despachos repetidos, y la fuimos separando:
1. **Primera forma normal:** sacamos esos grupos repetidos a sus propias tablas y dejamos cada dato en una sola celda.
2. **Segunda forma normal:** en las tablas con llave compuesta, movimos a `producto` y a `proveedor` lo que dependía solo de una parte de la llave.
3. **Tercera forma normal:** quitamos las dependencias entre atributos que no son llave, y de ahí salieron `cliente`, `categoria` y `transportadora`.

Al final, todo lo que determina a otro dato es una llave, así que el modelo también cumple la forma normal de Boyce-Codd. El detalle de cada paso está en `modelo/normalizacion.md`.

## Las decisiones que más pensamos
- **Precio aplicado.** Guardamos `precio_unitario_aplicado` en cada línea del pedido. Podría parecer un dato repetido, pero no lo es: el precio del catálogo cambia con el tiempo y el de una venta ya hecha no debe cambiar. Es justo lo que pide el caso.
- **Total del pedido.** No lo guardamos como columna. Se calcula sumando cantidad por precio de cada línea, y guardarlo solo abriría la puerta a que no coincida con el detalle. Lo resolveremos con consultas y vistas.
- **Inventario.** El stock actual y el mínimo viven en `producto`, porque dependen únicamente del producto. Un historial de movimientos de inventario sería una mejora válida, pero se salía del alcance del caso.
- **Dirección de entrega.** La guardamos en `despacho` como la dirección que se usó en ese envío. El cliente puede cambiarla después y el envío ya hecho no debe cambiar. Una tabla de direcciones también habría sido una opción.
- **Estados.** Los manejamos con `CHECK` y no con tablas aparte, porque son pocos y estables. Si cambian, se modifica la restricción.
