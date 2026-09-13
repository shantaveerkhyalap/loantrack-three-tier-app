CREATE TABLE loans (
    id SERIAL PRIMARY KEY,
    borrower_name TEXT NOT NULL,
    loan_amount NUMERIC(14,2) NOT NULL,
    property_city TEXT,
    status TEXT NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO loans (borrower_name, loan_amount, property_city, status) VALUES
('Alice Smith', 250000.00, 'New York', 'APPROVED'),
('Bob Johnson', 150000.50, 'Los Angeles', 'PENDING'),
('Charlie Brown', 300000.00, 'Chicago', 'REJECTED'),
('Diana Prince', 450000.00, 'Washington D.C.', 'APPROVED'),
('Evan Wright', 100000.00, 'Austin', 'PENDING');
