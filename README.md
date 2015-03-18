paranoid-prosody
===================

This script is a fork of https://github.com/micahflee/tor-relay-bootstrap. It has been modified to install Prosody (An XMPP server) with strong SSL/TLS ciphers, disables logging, and does some other paranoid things. It also sets up Tor to provide a hidden service for Prosody.

This is a script to bootstrap a Debian/Ubuntu server to be a set-and-forget Prosody server . It's been tested on Debian Wheezy and Ubuntu 14.04, and should work on any other maintained version of those two distros.

paranoid-prosody does this:

* Upgrades all the software on the system
* Adds the deb.torproject.org and the packages.prosody.im/debian repositories to apt, so Prosody and Tor updates come directly from the source.
* Installs and configures Prosody with reasonably paranoid defaults.
* Installs and configures Tor to be a hidden service for Prosody (You can also manually edit torrc to make SSH an authenticated hidden service)
* Configures sane default firewall rules
* Configures automatic updates
* Installs tlsdate to ensure time is synced
* Gives instructions on what the sysadmin needs to manually do at the end

To use it, set up a new Debian or Ubuntu server, SSH into it, switch to the root user, and:

```sh
git clone https://github.com/NSAKEY/paranoid-prosody.git
cd paranoid-prosody
./bootstrap.sh
```

