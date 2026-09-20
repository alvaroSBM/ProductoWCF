using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ProductoWCF
{
    public class InfoProducto
    {
        public static List<Producto> ObtenerProductos()
        {
            return new List<Producto>
            {
                new Producto { Id = 1, Nombre = "Teclado", Precio = 40 },
                new Producto { Id = 2, Nombre = "Mouse", Precio = 60 },
                new Producto { Id = 3, Nombre = "Monitor", Precio = 250 },
                new Producto { Id = 4, Nombre = "Audífonos", Precio = 80 },
                new Producto { Id = 5, Nombre = "Laptop", Precio = 2500 }
            };
        }
    }
}