WebDB
=====

This is a simple Perl script to load and save key/value pairs over HTTP/HTTPS. Everything is sent with GET or POST values and returned as plain text with HTTP status codes.

Functions
---------
* register
* load
* save
* timestamp

Use the index.html for a quick AJAX demo.

Installation
------------
Just copy `webdb.pl`, `webdb.sqlite` and optionally `index.html` to a folder on your web server.

Usage
-----
Register an app: `http://web server/webdb.pl?register=appname`

This returns a 64-bytes secret.

Save a key/value pair: `http://web server/webdb.pl?secret=mysecret&save=key&data=value`

Load a key/value pair: `http://web server/webdb.pl?secret=mysecret&load=key`

Possible result codes
---------------------
* 200, "OK"
* 400, "Bad Request"
* 401, "Unauthorized"
* 404, "Not Found"
* 405, "Method Not Allowed"
* 409, "Conflict"
* 412, "Invalid Length"
* 500, "Internal Server Error"

