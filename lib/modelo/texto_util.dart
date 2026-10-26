String normalizarTexto(String texto) {
  const remplazos = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
  };
  var resultado = texto.toLowerCase();
  remplazos.forEach((de, a) => resultado = resultado.replaceAll(de, a));
  return resultado.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
}

List<String> terminosDe(String texto, {int minimo = 4}) =>
    normalizarTexto(texto)
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= minimo)
        .toSet()
        .toList();
