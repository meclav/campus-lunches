Install
------

haraka
rabbitmq
stack (for haskell development)


Deploy
------
scp /mnt/c/projects/haskell/receive.hs root@138.68.141.114:/app/src && ssh droplet stack /app/src/receive.hs
git push $$ ssh droplet "cd /app ; git pull"

Run
------
```
haraka -c /app/mail >> /var/log/haraka.log
# rabbit
# main haskell thingy
```
Developed on Ubuntu x64.
