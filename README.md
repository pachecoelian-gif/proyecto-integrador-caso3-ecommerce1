# Proyecto integrador — Caso 3: Comercio electrónico

**Asignatura:** Bases de Datos · **Universidad:** Universidad Santo Tomás 

## 1. Equipo
| Integrante | Rol principal | Usuario Git |
|---|---|---|
| Elian Santiago Pacheco Vanegas | _Diseño y Prueba_ | _Pachecoelian-gif_ |
| Ronald Andres Rodriguez | _Diseño_ | _Ronald3Rodriguez_ |

## 2. Descripción del caso
Tienda digital que vende productos de distintas categorías y proveedores. Administra clientes, catálogo,
inventario, pedidos, pagos y despachos, conservando la trazabilidad del precio cobrado y del estado de
cada pedido. La gerencia analiza productos vendidos, clientes recurrentes y cumplimiento de entregas.

## 3. Estado del proyecto
| Fase | Entregable | Estado |
|---|---|---|
| Parte I (diseño) | Modelo E-R, modelo relacional, normalización 3FN, diccionario de datos | Completo |
| Parte II (SQL Server) | DDL, restricciones, datos semilla (≥1.000 por tabla), consultas, vistas, pruebas | Completo |
| Complemento | Colección MongoDB `pedido_eventos` + CRUD | Taller completo |

## 4. Estructura del repositorio
```
├── README.md
├── modelo/                  # E-R, modelo relacional, diccionario de datos
├── scripts/
│   ├── sqlserver/           # 00_reinicio ... 05_vistas
│   └── mongodb/             # Taller seccion 8
├── documentacion/           # decisiones, uso de IA
└── evidencias/capturas_o_resultados/
```

## 5. Requisitos de instalación
- SQL Server 2019+ (o Express/Developer) y SQL Server Management Studio (SSMS)
- Git

## 6. Orden de ejecución (se completará en la Parte II)
1. `scripts/sqlserver/00_reinicio_entorno.sql` ⚠ BORRA la base `ComercioElectronico` (solo si se quiere reconstruir)
2. `scripts/sqlserver/01_crear_base_y_tablas.sql`
3. `scripts/sqlserver/02_restricciones_y_reglas.sql`
4. `scripts/sqlserver/03_datos_semilla.sql`
5. `scripts/sqlserver/04_consultas_negocio.sql`



