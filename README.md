# dashboard
scripts, daemons and configs for a home network dashboard

i'll put together a proper readme soon, in the meantime, i sourced heavily from:
- https://www.reddit.com/r/homelab/comments/40pej2/its_taken_2_weeks_but_i_finally_got_my_grafana/
- https://denlab.io/setup-a-wicked-grafana-dashboard-to-monitor-practically-anything/

dashboard utilizes:
- Synology DS916+
- Raspberry Pi 3 (runs monitoring scripts)
- APC UPS
- influxDB (docker on the DS916+)
- grafana (docker on the DS916+)

todo:
- [ ] a proper readme
- [x] collect & dashboard network stats
- [ ] clean up presentation of network stats
- [ ] set up seperate network dashboard
- [ ] validate interfaces for network stats
- [ ] point network logging to main db
- [ ] figure out why UPS load stats are flat regardless of what is on / plugged in
- [ ] general system stats on synology (collectD?)
- [ ] collect & dashboard stats on mini