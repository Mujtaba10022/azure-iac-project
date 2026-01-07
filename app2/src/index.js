const express = require('express');
const sql = require('mssql');
const helmet = require('helmet');
const { DefaultAzureCredential } = require('@azure/identity');
const { SecretClient } = require('@azure/keyvault-secrets');

const app = express();
const port = process.env. PORT || 8080;

// Security middleware
app.use(helmet());
app.use(express.json());

// SQL connection configuration
let sqlConfig = null;
let secretClient = null;

// Initialize Key Vault client
if (process. env.KEY_VAULT_NAME) {
  const credential = new DefaultAzureCredential();
  const vaultUrl = `https://${process.env.KEY_VAULT_NAME}.vault.azure.net`;
  secretClient = new SecretClient(vaultUrl, credential);
}

// Initialize SQL connection
async function initializeSqlConnection() {
  try {
    let connectionString = process.env.SQL_CONNECTION_STRING;
    
    // If connection string contains Key Vault reference, it's already resolved
    // by App Service.  Otherwise, fetch from Key Vault directly. 
    if (! connectionString && secretClient) {
      const secret = await secretClient.getSecret('sql-connection-string');
      connectionString = secret.value;
    }
    
    if (connectionString) {
      // Parse connection string for mssql config
      sqlConfig = {
        server: extractFromConnectionString(connectionString, 'Server'),
        database: extractFromConnectionString(connectionString, 'Database'),
        authentication: {
          type: 'azure-active-directory-msi-app-service'
        },
        options: {
          encrypt: true,
          trustServerCertificate: false
        }
      };
      
      console.log('SQL configuration initialized');
    }
  } catch (error) {
    console.error('Failed to initialize SQL connection:', error. message);
  }
}

function extractFromConnectionString(connString, key) {
  const regex = new RegExp(`${key}=([^;]+)`, 'i');
  const match = connString.match(regex);
  return match ? match[1]. replace('tcp:', '').split(',')[0] : null;
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    app: 'app2-backend',
    timestamp: new Date().toISOString()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to App2 - Backend API',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      data: '/api/data',
      dbStatus: '/api/db-status'
    }
  });
});

// Data endpoint
app.get('/api/data', (req, res) => {
  res.json({
    status: 'healthy',
    message: 'Data from backend API',
    data: {
      items: [
        { id: 1, name: 'Item 1', value: 100 },
        { id: 2, name: 'Item 2', value: 200 },
        { id: 3, name: 'Item 3', value: 300 }
      ],
      metadata: {
        totalCount: 3,
        source: 'app2-backend',
        timestamp: new Date().toISOString()
      }
    }
  });
});

// Database status endpoint
app.get('/api/db-status', async (req, res) => {
  try {
    if (!sqlConfig) {
      return res.status(503).json({
        status: 'not_configured',
        message: 'Database connection not configured'
      });
    }
    
    const pool = await sql.connect(sqlConfig);
    const result = await pool.request().query('SELECT 1 as connected');
    
    res.json({
      status: 'connected',
      database: sqlConfig.database,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Database connection failed:', error.message);
    res.status(503).json({
      status: 'disconnected',
      error: error.message
    });
  }
});

// POST endpoint for data operations
app.post('/api/data', (req, res) => {
  const { name, value } = req.body;
  
  if (!name || value === undefined) {
    return res.status(400).json({
      error: 'Missing required fields:  name and value'
    });
  }
  
  res.status(201).json({
    status: 'created',
    data: {
      id: Math.floor(Math.random() * 1000),
      name,
      value,
      createdAt: new Date().toISOString()
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
});

// Initialize and start server
async function startServer() {
  await initializeSqlConnection();
  
  app.listen(port, () => {
    console.log(`App2 (Backend) listening on port ${port}`);
  });
}

startServer();

module.exports = app;