import express from "express";
import { ethers } from "ethers";
import dotenv from "dotenv";
import InvestmentPoolsABI from "../../build/contracts/InvestmentPools.json" assert { type: "json" };

dotenv.config();

const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const privateKey = process.env.PRIVATE_KEY;
const wallet = new ethers.Wallet(privateKey, provider);

const contractAddress = process.env.CONTRACT_ADDRESS;
const contract = new ethers.Contract(
  contractAddress,
  InvestmentPoolsABI.abi,
  wallet
);

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// Ruta para crear un pool
app.post("/create-pool", async (req, res) => {
  try {
    const { name, description, goal, durationInDays, tokenAmount, codigoLote } =
      req.body;
    const tx = await contract.createPool(
      name,
      description,
      goal,
      durationInDays,
      tokenAmount,
      codigoLote
    );
    await tx.wait();
    res.json({
      message: "Pool created successfully",
      transactionHash: tx.hash,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error creating pool" });
  }
});

// Ruta para invertir en un pool
app.post("/invest/:poolId", async (req, res) => {
  try {
    const poolId = parseInt(req.params.poolId, 10);
    const amount = ethers.utils.parseEther(req.body.amount);
    const tx = await contract.invest(poolId, { value: amount });
    await tx.wait();
    res.json({
      message: "Investment made successfully",
      transactionHash: tx.hash,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error making investment" });
  }
});

// Ruta para verificar y cerrar un pool
app.post("/check-and-close/:poolId", async (req, res) => {
  try {
    const poolId = parseInt(req.params.poolId, 10);
    const tx = await contract.checkAndClosePool(poolId);
    await tx.wait();
    res.json({
      message: "Pool checked and closed successfully",
      transactionHash: tx.hash,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error checking and closing pool" });
  }
});

// Ruta para retirar fondos del contrato
app.post("/withdraw-funds", async (req, res) => {
  try {
    const tx = await contract.withdrawFunds();
    await tx.wait();
    res.json({
      message: "Funds withdrawn successfully",
      transactionHash: tx.hash,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error withdrawing funds" });
  }
});

// Ruta para obtener todos los lotes
app.get("/lotes", async (req, res) => {
  try {
    const loteCount = await contract.loteCounter(); // Obtener la cantidad de lotes creados
    const lotesArray = [];

    for (let i = 0; i < loteCount; i++) {
      const lote = await contract.getLote(i); // Obtener cada lote individual
      lotesArray.push(lote); // Agregarlo al array
    }

    res.json(lotesArray);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error obteniendo los lotes" });
  }
});

app.get("/porcentaje-venta/:loteId", async (req, res) => {
  try {
    const loteId = parseInt(req.params.loteId, 10);
    const porcentaje = await contract.porcentajeVenta(loteId);
    res.json({
      porcentaje: porcentaje.toString(),
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error obteniendo el porcentaje de venta" });
  }
});

// Inicia el servidor
app.listen(port, () => {
  console.log(`Servidor escuchando en el puerto ${port}`);
});
