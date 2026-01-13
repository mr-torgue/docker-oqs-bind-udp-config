docker exec -it nslocal-ns_local-1 /update_bind.sh
docker exec -it nslocal-ns_local-1 /set_udp_fragmentation.bash QBF
docker exec -it nslocal-ns_local-1 /run_bind.bash false