<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="TestClienteWeb.Default" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <title>Lista de Productos WCF</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" />
</head>
<body>
    <form id="form1" runat="server">
        <div class="container mt-4">
            <div class="card mb-4 border-primary">
                <div class="card-header bg-primary text-white">
                    <h5 class="mb-0">Búsqueda de Producto por ID</h5>
                </div>
                <div class="card-body">
                    <div class="row g-2 align-items-center mb-3">
                        <div class="col-auto">
                            <label for="txtId" class="col-form-label fw-bold">ID Producto:</label>
                        </div>
                        <div class="col-auto">
                            <asp:TextBox ID="txtId" runat="server" CssClass="form-control" Text="2" TextMode="Number" style="width: 120px;"></asp:TextBox>
                        </div>
                        <div class="col-auto">
                            <asp:Button ID="btnBuscar" runat="server" Text="Buscar por ID" CssClass="btn btn-primary" OnClick="btnBuscar_Click" />
                            <asp:Button ID="btnLimpiar" runat="server" Text="Limpiar" CssClass="btn btn-secondary" OnClick="btnLimpiar_Click" />
                        </div>
                    </div>
                    <asp:Label ID="lblMensaje" runat="server" CssClass="alert alert-warning d-block" Visible="false"></asp:Label>
                    <h6 class="text-secondary mt-3">Resultado de la Búsqueda:</h6>
                    <asp:GridView ID="gvProductoId" runat="server" AutoGenerateColumns="true" CssClass="table table-bordered table-hover bg-light">
                    </asp:GridView>
                </div>
            </div>
            <h2 class="text-primary mb-3">Lista General de Productos</h2>
            <asp:GridView ID="gvProductos" runat="server" AutoGenerateColumns="true" CssClass="table table-striped table-bordered mt-3">
            </asp:GridView>
        </div>
    </form>
</body>
</html>