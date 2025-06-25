
-- Use or create the database
DROP DATABASE IF EXISTS gift_card_system;
CREATE DATABASE gift_card_system;
USE gift_card_system;

-- USERS TABLE
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

-- GIFT CARDS TABLE
CREATE TABLE gift_cards (
    card_id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    initial_balance DECIMAL(10,2) NOT NULL,
    current_balance DECIMAL(10,2) NOT NULL,
    expiration_date DATE NOT NULL,
    status ENUM('active', 'inactive', 'blocked', 'expired') DEFAULT 'active',
    assigned_user_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (assigned_user_id) REFERENCES users(user_id)
);

-- TRANSACTIONS TABLE
CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    card_id INT NOT NULL,
    type ENUM('redeem', 'recharge') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description VARCHAR(255),
    FOREIGN KEY (card_id) REFERENCES gift_cards(card_id)
);

-- CARD TRANSFERS TABLE
CREATE TABLE card_transfers (
    transfer_id INT AUTO_INCREMENT PRIMARY KEY,
    card_id INT NOT NULL,
    from_user_id INT,
    to_user_id INT,
    transfer_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (card_id) REFERENCES gift_cards(card_id),
    FOREIGN KEY (from_user_id) REFERENCES users(user_id),
    FOREIGN KEY (to_user_id) REFERENCES users(user_id)
);

-- CARD STATUS LOGS TABLE
CREATE TABLE card_status_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    card_id INT NOT NULL,
    old_status ENUM('active', 'inactive', 'blocked', 'expired'),
    new_status ENUM('active', 'inactive', 'blocked', 'expired'),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (card_id) REFERENCES gift_cards(card_id)
);

-- INSERT SAMPLE USERS
INSERT INTO users (name, email) VALUES 
('Rajesh Kumar', 'rajesh.kumar@gmail.com'),
('Neha Sharma', 'neha.sharma@gmail.com');

-- INSERT SAMPLE GIFT CARDS
INSERT INTO gift_cards (code, initial_balance, current_balance, expiration_date, assigned_user_id) VALUES 
('GC123456', 1000, 1000, '2025-12-31', 1),
('GC654321', 500, 500, '2025-09-01', 2);

-- RECHARGE PROCEDURE
DELIMITER $$
CREATE PROCEDURE RechargeGiftCard(IN p_code VARCHAR(20), IN p_amount DECIMAL(10,2))
BEGIN
    DECLARE card_id INT;
    SELECT card_id INTO card_id FROM gift_cards WHERE code = p_code;
    UPDATE gift_cards SET current_balance = current_balance + p_amount WHERE card_id = card_id;
    INSERT INTO transactions(card_id, type, amount, description) 
    VALUES (card_id, 'recharge', p_amount, 'Recharge done');
END;
$$
DELIMITER ;

-- REDEEM PROCEDURE
DELIMITER $$
CREATE PROCEDURE RedeemGiftCard(IN p_code VARCHAR(20), IN p_amount DECIMAL(10,2))
BEGIN
    DECLARE card_id INT;
    DECLARE balance DECIMAL(10,2);
    DECLARE card_status VARCHAR(20);

    SELECT card_id, current_balance, status INTO card_id, balance, card_status
    FROM gift_cards WHERE code = p_code;

    IF card_status != 'active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Card is not active';
    ELSEIF balance < p_amount THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient balance';
    ELSE
        UPDATE gift_cards SET current_balance = current_balance - p_amount WHERE card_id = card_id;
        INSERT INTO transactions(card_id, type, amount, description) 
        VALUES (card_id, 'redeem', p_amount, 'Redemption done');
    END IF;
END;
$$
DELIMITER ;

-- TRANSFER PROCEDURE
DELIMITER $$
CREATE PROCEDURE TransferGiftCard(IN p_code VARCHAR(20), IN p_to_user INT)
BEGIN
    DECLARE card_id INT;
    DECLARE old_user INT;
    SELECT card_id, assigned_user_id INTO card_id, old_user FROM gift_cards WHERE code = p_code;
    UPDATE gift_cards SET assigned_user_id = p_to_user WHERE card_id = card_id;
    INSERT INTO card_transfers(card_id, from_user_id, to_user_id)
    VALUES (card_id, old_user, p_to_user);
END;
$$
DELIMITER ;

-- BULK GENERATE CARDS
DELIMITER $$
CREATE PROCEDURE BulkGenerateCards(IN p_count INT, IN p_balance DECIMAL(10,2), IN p_expiry DATE)
BEGIN
  DECLARE i INT DEFAULT 0;
  WHILE i < p_count DO
    INSERT INTO gift_cards (code, initial_balance, current_balance, expiration_date)
    VALUES (CONCAT('GC', FLOOR(RAND() * 1000000)), p_balance, p_balance, p_expiry);
    SET i = i + 1;
  END WHILE;
END;
$$
DELIMITER ;

-- AUTO-EXPIRE EVENT
SET GLOBAL event_scheduler = ON;
DELIMITER $$
CREATE EVENT expire_cards
ON SCHEDULE EVERY 1 DAY
DO
  UPDATE gift_cards
  SET status = 'expired'
  WHERE expiration_date < CURDATE() AND status != 'expired';
$$
DELIMITER ;

-- REPORTING VIEWS
CREATE VIEW active_cards AS SELECT * FROM gift_cards WHERE status = 'active';
CREATE VIEW expired_cards AS SELECT * FROM gift_cards WHERE status = 'expired';
CREATE VIEW total_redeemed_value AS
SELECT card_id, SUM(amount) AS redeemed_amount
FROM transactions
WHERE type = 'redeem'
GROUP BY card_id;
CREATE VIEW total_issued_cards AS SELECT COUNT(*) AS total_cards FROM gift_cards;

-- INDEXING
CREATE INDEX idx_code ON gift_cards(code);
CREATE INDEX idx_user_id ON gift_cards(assigned_user_id);
CREATE INDEX idx_card_id ON transactions(card_id);
-- Tables
SELECT * FROM gift_cards;
SELECT * FROM users;
SELECT * FROM transactions;
SELECT * FROM card_status_logs;

-- Views
SELECT * FROM active_cards;
SELECT * FROM expired_cards;
SELECT * FROM total_redeemed_value;
SELECT * FROM total_issued_cards;

-- Joins
SELECT g.code AS Gift_Card_Code, g.status, g.current_balance, u.name AS User_Name, u.email
FROM gift_cards g
LEFT JOIN users u ON g.assigned_user_id = u.user_id;

SELECT t.transaction_id, g.code AS Gift_Card_Code, t.transaction_type, t.amount, t.transaction_date
FROM transactions t
JOIN gift_cards g ON t.card_id = g.card_id
ORDER BY t.transaction_date DESC;

-- Extra
SELECT * FROM gift_cards WHERE assigned_user_id IS NULL;



