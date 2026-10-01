final: prev: {
  # Wrap omp so every invocation loads the checked-in look overlay.
  # A wrapper (not hjem-managed config.yml) keeps the live
  # ~/.omp/agent/config.yml user-mutable: `omp config set` keeps working
  # because the base file stays a regular file, while look keys win at
  # runtime via --config overlay merge. Sorts after omp-18.4.3.nix, so
  # prev.omp is the pinned binary.
  omp = prev.omp.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [prev.makeWrapper];
    postInstall =
      (old.postInstall or "")
      + ''
        mv $out/bin/omp $out/bin/.omp-real
        makeWrapper $out/bin/.omp-real $out/bin/omp \
          --add-flags "--config ${./omp-look.yml}"
      '';
  });
}
