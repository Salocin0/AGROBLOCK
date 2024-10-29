// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract LoteInversion is Ownable {
    struct Lote {
        string nombre;
        uint cantidadTokens;     // Cantidad total de tokens para este lote
        uint tokensVendidos;     // Tokens ya vendidos
        bool activo;             // Si el lote está activo o no
        uint precioPorTokenUSD;  // Precio por token en USD
        ERC20 token;             // Token asociado al lote
    }

    mapping(uint => Lote) public lotes;
    uint public loteCounter;
    mapping(uint => mapping(address => uint)) public inversiones;  // loteId => inversor => cantidadTokens

    AggregatorV3Interface internal priceFeed; // Oráculo para obtener el precio de MATIC

    event LoteCreado(uint indexed loteId, string nombre, uint cantidadTokens, uint precioPorTokenUSD);
    event TokenComprado(uint indexed loteId, address indexed inversor, uint cantidad);
    event GananciasDistribuidas(uint indexed loteId, uint montoTotal);
    event LoteCerrado(uint indexed loteId);

    constructor(address _priceFeed) {
        loteCounter = 0;
        priceFeed = AggregatorV3Interface(_priceFeed); // Inicializa el oráculo
    }

    function crearLote(string memory nombre, uint cantidadTokens, uint precioTotalUSD) external onlyOwner {
        require(cantidadTokens > 0, "Debe haber al menos 1 token");
        require(precioTotalUSD > 0, "El precio total debe ser mayor que 0");

        // Calcular el precio por token en USD
        uint precioPorTokenUSD = precioTotalUSD / cantidadTokens;

        Lote storage lote = lotes[loteCounter];
        lote.nombre = nombre;
        lote.cantidadTokens = cantidadTokens;
        lote.precioPorTokenUSD = precioPorTokenUSD; // Guardar el precio por token
        lote.activo = true;

        // Crear un nuevo token ERC20 específico para este lote
        lote.token = new ERC20(nombre);

        loteCounter++;

        emit LoteCreado(loteCounter - 1, nombre, cantidadTokens, precioPorTokenUSD);
    }

    function comprarTokens(uint loteId) external payable {
        Lote storage lote = lotes[loteId];
        require(lote.activo, "El lote no esta activo");

        // Obtener el precio actual de MATIC en USD usando el oráculo
        uint precioMATIC = uint(getLatestPrice());

        // Calcular cuántos MATIC equivalen a 1 USD
        uint maticPorUSD = precioMATIC / 1e18; // Asegúrate de tener el precio en la misma unidad

        // Calcular cuántos tokens se pueden comprar con el monto enviado
        uint montoEnUSD = msg.value * maticPorUSD; // Monto en USD que se está enviando
        uint cantidadTokens = montoEnUSD / lote.precioPorTokenUSD; // Convertir a tokens según el precio por token

        require(cantidadTokens > 0 && cantidadTokens <= lote.cantidadTokens - lote.tokensVendidos, "Cantidad de tokens invalida");

        inversiones[loteId][msg.sender] += cantidadTokens;
        lote.tokensVendidos += cantidadTokens;

        emit TokenComprado(loteId, msg.sender, cantidadTokens);
    }

    function verPorcentajeLote(uint loteId, address inversor) external view returns (uint) {
        Lote storage lote = lotes[loteId];
        if (lote.tokensVendidos == 0) return 0;
        return (inversiones[loteId][inversor] * 100) / lote.tokensVendidos;
    }

    function ingresarFondosYDistribuir(uint loteId) external payable onlyOwner {
        Lote storage lote = lotes[loteId];
        require(lote.activo, "El lote no esta activo");
        require(msg.value > 0, "Debes enviar fondos");

        uint montoDistribucion = msg.value;

        for (uint i = 0; i < loteCounter; i++) {
            address inversor = address(i); // Aquí deberías mapear a los inversores adecuadamente
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
        for (uint i = 0; i < loteCounter; i++) {
            address inversor = address(i); // Aquí deberías mapear a los inversores adecuadamente
            uint cantidadTokens = inversiones[loteId][inversor];
            if (cantidadTokens > 0) {
                uint liquidacion = (fondosRestantes * cantidadTokens) / lote.tokensVendidos;
                payable(inversor).transfer(liquidacion);
            }
        }

        emit LoteCerrado(loteId);
    }

    function getLatestPrice() public view returns (int) {
        (
            , 
            int price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        return price; // Devuelve el precio más reciente
    }
}
