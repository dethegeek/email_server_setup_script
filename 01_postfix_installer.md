# Postfix Installer #

Following script may be used for configuring complete and secure email server on fresh install of Debian 7. It will probably work on other distributions using apt-get. After minor changes you'll be able to use it on other Linux distros.

## Usage ##

1. Run `postfix.sh` script.
2. Configure postgres to allow connections.
3. Configure postfix admin. Remember to set these:
```
$CONF['configured'] = true;
$CONF['domain_path'] = 'YES';
$CONF['domain_in_mailbox'] = 'YES';
$CONF['database_type'] = 'pgsql';
$CONF['database_host'] = 'localhost';
$CONF['database_user'] = 'postfix_user';
$CONF['database_password'] = 'PASSWORD FROM INSTALLER SCRIPT';
$CONF['database_name'] = 'postfix_db';
```
4. Create domain and at least one user.
5. Configure roundcube. Set imap to port `993`, host to: ssl://localhost. Set smtp to port `587`, host to tls://localhost.

This is just a draft right now, it will be updated.