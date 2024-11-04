# AgroBlock Smart Contract

## Participantes

- Fernando Martinez
- Nicolas Durelli
- Matias Armesto
- Nahuel Saba
- Boschin Gonzalo
- Nicolette Bloin

## ultima version del contrato verificado y deployado

- [Link a polygonscan](https://amoy.polygonscan.com/address/0x796DFd322B1Dae3DB45B88cbd2E00e6fEA5a64B2)

- Direccion del contrato: 0x796DFd322B1Dae3DB45B88cbd2E00e6fEA5a64B2
## Video Demo
- [Video Demo](https://www.youtube.com/watch?v=Pzy_jVBEGr0)

## Descripcion

Este contrato permite la creación de pools de inversión diseñados específicamente para adquirir terrenos agrícolas. A través de estos pools, múltiples inversores pueden contribuir con capital, formando colectivamente un fondo de inversión destinado a la compra de un terreno agrícola determinado. La meta de cada pool es alcanzar un objetivo de compra predefinido, que representa el monto total necesario para adquirir el terreno.

Si el objetivo de compra se logra en el tiempo estipulado, el contrato ejecuta la adquisición del terreno. Posteriormente, los inversores reciben tokens que representan la propiedad fraccionada del terreno, lo cual equivale a un porcentaje del campo adquirido. Estos tokens no solo reflejan la proporción de inversión de cada participante, sino que también funcionan como activos digitales transferibles, permitiendo a los inversores poseer, vender o transferir su participación en el terreno.

Una vez adquirido el terreno y comenzada su explotación agrícola, los ingresos generados, ya sean por cosechas, arrendamientos u otras actividades productivas, se distribuyen automáticamente entre los poseedores de tokens. Esto garantiza que cada inversor reciba ingresos proporcionales a la cantidad de tokens que posee, generando una fuente de ingresos pasiva y directa desde la plataforma. De esta manera, el contrato no solo democratiza el acceso a la inversión en terrenos agrícolas, sino que también asegura una gestión transparente y confiable de los fondos y las ganancias, facilitando el retorno de inversión a los participantes.

## Clonar repositorio

Para clonar el repositorio ejecutamos el siguiente comando

```
git clone https://github.com/Salocin0/AGROBLOCK.git
```

## Instalar

Para instalar las librerias ejecutamos el siguiente comando

```
npm install
```

## Compilar

Para compilar el contrato ejecutamos el siguiente comando

```
npm run compile
```

## Deployar

Para deployar el contrato en la red de pruebas de polygon creamos un archivo llamado .env con los siguiente valores.

```
WALLET_ADDRESS= /*completar la direccion de la wallet que va a deployar el contrato*/
PRIVATE_KEY= /*completar la clave privada de la wallet que va a deployar el contrato*/
RPC_URL=https://rpc-amoy.polygon.technology/
```

Ejecutamos el siguiente comando para deployarlo en modo dev

```
npm run deploy
```

## Funciones del contrato

### 1. `constructor`

```solidity
constructor(bool _isDevMode) Ownable() {
  isDevMode = _isDevMode;
  escala = 100000;
}
```

- **Entrada**:
  - `_isDevMode`: Un booleano que indica si el contrato está en modo desarrollo.

-- _El modo desarrollo es para setear el valor del token enviado en la transaccion en 1 USD_
-- _La escala indica que la porcion minima de un lote puede valer como minimo 1 centavo de dolar_

### 2. `crearLote`

```solidity
function crearLote(
  string memory nombreLote,
  uint256 cantidadTokens,
  uint256 precioTotalUSD,
  uint256 fechaInicioPool,
  uint256 fechaCierrePool,
  string memory simboloToken
) external onlyOwner {
  require(cantidadTokens > 0, "Debe haber al menos 1 token");
  require(precioTotalUSD > 0, "El precio total debe ser mayor que 0");

  uint256 precioPorTokenUSD = (precioTotalUSD * escala) / cantidadTokens;
  require(
    precioPorTokenUSD >= 1,
    "El precio por token debe ser al menos un decimo de centavo"
  );

  LoteToken nuevoToken = new LoteToken(
    nombreLote,
    simboloToken,
    cantidadTokens * escala
  );

  Lote storage lote = lotes[loteCounter];
  lote.nombreLote = nombreLote;
  lote.cantidadTokens = cantidadTokens;
  lote.precioPorTokenUSD = precioPorTokenUSD;
  lote.fechaInicioPool = fechaInicioPool;
  lote.fechaCierrePool = fechaCierrePool;
  lote.activo = true;
  lote.token = nuevoToken;
  lote.precioTotalUSD = precioTotalUSD;
  lote.estado = EstadoLote.Creado;

  loteCounter++;

  emit LoteCreado(
    loteCounter - 1,
    nombreLote,
    cantidadTokens,
    precioPorTokenUSD
  );
}
```

- **Entrada**:
  - `nombreLote`: El nombre del lote.
  - `cantidadTokens`: La cantidad de tokens a crear.
  - `precioTotalUSD`: El precio total del lote en USD.
  - `fechaInicioPool`: La fecha de inicio del pool.
  - `fechaCierrePool`: La fecha de cierre del pool.
  - `simboloToken`: El símbolo del token.
- **Utilidad**: Crear un nuevo lote y emiter un evento de creación.

### 3. `comprarTokens`

```solidity
function comprarTokens(
  uint256 loteId,
  address tokenPagado,
  uint256 cantidadPagada
) external payable {
  Lote storage lote = lotes[loteId];
  require(lote.activo, "El lote no esta activo");
  require(
    lote.estado == EstadoLote.VendidoParcialmente ||
      lote.estado == EstadoLote.Creado,
    "el lote no esta en venta"
  );
  uint256 precioTokenUSD;
  uint256 cantPag = cantidadPagada;

  if (isDevMode) {
    precioTokenUSD = 1;
    cantPag = msg.value;
  }

  uint256 montoEnUSD = (cantPag * precioTokenUSD) / (10 ** 18);
  uint256 cantidadTokensDeseada = (montoEnUSD * escala) /
    lote.precioPorTokenUSD;

  uint256 tokensDisponibles = lote.cantidadTokens - lote.tokensVendidos;
  uint256 cantidadTokensFinal = cantidadTokensDeseada > tokensDisponibles
    ? tokensDisponibles
    : cantidadTokensDeseada;

  uint256 costoTotalUSD = (cantidadTokensFinal * lote.precioPorTokenUSD) /
    escala;
  uint256 costoPagado = (costoTotalUSD * (10 ** 18)) / precioTokenUSD;

  require(cantidadTokensFinal > 0, "No hay tokens suficientes disponibles");
  require(montoEnUSD >= costoTotalUSD, "El monto pagado es insuficiente");

  lote.token.transfer(msg.sender, cantidadTokensFinal);
  inversiones[loteId][msg.sender] += cantidadTokensFinal;

  if (inversiones[loteId][msg.sender] == cantidadTokensFinal) {
    inversores[loteId].push(msg.sender);
  }

  lote.tokensVendidos += cantidadTokensFinal;

  if (cantPag > costoPagado) {
    uint256 sobrante = cantPag - costoPagado;
    if (isDevMode) {
      payable(msg.sender).transfer(sobrante);
    } else {
      IERC20(tokenPagado).transfer(msg.sender, sobrante);
    }
  }
  emit TokenComprado(loteId, msg.sender, cantidadTokensFinal);
  actualizarEstado(loteId);
}
```

- **Entrada**:
  - `loteId`: El ID del lote que se desea comprar.
  - `tokenPagado`: La dirección del token usado para la compra. (no necesario si esta el modo dev)
  - `cantidadPagada`: La cantidad pagada por el comprador. (no necesario si esta el modo dev)
- **Utilidad**: Permite a los inversores comprar tokens del lote.

_el valor que se toma para los fondos enviados en la transaccion son fijos en 1 USD en el modo dev_

### 4. `asignarEmpresa`

```solidity
function asignarEmpresa(
  uint256 loteId,
  string memory empresa
) external onlyOwner {
  Lote storage lote = lotes[loteId];
  lote.empresa = empresa;
  actualizarEstado(loteId);
}
```

- **Entrada**:
  - `loteId`: El ID del lote al que se quiere asignar una empresa.
  - `empresa`: nombre de la empresa.
- **Utilidad**: permite asignar una empresa al lote lo que actualiza su estado y cambia sus funciones disponibles

### 5. `quitarEmpresa`

```solidity
function quitarEmpresa(uint256 loteId) external onlyOwner {
  Lote storage lote = lotes[loteId];
  lote.empresa = "";
  actualizarEstado(loteId);
}
```

- **Entrada**:
  - `loteId`: El ID del lote al que se quiere quitar la empresa.
- **Utilidad**: permite borrar empresa al lote lo que actualiza su estado y cambia sus funciones disponibles

### 6. `actualizarEstado`

```solidity
function actualizarEstado(uint256 loteId) internal {
  Lote storage lote = lotes[loteId];

  if (lote.tokensVendidos == 0) {
    lote.estado = EstadoLote.Creado;
  } else if (
    lote.tokensVendidos > 0 && lote.tokensVendidos < lote.cantidadTokens
  ) {
    lote.estado = EstadoLote.VendidoParcialmente;
  } else if (
    lote.tokensVendidos == lote.cantidadTokens &&
    bytes(lote.empresa).length == 0
  ) {
    lote.estado = EstadoLote.VendidoTotal;
  } else if (
    lote.tokensVendidos == lote.cantidadTokens && bytes(lote.empresa).length > 0
  ) {
    lote.estado = EstadoLote.EnProduccion;
  } else if (!lote.activo) {
    lote.estado = EstadoLote.Deshabilitado;
  }
}
```

- **Entrada**:
  - `loteId`: El ID del lote al que se quiere actualizar el estado.
- **Utilidad**: permite actualizar el estado de un lote especifico.