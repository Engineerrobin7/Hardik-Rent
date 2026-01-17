-- Hardik Rent Database Schema

CREATE DATABASE IF NOT EXISTS hardik_rent;
USE hardik_rent;

-- Users Table
CREATE TABLE users (
    id VARCHAR(255) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255),
    name VARCHAR(255) NOT NULL,
    role ENUM('owner', 'tenant') NOT NULL,
    phone VARCHAR(20),
    profile_image VARCHAR(512),
    fcm_token VARCHAR(512),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Properties Table
CREATE TABLE properties (
    id VARCHAR(255) PRIMARY KEY,
    owner_id VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Unit Structure (Floors and Units)
CREATE TABLE units (
    id VARCHAR(255) PRIMARY KEY,
    property_id VARCHAR(255) NOT NULL,
    floor_number INT NOT NULL,
    unit_number VARCHAR(50) NOT NULL,
    status ENUM('vacant', 'occupied', 'maintenance') DEFAULT 'vacant',
    tenant_id VARCHAR(255),
    rent_amount DECIMAL(10, 2),
    is_electricity_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE,
    FOREIGN KEY (tenant_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Rent Payments Table
CREATE TABLE payments (
    id VARCHAR(255) PRIMARY KEY,
    unit_id VARCHAR(255) NOT NULL,
    tenant_id VARCHAR(255) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    status ENUM('paid', 'pending', 'overdue') DEFAULT 'pending',
    payment_date TIMESTAMP NULL,
    due_date TIMESTAMP NOT NULL,
    transaction_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (unit_id) REFERENCES units(id),
    FOREIGN KEY (tenant_id) REFERENCES users(id)
);

-- Maintenance Requests Table
CREATE TABLE maintenance_requests (
    id VARCHAR(255) PRIMARY KEY,
    unit_id VARCHAR(255) NOT NULL,
    tenant_id VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    status ENUM('open', 'in_progress', 'resolved', 'closed') DEFAULT 'open',
    photo_url VARCHAR(512),
    resolution_notes TEXT,
    cost DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (unit_id) REFERENCES units(id),
    FOREIGN KEY (tenant_id) REFERENCES users(id)
);

-- Digital Rent Agreements Table
CREATE TABLE agreements (
    id VARCHAR(255) PRIMARY KEY,
    unit_id VARCHAR(255) NOT NULL,
    tenant_id VARCHAR(255) NOT NULL,
    owner_id VARCHAR(255) NOT NULL,
    pdf_url VARCHAR(512) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status ENUM('active', 'expired', 'terminated') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (unit_id) REFERENCES units(id),
    FOREIGN KEY (tenant_id) REFERENCES users(id),
    FOREIGN KEY (owner_id) REFERENCES users(id)
);

-- Insertion triggers for structure (Optional logic helper)
