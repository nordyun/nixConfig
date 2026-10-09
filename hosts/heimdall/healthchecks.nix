{ config, ... }:
let
  host = "heimdall.taila3fef.ts.net";
  base = "https://${host}:11443";
in
{
  age.secrets.healthchecks_secret_key = {
    file = ../../secrets/healthchecks_secret_key.age;
    owner = "healthchecks";
  };
  services.healthchecks = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 8000;
    settings = {
      ALLOWED_HOSTS = [ host ];
      SECRET_KEY_FILE = config.age.secrets.healthchecks_secret_key.path;
      SITE_ROOT = base;
      SITE_NAME = "heimdall-healthchecks";
      PING_ENDPOINT = "${base}/ping/";
      CSRF_TRUSTED_ORIGINS = base;
      SECURE_PROXY_SSL_HEADER = "HTTP_X_FORWARDED_PROTO,https";
      REGISTRATION_OPEN = false;
      DEBUG = false;
    };
  };
  myTailscaleServe.mounts."11443" = "http://127.0.0.1:8000";
  services.monit.config = ''
    check host healthchecks with address 127.0.0.1
      if failed port 8000 protocol http
        request "/" with http headers [Host: "${host}"]
        for 3 cycles then alert
  '';
}
