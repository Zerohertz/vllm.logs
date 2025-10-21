NODE_COUNT=2
ray start --head --port=6379 --disable-usage-stats --node-ip-address=${MNCSVR11_IP}
while true; do
	node_count=$(ray status | grep node_ | wc -l)
	echo "Current node count: $node_count"
	if [ "$node_count" -eq $NODE_COUNT ]; then
		echo "Node count is $NODE_COUNT. Exiting loop."
		break
	fi
	sleep 1
done

vllm serve Qwen/Qwen2.5-VL-72B-Instruct \
	--host=0.0.0.0 --port 8000 --gpu-memory-utilization 0.90 \
	--distributed-executor-backend ray \
	-tp 8 -pp 2 \
	--enable-auto-tool-choice --tool-call-parser hermes \
	--max-model-len 128000 --limit-mm-per-prompt '{"video":0}'
