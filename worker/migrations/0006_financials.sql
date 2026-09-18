-- Migration 0006: Financials & Invoicing

ALTER TABLE projects ADD COLUMN total_value REAL NULL;

CREATE TABLE invoices (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    invoice_number TEXT UNIQUE NOT NULL,
    amount REAL NOT NULL,
    currency TEXT DEFAULT 'INR' NOT NULL,
    status TEXT NOT NULL,
    due_date DATETIME NOT NULL,
    created_at DATETIME NOT NULL,
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

CREATE TABLE payments (
    id TEXT PRIMARY KEY,
    invoice_id TEXT NOT NULL,
    amount REAL NOT NULL,
    payment_method TEXT NOT NULL,
    processed_at DATETIME NOT NULL,
    recorded_by TEXT NOT NULL,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id),
    FOREIGN KEY (recorded_by) REFERENCES users(id)
);

CREATE INDEX idx_invoices_project_id ON invoices(project_id);
CREATE INDEX idx_payments_invoice_id ON payments(invoice_id);
