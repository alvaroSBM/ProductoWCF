using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.Text;

namespace ProductoWCF
{
    // NOTA: puede usar el comando "Rename" del menú "Refactorizar" para cambiar el nombre de clase "Service2" en el código, en svc y en el archivo de configuración a la vez.
    // NOTA: para iniciar el Cliente de prueba WCF para probar este servicio, seleccione Service2.svc o Service2.svc.cs en el Explorador de soluciones e inicie la depuración.
    public class ServicioProducto : IServicioProducto
    {
        public List<Producto> ListarProductos()
        {
            return InfoProducto.ObtenerProductos();
        }

        public Producto ObtenerProducto(int id)
        {
            List<Producto> productos = InfoProducto.ObtenerProductos();
            return productos.Find(p => p.Id == id);
        }
    }
}
