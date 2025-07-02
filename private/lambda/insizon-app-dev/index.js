const https = require('https');
const http = require('http');
const url = require('url');

exports.handler = async function (event) {
  try {
    const target = process.env.TARGET_URL;

    if (!target) {
      throw new Error("Missing TARGET_URL environment variable.");
    }

    const parsedUrl = url.parse(target);
    const isHttps = parsedUrl.protocol === 'https:';
    const client = isHttps ? https : http;

    const options = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port || (isHttps ? 443 : 80),
      path: parsedUrl.path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
    };

    return await new Promise((resolve, reject) => {
      const req = client.request(options, (res) => {
        let responseData = '';

        res.on('data', (chunk) => {
          responseData += chunk;
        });

        res.on('end', () => {
          console.log(`Response Code: ${res.statusCode}`);
          resolve({
            statusCode: res.statusCode,
            body: responseData,
          });
        });
      });

      req.on('error', (error) => {
        console.error('Request Error:', error);
        reject({
          statusCode: 500,
          body: JSON.stringify({ error: error.message }),
        });
      });

      // Optional: send payload
      req.write(JSON.stringify({ trigger: "scheduled", timestamp: new Date().toISOString() }));

      req.end();
    });
  } catch (err) {
    console.error('Handler Error:', err);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: err.message }),
    };
  }
};
