# Version 0.0.0
INI : Set basic servers (api_rest, webapp, blog).
FIX : Correct all endpoints to dockas endpoints.
ENH : Merge stage endpoint to production ones.
ENH : Add .com.br routes.
BUG : Correct bug with missing .com.br endpoints in nginx.cert.conf.
ENH : Update file server config to serve static files in /home/files directory.
FEA : Add file.stage.dockas.com(.br) server names to file server config.
ENH : Generate SSL certificate for files server.
FEA : Add ssl generation config specific to stage environment.
BUG : Creta deep letsencrypt file in /etc/letsencrypt/live/dockas.com.
BUG : Create symbolic link from stage letsencrypt live dir to production mock one.
BUG : Proxy socket.io request to api_rest instead to a "socket" service.