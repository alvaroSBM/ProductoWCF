using System.Collections.Generic;
using System.ServiceModel;

namespace ProductoWCF
{
    [ServiceContract]
    public interface IServicioProducto
    {
        [OperationContract]
        List<Producto> ListarProductos();

        [OperationContract]
        RespuestaServicio ObtenerProducto(int id);

        [OperationContract]
        RespuestaServicio InsertarProducto(Producto producto);

        [OperationContract]
        RespuestaServicio ActualizarProducto(Producto producto);

        [OperationContract]
        RespuestaServicio EliminarProducto(int id);
    }
}

