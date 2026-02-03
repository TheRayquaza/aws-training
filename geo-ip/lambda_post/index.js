const { createClient } = require('redis');
const mysql = require('mysql2/promise');
const axios = require('axios');

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

async function getIPInfo(ip) {
  try {
    const token = process.env.IPINFO_TOKEN;
    const url = token 
      ? `https://ipinfo.io/${ip}?token=${token}`
      : `https://ipinfo.io/${ip}/json`;
    
    const response = await axios.get(url, { timeout: 3000 });
    const data = response.data;
    
    const [lat, lon] = (data.loc || '0,0').split(',').map(Number);
    
    return {
      country: data.country || 'XX',
      city: data.city || 'Unknown',
      latitude: lat,
      longitude: lon
    };
  } catch (error) {
    console.error('Error fetching IP info:', error.message);
    // Return default values if geolocation fails
    return {
      country: 'XX',
      city: 'Unknown',
      latitude: 0,
      longitude: 0
    };
  }
}

exports.handler = async (event) => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS'
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
    const body = JSON.parse(event.body || '{}');
    const { ip } = body;
    
    if (!ip) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'IP address is required' })
      };
    }

    // Validate IP format (basic validation)
    const ipRegex = /^(\d{1,3}\.){3}\d{1,3}$/;
    if (!ipRegex.test(ip)) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Invalid IP address format' })
      };
    }

    console.log(`Tracking IP: ${ip}`);

    // Get geolocation info for the IP
    const ipInfo = await getIPInfo(ip);
    
    // Update RDS database
    const connection = await getRDSConnection();
    
    try {
      // Insert or update the IP record
      await connection.execute(
        `INSERT INTO ip_tracking (ip, country, city, latitude, longitude, visits, last_seen)
         VALUES (?, ?, ?, ?, ?, 1, NOW())
         ON DUPLICATE KEY UPDATE
           visits = visits + 1,
           last_seen = NOW(),
           country = VALUES(country),
           city = VALUES(city),
           latitude = VALUES(latitude),
           longitude = VALUES(longitude)`,
        [ip, ipInfo.country, ipInfo.city, ipInfo.latitude, ipInfo.longitude]
      );
      
      console.log('RDS updated successfully');
      
    } finally {
      await connection.end();
    }

    // Invalidate Redis cache to force refresh
    const redis = await getRedisClient();
    const cacheKey = 'geo_ip_leaderboard';
    await redis.del(cacheKey);
    
    console.log('Redis cache invalidated');

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        success: true,
        message: 'IP tracked successfully',
        ip,
        location: `${ipInfo.city}, ${ipInfo.country}`
      })
    };

  } catch (error) {
    console.error('Error tracking IP:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: 'Failed to track IP',
        message: error.message
      })
    };
  }
};
