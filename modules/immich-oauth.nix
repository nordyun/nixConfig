# Shared Immich system settings, including the settings migrated from Anubis's
# database. File-based configuration is authoritative for system settings.
# On thoth, first add its host key to the secret recipients and rekey.
{ config, ... }:
{
  age.secrets.immich_google_client_secret.file = ../secrets/immich_google_client_secret.age;

  services.immich.settings = {
    server = {
      publicUsers = false;
      externalDomain = "https://photos.washatka.net";
    };
    storageTemplate = {
      enabled = true;
      template = "{{y}}/{{MM}}/{{filename}}";
    };
    oauth = {
      enabled = true;
      issuerUrl = "https://accounts.google.com";
      clientId = "494778949393-8e0t6mdf547akrqo93tmvf7252kpl3je.apps.googleusercontent.com";
      clientSecret._secret = config.age.secrets.immich_google_client_secret.path;
      scope = "openid email profile";
      buttonText = "Sign in with Google";
      autoRegister = false;
      autoLaunch = false;
      mobileOverrideEnabled = true;
      mobileRedirectUri = "https://photos.washatka.net/api/oauth/mobile-redirect";
    };
    # Family accounts are linked and mobile uploads verified; require Google login.
    passwordLogin.enabled = false;
  };
}
