// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LoteToken is ERC20 {
    constructor(
        string memory nombre,
        string memory simbolo,
        uint256 cantidad
    ) ERC20(nombre, simbolo) {
        _mint(msg.sender, cantidad);
    }
}

contract AgroBlock is Ownable {
    enum EstadoLote {
        Creado,
        VendidoParcialmente,
        VendidoTotal,
        EnProduccion,
        Deshabilitado
    }

    struct Lote {
    string nombreLote;
    uint256 cantidadTokens;
    uint256 tokensVendidos;
    bool activo;
    uint256 precioPorTokenUSD;
    uint256 fechaInicioPool;
    uint256 fechaCierrePool;
    uint256 precioTotalUSD;
    LoteToken token;
    EstadoLote estado;
    string empresa;
}

    mapping(uint256 => Lote) public lotes;
    uint256 public loteCounter;

    mapping(uint256 => mapping(address => uint256)) public inversiones;
    mapping(uint256 => address[]) public inversores;

    bool public isDevMode;

    uint256 escala;

    event LoteCreado(
        uint256 indexed loteId,
        string nombre,
        uint256 cantidadTokens,
        uint256 precioPorTokenUSD
    );
    event TokenComprado(
        uint256 indexed loteId,
        address indexed inversor,
        uint256 cantidad
    );
    event GananciasDistribuidas(uint256 indexed loteId, uint256 montoTotal);


    constructor(bool _isDevMode) Ownable() {
        isDevMode = _isDevMode;
        escala = 100000;
    }

    function actualizarEstado(uint256 loteId) internal {
        Lote storage lote = lotes[loteId];

        if (lote.tokensVendidos == 0) {
            lote.estado = EstadoLote.Creado; 
        } else if (lote.tokensVendidos > 0 && lote.tokensVendidos < lote.cantidadTokens) {
            lote.estado = EstadoLote.VendidoParcialmente;
        } else if (lote.tokensVendidos == lote.cantidadTokens && bytes(lote.empresa).length == 0) {
            lote.estado = EstadoLote.VendidoTotal;
        } else if (lote.tokensVendidos == lote.cantidadTokens && bytes(lote.empresa).length > 0) {
            lote.estado = EstadoLote.EnProduccion;
        } else if (!lote.activo) {
            lote.estado = EstadoLote.Deshabilitado; 
        }
    }

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
        lote.estado=EstadoLote.Creado;

        loteCounter++;

        emit LoteCreado(
            loteCounter - 1,
            nombreLote,
            cantidadTokens,
            precioPorTokenUSD
        );

    }

    function comprarTokens(
        uint256 loteId,
        address tokenPagado,
        uint256 cantidadPagada
    ) external payable {
        Lote storage lote = lotes[loteId];
        require(lote.activo, "El lote no esta activo");
        require(lote.estado==EstadoLote.VendidoParcialmente || lote.estado==EstadoLote.Creado, "el lote no esta en venta");
        uint256 precioTokenUSD;
        uint256 cantPag = cantidadPagada;

        if (isDevMode) {
            precioTokenUSD = 1;
            cantPag = msg.value;
        }

        uint256 montoEnUSD = (cantPag * precioTokenUSD) / (10**18);
        uint256 cantidadTokensDeseada = (montoEnUSD * escala) /
            lote.precioPorTokenUSD;

        uint256 tokensDisponibles = lote.cantidadTokens - lote.tokensVendidos;
        uint256 cantidadTokensFinal = cantidadTokensDeseada > tokensDisponibles
            ? tokensDisponibles
            : cantidadTokensDeseada;

        uint256 costoTotalUSD = (cantidadTokensFinal * lote.precioPorTokenUSD) /
            escala;
        uint256 costoPagado = (costoTotalUSD * (10**18)) / precioTokenUSD;

        require(
            cantidadTokensFinal > 0,
            "No hay tokens suficientes disponibles"
        );
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

    function asignarEmpresa(uint256 loteId, string memory empresa) external onlyOwner {
        Lote storage lote = lotes[loteId];
        lote.empresa = empresa;
        actualizarEstado(loteId);
    }

    function quitarEmpresa(uint256 loteId) external onlyOwner {
        Lote storage lote = lotes[loteId];
        lote.empresa = "";
        actualizarEstado(loteId);
    }

}
