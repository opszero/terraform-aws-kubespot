# Disable swapping and clear the file system page cache to free memory first.
sys.vm.swappiness=0

# Amount of memory to keep free. Don't want to make this too high as
# Linux will spend more time trying to reclaim memory.
sys.vm.min_free_kbytes=65536

# (min, default, max): The sizes of the write buffer for the IP protocol.
sys.net.ipv4.tcp_wmem=4096 65536 16777216

sys.net.ipv4.tcp_tw_reuse=1

# Increase the tcp-time-wait buckets pool size to prevent simple DOS attacks
sys.net.ipv4.tcp_max_tw_buckets=400000

# The number of incoming connections on the backlog queue. The maximum
# number of packets queued on the INPUT side.
sys.net.core.netdev_max_backlog=30000

# (min, default, max): The sizes of the receive buffer for the IP protocol.
sys.net.ipv4.tcp_rmem=4096 87380 16777216

# Number of times initial SYNs for a TCP connection attempt will
# be retransmitted for outgoing connections.
sys.net.ipv4.tcp_syn_retries=2

# The max is double the previous value.
# https:..wiki.khnet.info.index.php.Conntrack_tuning
sys.net.netfilter.nf_conntrack_max=200000

# The size of the receive buffer for all the sockets. 16MB per socket.
sys.net.core.rmem_max=16777216

# TCP saves various connection metrics in the route cache when the
# connection closes so that connections established in the near future
# can use these to set initial conditions. Usually, this increases
# overall performance, but may sometimes cause performance
# degradation.
sys.net.ipv4.tcp_no_metrics_save=1

# The maximum number of queued sockets on a connection.
sys.net.core.somaxconn=16096

# On a typical machine there are around 28,000 ports available to be
# bound to. This number can get exhausted quickly if there are many
# connections. We will increase this.
sys.net.ipv4.ip_local_port_range=1024 65535

# Usually, the Linux kernel holds a TCP connection even after it
# is closed for around two minutes. This means that there may be
# a port exhaustion as the kernel waits to close the
# connections. By moving the fin_timeout to 15 seconds we
# drastically reduce the length of time the kernel is waiting
# for the socket to get any remaining packets.
sys.net.ipv4.tcp_fin_timeout=15

# Security to prevent DDoS attacks. http:..cr.yp.to.syncookies.html
sys.net.ipv4.tcp_syncookies=1

# This setting determines the number of SYN+ACK packets sent before
# the kernel gives up on the connection
sys.net.ipv4.tcp_synack_retries=2

# The size of the buffer for all the sockets. 16MB per socket.
sys.net.core.wmem_max=16777216

# Increase the number syn requests allowed. Sets how many half-open connections to backlog queue
sys.net.ipv4.tcp_max_syn_backlog=20480
