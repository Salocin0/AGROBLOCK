import React from 'react';

const Card = ({ title, percentage, onDetailsClick,img }) => {
    return (
        <div style={styles.card}>
            <img src={img} alt={title} style={styles.image} />
            <h3>{title}</h3>
            <div style={styles.progressBar}>
                <div style={{ ...styles.progress, width: `${percentage}%` }}></div>
            </div>
            <p>{percentage}% invertido</p>
            <button onClick={onDetailsClick} style={styles.button}>Ver detalles</button>
        </div>
    );
};

const styles = {
    card: {
        width: '300px',
        padding: '20px',
        border: '1px solid #e9ecef',
        borderRadius: '5px',
        backgroundColor: '#fff',
        textAlign: 'center',
        marginBottom: '20px'
    },
    image: {
        width: '100%',
        height: '150px',
        objectFit: 'cover', // Esto asegura que la imagen se ajuste al contenedor sin estirarse
        borderRadius: '5px',
        marginBottom: '15px'
    },
    progressBar: {
        width: '100%',
        height: '10px',
        backgroundColor: '#e9ecef',
        borderRadius: '5px',
        marginBottom: '10px'
    },
    progress: {
        height: '10px',
        backgroundColor: '#28a745',
        borderRadius: '5px'
    },
    button: {
        padding: '10px 15px',
        backgroundColor: '#007bff',
        color: '#fff',
        border: 'none',
        borderRadius: '5px',
        cursor: 'pointer'
    }
};

export default Card;