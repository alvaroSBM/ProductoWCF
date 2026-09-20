using System;
using System.Collections.Generic;
using System.Linq;
using System.ServiceModel;
using System.Web;

namespace ProductoWCF
{
    [ServiceContract]
    public interface IServicioProducto
    {
        [OperationContract]
        List<Producto> ListarProductos();

        [OperationContract]
        Producto ObtenerProducto(int id);
    }
}