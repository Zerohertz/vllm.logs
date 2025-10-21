MNCSVR11_IP=192.168.100.12
MNCSVR12_IP=192.168.100.22
GLOO_SOCKET_IFNAME=ens3f0
NCCL_SOCKET_IFNAME=ens3f0,ens1f0
NCCL_IB_HCA=rocep9s0f0,rocep66s0f0
CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7

docker run \
	-d \
	--network host \
	--ipc host \
	--privileged \
	--name vllm \
	--device=/dev/infiniband \
	--entrypoint /bin/bash \
	--ulimit memlock=-1:-1 \
	-v /dev/shm:/dev/shm \
	-v /dev/infiniband:/dev/infiniband \
	-v /sys/class/infiniband:/sys/class/infiniband \
	-v "/mnt/data01/huggingface/cache:/root/.cache/huggingface" \
	-v "/root/hgoh:/root" \
	-e CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES} \
	-e NVIDIA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES} \
	-e MNCSVR11_IP=${MNCSVR11_IP} \
	-e MNCSVR12_IP=${MNCSVR12_IP} \
	-e VLLM_HOST_IP=${MNCSVR11_IP} \
	-e GLOO_SOCKET_IFNAME=${GLOO_SOCKET_IFNAME} \
	-e NCCL_SOCKET_IFNAME=${NCCL_SOCKET_IFNAME} \
	-e NCCL_P2P_DISABLE=0 \
	-e NCCL_IB_DISABLE=1 \
	-e NCCL_IB_HCA=${NCCL_IB_HCA} \
	-e NCCL_IB_GID_INDEX=1 \
	-e NCCL_DEBUG=TRACE \
	-e NCCL_DEBUG_SUBSYS=ALL \
	-e TORCH_DISTRIBUTED_DEBUG=INFO \
	-e VLLM_LOGGING_LEVEL=DEBUG \
	-e VLLM_USE_V1=1 \
	vllm/vllm-openai:v0.11.0 \
	-c "~/entrypoint.sh"
