using System.Runtime.Serialization;

namespace ProductoWCF
{
    [DataContract]
    public class Producto
    {
        [DataMember] public int Id { get; set; }
        [DataMember] public string Nombre { get; set; }
        [DataMember] public string Descripcion { get; set; }
        [DataMember] public decimal Precio { get; set; }
        [DataMember] public int Stock { get; set; }

        // FK hacia Categorias
        [DataMember] public int IdCategoria { get; set; }

        // Datos que vienen del JOIN con Categorias (solo lectura)
        [DataMember] public string NombreCategoria { get; set; }
        [DataMember] public string DescripcionCategoria { get; set; }

        [DataMember] public string UrlImagen { get; set; }
    }

    /// <summary>
    /// Respuesta estandar de las operaciones: indica si el proceso fue
    /// exitoso, un mensaje claro (exito o motivo del fallo) y, cuando
    /// corresponde, el producto afectado.
    /// </summary>
    [DataContract]
    public class RespuestaServicio
    {
        [DataMember] public bool Exito { get; set; }
        [DataMember] public string Mensaje { get; set; }
        [DataMember] public Producto Producto { get; set; }
    }
}
