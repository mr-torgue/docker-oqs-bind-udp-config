docker exec -it nsroot-ns_root-1 /update_bind.bash
docker exec -it nsroot-ns_root-1 /set_udp_fragmentation.bash QBF
docker exec -it nsroot-ns_root-1 /run_bind.bash false
