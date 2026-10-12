/* ============================================================
   BASE DE DATOS COMPLETA - DBProductos
   Ejecutar UNA SOLA VEZ en SSMS (Ctrl+A y F5).
   Orden: 1) base, tablas y procedimientos  2) ajuste del INSERT
          3) categorias y productos adicionales
   ============================================================ */

/* ============================================================
   Base de datos: DBProductos  (SQL Server)
   Tablas: Categorias, Productos (relacionadas por clave foranea)
   Acceso a datos: solo mediante procedimientos almacenados
   ============================================================ */

-- 1. Crear la base de datos -----------------------------------
IF DB_ID('DBProductos') IS NULL
    CREATE DATABASE DBProductos;
GO

USE DBProductos;
GO

-- 2. Limpieza (permite volver a ejecutar el script) -----------
IF OBJECT_ID('dbo.usp_Producto_ObtenerPorId', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Producto_ObtenerPorId;
IF OBJECT_ID('dbo.usp_Producto_Listar',       'P') IS NOT NULL DROP PROCEDURE dbo.usp_Producto_Listar;
IF OBJECT_ID('dbo.usp_Producto_Insertar',     'P') IS NOT NULL DROP PROCEDURE dbo.usp_Producto_Insertar;
IF OBJECT_ID('dbo.usp_Producto_Actualizar',   'P') IS NOT NULL DROP PROCEDURE dbo.usp_Producto_Actualizar;
IF OBJECT_ID('dbo.usp_Producto_Eliminar',     'P') IS NOT NULL DROP PROCEDURE dbo.usp_Producto_Eliminar;
IF OBJECT_ID('dbo.Productos',  'U') IS NOT NULL DROP TABLE dbo.Productos;
IF OBJECT_ID('dbo.Categorias', 'U') IS NOT NULL DROP TABLE dbo.Categorias;
GO

-- 3. Tabla Categorias -----------------------------------------
CREATE TABLE dbo.Categorias
(
    id          INT IDENTITY(1,1) NOT NULL,
    nombre      VARCHAR(100)      NOT NULL,
    descripcion VARCHAR(250)      NULL,
    CONSTRAINT PK_Categorias        PRIMARY KEY (id),
    CONSTRAINT UQ_Categorias_nombre UNIQUE (nombre)
);
GO

-- 4. Tabla Productos (FK hacia Categorias) --------------------
CREATE TABLE dbo.Productos
(
    id           INT IDENTITY(1,1) NOT NULL,
    nombre       VARCHAR(150)      NOT NULL,
    descripcion  VARCHAR(500)      NULL,
    precio       DECIMAL(10,2)     NOT NULL,
    stock        INT               NOT NULL CONSTRAINT DF_Productos_stock DEFAULT (0),
    categoria    INT               NOT NULL,   -- FK hacia Categorias.id
    url_imagen   VARCHAR(300)      NULL,
    CONSTRAINT PK_Productos        PRIMARY KEY (id),
    CONSTRAINT CK_Productos_precio CHECK (precio >= 0),
    CONSTRAINT CK_Productos_stock  CHECK (stock  >= 0),
    CONSTRAINT FK_Productos_Categorias
        FOREIGN KEY (categoria) REFERENCES dbo.Categorias (id)
);
GO

-- 5. Datos de prueba ------------------------------------------
INSERT INTO dbo.Categorias (nombre, descripcion) VALUES
('Perifericos',  'Teclados, mouse y accesorios de entrada'),
('Monitores',    'Pantallas y displays'),
('Audio',        'Audifonos, parlantes y microfonos'),
('Computadoras', 'Laptops y equipos de escritorio');
GO

INSERT INTO dbo.Productos (nombre, descripcion, precio, stock, categoria, url_imagen) VALUES
('Teclado',   'Teclado mecanico retroiluminado',   40.00,   25, 1, 'https://ejemplo.com/img/teclado.jpg'),
('Mouse',     'Mouse inalambrico ergonomico',      60.00,   40, 1, 'https://ejemplo.com/img/mouse.jpg'),
('Monitor',   'Monitor LED de 24 pulgadas',       250.00,   12, 2, 'https://ejemplo.com/img/monitor.jpg'),
('Audifonos', 'Audifonos Bluetooth con microfono', 80.00,   30, 3, 'https://ejemplo.com/img/audifonos.jpg'),
('Laptop',    'Laptop de 14 pulgadas, 16 GB RAM', 2500.00,   8, 4, 'https://ejemplo.com/img/laptop.jpg');
GO

/* ============================================================
   PROCEDIMIENTOS ALMACENADOS
   ============================================================ */

-- 6. SELECT: obtener un producto por Id (JOIN con Categorias) --
CREATE PROCEDURE dbo.usp_Producto_ObtenerPorId
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  p.id,
            p.nombre,
            p.descripcion,
            p.precio,
            p.stock,
            p.categoria          AS id_categoria,
            c.nombre             AS nombre_categoria,
            c.descripcion        AS descripcion_categoria,
            p.url_imagen
    FROM    dbo.Productos  AS p
    INNER JOIN dbo.Categorias AS c ON c.id = p.categoria
    WHERE   p.id = @id;
END
GO

-- 7. SELECT: listar todos los productos (apoya a ListarProductos) --
CREATE PROCEDURE dbo.usp_Producto_Listar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  p.id,
            p.nombre,
            p.descripcion,
            p.precio,
            p.stock,
            p.categoria          AS id_categoria,
            c.nombre             AS nombre_categoria,
            c.descripcion        AS descripcion_categoria,
            p.url_imagen
    FROM    dbo.Productos  AS p
    INNER JOIN dbo.Categorias AS c ON c.id = p.categoria
    ORDER BY p.id;
END
GO

-- 8. INSERT: registrar un nuevo producto ----------------------
CREATE PROCEDURE dbo.usp_Producto_Insertar
    @nombre      VARCHAR(150),
    @descripcion VARCHAR(500)  = NULL,
    @precio      DECIMAL(10,2),
    @stock       INT           = 0,
    @categoria   INT,
    @url_imagen  VARCHAR(300)  = NULL,
    @id_nuevo    INT           = NULL OUTPUT   -- devuelve el Id generado
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE id = @categoria)
    BEGIN
        RAISERROR('La categoria indicada no existe.', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.Productos (nombre, descripcion, precio, stock, categoria, url_imagen)
    VALUES (@nombre, @descripcion, @precio, @stock, @categoria, @url_imagen);

    SET @id_nuevo = SCOPE_IDENTITY();
    SELECT @id_nuevo AS id_nuevo;
END
GO

-- 9. UPDATE: modificar un producto existente ------------------
CREATE PROCEDURE dbo.usp_Producto_Actualizar
    @id          INT,
    @nombre      VARCHAR(150),
    @descripcion VARCHAR(500)  = NULL,
    @precio      DECIMAL(10,2),
    @stock       INT,
    @categoria   INT,
    @url_imagen  VARCHAR(300)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Productos WHERE id = @id)
    BEGIN
        RAISERROR('El producto indicado no existe.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE id = @categoria)
    BEGIN
        RAISERROR('La categoria indicada no existe.', 16, 1);
        RETURN;
    END

    UPDATE dbo.Productos
    SET    nombre      = @nombre,
           descripcion = @descripcion,
           precio      = @precio,
           stock       = @stock,
           categoria   = @categoria,
           url_imagen  = @url_imagen
    WHERE  id = @id;

    SELECT @@ROWCOUNT AS filas_afectadas;
END
GO

-- 10. DELETE: eliminar un producto ----------------------------
CREATE PROCEDURE dbo.usp_Producto_Eliminar
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Productos WHERE id = @id)
    BEGIN
        RAISERROR('El producto indicado no existe.', 16, 1);
        RETURN;
    END

    DELETE FROM dbo.Productos WHERE id = @id;

    SELECT @@ROWCOUNT AS filas_afectadas;
END
GO
GO


/* ---------- 2) AJUSTE DEL INSERT PARA ENTITY FRAMEWORK ---------- */
/* Ejecutar en SSMS ANTES de crear el modelo de Entity Framework.
   Quita el parametro OUTPUT del procedimiento de insercion y devuelve
   el Id nuevo como resultado, para que el asistente lo importe sin problemas. */

USE DBProductos;
GO

ALTER PROCEDURE dbo.usp_Producto_Insertar
    @nombre      VARCHAR(150),
    @descripcion VARCHAR(500)  = NULL,
    @precio      DECIMAL(10,2),
    @stock       INT           = 0,
    @categoria   INT,
    @url_imagen  VARCHAR(300)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE id = @categoria)
    BEGIN
        RAISERROR('La categoria indicada no existe.', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.Productos (nombre, descripcion, precio, stock, categoria, url_imagen)
    VALUES (@nombre, @descripcion, @precio, @stock, @categoria, @url_imagen);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_nuevo;
END
GO


/* ---------- 3) CATEGORIAS Y PRODUCTOS ADICIONALES ---------- */
/* ============================================================
   Datos adicionales para DBProductos
   - Agrega 2 categorias nuevas y 18 productos.
   - Se puede ejecutar varias veces: no duplica registros.
   ============================================================ */
USE DBProductos;
GO

-- 1. Categorias nuevas (si no existen) ------------------------
INSERT INTO dbo.Categorias (nombre, descripcion)
SELECT v.nombre, v.descripcion
FROM (VALUES
    ('Almacenamiento', 'Discos SSD, discos externos y memorias USB'),
    ('Redes',          'Routers, switches y cableado de red')
) AS v(nombre, descripcion)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Categorias c WHERE c.nombre = v.nombre);
GO

-- 2. Productos (la categoria se busca por nombre) -------------
INSERT INTO dbo.Productos (nombre, descripcion, precio, stock, categoria, url_imagen)
SELECT v.nombre, v.descripcion, v.precio, v.stock, c.id, v.url_imagen
FROM (VALUES
    -- Perifericos
    ('Webcam Full HD 1080p',        'Camara web con microfono integrado y enfoque automatico', 129.90, 22, 'Perifericos',  'https://ejemplo.com/img/webcam.jpg'),
    ('Mousepad XL',                 'Alfombrilla extendida antideslizante 90x40 cm',            35.00, 60, 'Perifericos',  'https://ejemplo.com/img/mousepad.jpg'),
    ('Teclado inalambrico compacto','Teclado Bluetooth de perfil bajo con bateria recargable',  89.90, 28, 'Perifericos',  'https://ejemplo.com/img/teclado-bt.jpg'),
    ('Mouse gamer RGB',             'Mouse con sensor de 16000 DPI y 7 botones programables',  110.00, 35, 'Perifericos',  'https://ejemplo.com/img/mouse-gamer.jpg'),

    -- Monitores
    ('Monitor curvo 27 pulgadas',   'Pantalla curva QHD de 165 Hz con panel VA',               680.00, 10, 'Monitores',    'https://ejemplo.com/img/monitor-curvo.jpg'),
    ('Monitor 4K 32 pulgadas',      'Pantalla UHD 4K con panel IPS y HDR',                    1450.00,  6, 'Monitores',    'https://ejemplo.com/img/monitor-4k.jpg'),

    -- Audio
    ('Parlantes 2.1',               'Sistema de parlantes con subwoofer y control de volumen', 160.00, 18, 'Audio',        'https://ejemplo.com/img/parlantes.jpg'),
    ('Microfono USB condensador',   'Microfono para streaming y podcast con tripode',          210.00, 14, 'Audio',        'https://ejemplo.com/img/microfono.jpg'),
    ('Audifonos gamer 7.1',         'Audifonos con sonido envolvente y microfono desmontable', 190.00, 24, 'Audio',        'https://ejemplo.com/img/audifonos-gamer.jpg'),

    -- Computadoras
    ('Laptop gamer 15.6 pulgadas',  'Procesador Core i7, 16 GB RAM, SSD 512 GB y RTX 4050',   4200.00,  5, 'Computadoras', 'https://ejemplo.com/img/laptop-gamer.jpg'),
    ('PC de escritorio Core i5',    'Core i5, 16 GB RAM, SSD 512 GB, incluye teclado y mouse',2300.00,  9, 'Computadoras', 'https://ejemplo.com/img/pc-escritorio.jpg'),
    ('Mini PC',                     'Equipo compacto con Ryzen 5, 16 GB RAM y SSD 512 GB',    1100.00, 12, 'Computadoras', 'https://ejemplo.com/img/mini-pc.jpg'),

    -- Almacenamiento
    ('Disco SSD 1 TB',              'Unidad de estado solido NVMe con lectura de 3500 MB/s',   320.00, 40, 'Almacenamiento','https://ejemplo.com/img/ssd-1tb.jpg'),
    ('Disco duro externo 2 TB',     'Disco portatil USB 3.0 con cable incluido',               280.00, 26, 'Almacenamiento','https://ejemplo.com/img/hdd-externo.jpg'),
    ('Memoria USB 128 GB',          'Pendrive USB 3.2 de alta velocidad',                       45.00, 80, 'Almacenamiento','https://ejemplo.com/img/usb-128.jpg'),

    -- Redes
    ('Router WiFi 6',               'Router de doble banda con cobertura para 4 ambientes',    240.00, 20, 'Redes',        'https://ejemplo.com/img/router.jpg'),
    ('Switch 8 puertos',            'Switch Gigabit no administrable de 8 puertos',             95.00, 15, 'Redes',        'https://ejemplo.com/img/switch.jpg'),
    ('Cable de red Cat6 5 m',       'Cable Ethernet Cat6 blindado de 5 metros',                 18.00, 100,'Redes',        'https://ejemplo.com/img/cable-cat6.jpg')
) AS v(nombre, descripcion, precio, stock, categoria, url_imagen)
JOIN dbo.Categorias AS c ON c.nombre = v.categoria
WHERE NOT EXISTS (SELECT 1 FROM dbo.Productos p WHERE p.nombre = v.nombre);
GO

-- 3. Verificacion ---------------------------------------------
SELECT p.id, p.nombre, p.precio, p.stock, c.nombre AS categoria
FROM dbo.Productos AS p
INNER JOIN dbo.Categorias AS c ON c.id = p.categoria
ORDER BY c.nombre, p.nombre;
GO
