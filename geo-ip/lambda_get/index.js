const { createClient } = require('redis');
const mysql = require('mysql2/promise');

let redisClient = null;

async function getRedisClient() {
  if (!redisClient) {
    redisClient = createClient({
      socket: {
        host: process.env.REDIS_HOST,
        port: process.env.REDIS_PORT || 6379
      },
      password: process.env.REDIS_PASSWORD
    });
    
    redisClient.on('error', (err) => console.error('Redis Client Error', err));
    await redisClient.connect();
  }
  return redisClient;
}

async function getRDSConnection() {
  return await mysql.createConnection({
    host: process.env.RDS_HOST,
    user: process.env.RDS_USER,
    password: process.env.RDS_PASSWORD,
    database: process.env.RDS_DATABASE
  });
}

exports.handler = async (event) => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, OPTIONS'
  };

  // Handle OPTIONS request for CORS
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: ''
    };
  }

  try {
    const redis = await getRedisClient();
    const cacheKey = 'geo_ip_leaderboard';
    
    // Try to get from Redis cache first
    const cached = await redis.get(cacheKey);
    
    if (cached) {
      console.log('Cache hit - returning from Redis');
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          leaderboard: JSON.parse(cached),
          source: 'cache'
        })
      };
    }
    
    console.log('Cache miss - fetching from RDS');
    
    // If not in cache, fetch from RDS
    const connection = await getRDSConnection();
    
    try {
      const [rows] = await connection.execute(
        `SELECT ip, country, city, visits, last_seen as lastSeen, latitude as lat, longitude as lon
         FROM ip_tracking
         ORDER BY visits DESC
         LIMIT 100`
      );
      
      // Cache the result for 30 seconds
      await redis.setEx(cacheKey, 30, JSON.stringify(rows));
      
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          leaderboard: rows,
          source: 'database'
        })
      };
    } finally {
      await connection.end();
    }
    
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: 'Failed to fetch leaderboard',
        message: error.message
      })
    };
  }
};
