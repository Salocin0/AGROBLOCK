import express from "express";
import { ethers } from "ethers";
import dotenv from "dotenv";
import SimpleStamperABI from "./../build/contracts/SimpleStamper.json" assert { type: "json" };

dotenv.config();

const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const privateKey = process.env.PRIVATE_KEY;
const wallet = new ethers.Wallet(privateKey, provider);

const contractAddress = process.env.CONTRACT_ADDRESS;
const contract = new ethers.Contract(
  contractAddress,
  SimpleStamperABI.abi,
  wallet
);

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// Ruta para sellar una lista de hashes
app.post("/put", async (req, res) => {
  try {
    const { objectList } = req.body;
    const tx = await contract.put(objectList);
    await tx.wait();
    res.json({
      message: "Hashes stamped successfully",
      transactionHash: tx.hash,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error al sellar los hashes" });
  }
});

// Ruta para verificar si un objeto está sellado
app.get("/is-stamped/:object", async (req, res) => {
  try {
    const object = req.params.object;
    const result = await contract.isStamped(object);
    res.json({ isStamped: result });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error al verificar el objeto" });
  }
});

// Ruta para obtener un sello completo en una posición específica
app.get("/stamp/:pos", async (req, res) => {
  try {
    const pos = parseInt(req.params.pos);
    const result = await contract.getStamplistPos(pos);
    const response = {
      object: result[0].toString(),
      blockNo: result[1].toString(),
      timestamp: result[2].toString(),
    };

    res.json(response);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error al obtener el sello" });
  }
});

// Ruta para obtener la marca de tiempo del bloque por hash
app.get("/timestamp-by-hash/:object", async (req, res) => {
  try {
    const object = req.params.object;
    const result = await contract.getTimestampByHash(object);
    const timestamp = parseInt(result.toString(), 10);
    const date = new Date(timestamp * 1000);
    const localDate = date.toLocaleString();
    res.json({
      timestamp,
      localDate,
    });
  } catch (error) {
    console.error("Error:", error.message);
    res
      .status(500)
      .json({ error: "Error al obtener la marca de tiempo por hash" });
  }
});

// Ruta para obtener la marca de tiempo del bloque en una posición específica
app.get("/timestamp-by-pos/:pos", async (req, res) => {
    try {
      const pos = parseInt(req.params.pos, 10);
      const result = await contract.getTimestampByPos(pos);
      const timestamp = parseInt(result.toString(), 10);
      const date = new Date(timestamp * 1000);
      const localDate = date.toLocaleString();
      res.json({
        timestamp,
        localDate
      });
    } catch (error) {
      console.error('Error:', error.message);
      res.status(500).json({ error: "Error al obtener la marca de tiempo por posición" });
    }
  });
  

// Inicia el servidor
app.listen(port, () => {
  console.log(`Servidor escuchando en el puerto ${port}`);
});
