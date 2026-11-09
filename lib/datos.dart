const servicios = ['Ciudad', 'Moto', 'Interurbano', 'Entregas', 'Fletes'];

const pagos = [
  'Tenpo',
  'MACH',
  'Banco Santander',
  'Mercado Pago',
  'PagoRUT',
  'Efectivo',
];

const lugares = {
  'Universidad del Desarrollo': 'Av. Plaza, Las Condes',
  'Medicina UDD': 'República de Honduras, Las Condes',
  'Estacionamientos UDD': 'Génova Poniente, Las Condes',
  'Metro Salvador': 'Providencia, Santiago',
  'Renaissance Santiago Hotel': 'Vitacura, Santiago',
  'Mallplaza Los Dominicos': 'Las Condes, Santiago',
};

String normalizar(String texto) {
  const tildes = 'áéíóúü';
  const letras = 'aeiouu';
  texto = texto.toLowerCase().trim();
  for (var i = 0; i < tildes.length; i++) {
    texto = texto.replaceAll(tildes[i], letras[i]);
  }
  return texto;
}

bool coincide(String texto, String busqueda) =>
    normalizar(texto).contains(normalizar(busqueda));

String clp(int precio) {
  final pesos = precio.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'CLP\$$pesos';
}
