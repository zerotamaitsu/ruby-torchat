torchat - the Ruby implementation
=================================
You can find the official implementation [here](https://github.com/prof7bit/TorChat).

This aims to be a Ruby implementation and daemon to deal with a TorChat session even from
outside or with other languages without having to implement the whole thing.

The main target is supporting TorChat in bitlbee.

Setup the daemon
----------------
The daemon to work needs a tor configured with a hidden service, you can leave it automatic by
passing `-t` as an option or you can configure it yourself.

If you have an already created default TorChat session you just have to run `torchatd -t`, it
will do all is needed, and you'll be able to connect to it on port `11110`. If you use bitlbee
you just have to add the account, you can also pass a password with `-P password` which will have
to be the password you added the account with.

The daemon has a helper function to generate the needed tor configuration file based either
on a YAML file or a TorChat configuration file.

Example of tor configuration generation:

```
$ torchatd -g -c etc/torchat.yml
SocksPort 11108

HiddenServiceDir hidden_service
HiddenServicePort 11009 127.0.0.1:11008

DataDirectory tor_data

AvoidDiskWrites 1
LongLivedPorts 11009
FetchDirInfoEarly 1
CircuitBuildTimeout 30
NumEntryGuards 6
```

Contacting the author
---------------------
If you want to contact me on torchat my id is `7acbk6jpofsanyfp`.
