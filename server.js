// JavaScript File
var express = require('express');
var fs = require('fs');
var morgan = require('morgan');
var path = require('path');
var http = require('http');
var https = require('https');
var app = express();


var HTTP_PORT = process.env.OPENSHIFT_NODEJS_PORT || 8080,
    HTTPS_PORT = 4443,
    IP_ADDRESS = process.env.OPENSHIFT_NODEJS_IP || "127.0.0.1",
    SSL_OPTS = {
      key: fs.readFileSync(path.resolve(__dirname,'.ssl/www.example.com.key')),
	  cert: fs.readFileSync(path.resolve(__dirname,'.ssl/www.example.com.cert'))
    };

/*
 *  Define Middleware & Utilties
 **********************************
 */
var allowCrossDomain = function(req, res, next) {
  if (req.headers.origin) {
    res.header('Access-Control-Allow-Origin', req.headers.origin);
  }
  res.header('Access-Control-Allow-Credentials', true);
  // send extra CORS headers when needed
  if ( req.headers['access-control-request-method'] ||
    req.headers['access-control-request-headers']) {
    res.header('Access-Control-Allow-Headers', 'X-Requested-With');
    res.header('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
    res.header('Access-Control-Max-Age', 1728000);  // 20 days
    // intercept OPTIONS method
    if (req.method == 'OPTIONS') {
        res.send(200);
    }
  }
  else {
      next();
  }
};

/*
 * Use Middlewares
 **********************************
 */
app.use(morgan());
//app.use(express.compress());
app.use(allowCrossDomain);
app.use(function(err, req, res, next) {
  console.error(err.stack);
  res.send(500, 'Something broke!');
});
app.use(express.static('dist'));


// Create an HTTP service.
http.createServer(app).listen(HTTP_PORT, IP_ADDRESS, function() {
  console.log('Listening to HTTP on port ' + HTTP_PORT);
});

// Create an HTTPS service identical to the HTTP service.
//https.createServer(SSL_OPTS, app).listen(HTTPS_PORT,function() {
//  console.log('Listening to HTTPS on port ' + HTTPS_PORT);
//});