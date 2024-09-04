import React, { useState } from 'react';
import Header from './Components/header';
import Modal from './Components/modal';
import Card from './Components/card';
import imgCampo1 from './assets/campo-1.jpg';
import imgCampo2 from './assets/campo-2.webp';


const App = () => {
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [selectedLote, setSelectedLote] = useState(null);

    const openModal = (lote) => {
        setSelectedLote(lote);
        setIsModalOpen(true);
    };

    const closeModal = () => {
        setIsModalOpen(false);
    };

    const lotes = [
        {
            title: 'Lote La Pampa',
            percentage: 60,
            arrendatario: 'Campos Argentinos S.R.L.',
            hectareas: 750,
            rendimiento: { soja: 3.8, trigo: 4.5, maiz: 10.2 },
            lluviaPromedio: 850,
            imagen:imgCampo1
        },
        {
            title: 'Lote San Juan',
            percentage: 75,
            arrendatario: 'Agro San Juan S.A.',
            hectareas: 600,
            rendimiento: { soja: 3.5, trigo: 4.2, maiz: 9.8 },
            lluviaPromedio: 700,
            imagen:imgCampo2
        }
    ];

    return (
        <div>
            <Header />
            <div style={styles.cardsContainer}>
                {lotes.map(lote => (
                    <Card 
                        key={lote.title} 
                        title={lote.title} 
                        percentage={lote.percentage} 
                        onDetailsClick={() => openModal(lote)} 
                        img={lote.imagen} 
                    />
                ))}
            </div>
            {selectedLote && 
                <Modal 
                    isOpen={isModalOpen} 
                    onClose={closeModal} 
                    loteDetails={selectedLote} 
                />}
        </div>
    );
};

const styles = {
    cardsContainer: {
        display: 'flex',
        gap: '20px',
        padding: '20px',
        justifyContent: 'center'
    }
};

export default App;
