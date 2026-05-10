{...}: {
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = false;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };
}
