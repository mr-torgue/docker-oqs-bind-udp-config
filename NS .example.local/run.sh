docker exec -it nsexamplelocal-ns_example_local-1 /update_bind.bash
docker exec -it nsexamplelocal-ns_example_local-1 /set_udp_fragmentation.bash QBF
docker exec -it nsexamplelocal-ns_example_local-1 /run_bind.bash false
