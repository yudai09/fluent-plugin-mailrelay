# Fluent::Plugin::Mailrelay

Fluentd plugin to tracking mail relay in your networks.
This plugin expects fluent-plugin-sendmail `unbundled' JSON outputs.

## Configuration

```
<source>
  type sendmail
  path /var/log/maillog
  tag sendmail
  unbundle yes
</source>

<match sendmail>
  type mailrelay
  mynetworks ["127.0.0.1", "1.1.1.0/24"]
  flush_interval 60
  @label @relay
</match>

<label @relay>
  <match sendmail>
     type file
     path /var/log/sendmail
  </match>
</label>
```

example of sendmail log

```

@centos001

Jul  7 19:47:51 centos001 sendmail[22886]: u67AlmbO022886: from=<grandeur09+from@gmail.com>, size=5, class=0, nrcpts=1, msgid=<201607071047.u67AlmbO022886@centos001.localdomain>, proto=SMTP, daemon=MTA, relay=localhost [127.0.0.1]
Jul  7 19:47:51 centos001 sendmail[22888]: u67AlmbO022886: to=<grandeur09+to@gmail.com>, delay=00:00:00, xdelay=00:00:00, mailer=smtp, pri=120005, relay=[1.1.1.2] [1.1.1.2], dsn=2.0.0, stat=Sent (u67Alp74018025 Message accepted for delivery)

@centos002

Jul  7 19:47:51 centos002 sendmail[18025]: u67Alp74018025: from=<grandeur09+from@gmail.com>, size=417, class=0, nrcpts=1, msgid=<201607071047.u67AlmbO022886@centos001.localdomain>, proto=ESMTP, daemon=MTA, relay=[1.1.1.1]
Jul  7 19:47:53 centos002 sendmail[18027]: u67Alp74018025: to=<grandeur09+to@gmail.com>, delay=00:00:02, xdelay=00:00:02, mailer=esmtp, pri=120417, relay=gmail-smtp-in.l.google.com. [74.125.204.27], dsn=2.0.0, stat=Sent (OK 1467888473 d129si502387itc.63 - gsmtp)

```

This plugin emit record like below:

```
2016-07-07T19:47:53+09:00       sendmail
{
   "from":"<grandeur09+from@gmail.com>",
   "to":"<grandeur09+to@gmail.com>",
   "msgid":"<201607071047.u67AlmbO022886@centos001.localdomain>",
   "delay_sec_sum":2,
   "relay":[
      {
         "mta":"centos001",
         "relay_to":{
            "ip":"1.1.1.2",
            "host":null
         },
         "stat":"sent",
         "dsn":"2.0.0",
         "delay":"00:00:00",
         "arrived_at_mta":1467888471
      },
      {
         "mta":"centos002",
         "relay_to":{
            "ip":"74.125.204.27",
            "host":"gmail-smtp-in.l.google.com."
         },
         "stat":"sent",
         "dsn":"2.0.0",
         "delay":"00:00:02",
         "arrived_at_mta":1467888473
      }
   ]
}
```

## TODO

* writing test code.

## ChangeLog

See [CHANGELOG.md](CHANGELOG.md) for details.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright (c) 2014 yudai09. See [LICENSE](LICENSE) for details.
