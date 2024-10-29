// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// Contrato para el token del lote
contract LoteToken is ERC20 {
    constructor(string memory nombre, string memory simbolo, uint256 cantidad) 
        ERC20(nombre, simbolo) {
        _mint(msg.sender, cantidad); // Minta la cantidad de tokens al creador del contrato
    }
}

contract LoteInversion is Ownable {
    struct Lote {
        string nombre;
        uint cantidadTokens;     // Cantidad total de tokens para este lote
        uint tokensVendidos;     // Tokens ya vendidos
        bool activo;             // Si el lote está activo o no
        uint precioPorTokenUSD;  // Precio por token en USD
        LoteToken token;         // Token asociado al lote
    }

    mapping(uint => Lote) public lotes;
    uint public loteCounter;

    // Mapeo para almacenar inversiones por lote y por inversor
    mapping(uint => mapping(address => uint)) public inversiones;
    mapping(uint => address[]) public inversores; // Almacena las direcciones de los inversores por lote

    AggregatorV3Interface internal priceFeed; // Oráculo para obtener el precio de MATIC

    event LoteCreado(uint indexed loteId, string nombre, uint cantidadTokens, uint precioPorTokenUSD);
    event TokenComprado(uint indexed loteId, address indexed inversor, uint cantidad);
    event GananciasDistribuidas(uint indexed loteId, uint montoTotal);
    event LoteCerrado(uint indexed loteId);

    // Constructor que acepta la dirección del oráculo para obtener el precio
    constructor(address _priceFeed, uint number) Ownable() {
        loteCounter = 0;

        // Si no se pasa una dirección, se establece un valor fijo para el precio de MATIC
        if (number == 0) {
            priceFeed = AggregatorV3Interface(address(0)); // O puedes dejarlo como `0`
        } else {
            priceFeed = AggregatorV3Interface(_priceFeed); // Inicializa el oráculo
        }
    }

    function crearLote(string memory nombre, uint cantidadTokens, uint precioTotalUSD) external onlyOwner {
        require(cantidadTokens > 0, "Debe haber al menos 1 token");
        require(precioTotalUSD > 0, "El precio total debe ser mayor que 0");

        // Calcular el precio por token en USD
        uint precioPorTokenUSD = precioTotalUSD / cantidadTokens;

        // Crear un nuevo token ERC20 específico para este lote
        LoteToken nuevoToken = new LoteToken(nombre, "LTKN", cantidadTokens); // Cambia "LTKN" por un símbolo adecuado

        Lote storage lote = lotes[loteCounter];
        lote.nombre = nombre;
        lote.cantidadTokens = cantidadTokens;
        lote.precioPorTokenUSD = precioPorTokenUSD; // Guardar el precio por token
        lote.activo = true;
        lote.token = nuevoToken;

        loteCounter++;

        emit LoteCreado(loteCounter - 1, nombre, cantidadTokens, precioPorTokenUSD);
    }

    function comprarTokens(uint loteId) external payable {
        Lote storage lote = lotes[loteId];
        require(lote.activo, "El lote no esta activo");

        // Obtener el precio actual de MATIC en USD usando el oráculo
        uint precioMATIC;
        if (address(priceFeed) == address(0)) {
            // Si no hay oráculo, usar el valor predeterminado
            precioMATIC = 5 * 1e18; // 5 USD en formato de wei
        } else {
            precioMATIC = uint(getLatestPrice());
        }

        // Calcular cuántos tokens se pueden comprar con el monto enviado
        uint montoEnUSD = (msg.value * precioMATIC) / 1e18; // Monto en USD que se está enviando
        uint cantidadTokens = montoEnUSD / lote.precioPorTokenUSD; // Convertir a tokens según el precio por token

        require(cantidadTokens > 0 && cantidadTokens <= lote.cantidadTokens - lote.tokensVendidos, "Cantidad de tokens invalida");

        // Transferir los tokens al comprador
        lote.token.transfer(msg.sender, cantidadTokens);

        inversiones[loteId][msg.sender] += cantidadTokens;

        // Verifica si el inversor ya está registrado y si no, agrégalo
        if (inversiones[loteId][msg.sender] == cantidadTokens) {
            inversores[loteId].push(msg.sender);
        }

        lote.tokensVendidos += cantidadTokens;

        emit TokenComprado(loteId, msg.sender, cantidadTokens);
    }

    function verPorcentajeLote(uint loteId) external view returns (uint) {
        Lote storage lote = lotes[loteId];
        if (lote.cantidadTokens == 0) return 0; // Evitar división por cero
        return (lote.tokensVendidos * 100) / lote.cantidadTokens; // Porcentaje de tokens vendidos
    }

    function ingresarFondosYDistribuir(uint loteId) external payable onlyOwner {
        Lote storage lote = lotes[loteId];
        require(lote.activo, "El lote no esta activo");
        require(msg.value > 0, "Debes enviar fondos");

        uint montoDistribucion = msg.value;

        for (uint i = 0; i < inversores[loteId].length; i++) {
            address inversor = inversores[loteId][i]; // Obtén la dirección del inversor desde el mapeo
            uint cantidadTokens = inversiones[loteId][inversor];
            if (cantidadTokens > 0) {
                uint ganancia = (montoDistribucion * cantidadTokens) / lote.tokensVendidos;
                payable(inversor).transfer(ganancia);
            }
        }

        emit GananciasDistribuidas(loteId, msg.value);
    }

    function cerrarYLiquidarLote(uint loteId) external onlyOwner {
        Lote storage lote = lotes[loteId];
        require(lote.activo, "El lote ya fue cerrado");
        lote.activo = false;

        uint fondosRestantes = lote.tokensVendidos; // Distribuir según los tokens vendidos
        for (uint i = 0; i < inversores[loteId].length; i++) {
            address inversor = inversores[loteId][i]; // Obtén la dirección del inversor desde el mapeo
            uint cantidadTokens = inversiones[loteId][inversor];
            if (cantidadTokens > 0) {
                uint liquidacion = (fondosRestantes * cantidadTokens) / lote.tokensVendidos;
                payable(inversor).transfer(liquidacion);
            }
        }

        emit LoteCerrado(loteId);
    }

    function getLatestPrice() public view returns (int) {
        if (address(priceFeed) == address(0)) {
            return 5 * 1e18; // Retorna el valor por defecto si no hay oráculo
        } else {
            (
                , 
                int price,
                ,
                ,
                
            ) = priceFeed.latestRoundData();
            return price; // Devuelve el precio más reciente
        }
    }
}
