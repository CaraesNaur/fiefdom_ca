# Fiefdom-CA: A small Certificate Authority

This project is comprised of a set of Bash scripts which allow developers to quickly establish an OpenSSL Certificate Authority for local development environments and deploy host identities (key, certificate) to services/daemons.

These scripts are intended to provide developers a quick, easy process for establishing their own *local* Certificate Authority and distributing host identity files.

It may be prefereable to download this project rather than clone its repository.

**Note**: These scripts are sufficient for local development, however no claim is made to their suitability for production or other environments accessible via the Internet at large.

**Note**: Fiefdom-CA does not currently support `localhost` as a hostname.  It is designed for use with named hosts *in a domain*.

The Certificiate Authority (CA) setup process is based on this guide written by Jamie Nguyen:

* https://jamielinux.com/docs/openssl-certificate-authority/index.html

Prototype OpenSSL configuraton files are from the Appendix there.

However, these tools organize the files differently.  See **Other Fiefdom-CA Assets**, below.

Each of these directories contain several other directories where configuration, key, CSR, certificate, and other files reside.

The nature of these scripts may require them to be executed via `sudo`.

It is not advisable to move, rename, edit, or delete any files created by these scripts within these directories.  Doing so may destroy the CA chain of trust and/or invalidate host identities.

## Certificate Authority Basics

A [Certificate Authority](https://en.wikipedia.org/wiki/Certificate_authority) (CA) is an entity that stores, signs, and issues digital certificates.

Certificates trusted by client software (i.e, browsers) can establish secure connectsions using SSL and TLS.

Types of files used by a CA:

* **Key**: A cryptographic document which an entity presents as identification.
* **Certificate Signing Request (CSR)**: A cryptographic document used by one entity to sign a certificate for another entity.
* **Certificate**: A signed cryptographic document that verifies the identity of an entity.
* **Certificate Revocation List (CRL)**: A list of certificates that an entity has signed and later revoked.
* **Chain File**: Contains certificates issued by multiple related entities to establish a *Chain of Trust*.

### CA Entities

The CA established by these scripts consists of three entity types:

#### Root CA

The Root CA is the top level authority of the enture CA.  All trust of other entities ultimately comes from the Root CA.

The Root CA's certificate is self-signed.

The Root CA signs the Intermediate CA's certificate.  Therefore, the Root CA's identity can be used *indirectly*.

#### Intermediate CA

The Intermediate CA serves as a lieutenant of the Root CA.

The Intermediate CA certificate is signed by the Root CA (therefore, not self-signed).

It in turn signs host certificates.

#### Host(s)

Host entities are the (local) sites governed by the CA: `https://mystuff.local`, `https://project1.devbox`, etc.

Host certificates are signed by the Intermendiate CA.  Generating host certificates is the ultimate goal of establishing a Certificate Authority.

Each hosts's key and certificate (along with the CA chain file) is deployed to the application server (Apache2, Nginx) for establishing trust and therefore enabling SSL/TLS connections.

### Distinguished Names

Certificates embed values that comprise the details of entities referenced in the certififate.  These values are collectively referred to as a Distinshuished Name (DN).

A DN is comprised of several fields.  Fields relevant here are:

* **Country Name** (`C`): Two-letter ISO Country Code.
* **State or Province Name** (`ST`): Self-explanatory.
* **Locality Name** (`L`): eg, City.
* **Organization Name** (`O`): Name of the Organization to which the entity belongs.
* **Organizational Unit Name** (`OU`): Department/section within the Organization to which the entity belongs.
* **Common Name** (`CN`): For CA entities, this can be any unique string.  For hosts, this must be the fully qualified domain name.
* **Email Address** (`emailAddress`): Entity contact email address.

**Note**: These scripts do not utilize `emailAddress`, although `openssl` will prompt for it.

For the purposes of these scripts, DN values need not be *real* or *legitimate*, but must still be *valid*.

These scripts attempt to make this process as simple and error-free as possible, including the inheritance of DN values which must match among entities.

## File Distribution & Installation

### Certificate Authority Files

#### Add CA To The System Certificate Store

Any systems that will access services governed by this Certificate Authority (including the system where the CA resides) need the CA's idenitity files installed.  This process varies by platform.

On Debian-based systems (including Ubuntu), first install the `ca-certificates` package:

    $ sudo apt-get install -y ca-certificates

Next, copy the Root and Intermediate CA certificates and the chain file to

    /usr/local/share/ca-certificates/

With a .crt extension, such as:

    $ sudo cp /root/fiefdom_ca/root_ca/certs/devbox_root_ca.cert.pem /usr/local/share/ca-certificates/devbox_root_ca.crt
    $ sudo cp /root/fiefdom_ca/intm_ca/certs/devbox_intm_ca.cert.pem /usr/local/share/ca-certificates/devbox_intm_ca.crt
    $ sudo cp /root/fiefdom_ca/intm_ca/certs/devbox_intm_ca_chain.cert.pem /usr/local/share/ca-certificates/devbox_ca_chain.crt

The exact filenames will vary based on where this project code resides and the values used by `ca_setup.sh`; the correct commands will be displayed by `ca_setup.sh` at the end of the setup process.

Then, update the system certificate store:

    $ sudo update-ca-certificates

Installation can be verified with this command:

    $ awk -v cmd='openssl x509 -noout -subject' '/BEGIN/{close(cmd)};{print | cmd}' < /etc/ssl/certs/ca-certificates.crt | grep -i 'FOO'

Where `FOO` is some part of the **Organization Name**, **Organization Unit Name**, or
**Common Name** for your CA's Root or Intermediate identity signature.


#### Add CA To Client Software Certificate Store(s)

Client software (eg, browsers) may need to import your CA's identity before trusting it.  Other client software may utilize the system's certificate store.

Follow the client software's instructions for adding a Certificate Authority.  When asked to import a file, use the CA Chain file.

You may need first to **copy* it to a location your user account can access.

### Host Files

After generating identity files for a host, they must be deployed to services/daemons (eg, Apache 2, Nginx) to enable TLS connections with client software.

Host identity files should be **copied** (not moved) to the service's configuration.  The specific location may be a sub-directory (eg, `/etc/apache2/ssl/`), and may also require that directory and/or its contents have specific limited permissions.

Other configuration files of a service likely need to be edited to reference host identity files correctly.

Consult the service's documentation.

A service needs the following files:

* CA Chain file
* Host Key
* Host Certificate

Once the files are in place and service configuration is updated accordingly, restart the service.

Both the service and client software need the CA identity in order to perform the handshake.

## Fiefdom-CA Project Manifest

This section details all the files which are part of the project.

### Files

* `README.md`: This document.
* `ca_setup.sh`: Bash script that establishes the Certificate Authority.  See full documentation below.
* `certificate_authority.conf`: Config file created by `ca_setup.sh`, loaded by the other scripts via `source`.
* `crt_deploy.ini`: Config file for host identity deployments; created by `depmgr.sh`.
* `depmgr.sh`: Bash script used to establish host identity deployment locations.  See full documentatuon below.
* `genhostcrt.sh`: Bash script that generates identity assets for a host.  See full documentation below.
* `host_deploy.sh`: Bash script that can deploy host identity files to configured locations.  See full documentation below.
* `iniget`: Bash script for reading data from `.ini` files.
* `iniset`: Bash script that writing data to `.ini` files (currently unused).

**Note**: `iniget` and `iniset` are lightly modified versions of scripts available at

    https://github.com/cherrynoize/dotfiles/tree/main/bin

### Directories

* `./dist_files/`: Contains OpenSSL configuration file templates, one for each type of CA entity.
* `./includes/`: Supplementary files loaded by the main scripts.

## Other Fiefdom-CA Assets

The scripts `ca_setup.sh` and `depmgr.sh` create several additional directories and files.

* `./root_base/`: Root CA files
  * `certs/`: Root CA certificate is kept here
  * `crl/` Root CA Certificate Revocation List is kept here
  * `crlnumber`: Used by `openssl`
  * `csr/`: Stores CSR files (not used)
  * `index.txt`: Used by `openssl`
  * `index.txt.attr`: Used by `openssl`
  * `index.txt.old`: Used by `openssl`; backup of `index.txt`
  * `newcerts/`: Used by `openssl`
  * `openssl.cnf`: OpenSSL config file for Root CA
  * `private/`: Root CA key is kept here
  * `serial`: Counter file used by `openssl`
  * `serial.old`: Backup of `serial`
* `./intm_base/`: Intermediate CA files
  * `certs/`: Intermediate CA certificate is kept here
  * `crl/` Intermediate CA Certificate Revocation List is kept here
  * `crlnumber`: Used by `openssl`
  * `csr/`: Stores CSR files made by Intermediate CA
  * `index.txt`: Used by `openssl`
  * `index.txt.attr`: Used by `openssl`
  * `index.txt.old`: Used by `openssl`; backup of `index.txt`
  * `newcerts/`: Used by `openssl`
  * `openssl.cnf`: OpenSSL config file for Intermediate CA
  * `private/`: Intermediate CA key is kept here
  * `serial`: Counter file used by `openssl`
  * `serial.old`: Backup of `serial`
* `./hosts/`: Host files
  * `certs/`: Host CA certificates are kept here
  * `conf/`: Host openSSL config files are kept here
  * `csr/`: Stores CSR files made by hosts
  * `private/`: Host keys are kept here

These all are, or contain, sensitive files that should not be distributed on public systems.  The bulk of this project's `.gitignore` is intended to prevent unintentional distribution.

## Script Documentation

The final sections documents usage & behavior of the main Fiefdom-CA scripts.

### Certificate Authority Setup (`ca_setup.sh`)

Guides the user through setup and configuration for the Certificate Authority.

Arguments:

* None

At prompts which display `[Y/n]` options, the default is capitalized and (if the terminal is capable) colored green.  Default options can be accepted by pressing `<enter>`.  Any other input which is not the default will be considered 'no',

This script first checks for the existence of `./root_base/`, `./intm_base/`, `./hosts/`, and `./certificate_authority.conf`.  If any of these are found, aborts with an advisory message.

It then prompts for a domain, providing the output of ``hostname`` as a default.  When generating host identity files, host names are constructed as follows:

    [hostname].[domain]

This construct forms the first part of a host's key, CSR, and certificate file names.

The semi-complete Fiefdom-CA configuration file is then created at `./certificate_authority.conf`.

It then proceeds to configure the Root then Intermediary CA entities, providing extensive information about the process along the way.

Sub-directories and files for the CA entity are created, populated, and set to proper permissions as necessary.

The user is prompted to establish Distingsuished Name default values for the CA entity.  Accepting the default (Y) is highly recommended.

Each DN value is prompted for.  For the Root CA, thes must all be entered (except 'emailAddrress').  For the Intermediate CA, DN values from the Root CA which must match are re-used without prompt.

**Note**: The prompts for 'organizationalUnitName' are pre-populated with "Root CA" or "Intm CA", respectively.

The CA entity key is created.  `openssl` requires that CA entity keys have a passphrase.  If key generation fails, `ca_setup.sh` will exit with a message.

The CA entity certificate is created.  The CA entity's DN values have already been written to the CA entity configuration file; these are read by `openssl` when it prompts for them again.

The DN field 'Common Name' has no default in this process and must be entered here.  Each 'Common Name' must be unique; for CA entities, this may be a human-readable identifier (personal/company name, etc).

The certificate file is created and it permissions set to `444`.

`openssl` is then invoked to verify the certificate.

> **Note**: When the CA entity setup process repeats for the Intermediate CA, a CSR is created before generating the certificate.  This is where `openssl` gathers Intermediate CA DN values.
>
>
> The Intermediate CA certificate must then be signed by the Root CA; `openssl` will prompt for the Root CA key passphrase, then prommpt the user to confirm signing the certificate, and finally to commit the Intermediate CA certificate to the Root CA's index.
>
>
> After verifying the Intermediate CA certificate, `openssl` will be invoked again to verify the Intermediate CA certificate against the Root CA certificate.

Should any invocation of `openssl` throughout CA setup fail, `ca_setup.sh` will terminate.

Once the Root CA and Intermediate CA setups are completed, the script prompts the user to gather DN defaults for hosts.  If the default is accepted, the script proceeds through prompting for each host DN field, providing corresponding values from the Intermediate CA.  Host default DN values are then stored in the Fiefdom-CA configuration file.

Finally, `ca_setup.sh` displays some information about what the user can do next.

CA setup is now complete.


### Host Certificate Generator (`genhostcrt.sh`)

Guides the user through generating the key and certificate for a host.

Arguments:

* `-h` (required): Hostname to work with (should not include domain)

First checks for presence of the Fiefdom-CA configuraton file.  If not found, terminates with a message.

After loading the Fiefdom-CA configuration file, verifies the the config values (including checking that other necessary files & directories exist).  If any do not pass, terminates with a message.

The given hostname argument is then validated.  If this fails, script terminates with a message.

Generates the host's key file.  Host keys are generated without a passphrase to allow services to (re)start without prompting for passphrases.

If a key for the host already exists, it will be used.

Creates a CSR for the host, to be signed by the Intermediate CA.  If a CSR for the host already exists, it will be used.  Prompts the user to examine the CSR.

The user is prompted for the number of days the certificate will be valid.  The default is `397`, however a lesser number may be entered.

For user reference, an approximate end date of the validity period is displayed, in both local time and UTC.

The host's certificate is then generated, with instruction for what user input `openssl` expects.

The script then prompts the user to examine the host certificate.

At this point, host identity creation is complete.  For reference, relevant file locations are displayed.

Should any invocation of `openssl` throughout CA setup fail, `ca_setup.sh` will terminate.

Finally, `genhostcrt.sh` prompts the user whether to invoke `host_deploy.sh` to deploy the host identity.


### Host Identity Deployment Manager (`depmgr.sh`)

Allows the user to configure disk locations and related services for host identity deployment.

Arguments:

* None

This script first checks for the existence of the deployment configuration file, `./crt_deploy.ini`.  If not found, creates it.

It then displays some information about its purpose and lists the currently configured deployments.

Configured deployments are flagged and (if the terminal is capable, colored) based on viability.  Viable entries are prefixed `***` and colored green, while others are prefixed '!!!' and colored red.  Non-viable entries include notation(s) describing why they are that way.

The user is prompted to add a deployment.

A deployment consists of:

* **Label**: Identifier for user reference.
* **Path**: Disk location where host identify files will be **copied**.
* **Service**: Associated service/daemon that listens at a hostname.

'Label' must be unique among the deployments.

'Path' must be an existing filesystem location.

'Service' must be an installed system service (but may be repeated among deployments).  That is, an entry among `systemctl` unit files.

Each deployment prompt will repeat until a valid value is entered.

If a value consisting only of whitespace is entered, the deployment addition procedure is aborted, returning to the "Add Deployment?" prompt.

Once all valid values have been captured, the new deployment is written to the deployment configuration file.

This process will repeat until the script is terminated by the user (`ctrl-c`) or entering somehting other than Y/y at the add prompt.

Finally, the script will then report how many new deployments were added and the total deployments configured.

#### Deployment Configuration File

This file (`./crt_deploy.ini`) is a simple `.ini` file containing a section for each deployment.

The deployment **Label** serves as the section header.

Each section contains lines for `path` and `service` of the deployment.

While `depmgr.sh` is provided to add sections to this file, no means of removing or otherwise maintaining them is provided.  Users are responsible for making such changes to this file.


### Host Identity Deployer (`host_deploy.sh`)

Performs deployment of host identity files to configured deployments.

Arguments:

* `-h` (required): Hostname to work with (should not include domain)

This script first checks for the existence of the Certificate Authority configuration file, `./certificate_authority.conf`.  If not found, terminates with a message.

The given hostname argument is checked; if missing or invalid, script terminates with a message.

After loading the Fiefdom-CA configuration file, verifies the the config values (including checking that other necessary files & directories exist).  If any do not pass, terminates with a message.

Next, existence of the host's key, certificate, CSR, and config files are checked and reported.  If any are missing, the script terminates with a message.

A summary of what is about to be done is displayed, including a count of configured deployments.

The script now iterates though the deployments, displaying each as described for `depmgr.sh`.

Non-viable deployments are ignored; the script displays a message and continues to the next.

For viable deployments, the target file paths are displayed; if neither the key or certificate exist at the deployment location, "Deployment clear!" id displayed and the user is prompted to confirm ther deployment.  The files are copied, and the script continues to the next entry.

If either key or certificate exist at the deployment location, a warning is displayed.  The user is then prompted to confirm... this prompt has no default and requires 'Y' to confirm.

If confirmation is not done, the deployment is ignored.  Otherwise, the files that exist at the deployment location are renamed in-place with a timestamp suffix in the format `.YYYYMMDD_HHIISS.N` (N is microseconds).  These preserved filenames are displayed for user reference.

The key and certificate files found within Fiefdom-CA are then copied to the deployment location.

Once all the deployments have been iterated through, the script reports how many were performed and lists the services to be restarted.

**Note**: Users should take care not to leave unwanted/unnecessary host identity files scattered around their systems.


## Conclusion

Enjoy!

