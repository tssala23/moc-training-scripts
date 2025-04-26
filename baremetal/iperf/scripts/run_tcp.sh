
for SERVER in $N0 $N1 $N2; do
  for CLIENT in $N0 $N1 $N2; do
    if [ "$SERVER" = "$CLIENT" ]; then continue; fi
    SERVER_NAME=$(ssh cloud-user@$SERVER 'hostname | tr "[:upper:]" "[:lower:]" | tr -d "-"')
    CLIENT_NAME=$(ssh cloud-user@$CLIENT 'hostname | tr "[:upper:]" "[:lower:]" | tr -d "-"')
    echo "Running $SERVER_NAME - $CLIENT_NAME"
    BUF_SIZE=128K
    UNITS=128
    MTU=$(ssh cloud-user@$SERVER "ip -o addr show | grep 'inet $SERVER' | awk '{print \$2}' | xargs -I {} ip link show {} | grep mtu | awk '{print \$5}'")
    ssh -f cloud-user@$SERVER "~/iperf/install/bin/iperf3 -s -p 12345 -1 &> /tmp/iperf_tcp_srv_${MTU}_${BUF_SIZE}_${UNITS}_${SERVER_NAME}_${CLIENT_NAME}.log"
    sleep 2
    ssh cloud-user@$CLIENT "~/iperf/install/bin/iperf3 -c $SERVER -p 12345 -l ${BUF_SIZE} -P ${UNITS}"
    sleep 2
    mkdir -p logs
    scp cloud-user@$SERVER:/tmp/iperf_tcp_srv_${MTU}_${BUF_SIZE}_${UNITS}_${SERVER_NAME}_${CLIENT_NAME}.log ./logs/
    cat ./logs/iperf_tcp_srv_${MTU}_${BUF_SIZE}_${UNITS}_${SERVER_NAME}_${CLIENT_NAME}.log | grep "\[SUM\]" > ./logs/iperf_tcp_srv_${MTU}_${BUF_SIZE}_${UNITS}_${SERVER_NAME}_${CLIENT_NAME}_sum.log
    cat ./logs/iperf_tcp_srv_${MTU}_${BUF_SIZE}_${UNITS}_${SERVER_NAME}_${CLIENT_NAME}_sum.log
  done
done

