docker exec -it resolver-resolver-1 /update_bind.bash
docker exec -it resolver-resolver-1 /set_udp_fragmentation.bash QBF
docker exec -it resolver-resolver-1 /run_bind.bash false
