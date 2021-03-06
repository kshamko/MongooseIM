## Logs

It is a best practice to store logs in one centralized place when working in a clustered environment.
MongooseIM uses Lager - the logging framework. Its backend can be easily replaced.

Some of the recommended backends are:

- https://github.com/basho/lager_syslog to use syslog.
- https://github.com/mhald/lager_logstash_backend for [logstash](http://logstash.net/).

### syslog

To activate the syslog backend you have to edit `rel/files/app.config` and uncomment the line:

    %% use below line to add syslog backend for Lager
    %        {lager_syslog_backend, [ "mongooseim", local0, info]},

We ought to provide parameter list to make our lager syslog backend running:

* The first parameter is the string to tag all messages with in syslog. The default is `mongooseim`.
* The second one is the facility to log to (see the syslog documentation).
* The last parameter is the lager level at which the backend accepts messages. In our case it's `info`.

Depending on the system platform you use, remember also to add the appropriate line in the syslog config file:

    local0.info                     /var/log/mongooseim.log

Now all the logs of level `info` will be passed to `/var/log/mongooseim.log` file

Example log (e.g `tail -f /var/log/mongooseim.log`):

    Apr  1 12:36:49 User.local mongooseim[6068]: [info] <0.7.0> Application mnesia started on node mongooseim@localhost

### logstash

TODO

## Monitoring

### WombatOAM

WombatOAM is an operations and maintenance framework for Erlang based systems. Its Web Dashboard displays this data in an aggregated manner and provides interfaces to feed the data to other OAM tools such as Graphite, Nagios or Zabbix.

For more information see: [WombatOAM](https://www.erlang-solutions.com/products/wombat-oam.html).

### graphite-collectd

To monitor MongooseIM during load testing, we recommend the following open source applications:

- [Graphite](http://graphite.wikidot.com/) is used for data presentation.
- [collectd](http://collectd.org/) is a daemon running on monitored nodes capturing data related to CPU and Memory usage, IO etc.

### mod_api_metrics

It provides REST interface for Mongoose's metrics, so it can be easily integrated
with other services.

You can read more about it here: [REST interface to metrics](/developers-guide/REST-interface-to-metrics).

### Built-in Exometer reporters

MongooseIM uses the Exometer libary for collecting the metrics. Exometer has many
build-in reporters that can send metrics to external services like:

* graphite
* amqp
* statsd
* snmp
* opentsdb

It is possible to enable them in MoongooseIM via  the `app.config` file. The file sits next
to the `ejabberd.cfg` file and both files are located in the `rel/files` and `_REL_DIR_/etc` directories.
For more details, please visit the Exometer's project page: [Exometer](https://github.com/Feuerlabs/exometer).

**Note that we are using the 1.2.1 version.**

Below you can find sample configuration, it setups graphite reporter which connects
to graphite running on localhost.

You can see an additional option not listed in the Exometer docs - `mongooseim_report_interval`.
That option sets metrics resolution - in other words: how often Exometer gathers and sends metrics
through reporters. By default that is 60 seconds.

```erl
...
{exometer, [
    {mongooseim_report_interval, 60000}, %% 60 seconds
    {report, [
        {reporters, [
                     {exometer_report_graphite, [
                                                 {prefix, "mongooseim"},
                                                 {connect_timeout, 5000},
                                                 {host, "127.0.0.1"},
                                                 {port, 2003},
                                                 {api_key, ""}
                                                ]}
                    ]}
    ]}
  ]}
...
```

### Run graphite in Docker - quick start

Start docker machine:

    docker-machine start

Make sure it is running:

    $ docker-machine status
    Running

Run the following command:

    $ docker run -d --name graphite --restart=always hopsoft/graphite-statsd

Get the "local" IP address of the container:

    $ docker inspect graphite | grep IPAdd | grep -v Secon | cut -d '"' -f 4 | head -n 1
    172.17.0.2

Get IP address of the machine:

    $ docker-machine ip
    192.168.99.100

Route subnet:

    $ sudo route add -net 172.17.0.0 192.168.99.100

And now http://172.17.0.2 should show a graphite page.

Check if data collection works - run:

    $ while true; do echo -n "example:$((RANDOM % 100))|c" | nc -w 1 -u 172.17.0.2 8125; done

Wait a while, then open:

    http://172.17.0.2/render?from=-10mins&until=now&target=stats.example

Then, if you configure your MongooseIM to send Exometer reports to that IP address and run it for a while,
you should be able to see some interesting charts.
