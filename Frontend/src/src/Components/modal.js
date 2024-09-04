import React from "react";

const Modal = ({ isOpen, onClose, loteDetails }) => {
  if (!isOpen) return null;

  return (
    <div style={styles.modalOverlay}>
      <div style={styles.modalContent}>
        <h2>{loteDetails.title}</h2>
        <img
          src={loteDetails.imagen}
          alt={loteDetails.title}
          style={styles.image}
        />
        <div style={styles.details}>
          <p>
            <strong>Arrendatario:</strong> {loteDetails.arrendatario}
          </p>
          <p>
            <strong>Hectáreas:</strong> {loteDetails.hectareas}
          </p>
          <p>
            <strong>Rendimiento Promedio:</strong>
          </p>
          <ul>
            <li>Soja: {loteDetails.rendimiento.soja} ton/ha</li>
            <li>Trigo: {loteDetails.rendimiento.trigo} ton/ha</li>
            <li>Maíz: {loteDetails.rendimiento.maiz} ton/ha</li>
          </ul>
          <p>
            <strong>Lluvia Promedio:</strong> {loteDetails.lluviaPromedio}{" "}
            mm/año
          </p>
        </div>
        <div style={styles.buttonContainer}>
          <button onClick={onClose} style={styles.closeButton}>
            Cerrar
          </button>
          <button style={styles.invertirButton}>
            Invertir
          </button>
        </div>
      </div>
    </div>
  );
};

const styles = {
  modalOverlay: {
    position: "fixed",
    top: 0,
    left: 0,
    width: "100%",
    height: "100%",
    backgroundColor: "rgba(0, 0, 0, 0.5)",
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
  },
  modalContent: {
    width: "500px",
    padding: "20px",
    backgroundColor: "#fff",
    borderRadius: "5px",
    position: "relative",
  },
  image: {
    width: "100%",
    height: "200px",
    objectFit: "cover", // Asegura que la imagen se ajuste al contenedor sin estirarse
    borderRadius: "5px",
    marginBottom: "15px",
  },
  details: {
    marginBottom: "20px",
  },
  buttonContainer: {
    display: "flex",
    justifyContent: "space-between", // Separa los botones a los extremos del contenedor
  },
  closeButton: {
    padding: "10px 15px",
    backgroundColor: "#dc3545",
    color: "#fff",
    border: "none",
    borderRadius: "5px",
    cursor: "pointer",
  },
  invertirButton: {
    padding: "10px 15px",
    backgroundColor: "black",
    color: "#fff",
    border: "none",
    borderRadius: "5px",
    cursor: "pointer",
  },
};

export default Modal;
