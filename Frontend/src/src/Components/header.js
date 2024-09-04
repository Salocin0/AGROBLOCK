import React from 'react';

const Header = () => {
    return (
        <header style={styles.header}>
            <h1 style={styles.title}>Pools de Inversión Disponibles</h1>
            <nav style={styles.nav}>
                <a href="/" style={styles.link}>Inicio</a>
                <a href="/pools" style={styles.link}>Pools</a>
                <a href="/inversiones" style={styles.link}>Inversiones</a>
                <a href="/login" style={styles.link}>Login</a>
            </nav>
        </header>
    );
};

const styles = {
    header: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '20px',
        backgroundColor: '#f8f9fa',
        borderBottom: '1px solid #e9ecef'
    },
    title: {
        margin: 0,
        fontSize: '24px',
        color: '#333'
    },
    nav: {
        display: 'flex',
        gap: '15px'
    },
    link: {
        textDecoration: 'none',
        color: '#007bff'
    }
};

export default Header;
