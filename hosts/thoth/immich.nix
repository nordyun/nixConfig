{ config, myLib, pkgs, ... }:
let
  unstable = myLib.mkUnstable pkgs;
in
{
  age.secrets.immich_google_client_secret.file = ../../secrets/immich_google_client_secret.age;

  services.immich = {
    enable = true;
    package = unstable.immich;
    port = 2283;
    host = "0.0.0.0";
    openFirewall = true;
    settings = {
      library = {
        scan = {
          enabled = true;
          cronExpression = "0 6 * * *";
        };
        watch.enabled = false;
      };
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
  };
}
