cd /etc/swift
swift-ring-builder account.builder create 10 3 1
swift-ring-builder account.builder add --region 1 --zone 1 --ip 127.0.0.1 --port 6002 --device sdv --weight 1
swift-ring-builder account.builder rebalance

swift-ring-builder container.builder create 10 3 1
swift-ring-builder container.builder add --region 1 --zone 1 --ip 127.0.0.1 --port 6001 --device sdv --weight 1
swift-ring-builder container.builder rebalance

swift-ring-builder object.builder create 10 3 1
swift-ring-builder object.builder add --region 1 --zone 1 --ip 127.0.0.1 --port 6000 --device 127.0.0.1:8123 --weight 1
swift-ring-builder object.builder add --region 1 --zone 1 --ip 127.0.0.1 --port 6000 --device 127.0.0.1:8124 --weight 1
swift-ring-builder object.builder add --region 1 --zone 1 --ip 127.0.0.1 --port 6000 --device 127.0.0.1:8125 --weight 1
swift-ring-builder object.builder add --region 1 --zone 1 --ip 127.0.0.1 --port 6000 --device 127.0.0.1:8126 --weight 1
swift-ring-builder object.builder add --region 1 --zone 1 --ip 127.0.0.1 --port 6000 --device 127.0.0.1:8127 --weight 1
swift-ring-builder object.builder add --region 1 --zone 1 --ip 127.0.0.1 --port 6000 --device 127.0.0.1:8128 --weight 1
swift-ring-builder object.builder rebalance
