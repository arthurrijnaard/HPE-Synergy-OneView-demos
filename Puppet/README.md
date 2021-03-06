## Puppet Oneview with Image Streamer demo

Infrastructure as code demo to automate the deployment of compute resources managed via OneView using Puppet manifests.
OS deployment and OS configuration are managed by HPE Image Streamer.   

   
## Environment setup

You need to install the Puppet Module for HPE OneView in order to run these manifests.    
See https://github.com/HewlettPackard/oneview-puppet 

You also need an Image Streamer artifact bundles, see https://github.com/search?q=org:HewlettPackard+image-streamer   

In these manifests, we use the RHEL 7.3 artifact bundle, see https://github.com/HewlettPackard/image-streamer-rhel/tree/master/artifact-bundles   

>The manifests have been developed and tested with *HPE-RHEL-7.3-2017-04-20.zip*.

It is necessary to edit the manifest variables with your own settings (i.e. Profile name, Server Hardware name, Network names, etc.) and with your custom attributes to personalized the OS settings (i.e. Hostname, network URIs, new user, SSH enabled, etc.).

### To create a new server profile using the Image Streamer to deploy the OS
` puppet apply <path>/Server_Profile_Provisioning_with_Image_Streamer.pp` 

The manifest ensures the Compute Module is power-off before the profile is created and assigned. Then the script automatically power-on the server once the profile creation is completed.

### To remove the server profile 
` puppet apply <path>/Server_Profile_Unprovisioning_with_Image_Streamer.pp` 

The manifest powers off the server then delete the server profile 
