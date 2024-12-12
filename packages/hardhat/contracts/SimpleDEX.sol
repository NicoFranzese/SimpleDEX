// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importación de OpenZeppelin para la interfaz ERC-20
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Paso 1: Implementación del contrato de Exchange
contract SimpleDEX {
    // Instancias de los tokens usando la interfaz IERC20
    IERC20 public tokenA;
    IERC20 public tokenB;

    // Balances del pool de liquidez
    uint256 public reserveA;
    uint256 public reserveB;
    address public owner;

    //variable para lleva registro de las liquidaciones agregadas por token por los Usuarios.
    mapping(address => mapping(address => uint256)) public liquidityProviders;

    // Constructor para inicializar el contrato con las direcciones de los tokens
    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        owner = msg.sender;
    }

    // Evento para añadir liquidez
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    
    // Evento para intercambios
    event TokenSwapped(address indexed trader, address inputToken, uint256 inputAmount, address outputToken, uint256 outputAmount);

    // Evento para retiro de liquidez
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);


    /*modifier onlyOwner() {
        require(msg.sender ==owner, "usted no tiene permisos");
        _;
    }*/

    // Función para añadir liquidez
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        // Transferir tokens al contrato
        require(tokenA.transferFrom(msg.sender, address(this), amountA), "Transferencia de TokenA fallida");
        require(tokenB.transferFrom(msg.sender, address(this), amountB), "Transferencia de TokenB fallida");

        // Actualizar reservas
        reserveA += amountA;
        reserveB += amountB;

        // Registrar la cantidad de cada token añadida por el usuario
        liquidityProviders[msg.sender][address(tokenA)] += amountA;
        liquidityProviders[msg.sender][address(tokenB)] += amountB;
                
        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

     // Función para intercambiar TokenA por TokenB
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Debe ingresar una cantidad mayor a cero");

        // Transferencia de TokenA al contrato
        require(tokenA.transferFrom(msg.sender, address(this), amountAIn), "Transferencia de TokenA fallida");

        //Calculo PPT: (x + dx) * (y - dy) = x * y.
        /*La cantidad de TokenB (dy) que recibirá se puede calcular a partir de la fórmula del producto constante:
        (x + dx) * (y - dy) = x * y
        Reemplazando los valores conocidos:     (1000 + 100) * (2000 - dy) = 1000 * 2000
        Resolviendo para dy:
        1100 * (2000 - dy) = 2000000
        2000 - dy = 2000000 / 1100
        2000 - dy ≈ 1818.18        =>   dy ≈ 2000 - 1818.18 ≈ 181.82
        El usuario recibirá aproximadamente 181.82 unidades de TokenB a cambio de las 100 unidades de TokenA que depositó en el pool.
        */

        uint256 newReserveA = reserveA + amountAIn;  
        uint256 multPools = (reserveA * reserveB);
        uint256 calc3 = multPools / newReserveA;
        uint256 totalB = reserveB - calc3;

        require(totalB > 0, "Cantidad de salida no valida");

        // Actualizar reservas
        reserveA = newReserveA;
        reserveB -= totalB;

        // Transferir TokenB al usuario
        require(tokenB.transfer(msg.sender, totalB), "Transferencia de TokenB fallida");

        emit TokenSwapped(msg.sender, address(tokenA), amountAIn, address(tokenB), totalB);
    }

    // Función para intercambiar TokenB por TokenA
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Debe ingresar una cantidad mayor a cero");

        // Transferencia de TokenB al contrato
        require(tokenB.transferFrom(msg.sender, address(this), amountBIn), "Transferencia de TokenB fallida");

        uint256 newReserveB = reserveB + amountBIn;
        uint256 multPools = (reserveA * reserveB);
        uint256 calc3 = multPools / newReserveB;
        uint256 totalA = reserveA - calc3;

        require(totalA > 0, "Cantidad de salida no valida");   

        // Actualizar reservas
        reserveB = newReserveB;
        reserveA -= totalA;

        // Transferir TokenA al usuario
        require(tokenA.transfer(msg.sender, totalA), "Transferencia de TokenA fallida");

        emit TokenSwapped(msg.sender, address(tokenB), amountBIn, address(tokenA), totalA);
    }

    // Función para retirar liquidez
    function removeLiquidity(uint256 amountA, uint256 amountB) external {

        // Verificar que el usuario tiene suficiente liquidez para retirar
        require(liquidityProviders[msg.sender][address(tokenA)] >= amountA, "Not enough TokenA liquidity to withdraw");
        require(liquidityProviders[msg.sender][address(tokenB)] >= amountB, "Not enough TokenB liquidity to withdraw");

        // Reducir el saldo de liquidez del usuario en el mapeo
        liquidityProviders[msg.sender][address(tokenA)] -= amountA;
        liquidityProviders[msg.sender][address(tokenB)] -= amountB;

        // Transferir los tokens desde el contrato al usuario
        require(IERC20(tokenA).transfer(msg.sender, amountA), "TokenA transfer failed");
        require(IERC20(tokenB).transfer(msg.sender, amountB), "TokenB transfer failed");

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    // Función para obtener el precio de un token en términos del otro
    function getPrice(address _token) external view returns (uint256) {
        require(_token == address(tokenA) || _token == address(tokenB), "Token no soportado");

        if (_token == address(tokenA)) {
            return (reserveB * 1e18) / reserveA; // Precio de TokenA en términos de TokenB
        } else {
            return (reserveA * 1e18) / reserveB; // Precio de TokenB en términos de TokenA
        }
    }
}
