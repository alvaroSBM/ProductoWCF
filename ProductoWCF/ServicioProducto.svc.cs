using System;
using System.Collections.Generic;
using System.Data.Entity.Core;
using System.Data.SqlClient;
using System.Linq;
using System.ServiceModel;

namespace ProductoWCF
{
    /// <summary>
    /// Servicio WCF con Entity Framework. Todo el acceso a datos se hace
    /// llamando a los procedimientos almacenados (Function Imports).
    /// Las operaciones validan los datos y devuelven un mensaje claro.
    /// </summary>
    public class ServicioProducto : IServicioProducto
    {
        // ---------- SELECT: listar ----------
        public List<Producto> ListarProductos()
        {
            try
            {
                using (var db = new DBProductosEntities())
                {
                    return db.usp_Producto_Listar()
                             .ToList()
                             .Select(r => Mapear(r))
                             .ToList();
                }
            }
            catch (EntityException ex)
            {
                throw new FaultException("Error de base de datos: " + Detalle(ex));
            }
        }

        // ---------- SELECT: obtener por Id ----------
        public RespuestaServicio ObtenerProducto(int id)
        {
            if (id <= 0)
                return Fallido("El Id del producto debe ser mayor que cero.");

            try
            {
                using (var db = new DBProductosEntities())
                {
                    var r = db.usp_Producto_ObtenerPorId(id).FirstOrDefault();

                    if (r == null)
                        return Fallido("No se encontró ningún producto con Id " + id + ".");

                    return Correcto("Producto encontrado correctamente.", Mapear(r));
                }
            }
            catch (EntityException ex) { return ErrorBD(ex, null); }
        }

        // ---------- INSERT ----------
        public RespuestaServicio InsertarProducto(Producto p)
        {
            string error = Validar(p, false);
            if (error != null)
                return Fallido(error);

            try
            {
                using (var db = new DBProductosEntities())
                {
                    var nuevoId = Convert.ToInt32(
                        db.usp_Producto_Insertar(
                            p.Nombre.Trim(), Limpiar(p.Descripcion), p.Precio,
                            p.Stock, p.IdCategoria, Limpiar(p.UrlImagen)).FirstOrDefault());

                    var creado = db.usp_Producto_ObtenerPorId(nuevoId).FirstOrDefault();

                    return Correcto(
                        "Producto registrado correctamente con Id " + nuevoId + ".",
                        creado == null ? null : Mapear(creado));
                }
            }
            catch (EntityException ex) { return ErrorBD(ex, "No se pudo registrar el producto"); }
        }

        // ---------- UPDATE ----------
        public RespuestaServicio ActualizarProducto(Producto p)
        {
            string error = Validar(p, true);
            if (error != null)
                return Fallido(error);

            try
            {
                using (var db = new DBProductosEntities())
                {
                    // Producto existente para UPDATE
                    if (db.usp_Producto_ObtenerPorId(p.Id).FirstOrDefault() == null)
                        return Fallido("No existe un producto con Id " + p.Id + ". No se puede actualizar.");

                    db.usp_Producto_Actualizar(
                        p.Id, p.Nombre.Trim(), Limpiar(p.Descripcion), p.Precio,
                        p.Stock, p.IdCategoria, Limpiar(p.UrlImagen)).FirstOrDefault();

                    var actualizado = db.usp_Producto_ObtenerPorId(p.Id).FirstOrDefault();

                    return Correcto(
                        "Producto con Id " + p.Id + " actualizado correctamente.",
                        actualizado == null ? null : Mapear(actualizado));
                }
            }
            catch (EntityException ex) { return ErrorBD(ex, "No se pudo actualizar el producto"); }
        }

        // ---------- DELETE ----------
        public RespuestaServicio EliminarProducto(int id)
        {
            if (id <= 0)
                return Fallido("El Id del producto debe ser mayor que cero.");

            try
            {
                using (var db = new DBProductosEntities())
                {
                    var existente = db.usp_Producto_ObtenerPorId(id).FirstOrDefault();

                    if (existente == null)
                        return Fallido("No se pudo eliminar: no existe un producto con Id " + id + ".");

                    db.usp_Producto_Eliminar(id).FirstOrDefault();

                    return Correcto(
                        "Producto '" + existente.nombre + "' (Id " + id + ") eliminado correctamente.",
                        null);
                }
            }
            catch (EntityException ex) { return ErrorBD(ex, "No se pudo eliminar el producto"); }
        }

        // =====================================================
        //  VALIDACIONES (INSERT y UPDATE)
        // =====================================================
        // Devuelve el mensaje del primer problema encontrado, o null si todo esta bien.
        private static string Validar(Producto p, bool esActualizacion)
        {
            if (p == null)
                return "No se recibieron los datos del producto.";

            if (esActualizacion && p.Id <= 0)
                return "Debe indicar el Id del producto que desea actualizar.";

            // Campos obligatorios: nombre, precio, stock y categoria
            if (string.IsNullOrWhiteSpace(p.Nombre))
                return "El nombre del producto es obligatorio.";

            if (p.Nombre.Trim().Length > 150)
                return "El nombre no puede superar los 150 caracteres.";

            if (p.Descripcion != null && p.Descripcion.Length > 500)
                return "La descripción no puede superar los 500 caracteres.";

            if (p.UrlImagen != null && p.UrlImagen.Length > 300)
                return "La URL de la imagen no puede superar los 300 caracteres.";

            // Precio mayor que cero
            if (p.Precio <= 0)
                return "El precio debe ser mayor que cero.";

            if (p.Precio > 99999999.99m)
                return "El precio supera el valor máximo permitido (99,999,999.99).";

            // Stock valido
            if (p.Stock < 0)
                return "El stock no puede ser negativo.";

            if (p.IdCategoria <= 0)
                return "Debe indicar una categoría válida (IdCategoria mayor que cero).";

            // La existencia de la categoria la valida el procedimiento almacenado;
            // su mensaje se devuelve en ErrorBD().
            return null;
        }

        // =====================================================
        //  UTILITARIOS
        // =====================================================
        private static RespuestaServicio Correcto(string mensaje, Producto producto)
        {
            return new RespuestaServicio { Exito = true, Mensaje = mensaje, Producto = producto };
        }

        private static RespuestaServicio Fallido(string mensaje)
        {
            return new RespuestaServicio { Exito = false, Mensaje = mensaje, Producto = null };
        }

        // Convierte un error de base de datos en una respuesta con mensaje claro.
        // Los RAISERROR de los procedimientos (por ejemplo "La categoria indicada
        // no existe.") llegan como SqlException con Number = 50000.
        private static RespuestaServicio ErrorBD(EntityException ex, string contexto)
        {
            var sql = ex.InnerException as SqlException;

            if (sql != null && sql.Number == 50000)
                return Fallido((contexto == null ? "" : contexto + ": ") + sql.Message);

            return Fallido("Error de base de datos: " + Detalle(ex));
        }

        private static string Detalle(Exception ex)
        {
            return ex.InnerException != null ? ex.InnerException.Message : ex.Message;
        }

        // Texto vacio o solo espacios -> null; si no, se recorta.
        private static string Limpiar(string texto)
        {
            return string.IsNullOrWhiteSpace(texto) ? null : texto.Trim();
        }

        // Convert.* se usa para que compile igual si el disenador genero
        // el tipo con o sin Nullable (int vs int?).
        private static Producto Mapear(usp_Producto_Listar_Result r)
        {
            return new Producto
            {
                Id = Convert.ToInt32(r.id),
                Nombre = r.nombre,
                Descripcion = r.descripcion,
                Precio = Convert.ToDecimal(r.precio),
                Stock = Convert.ToInt32(r.stock),
                IdCategoria = Convert.ToInt32(r.id_categoria),
                NombreCategoria = r.nombre_categoria,
                DescripcionCategoria = r.descripcion_categoria,
                UrlImagen = r.url_imagen
            };
        }

        private static Producto Mapear(usp_Producto_ObtenerPorId_Result r)
        {
            return new Producto
            {
                Id = Convert.ToInt32(r.id),
                Nombre = r.nombre,
                Descripcion = r.descripcion,
                Precio = Convert.ToDecimal(r.precio),
                Stock = Convert.ToInt32(r.stock),
                IdCategoria = Convert.ToInt32(r.id_categoria),
                NombreCategoria = r.nombre_categoria,
                DescripcionCategoria = r.descripcion_categoria,
                UrlImagen = r.url_imagen
            };
        }
    }
}

