
-- SACCO Database Management System (MySQL 8.0+)
-- Author: John Muli
-- Purpose: Schema-only .sql with tables, constraints, and relationships
-- Notes:
--   * This file contains ONLY DDL (CREATE TABLE/INDEX/VIEW) as per assignment.

 CREATE DATABASE sacco_db CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
 USE sacco_db;


-- Global SQL modes for strictness (optional; set at session level)

 SET SESSION sql_require_primary_key = 1;
 SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';


-- Reference tables


CREATE TABLE branches (
    branch_id       BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    code            VARCHAR(10) NOT NULL UNIQUE,
    name            VARCHAR(100) NOT NULL,
    county          VARCHAR(100) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    address_line1   VARCHAR(200),
    phone           VARCHAR(20),
    email           VARCHAR(150),
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE roles (
    role_id     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(200)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE users (
    user_id         BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    branch_id       BIGINT UNSIGNED NOT NULL,
    username        VARCHAR(50) NOT NULL UNIQUE,
    email           VARCHAR(150) NOT NULL UNIQUE,
    password_hash   CHAR(60) NOT NULL, -- e.g., bcrypt/argon hash
    full_name       VARCHAR(150) NOT NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_branch
        FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE user_roles (
    user_id BIGINT UNSIGNED NOT NULL,
    role_id BIGINT UNSIGNED NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_user_roles_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_role
        FOREIGN KEY (role_id) REFERENCES roles(role_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Members & KYC


CREATE TABLE members (
    member_id       BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    member_no       VARCHAR(30) NOT NULL UNIQUE, -- SACCO-assigned number
    branch_id       BIGINT UNSIGNED NOT NULL,
    first_name      VARCHAR(80) NOT NULL,
    last_name       VARCHAR(80) NOT NULL,
    other_names     VARCHAR(120),
    national_id     VARCHAR(20) NOT NULL UNIQUE,
    krapin          VARCHAR(20) UNIQUE, -- Kenya KRA PIN (optional)
    dob             DATE,
    gender          ENUM('M','F','OTHER') NOT NULL DEFAULT 'OTHER',
    phone           VARCHAR(20) NOT NULL UNIQUE,
    email           VARCHAR(150) UNIQUE,
    address_line1   VARCHAR(200),
    city            VARCHAR(100),
    county          VARCHAR(100),
    employment_status ENUM('EMPLOYED','SELF_EMPLOYED','UNEMPLOYED','STUDENT','RETIRED') NOT NULL DEFAULT 'EMPLOYED',
    employer_name   VARCHAR(150),
    join_date       DATE NOT NULL,
    status          ENUM('ACTIVE','DORMANT','SUSPENDED','CLOSED') NOT NULL DEFAULT 'ACTIVE',
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_members_branch
        FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- 1:1 KYC Profile (separate to demonstrate a 1-1 relationship)


CREATE TABLE member_kyc (
    member_id           BIGINT UNSIGNED PRIMARY KEY,
    occupation          VARCHAR(150),
    source_of_funds     VARCHAR(150),
    risk_rating         ENUM('LOW','MEDIUM','HIGH') NOT NULL DEFAULT 'LOW',
    id_doc_type         ENUM('NATIONAL_ID','PASSPORT') NOT NULL DEFAULT 'NATIONAL_ID',
    id_doc_number       VARCHAR(30) NOT NULL,
    id_doc_expiry       DATE,
    pep_status          TINYINT(1) NOT NULL DEFAULT 0, -- Politically Exposed Person
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_kyc_member
        FOREIGN KEY (member_id) REFERENCES members(member_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- 1:M Contacts (e.g., next of kin)


CREATE TABLE member_contacts (
    contact_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    member_id       BIGINT UNSIGNED NOT NULL,
    name            VARCHAR(150) NOT NULL,
    relationship    VARCHAR(80) NOT NULL, -- e.g., Spouse, Parent, Next of Kin
    phone           VARCHAR(20),
    email           VARCHAR(150),
    address_line1   VARCHAR(200),
    city            VARCHAR(100),
    county          VARCHAR(100),
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_contacts_member
        FOREIGN KEY (member_id) REFERENCES members(member_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Products & Accounts


CREATE TABLE account_types (
    account_type_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    code            VARCHAR(20) NOT NULL UNIQUE,  -- e.g., SAV_REG, SER, FIXED
    name            VARCHAR(100) NOT NULL,
    min_open_balance DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    interest_accrual ENUM('NONE','DAILY','MONTHLY','QUARTERLY','ANNUALLY') NOT NULL DEFAULT 'MONTHLY',
    interest_rate_apy DECIMAL(5,2) NOT NULL DEFAULT 0.00 CHECK (interest_rate_apy >= 0.00),
    allow_withdrawals TINYINT(1) NOT NULL DEFAULT 1,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE accounts (
    account_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    member_id       BIGINT UNSIGNED NOT NULL,
    branch_id       BIGINT UNSIGNED NOT NULL,
    account_type_id BIGINT UNSIGNED NOT NULL,
    account_number  VARCHAR(30) NOT NULL UNIQUE,
    opened_on       DATE NOT NULL,
    status          ENUM('ACTIVE','FROZEN','CLOSED') NOT NULL DEFAULT 'ACTIVE',
    current_balance DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_accounts_member
        FOREIGN KEY (member_id) REFERENCES members(member_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_accounts_branch
        FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_accounts_type
        FOREIGN KEY (account_type_id) REFERENCES account_types(account_type_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Monetary transactions for accounts (ledger)


CREATE TABLE account_transactions (
    txn_id          BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    account_id      BIGINT UNSIGNED NOT NULL,
    txn_time        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    txn_type        ENUM('DEPOSIT','WITHDRAWAL','TRANSFER_IN','TRANSFER_OUT','INTEREST','FEE','ADJUSTMENT') NOT NULL,
    amount          DECIMAL(18,2) NOT NULL CHECK (amount >= 0.00),
    running_balance DECIMAL(18,2) NOT NULL,
    currency        CHAR(3) NOT NULL DEFAULT 'KES',
    description     VARCHAR(255),
    external_ref    VARCHAR(100), -- e.g., Mpesa reference
    created_by      BIGINT UNSIGNED, -- users.user_id (nullable for system)
    CONSTRAINT fk_txn_account
        FOREIGN KEY (account_id) REFERENCES accounts(account_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_txn_user
        FOREIGN KEY (created_by) REFERENCES users(user_id)
        ON UPDATE SET NULL ON DELETE SET NULL,
    INDEX idx_txn_account_time(account_id, txn_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Shares & Contributions



CREATE TABLE share_products (
    share_product_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    code             VARCHAR(20) NOT NULL UNIQUE, -- e.g., ORD_SHR
    name             VARCHAR(100) NOT NULL,
    min_shares       INT UNSIGNED NOT NULL DEFAULT 0,
    par_value        DECIMAL(18,2) NOT NULL DEFAULT 100.00,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE member_shares (
    member_share_id  BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    member_id        BIGINT UNSIGNED NOT NULL,
    share_product_id BIGINT UNSIGNED NOT NULL,
    units_outstanding INT UNSIGNED NOT NULL DEFAULT 0,
    total_cost       DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    UNIQUE KEY uq_member_share(member_id, share_product_id),
    CONSTRAINT fk_mshares_member
        FOREIGN KEY (member_id) REFERENCES members(member_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_mshares_product
        FOREIGN KEY (share_product_id) REFERENCES share_products(share_product_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE share_transactions (
    share_txn_id     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    member_share_id  BIGINT UNSIGNED NOT NULL,
    txn_time         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    txn_type         ENUM('BUY','SELL','DIVIDEND') NOT NULL,
    units            INT UNSIGNED NOT NULL DEFAULT 0,
    amount           DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    description      VARCHAR(255),
    created_by       BIGINT UNSIGNED,
    CONSTRAINT fk_share_txn_ms
        FOREIGN KEY (member_share_id) REFERENCES member_shares(member_share_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_share_txn_user
        FOREIGN KEY (created_by) REFERENCES users(user_id)
        ON UPDATE SET NULL ON DELETE SET NULL,
    INDEX idx_share_txn_ms_time(member_share_id, txn_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



-- Loan Management



CREATE TABLE loan_products (
    loan_product_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    code            VARCHAR(20) NOT NULL UNIQUE,  -- e.g., DEV_LN, EMERG_LN
    name            VARCHAR(100) NOT NULL,
    interest_method ENUM('FLAT','REDUCING_BALANCE') NOT NULL DEFAULT 'REDUCING_BALANCE',
    interest_rate_pa DECIMAL(6,3) NOT NULL CHECK (interest_rate_pa >= 0.0), -- percent per annum
    default_term_months INT UNSIGNED NOT NULL,
    max_amount      DECIMAL(18,2) NOT NULL,
    min_amount      DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    requires_guarantors TINYINT(1) NOT NULL DEFAULT 1,
    max_guarantor_exposure_pct DECIMAL(5,2) NOT NULL DEFAULT 100.00 CHECK (max_guarantor_exposure_pct >= 0),
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE loans (
    loan_id         BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    loan_number     VARCHAR(30) NOT NULL UNIQUE,
    member_id       BIGINT UNSIGNED NOT NULL,
    loan_product_id BIGINT UNSIGNED NOT NULL,
    principal       DECIMAL(18,2) NOT NULL CHECK (principal > 0),
    interest_rate_pa DECIMAL(6,3) NOT NULL CHECK (interest_rate_pa >= 0.0),
    term_months     INT UNSIGNED NOT NULL,
    disbursed_on    DATE,
    status          ENUM('PENDING','APPROVED','DISBURSED','IN_ARREARS','CLOSED','REJECTED') NOT NULL DEFAULT 'PENDING',
    purpose         VARCHAR(200),
    created_by      BIGINT UNSIGNED,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_loans_member
        FOREIGN KEY (member_id) REFERENCES members(member_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_loans_product
        FOREIGN KEY (loan_product_id) REFERENCES loan_products(loan_product_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_loans_user
        FOREIGN KEY (created_by) REFERENCES users(user_id)
        ON UPDATE SET NULL ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- M:M Guarantors

CREATE TABLE loan_guarantors (
    loan_id     BIGINT UNSIGNED NOT NULL,
    guarantor_member_id BIGINT UNSIGNED NOT NULL,
    guaranteed_amount DECIMAL(18,2) NOT NULL CHECK (guaranteed_amount >= 0.00),
    PRIMARY KEY (loan_id, guarantor_member_id),
    CONSTRAINT fk_lg_loan
        FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_lg_member
        FOREIGN KEY (guarantor_member_id) REFERENCES members(member_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Collateral (1:M from loan)

CREATE TABLE loan_collateral (
    collateral_id   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    loan_id         BIGINT UNSIGNED NOT NULL,
    type            VARCHAR(80) NOT NULL, -- e.g., Title Deed, Motor Logbook
    description     VARCHAR(255),
    estimated_value DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    document_ref    VARCHAR(100),
    CONSTRAINT fk_collateral_loan
        FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Repayment schedule (1:M from loan)

CREATE TABLE loan_schedules (
    schedule_id     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    loan_id         BIGINT UNSIGNED NOT NULL,
    installment_no  INT UNSIGNED NOT NULL,
    due_date        DATE NOT NULL,
    principal_due   DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    interest_due    DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    fees_due        DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    principal_paid  DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    interest_paid   DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    fees_paid       DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    status          ENUM('DUE','PARTIAL','PAID','OVERDUE') NOT NULL DEFAULT 'DUE',
    UNIQUE KEY uq_loan_installment (loan_id, installment_no),
    CONSTRAINT fk_schedule_loan
        FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Repayments (can also mirror in account_transactions if loan is linked to account)

CREATE TABLE loan_payments (
    payment_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    loan_id         BIGINT UNSIGNED NOT NULL,
    paid_on         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount          DECIMAL(18,2) NOT NULL CHECK (amount > 0.00),
    allocation_principal DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    allocation_interest  DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    allocation_fees      DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    method          ENUM('CASH','MPESA','CHEQUE','BANK_TRANSFER','INTERNAL_TRANSFER') NOT NULL,
    reference_no    VARCHAR(100),
    received_by     BIGINT UNSIGNED,
    CONSTRAINT fk_payment_loan
        FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_payment_user
        FOREIGN KEY (received_by) REFERENCES users(user_id)
        ON UPDATE SET NULL ON DELETE SET NULL,
    INDEX idx_payment_loan_time(loan_id, paid_on)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Fees & Charges (configurable)


CREATE TABLE fee_types (
    fee_type_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    code        VARCHAR(20) NOT NULL UNIQUE, -- e.g., ACC_OPEN, ATM_FEE, LOAN_APP
    name        VARCHAR(100) NOT NULL,
    applies_to  ENUM('ACCOUNT','LOAN','MEMBERSHIP') NOT NULL,
    amount      DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    is_percentage TINYINT(1) NOT NULL DEFAULT 0, -- if 1, 'amount' is a percent (0-100)
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE applied_fees (
    applied_fee_id  BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    fee_type_id     BIGINT UNSIGNED NOT NULL,
    member_id       BIGINT UNSIGNED,
    account_id      BIGINT UNSIGNED,
    loan_id         BIGINT UNSIGNED,
    applied_on      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    base_amount     DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    fee_amount      DECIMAL(18,2) NOT NULL,
    description     VARCHAR(255),
    CONSTRAINT fk_applied_fee_type
        FOREIGN KEY (fee_type_id) REFERENCES fee_types(fee_type_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_applied_fee_member
        FOREIGN KEY (member_id) REFERENCES members(member_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_applied_fee_account
        FOREIGN KEY (account_id) REFERENCES accounts(account_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_applied_fee_loan
        FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Simple Accounting (General Ledger)


CREATE TABLE coa_accounts (
    coa_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    code        VARCHAR(20) NOT NULL UNIQUE,
    name        VARCHAR(150) NOT NULL,
    type        ENUM('ASSET','LIABILITY','EQUITY','INCOME','EXPENSE') NOT NULL,
    parent_id   BIGINT UNSIGNED,
    is_postable TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_coa_parent
        FOREIGN KEY (parent_id) REFERENCES coa_accounts(coa_id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE journal_entries (
    journal_id  BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    entry_time  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    memo        VARCHAR(255),
    created_by  BIGINT UNSIGNED,
    CONSTRAINT fk_journal_user
        FOREIGN KEY (created_by) REFERENCES users(user_id)
        ON UPDATE SET NULL ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE journal_lines (
    journal_line_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    journal_id      BIGINT UNSIGNED NOT NULL,
    coa_id          BIGINT UNSIGNED NOT NULL,
    debit           DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (debit >= 0),
    credit          DECIMAL(18,2) NOT NULL DEFAULT 0.00 CHECK (credit >= 0),
    description     VARCHAR(255),
    CONSTRAINT fk_jline_journal
        FOREIGN KEY (journal_id) REFERENCES journal_entries(journal_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_jline_coa
        FOREIGN KEY (coa_id) REFERENCES coa_accounts(coa_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_debit_credit CHECK (
        (debit = 0 AND credit > 0) OR (credit = 0 AND debit > 0)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Audit & Ops


CREATE TABLE audit_logs (
    audit_id    BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    occurred_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actor_user  BIGINT UNSIGNED,
    action      VARCHAR(50) NOT NULL, -- e.g., CREATE_MEMBER, UPDATE_ACCOUNT
    entity_name VARCHAR(50) NOT NULL, -- e.g., members, accounts
    entity_id   BIGINT UNSIGNED,
    details     JSON,
    CONSTRAINT fk_audit_user
        FOREIGN KEY (actor_user) REFERENCES users(user_id)
        ON UPDATE SET NULL ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Helpful Views (read-only convenience)


CREATE OR REPLACE VIEW v_member_core AS
SELECT
    m.member_id, m.member_no, m.first_name, m.last_name, m.phone, m.email, m.status,
    b.name AS branch_name,
    k.risk_rating, k.pep_status
FROM members m
JOIN branches b ON b.branch_id = m.branch_id
LEFT JOIN member_kyc k ON k.member_id = m.member_id;

CREATE OR REPLACE VIEW v_account_balances AS
SELECT
    a.account_id, a.account_number, atp.name AS account_type, a.current_balance, a.status,
    m.member_no, CONCAT(m.first_name, ' ', m.last_name) AS member_name
FROM accounts a
JOIN account_types atp ON atp.account_type_id = a.account_type_id
JOIN members m ON m.member_id = a.member_id;

CREATE OR REPLACE VIEW v_loan_status AS
SELECT
    l.loan_id, l.loan_number, l.status, l.principal, l.interest_rate_pa, l.term_months,
    m.member_no, CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    lp.name AS product_name
FROM loans l
JOIN members m ON m.member_id = l.member_id
JOIN loan_products lp ON lp.loan_product_id = l.loan_product_id;


-- Indexing notes (beyond FK auto-indexing)



CREATE INDEX idx_members_name ON members(last_name, first_name);
CREATE INDEX idx_accounts_member ON accounts(member_id);
CREATE INDEX idx_loans_member ON loans(member_id);
CREATE INDEX idx_loans_status ON loans(status);
CREATE INDEX idx_txn_time ON account_transactions(txn_time);
CREATE INDEX idx_journal_time ON journal_entries(entry_time);

-- End of schema
