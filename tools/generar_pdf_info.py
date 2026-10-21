"""Genera assets/info.pdf con la informacion que consulta la IA.

El PDF es la fuente de verdad (storage). Para cambiar los datos:
  1. Edita los bloques de SECCIONES abajo.
  2. Ejecuta: python tools\\generar_pdf_info.py
  3. Listo: la app Flutter y el bot de Telegram leen ese mismo archivo.

No pongas texto escaneado como imagen: la IA trabaja sobre el texto extraido.
"""

from pathlib import Path

from fpdf import FPDF

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUTPUT = PROJECT_ROOT / "assets" / "info.pdf"

SECCIONES = [
    (
        "Sobre VendedorVirtual",
        [
            "VendedorVirtual es un asistente virtual de compras de electrodomesticos "
            "y tecnologia; no es una tienda online ni un vendedor humano.",
            "Te guia en base a tus necesidades de compra: te hace preguntas para "
            "entender que buscas y te ayuda a decidirte.",
            "Atiende por chat en la app movil y por Telegram, en espanol, a cualquier hora.",
            "Contacto: ventas@vendedorvirtual.com - Tel: 11-3820-7840.",
        ],
    ),
    (
        "Como te puede ayudar",
        [
            "Entiende tu necesidad inicial (por ejemplo: quiero un aire para un "
            "departamento de 40 m2 con poco consumo).",
            "Hace preguntas especificas para acotar la busqueda: presupuesto, uso, "
            "preferencias de marca o caracteristicas.",
            "Recomienda opciones del catalogo de productos disponible, con precio y "
            "caracteristicas clave.",
            "Comparte el enlace de compra cuando el producto lo tiene.",
            "Acompana la decision hasta que confirmes cual te llevas; si ninguna "
            "opcion te convence, te sugiere ajustar la busqueda.",
        ],
    ),
    (
        "Alcance y limites",
        [
            "Su unico tema es la venta de electrodomesticos y tecnologia del "
            "catalogo. No responde consultas ajenas a las ventas ni a los "
            "productos; si le preguntan otra cosa (clima, deportes, politica, "
            "programacion, chistes, tareas escolares, temas personales, etc.), "
            "avisa amablemente que solo puede ayudar con la compra de productos y "
            "redirige la conversacion a lo que el usuario busca comprar.",
            "No da opiniones, consejos ni informacion general fuera de las ventas.",
            "Los productos, precios y stock salen unicamente del catalogo de la app: "
            "si algo no esta ahi, lo dice claramente en lugar de inventarlo.",
            "Si un producto no esta en el catalogo o no hay stock disponible, lo "
            "informa con claridad y ofrece ajustar la busqueda o ver alternativas "
            "disponibles.",
            "No procesa pagos, reservas ni envios: la compra se concreta en el enlace "
            "o canal del vendedor.",
            "No hace seguimiento de pedidos ni reclamos; para eso se contacta al "
            "vendedor por el canal indicado.",
            "Solo puede recomendar categorias presentes en su catalogo actual.",
        ],
    ),
    (
        "Sugerencias de uso",
        [
            "Cuanto mas especifico seas (presupuesto, marca, uso), mejores seran las "
            "recomendaciones.",
            "Podes pedir que compare dos o tres opciones y explique cual conviene mas "
            "y por que.",
            "Tambien podes pedirle resumen de caracteristicas, diferencia de precio "
            "entre modelos o la alternativa mas economica de una categoria.",
        ],
    ),
]


class PdfInfo(FPDF):
    def footer(self) -> None:
        self.set_y(-15)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(120, 120, 120)
        self.cell(0, 10, f"VendedorVirtual - pagina {self.page_no()}/{{nb}}", align="C")


def generar() -> Path:
    pdf = PdfInfo()
    pdf.alias_nb_pages()
    pdf.set_auto_page_break(auto=True, margin=20)
    pdf.add_page()

    pdf.set_font("Helvetica", "B", 18)
    pdf.set_text_color(20, 20, 20)
    pdf.cell(0, 12, "VendedorVirtual - Informacion del asistente", new_x="LMARGIN", new_y="NEXT")
    pdf.set_font("Helvetica", "I", 10)
    pdf.set_text_color(90, 90, 90)
    pdf.multi_cell(
        0,
        6,
        "Documento de referencia para el asistente IA. Editar el script "
        "tools/generar_pdf_info.py y regenerar para actualizar estos datos.",
    )
    pdf.ln(4)

    for titulo, lineas in SECCIONES:
        pdf.set_font("Helvetica", "B", 13)
        pdf.set_text_color(20, 20, 20)
        pdf.cell(0, 9, titulo, new_x="LMARGIN", new_y="NEXT")
        pdf.set_draw_color(0, 102, 204)
        pdf.set_line_width(0.4)
        y = pdf.get_y()
        pdf.line(pdf.l_margin, y, pdf.w - pdf.r_margin, y)
        pdf.ln(3)
        pdf.set_font("Helvetica", "", 11)
        pdf.set_text_color(35, 35, 35)
        for linea in lineas:
            pdf.set_x(pdf.l_margin)
            pdf.multi_cell(0, 6, f"- {linea}")
            pdf.ln(1)
        pdf.ln(3)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    pdf.output(str(OUTPUT))
    return OUTPUT


if __name__ == "__main__":
    ruta = generar()
    print(f"PDF generado: {ruta}")
