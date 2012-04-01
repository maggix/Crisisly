var redis = require("redis"),
  http = require("http"),
  io = require("socket.io"),
  express = require("express"),
  client = redis.createClient();

var app = express.createServer()
  , io = io.listen(app);

app.listen(8080);

app.get('/', function(req, res){
    res.send('These are not the droids you\'re looking for.');
});


io.sockets.on('connection', function (socket) {
  //socket.emit('news', { hello: 'world' });
});


client.on("pmessage", function (pattern, channel, message) {


	io.sockets.emit(channel, { data: message });
});

client.psubscribe("*");