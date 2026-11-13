-- UiTM eProcurement Database Schema
-- Database: uitm_intern_db

CREATE DATABASE IF NOT EXISTS uitm_intern_db;
USE uitm_intern_db;

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS tenders;
DROP TABLE IF EXISTS invitation_vendors;
DROP TABLE IF EXISTS invitations;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS company_profiles;

-- 1. Company profiles table
CREATE TABLE company_profiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    registration_no VARCHAR(50) NOT NULL UNIQUE,
    category VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2. Users table for authentication
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL, -- Store hashed passwords in production
    company_id INT,
    role VARCHAR(20) DEFAULT 'supplier', -- 'supplier', 'admin', etc.
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES company_profiles(id) ON DELETE SET NULL
);

-- 3. Invitations table
CREATE TABLE invitations (
    id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    agency VARCHAR(255) NOT NULL,
    closing_date DATETIME,
    location VARCHAR(255),
    status ENUM('baru', 'aktif', 'tutup') DEFAULT 'baru',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Bridge Table: Invitation Vendors 
CREATE TABLE invitation_vendors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invitation_id VARCHAR(50) NOT NULL,
    company_id INT NOT NULL,
    eligibility_status ENUM('invited', 'viewed', 'submitted', 'declined') DEFAULT 'invited',
    invited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_invitation_company (invitation_id, company_id),
    FOREIGN KEY (invitation_id) REFERENCES invitations(id) ON DELETE CASCADE,
    FOREIGN KEY (company_id) REFERENCES company_profiles(id) ON DELETE CASCADE
);

-- 5. Tenders table
CREATE TABLE tenders (
    id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    invitation_id VARCHAR(50),
    company_id INT,
    submitted_date DATE,
    amount DECIMAL(15, 2) DEFAULT 0.00,
    status VARCHAR(50) DEFAULT 'Draf', -- 'Dihantar', 'Draf', 'Berjaya'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (invitation_id) REFERENCES invitations(id) ON DELETE SET NULL,
    FOREIGN KEY (company_id) REFERENCES company_profiles(id) ON DELETE SET NULL
);

-- 6. Orders table
CREATE TABLE orders (
    id VARCHAR(50) PRIMARY KEY,
    po_number VARCHAR(50) NOT NULL UNIQUE,
    tender_id VARCHAR(50),
    company_id INT,
    title VARCHAR(255) NOT NULL,
    agency VARCHAR(255) NOT NULL,
    quantity INT DEFAULT 0,
    amount DECIMAL(15, 2) DEFAULT 0.00,
    status VARCHAR(50) DEFAULT 'Pesanan baharu', -- 'Pesanan baharu', 'Diterima', 'Dihantar'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (tender_id) REFERENCES tenders(id) ON DELETE SET NULL,
    FOREIGN KEY (company_id) REFERENCES company_profiles(id) ON DELETE SET NULL
);

-- 7. Invoices table
CREATE TABLE invoices (
    id VARCHAR(50) PRIMARY KEY,
    invoice_no VARCHAR(50) NOT NULL UNIQUE,
    order_ref VARCHAR(50),
    date DATE,
    amount DECIMAL(15, 2) DEFAULT 0.00,
    status VARCHAR(50) DEFAULT 'Draf', -- 'Dihantar', 'Dibayar', 'Draf'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_ref) REFERENCES orders(id) ON DELETE SET NULL
);

-- 8. Notifications table
CREATE TABLE notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    time VARCHAR(50),
    unread BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================
-- SEED DATA
-- ============================================

-- Seed company profiles
INSERT INTO company_profiles (id, name, registration_no, category, email, phone, address) VALUES
(1, 'Pembekal Mantap Sdn. Bhd.', '201901234567 (1234567-A)', 'Bekalan pejabat & percetakan', 'penjual@contoh.com', '03-1234 5678', 'No. 12, Jalan Perindustrian 4,\n40000 Shah Alam, Selangor'),
(2, 'Maju Teknologi Enterprise', '202103098765 (003198765-M)', 'ICT & Perkakasan Komputer', 'sales@majutek.com.my', '03-5544 8899', 'No. 8, Seksyen 13,\n40100 Shah Alam, Selangor');

-- Seed users (password should be hashed in production)
INSERT INTO users (id, username, password, company_id, role) VALUES
(1, 'supplier1', 'password123', 1, 'supplier'),
(2, 'supplier2', 'password123', 2, 'supplier'),
(3, 'admin', 'admin123', NULL, 'admin');

-- Seed invitations
INSERT INTO invitations (id, title, agency, closing_date, location, status) VALUES
('INV-CONTOH-001', 'Bekalan kertas A4', 'UiTM Shah Alam', '2026-10-18 12:00:00', 'Shah Alam, Selangor', 'baru'),
('INV-CONTOH-002', 'Toner pencetak', 'UiTM Puncak Alam', '2026-10-22 17:00:00', 'Puncak Alam, Selangor', 'baru'),
('INV-CONTOH-003', 'Perabot bilik mesyuarat', 'UiTM Shah Alam', '2026-10-30 12:00:00', 'Shah Alam, Selangor', 'aktif'),
('INV-CONTOH-004', 'Perkhidmatan penyelenggaraan penyaman udara', 'UiTM Dengkil', '2026-10-05 00:00:00', 'Dengkil, Selangor', 'tutup');

-- Seed invitation vendors
INSERT INTO invitation_vendors (invitation_id, company_id, eligibility_status) VALUES
('INV-CONTOH-001', 1, 'submitted'),
('INV-CONTOH-002', 1, 'submitted'),
('INV-CONTOH-003', 1, 'viewed'),
('INV-CONTOH-004', 1, 'declined'),
('INV-CONTOH-001', 2, 'invited'),
('INV-CONTOH-003', 2, 'invited');

-- Seed tenders
INSERT INTO tenders (id, title, invitation_id, company_id, submitted_date, amount, status) VALUES
('TWR-CONTOH-011', 'Bekalan kertas A4', 'INV-CONTOH-001', 1, '2026-10-14', 2308.00, 'Dihantar'),
('TWR-CONTOH-010', 'Toner pencetak', 'INV-CONTOH-002', 1, '2026-10-10', 1800.00, 'Dihantar'),
('TWR-CONTOH-009', 'Perabot bilik mesyuarat', 'INV-CONTOH-003', 1, NULL, 0.00, 'Draf');

-- Seed orders
INSERT INTO orders (id, po_number, tender_id, company_id, title, agency, quantity, amount, status) VALUES
('PO-CONTOH-018', 'PO-CONTOH-018', 'TWR-CONTOH-010', 1, 'Toner pencetak', 'UiTM Puncak Alam', 6, 1800.00, 'Pesanan baharu'),
('PO-CONTOH-015', 'PO-CONTOH-015', 'TWR-CONTOH-011', 1, 'Bekalan kertas A4', 'UiTM Shah Alam', 50, 2308.00, 'Diterima');

-- Seed invoices
INSERT INTO invoices (id, invoice_no, order_ref, date, amount, status) VALUES
('INV-CONTOH-018', 'INV-CONTOH-018', 'PO-CONTOH-018', '2026-10-14', 1800.00, 'Dihantar'),
('INV-CONTOH-015', 'INV-CONTOH-015', 'PO-CONTOH-015', '2026-10-12', 2308.00, 'Dibayar');

-- Seed notifications
INSERT INTO notifications (user_id, title, body, time, unread) VALUES
(1, 'Pelawaan baharu diterima', 'Bekalan kertas A4 · UiTM Shah Alam', '2 jam lalu', TRUE),
(1, 'Tawaran anda telah dihantar', 'Toner pencetak · TWR-CONTOH-010', 'Semalam', TRUE),
(1, 'Pesanan tempatan baharu', 'Toner pencetak · PO-CONTOH-018', '2 hari lalu', FALSE),
(1, 'Invois telah dibayar', 'INV-CONTOH-015 · RM2,308.00', '3 hari lalu', FALSE),
(2, 'Pelawaan baharu diterima', 'Bekalan kertas A4 · UiTM Shah Alam', '1 jam lalu', TRUE);