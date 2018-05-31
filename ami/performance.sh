# Amount of memory to keep free. Don't want to make this too high as
# Linux will spend more time trying to reclaim memory.
echo "sys.vm.min_free_kbytes=65536" | sudo tee -a /etc/sysctl.conf

# (min, default, max): The sizes of the write buffer for the IP protocol.
echo "sys.net.ipv4.tcp_wmem=4096 65536 16777216" | sudo tee -a /etc/sysctl.conf

# Increase the tcp-time-wait buckets pool size to prevent simple DOS attacks
echo "sys.net.ipv4.tcp_max_tw_buckets=400000" | sudo tee -a /etc/sysctl.conf

# The number of incoming connections on the backlog queue. The maximum
# number of packets queued on the INPUT side.
echo "sys.net.core.netdev_max_backlog=30000" | sudo tee -a /etc/sysctl.conf

# (min, default, max): The sizes of the receive buffer for the IP protocol.
echo "sys.net.ipv4.tcp_rmem=4096 87380 16777216" | sudo tee -a /etc/sysctl.conf

# Number of times initial SYNs for a TCP connection attempt will
# be retransmitted for outgoing connections.
echo "sys.net.ipv4.tcp_syn_retries=2" | sudo tee -a /etc/sysctl.conf

# The max is double the previous value.
# https:..wiki.khnet.info.index.php.Conntrack_tuning
echo "sys.net.netfilter.nf_conntrack_max=200000" | sudo tee -a /etc/sysctl.conf

# The size of the receive buffer for all the sockets. 16MB per socket.
echo "sys.net.core.rmem_max=16777216" | sudo tee -a /etc/sysctl.conf

# TCP saves various connection metrics in the route cache when the
# connection closes so that connections established in the near future
# can use these to set initial conditions. Usually, this increases
# overall performance, but may sometimes cause performance
# degradation.
echo "sys.net.ipv4.tcp_no_metrics_save=1" | sudo tee -a /etc/sysctl.conf

# The maximum number of queued sockets on a connection.
echo "sys.net.core.somaxconn=16096" | sudo tee -a /etc/sysctl.conf

# On a typical machine there are around 28,000 ports available to be
# bound to. This number can get exhausted quickly if there are many
# connections. We will increase this.
echo "sys.net.ipv4.ip_local_port_range=1024 65535" | sudo tee -a /etc/sysctl.conf

# Usually, the Linux kernel holds a TCP connection even after it
# is closed for around two minutes. This means that there may be
# a port exhaustion as the kernel waits to close the
# connections. By moving the fin_timeout to 15 seconds we
# drastically reduce the length of time the kernel is waiting
# for the socket to get any remaining packets.
echo "sys.net.ipv4.tcp_fin_timeout=15" | sudo tee -a /etc/sysctl.conf

# Security to prevent DDoS attacks. http:..cr.yp.to.syncookies.html
echo "sys.net.ipv4.tcp_syncookies=1" | sudo tee -a /etc/sysctl.conf

# This setting determines the number of SYN+ACK packets sent before
# the kernel gives up on the connection
echo "sys.net.ipv4.tcp_synack_retries=2" | sudo tee -a /etc/sysctl.conf

# The size of the buffer for all the sockets. 16MB per socket.
echo "sys.net.core.wmem_max=16777216" | sudo tee -a /etc/sysctl.conf

# Increase the number syn requests allowed. Sets how many half-open connections to backlog queue
echo "sys.net.ipv4.tcp_max_syn_backlog=20480" | sudo tee -a /etc/sysctl.conf
