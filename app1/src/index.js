const express = require("express");
const axios = require("axios");

const app = express();
const port = process.env.PORT || 8080;
const BACKEND_URL = process.env.BACKEND_API_URL || "http://localhost:3001";

app. get("/health", function(req, res) {
  res.json({ 
    status: "healthy", 
    app: "app1-frontend", 
    timestamp: new Date().toISOString() 
  });
});

app.get("/", function(req, res) {
  res.json({ 
    message: "Welcome to App1 - GM Frontend", 
    version: "1.0.0"
  });
});

app.get("/api/backend-health", async function(req, res) {
  try {
    const response = await axios.get(BACKEND_URL + "/health", { timeout:  10000 });
    res.json({ 
      status: "healthy", 
      backend:  response.data, 
      connectivity: "success" 
    });
  } catch (error) {
    res.status(503).json({ 
      status: "unhealthy", 
      error: error.message, 
      connectivity: "failed" 
    });
  }
});

app.get("/api/data", async function(req, res) {
  try {
    const response = await axios.get(BACKEND_URL + "/api/data", { timeout: 10000 });
    res.json({ 
      source: "app1-frontend", 
      backendData: response.data
    });
  } catch (error) {
    res.status(503).json({ 
      error: "Failed to fetch data from backend"
    });
  }
});

app.listen(port, function() {
  console.log("App1 Frontend running on port " + port);
});

module.exports = app;