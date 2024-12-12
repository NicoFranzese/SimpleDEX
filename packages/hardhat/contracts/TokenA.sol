// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importación de OpenZeppelin para los contratos ERC-20
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Paso 1: Creación de los Tokens ERC-20 simples

// Contrato TokenA
contract TokenA is ERC20 {
    
    address public owner;

    constructor() ERC20("TokenA", "TKA") {
        owner = msg.sender;
        // Asignar tokens iniciales al deployer (creador del contrato)
        _mint(owner, 1000000 * 10 ** decimals()); // 1 millón de tokens
    }
}