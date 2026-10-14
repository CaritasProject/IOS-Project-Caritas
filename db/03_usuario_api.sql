/* =============================================================================
   Usuario de SQL Server para la API (mínimo privilegio).
   Se corre una vez con SA, después de 01_esquema.sql.

   La API solo lee y escribe filas de las tablas y vistas del esquema dbo:
   no crea ni borra tablas, no ejecuta procedimientos y no entra a otras bases.
   SA queda solo para administrar (esquema, respaldos, cargas de datos).

   Antes de correrlo, cambia <CONTRASEÑA> por una contraseña larga y ponla en el
   .env del servidor (SQLSERVER_USUARIO=api_caritas, SQLSERVER_PASSWORD=...).
   La contraseña real no se sube al repositorio.
============================================================================= */
USE master;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'api_caritas')
    CREATE LOGIN api_caritas WITH PASSWORD = N'<CONTRASEÑA>',
        DEFAULT_DATABASE = caritas, CHECK_POLICY = ON;
GO

USE caritas;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'api_caritas')
    CREATE USER api_caritas FOR LOGIN api_caritas WITH DEFAULT_SCHEMA = dbo;

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO api_caritas;
GO

/* Comprobación: debe regresar solo SELECT, INSERT, UPDATE y DELETE sobre dbo,
   y ningún rol (ni db_owner ni db_ddladmin). */
SELECT p.permission_name, p.class_desc, SCHEMA_NAME(p.major_id) AS esquema
FROM sys.database_permissions p
WHERE p.grantee_principal_id = USER_ID(N'api_caritas') AND p.class_desc = N'SCHEMA';

SELECT r.name AS rol
FROM sys.database_role_members m
JOIN sys.database_principals r ON r.principal_id = m.role_principal_id
WHERE m.member_principal_id = USER_ID(N'api_caritas');
GO
