using System;
using System.Collections.Generic;
using System.Web.UI;
using TestClient.ServiceReference1;

namespace TestClienteWeb
{
    public partial class Default : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                CargarTodosLosProductos();
                BuscarProductoPorId(2);
            }
        }

        protected void btnBuscar_Click(object sender, EventArgs e)
        {
            if (int.TryParse(txtId.Text, out int id))
            {
                BuscarProductoPorId(id);
            }
            else
            {
                lblMensaje.Text = "Por favor, ingrese un ID numérico válido.";
                lblMensaje.Visible = true;
                gvProductoId.DataSource = null;
                gvProductoId.DataBind();
            }
        }

        protected void btnLimpiar_Click(object sender, EventArgs e)
        {
            txtId.Text = "";
            lblMensaje.Visible = false;
            gvProductoId.DataSource = null;
            gvProductoId.DataBind();
        }

        private void CargarTodosLosProductos()
        {
            try
            {
                ServicioProductoClient cliente = new ServicioProductoClient();
                var lista = cliente.ListarProductos();

                gvProductos.DataSource = lista;
                gvProductos.DataBind();

                cliente.Close();
            }
            catch (Exception ex)
            {
                Response.Write("<div class='alert alert-danger'>Error al listar productos: " + ex.Message + "</div>");
            }
        }

        private void BuscarProductoPorId(int id)
        {
            lblMensaje.Visible = false;
            try
            {
                ServicioProductoClient cliente = new ServicioProductoClient();
                var producto = cliente.ObtenerProducto(id);

                if (producto != null)
                {
                    gvProductoId.DataSource = new List<Producto> { producto };
                    gvProductoId.DataBind();
                }
                else
                {
                    lblMensaje.Text = "No se encontró ningún producto con el ID: " + id;
                    lblMensaje.Visible = true;
                    gvProductoId.DataSource = null;
                    gvProductoId.DataBind();
                }

                cliente.Close();
            }
            catch (Exception ex)
            {
                Response.Write("<div class='alert alert-danger'>Error al buscar por ID: " + ex.Message + "</div>");
            }
        }
    }
}
