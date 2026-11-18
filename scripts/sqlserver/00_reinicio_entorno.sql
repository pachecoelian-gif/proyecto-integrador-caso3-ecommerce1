/* ==============================================================================
   00_reinicio_entorno.sql
   Proyecto integrador - Caso 3: Comercio electronico (SQL Server)

   ****************************  ADVERTENCIA  ****************************
   Este script ELIMINA la base de datos ComercioElectronico y TODOS sus datos.
   Usarlo unicamente para reconstruir el entorno desde cero.
   ***********************************************************************
   ============================================================================== */
USE master;
GO

IF DB_ID(N'ComercioElectronico') IS NOT NULL
BEGIN
    ALTER DATABASE ComercioElectronico SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ComercioElectronico;
    PRINT 'Base de datos ComercioElectronico eliminada.';
END
ELSE
    PRINT 'La base de datos ComercioElectronico no existe; nada que eliminar.';
GO
