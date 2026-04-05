{ lib }:

# Helper functions to create samba shares with common defaults
{
  # Create a standard samba share with common settings
  mkSambaShare = { path, user, createMask ? "0644", directoryMask ? "0755", extraSettings ? {} }:
    {
      inherit path;
      browseable = "yes";
      "read only" = "no";
      "writeable" = "yes";
      "inherit acls" = "yes";
      "write list" = user;
      "create mask" = createMask;
      "directory mask" = directoryMask;
      "case sensitive" = "true";
      "default case" = "lower";
      "preserve case" = "yes";
      "short preserve case" = "yes";
      "force user" = user;
      "valid users" = user;
    } // extraSettings;

  # Create a Time Machine samba share
  mkTimeMachineShare = { path, user, maxSize ? "512G" }:
    {
      inherit path;
      browseable = "yes";
      "read only" = "no";
      "inherit acls" = "yes";
      "fruit:time machine" = "yes";
      "fruit:time machine max size" = maxSize;
      "write list" = user;
      "create mask" = "0600";
      "directory mask" = "0700";
      "case sensitive" = "true";
      "default case" = "lower";
      "preserve case" = "yes";
      "short preserve case" = "yes";
      "force user" = user;
      "valid users" = user;
    };
}
