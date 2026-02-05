-- =====================================================
-- Child Care Center Management System (CCMS)
-- MySQL Database Schema
-- Version: 1.0
-- Date: February 2026
-- =====================================================

-- Create database
CREATE DATABASE IF NOT EXISTS ccms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ccms;

-- =====================================================
-- Table: centers
-- Description: Child care centers (tenant boundary)
-- =====================================================
CREATE TABLE centers (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    opening_time TIME DEFAULT '07:00:00',
    closing_time TIME DEFAULT '18:00:00',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    
    INDEX idx_centers_active (is_active),
    INDEX idx_centers_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Table: users
-- Description: System users with authentication
-- =====================================================
CREATE TABLE users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    role ENUM('superadmin', 'center_admin') NOT NULL DEFAULT 'center_admin',
    center_id INT UNSIGNED,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    
    FOREIGN KEY (center_id) REFERENCES centers(id) ON DELETE SET NULL,
    INDEX idx_users_email (email),
    INDEX idx_users_role (role),
    INDEX idx_users_center (center_id),
    INDEX idx_users_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Table: children
-- Description: Child enrollment records
-- =====================================================
CREATE TABLE children (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    center_id INT UNSIGNED NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    enrollment_date DATE NOT NULL,
    payment_plan ENUM('hourly', 'daily', 'monthly') NOT NULL DEFAULT 'monthly',
    rate DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    
    FOREIGN KEY (center_id) REFERENCES centers(id) ON DELETE CASCADE,
    INDEX idx_children_center (center_id),
    INDEX idx_children_active (is_active),
    INDEX idx_children_name (last_name, first_name),
    INDEX idx_children_enrollment (enrollment_date),
    INDEX idx_children_payment_plan (payment_plan)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Table: attendance
-- Description: Daily attendance records
-- =====================================================
CREATE TABLE attendance (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    child_id INT UNSIGNED NOT NULL,
    date DATE NOT NULL,
    check_in TIME,
    check_out TIME,
    total_hours DECIMAL(5, 2) GENERATED ALWAYS AS (
        CASE 
            WHEN check_in IS NOT NULL AND check_out IS NOT NULL 
            THEN ROUND(TIME_TO_SEC(TIMEDIFF(check_out, check_in)) / 3600, 2)
            ELSE NULL 
        END
    ) STORED,
    status ENUM('present', 'absent', 'late') NOT NULL DEFAULT 'present',
    notes TEXT,
    created_by INT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (child_id) REFERENCES children(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY unique_attendance_child_date (child_id, date),
    INDEX idx_attendance_child (child_id),
    INDEX idx_attendance_date (date),
    INDEX idx_attendance_status (status),
    INDEX idx_attendance_child_date (child_id, date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Table: payments
-- Description: Payment records and billing
-- =====================================================
CREATE TABLE payments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    child_id INT UNSIGNED NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    status ENUM('pending', 'paid', 'overdue') NOT NULL DEFAULT 'pending',
    paid_at TIMESTAMP NULL,
    paid_by INT UNSIGNED,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (child_id) REFERENCES children(id) ON DELETE CASCADE,
    FOREIGN KEY (paid_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_payments_child (child_id),
    INDEX idx_payments_status (status),
    INDEX idx_payments_period (period_start, period_end),
    INDEX idx_payments_child_period (child_id, period_start, period_end)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Table: logs
-- Description: Audit trail for all system activities
-- =====================================================
CREATE TABLE logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED,
    center_id INT UNSIGNED,
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INT UNSIGNED,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (center_id) REFERENCES centers(id) ON DELETE SET NULL,
    INDEX idx_logs_user (user_id),
    INDEX idx_logs_center (center_id),
    INDEX idx_logs_action (action),
    INDEX idx_logs_entity (entity_type, entity_id),
    INDEX idx_logs_created (created_at),
    INDEX idx_logs_center_created (center_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Views for Reporting
-- =====================================================

-- View: Active children with center info
CREATE VIEW v_active_children AS
SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.date_of_birth,
    c.enrollment_date,
    c.payment_plan,
    c.rate,
    ctr.name AS center_name,
    ctr.id AS center_id
FROM children c
JOIN centers ctr ON c.center_id = ctr.id
WHERE c.is_active = TRUE AND c.deleted_at IS NULL;

-- View: Daily attendance summary
CREATE VIEW v_daily_attendance AS
SELECT 
    a.id,
    a.date,
    a.check_in,
    a.check_out,
    a.total_hours,
    a.status,
    CONCAT(c.first_name, ' ', c.last_name) AS child_name,
    c.id AS child_id,
    ctr.id AS center_id,
    ctr.name AS center_name
FROM attendance a
JOIN children c ON a.child_id = c.id
JOIN centers ctr ON c.center_id = ctr.id;

-- View: Payment summary with child info
CREATE VIEW v_payment_summary AS
SELECT 
    p.id,
    p.period_start,
    p.period_end,
    p.amount,
    p.status,
    p.paid_at,
    CONCAT(c.first_name, ' ', c.last_name) AS child_name,
    c.id AS child_id,
    c.payment_plan,
    ctr.id AS center_id,
    ctr.name AS center_name
FROM payments p
JOIN children c ON p.child_id = c.id
JOIN centers ctr ON c.center_id = ctr.id;

-- View: Outstanding payments
CREATE VIEW v_outstanding_payments AS
SELECT 
    p.*,
    CONCAT(c.first_name, ' ', c.last_name) AS child_name,
    c.payment_plan,
    ctr.id AS center_id,
    ctr.name AS center_name
FROM payments p
JOIN children c ON p.child_id = c.id
JOIN centers ctr ON c.center_id = ctr.id
WHERE p.status IN ('pending', 'overdue');

-- =====================================================
-- Stored Procedures
-- =====================================================

DELIMITER //

-- Procedure: Calculate payment for a child based on attendance
CREATE PROCEDURE sp_calculate_child_payment(
    IN p_child_id INT UNSIGNED,
    IN p_period_start DATE,
    IN p_period_end DATE
)
BEGIN
    DECLARE v_payment_plan VARCHAR(10);
    DECLARE v_rate DECIMAL(10, 2);
    DECLARE v_total_amount DECIMAL(10, 2) DEFAULT 0;
    
    -- Get child's payment plan and rate
    SELECT payment_plan, rate INTO v_payment_plan, v_rate
    FROM children WHERE id = p_child_id;
    
    -- Calculate based on payment plan
    CASE v_payment_plan
        WHEN 'hourly' THEN
            SELECT COALESCE(SUM(total_hours * v_rate), 0) INTO v_total_amount
            FROM attendance
            WHERE child_id = p_child_id 
            AND date BETWEEN p_period_start AND p_period_end
            AND status = 'present';
        WHEN 'daily' THEN
            SELECT COALESCE(COUNT(*) * v_rate, 0) INTO v_total_amount
            FROM attendance
            WHERE child_id = p_child_id 
            AND date BETWEEN p_period_start AND p_period_end
            AND status = 'present';
        WHEN 'monthly' THEN
            SET v_total_amount = v_rate;
    END CASE;
    
    SELECT v_total_amount AS calculated_amount;
END //

-- Procedure: Generate payments for all active children in a center
CREATE PROCEDURE sp_generate_center_payments(
    IN p_center_id INT UNSIGNED,
    IN p_period_start DATE,
    IN p_period_end DATE
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_child_id INT UNSIGNED;
    DECLARE v_amount DECIMAL(10, 2);
    
    DECLARE child_cursor CURSOR FOR
        SELECT id FROM children 
        WHERE center_id = p_center_id AND is_active = TRUE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN child_cursor;
    read_loop: LOOP
        FETCH child_cursor INTO v_child_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Calculate payment
        CALL sp_calculate_child_payment(v_child_id, p_period_start, p_period_end);
        SELECT calculated_amount INTO v_amount;
        
        -- Insert or update payment record
        INSERT INTO payments (child_id, period_start, period_end, amount, status)
        VALUES (v_child_id, p_period_start, p_period_end, v_amount, 'pending')
        ON DUPLICATE KEY UPDATE amount = v_amount;
    END LOOP;
    CLOSE child_cursor;
END //

-- Procedure: Get attendance report for a center
CREATE PROCEDURE sp_get_attendance_report(
    IN p_center_id INT UNSIGNED,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT 
        a.date,
        COUNT(DISTINCT CASE WHEN a.status = 'present' THEN a.child_id END) AS present_count,
        COUNT(DISTINCT CASE WHEN a.status = 'absent' THEN a.child_id END) AS absent_count,
        COUNT(DISTINCT CASE WHEN a.status = 'late' THEN a.child_id END) AS late_count,
        COALESCE(SUM(a.total_hours), 0) AS total_hours
    FROM attendance a
    JOIN children c ON a.child_id = c.id
    WHERE c.center_id = p_center_id
    AND a.date BETWEEN p_start_date AND p_end_date
    GROUP BY a.date
    ORDER BY a.date;
END //

-- Procedure: Get financial report for a center
CREATE PROCEDURE sp_get_financial_report(
    IN p_center_id INT UNSIGNED,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT 
        COALESCE(SUM(CASE WHEN p.status = 'paid' THEN p.amount END), 0) AS total_paid,
        COALESCE(SUM(CASE WHEN p.status = 'pending' THEN p.amount END), 0) AS total_pending,
        COALESCE(SUM(CASE WHEN p.status = 'overdue' THEN p.amount END), 0) AS total_overdue,
        COALESCE(SUM(p.amount), 0) AS total_expected
    FROM payments p
    JOIN children c ON p.child_id = c.id
    WHERE c.center_id = p_center_id
    AND p.period_start >= p_start_date
    AND p.period_end <= p_end_date;
END //

DELIMITER ;

-- =====================================================
-- Triggers for Audit Logging
-- =====================================================

DELIMITER //

-- Trigger: Log child updates
CREATE TRIGGER trg_children_audit_update
AFTER UPDATE ON children
FOR EACH ROW
BEGIN
    INSERT INTO logs (user_id, center_id, action, entity_type, entity_id, old_values, new_values)
    VALUES (
        @current_user_id,
        OLD.center_id,
        'UPDATE',
        'children',
        OLD.id,
        JSON_OBJECT(
            'first_name', OLD.first_name,
            'last_name', OLD.last_name,
            'payment_plan', OLD.payment_plan,
            'rate', OLD.rate,
            'is_active', OLD.is_active
        ),
        JSON_OBJECT(
            'first_name', NEW.first_name,
            'last_name', NEW.last_name,
            'payment_plan', NEW.payment_plan,
            'rate', NEW.rate,
            'is_active', NEW.is_active
        )
    );
END //

-- Trigger: Log attendance updates
CREATE TRIGGER trg_attendance_audit_update
AFTER UPDATE ON attendance
FOR EACH ROW
BEGIN
    DECLARE v_center_id INT UNSIGNED;
    SELECT center_id INTO v_center_id FROM children WHERE id = OLD.child_id;
    
    INSERT INTO logs (user_id, center_id, action, entity_type, entity_id, old_values, new_values)
    VALUES (
        @current_user_id,
        v_center_id,
        'UPDATE',
        'attendance',
        OLD.id,
        JSON_OBJECT(
            'check_in', OLD.check_in,
            'check_out', OLD.check_out,
            'status', OLD.status
        ),
        JSON_OBJECT(
            'check_in', NEW.check_in,
            'check_out', NEW.check_out,
            'status', NEW.status
        )
    );
END //

-- Trigger: Log payment updates
CREATE TRIGGER trg_payments_audit_update
AFTER UPDATE ON payments
FOR EACH ROW
BEGIN
    DECLARE v_center_id INT UNSIGNED;
    SELECT center_id INTO v_center_id FROM children WHERE id = OLD.child_id;
    
    INSERT INTO logs (user_id, center_id, action, entity_type, entity_id, old_values, new_values)
    VALUES (
        @current_user_id,
        v_center_id,
        'UPDATE',
        'payments',
        OLD.id,
        JSON_OBJECT(
            'amount', OLD.amount,
            'status', OLD.status,
            'paid_at', OLD.paid_at
        ),
        JSON_OBJECT(
            'amount', NEW.amount,
            'status', NEW.status,
            'paid_at', NEW.paid_at
        )
    );
END //

DELIMITER ;

-- =====================================================
-- Seed Data (Optional - for development)
-- =====================================================

-- Insert default SuperAdmin (password: 'admin123' - change in production!)
-- Password hash is for 'admin123' using BCrypt with cost 12
INSERT INTO users (email, password_hash, name, role, is_active) VALUES
('superadmin@ccms.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.VTtYA.qGZvKG6G', 'Super Administrator', 'superadmin', TRUE);

-- Insert sample centers
INSERT INTO centers (name, address, phone, email, opening_time, closing_time) VALUES
('Sunshine Daycare', '123 Main Street, Cityville', '555-0101', 'sunshine@ccms.com', '07:00:00', '18:00:00'),
('Happy Kids Center', '456 Oak Avenue, Townsburg', '555-0102', 'happykids@ccms.com', '06:30:00', '19:00:00'),
('Little Learners', '789 Pine Road, Villageton', '555-0103', 'learners@ccms.com', '07:30:00', '17:30:00');

-- Insert sample center admins (password: 'center123')
INSERT INTO users (email, password_hash, name, role, center_id, is_active) VALUES
('admin@sunshine.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.VTtYA.qGZvKG6G', 'Sunshine Admin', 'center_admin', 1, TRUE),
('admin@happykids.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.VTtYA.qGZvKG6G', 'HappyKids Admin', 'center_admin', 2, TRUE),
('admin@learners.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.VTtYA.qGZvKG6G', 'Learners Admin', 'center_admin', 3, TRUE);

-- Insert sample children
INSERT INTO children (center_id, first_name, last_name, date_of_birth, enrollment_date, payment_plan, rate) VALUES
(1, 'Emma', 'Johnson', '2020-03-15', '2024-01-10', 'monthly', 800.00),
(1, 'Liam', 'Smith', '2019-07-22', '2024-02-01', 'daily', 45.00),
(1, 'Olivia', 'Williams', '2021-01-08', '2024-03-15', 'hourly', 8.50),
(2, 'Noah', 'Brown', '2020-11-30', '2024-01-20', 'monthly', 750.00),
(2, 'Ava', 'Davis', '2019-05-14', '2024-02-10', 'daily', 40.00),
(3, 'Ethan', 'Miller', '2021-04-25', '2024-03-01', 'monthly', 700.00);

-- =====================================================
-- End of Schema
-- =====================================================
