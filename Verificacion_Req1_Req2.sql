/* ============================================================
   VERIFICACION DE REQ 1 y REQ 2  (base de datos DBProductos)
   Ejecutar cada bloque por separado: seleccionar el bloque
   y pulsar F5. Cada bloque indica el resultado esperado.
   Las pruebas de INSERT/UPDATE/DELETE usan ROLLBACK, por lo
   que NO modifican tus datos.
   ============================================================ */
USE DBProductos;
GO

/* ------------------------------------------------------------
   REQ 1 - Tablas, campos y clave foranea
   ------------------------------------------------------------ */

-- 1.1 Existen las tablas Productos y Categorias
-- ESPERADO: 2 filas (Categorias, Productos)
SELECT name AS tabla
FROM sys.tables
WHERE name IN ('Productos', 'Categorias');
GO

-- 1.2 La tabla Productos tiene los campos minimos
-- ESPERADO: id, nombre, descripcion, precio, stock, categoria, url_imagen
SELECT COLUMN_NAME AS columna, DATA_TYPE AS tipo, IS_NULLABLE AS acepta_nulos
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Productos'
ORDER BY ORDINAL_POSITION;
GO

-- 1.3 Existe la clave foranea Productos -> Categorias
-- ESPERADO: 1 fila: Productos.categoria referencia a Categorias.id
SELECT fk.name                                               AS clave_foranea,
       OBJECT_NAME(fk.parent_object_id)                      AS tabla_hija,
       COL_NAME(fkc.parent_object_id, fkc.parent_column_id)  AS columna_hija,
       OBJECT_NAME(fk.referenced_object_id)                  AS tabla_padre,
       COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS columna_padre
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc ON fkc.constraint_object_id = fk.object_id
WHERE OBJECT_NAME(fk.parent_object_id) = 'Productos';
GO

-- 1.4 La clave foranea funciona: rechaza una categoria que no existe
-- ESPERADO: mensaje que empieza con "OK" y habla de un conflicto con FOREIGN KEY
BEGIN TRY
    INSERT INTO dbo.Productos (nombre, precio, stock, categoria)
    VALUES ('Prueba FK', 10, 1, 9999);

    PRINT 'ERROR: la clave foranea no esta funcionando';
    DELETE FROM dbo.Productos WHERE nombre = 'Prueba FK';   -- limpieza
END TRY
BEGIN CATCH
    PRINT 'OK - La FK rechazo la categoria inexistente: ' + ERROR_MESSAGE();
END CATCH;
GO

/* ------------------------------------------------------------
   REQ 2 - Procedimientos almacenados
   ------------------------------------------------------------ */

-- 2.1 Existen los procedimientos
-- ESPERADO: 5 filas: Actualizar, Eliminar, Insertar, Listar, ObtenerPorId
SELECT name AS procedimiento, create_date AS creado
FROM sys.procedures
WHERE name LIKE 'usp_Producto_%'
ORDER BY name;
GO

-- 2.2 SELECT por Id con JOIN a Categorias
-- ESPERADO: primer resultado "SI usa JOIN"; segundo resultado: 1 fila del
--           Teclado con nombre_categoria y descripcion_categoria
SELECT CASE WHEN OBJECT_DEFINITION(OBJECT_ID('dbo.usp_Producto_ObtenerPorId')) LIKE '%JOIN%'
            THEN 'SI usa JOIN' ELSE 'NO usa JOIN' END AS usa_join;

EXEC dbo.usp_Producto_ObtenerPorId @id = 1;
GO

-- 2.3 INSERT, UPDATE y DELETE en una sola prueba (con ROLLBACK)
-- ESPERADO, en orden:
--   a) INSERT : se muestra el Id generado y el producto con categoria Perifericos
--   b) UPDATE : el producto aparece con el nombre, precio y categoria nuevos (Monitores)
--   c) DELETE : filas_afectadas = 1, y la consulta posterior devuelve 0 filas
BEGIN TRAN;

CREATE TABLE #nuevo (id INT);

PRINT '--- a) INSERT ---';
INSERT INTO #nuevo
EXEC dbo.usp_Producto_Insertar
     @nombre = 'Producto de prueba', @descripcion = 'Registro temporal',
     @precio = 99.90, @stock = 5, @categoria = 1, @url_imagen = NULL;

DECLARE @id INT = (SELECT TOP 1 id FROM #nuevo);
PRINT 'Id generado: ' + CAST(@id AS VARCHAR(10));
EXEC dbo.usp_Producto_ObtenerPorId @id = @id;

PRINT '--- b) UPDATE ---';
EXEC dbo.usp_Producto_Actualizar
     @id = @id, @nombre = 'Producto de prueba EDITADO', @descripcion = 'Modificado',
     @precio = 120.00, @stock = 8, @categoria = 2, @url_imagen = NULL;
EXEC dbo.usp_Producto_ObtenerPorId @id = @id;

PRINT '--- c) DELETE ---';
EXEC dbo.usp_Producto_Eliminar @id = @id;
PRINT 'Consulta despues de eliminar (debe devolver 0 filas):';
EXEC dbo.usp_Producto_ObtenerPorId @id = @id;

DROP TABLE #nuevo;
ROLLBACK TRAN;   -- deshace la prueba: tus datos quedan intactos
GO

-- 2.4 Los procedimientos rechazan datos invalidos con un mensaje claro
-- ESPERADO: tres mensajes que empiezan con "OK"
BEGIN TRY
    EXEC dbo.usp_Producto_Insertar @nombre = 'X', @precio = 10, @stock = 1, @categoria = 9999;
    PRINT 'ERROR: el INSERT deberia haber fallado';
END TRY
BEGIN CATCH
    PRINT 'OK - INSERT rechazado: ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRY
    EXEC dbo.usp_Producto_Actualizar @id = 99999, @nombre = 'X', @precio = 10, @stock = 1, @categoria = 1;
    PRINT 'ERROR: el UPDATE deberia haber fallado';
END TRY
BEGIN CATCH
    PRINT 'OK - UPDATE rechazado: ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRY
    EXEC dbo.usp_Producto_Eliminar @id = 99999;
    PRINT 'ERROR: el DELETE deberia haber fallado';
END TRY
BEGIN CATCH
    PRINT 'OK - DELETE rechazado: ' + ERROR_MESSAGE();
END CATCH;
GO
