-- schema.sql
-- D1 database schema for Archidraft

DROP TABLE IF EXISTS activity_logs;
DROP TABLE IF EXISTS assignments;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    mobile TEXT NOT NULL,
    role TEXT NOT NULL CHECK(role IN ('CLIENT', 'STUDIO_ADMIN', 'DRAUGHTSMAN')),
    qualification TEXT,
    dateOfBirth TEXT,
    address TEXT,
    companyName TEXT,
    collegeName TEXT,
    proofDocument TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE projects (
    id TEXT PRIMARY KEY,
    clientId TEXT NOT NULL,
    status TEXT NOT NULL CHECK(status IN (
        'DRAFT', 
        'SUBMITTED', 
        'WAITING_ASSIGNMENT', 
        'WAITING_ACCEPTANCE', 
        'IN_PROGRESS', 
        'UNDER_CLIENT_REVIEW', 
        'COMPLETED', 
        'CANCELLED'
    )),
    projectName TEXT,
    projectAddress TEXT,
    drawingName TEXT,
    drawingType TEXT,
    projectArea REAL,
    correctionRound INTEGER DEFAULT 0,
    lastActionId TEXT,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    submittedAt DATETIME,
    approvedAt DATETIME,
    approvedBy TEXT,
    cancelledAt DATETIME,
    FOREIGN KEY (clientId) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE assignments (
    id TEXT PRIMARY KEY,
    projectId TEXT NOT NULL,
    draughtsmanId TEXT NOT NULL,
    status TEXT NOT NULL CHECK(status IN (
        'PENDING',
        'ACCEPTED',
        'REJECTED',
        'REPLACED',
        'COMPLETED'
    )),
    assignedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    assignedBy TEXT,
    acceptedAt DATETIME,
    rejectedAt DATETIME,
    FOREIGN KEY (projectId) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (draughtsmanId) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE activity_logs (
    id TEXT PRIMARY KEY, -- actionId from client acts as idempotency key
    projectId TEXT NOT NULL,
    actionType TEXT NOT NULL,
    actorId TEXT NOT NULL,
    actorRole TEXT NOT NULL,
    details TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (projectId) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (actorId) REFERENCES users(id) ON DELETE CASCADE
);
