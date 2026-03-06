# Configuración de Gunicorn para producción

import os

# Bind
bind = f"0.0.0.0:{os.environ.get('PORT', '5000')}"

# Workers
workers = int(os.environ.get('GUNICORN_WORKERS', '4'))
worker_class = "sync"
worker_connections = 1000
timeout = 120
keepalive = 5

# Logging
accesslog = "-"  # Stdout
errorlog = "-"   # Stderr
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s"'

# Server mechanics
daemon = False
pidfile = None
umask = 0
user = None
group = None
tmp_upload_dir = None

# Process naming
proc_name = "gunicorn-firmadocumentos"

# SSL (si se necesita)
# keyfile = None
# certfile = None
