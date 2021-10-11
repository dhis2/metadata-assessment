--type: summary
--uid: U5DK7LdyJre
--name: abandoned_dashboards_S
--description: Dashboards with 1 or fewer views over the past three years
--detail_uid: Dfjw69AKQln
select 'dashboard_used' as indicator, 
count(*)::varchar as value, 
(100*count(*)/(select count(*) from dashboard))||'%' as percent, 
'Dashboards that have been viewed 1 time or less in the past three years' as description 
from dashboard where uid not in (select favoriteuid 
from datastatisticsevent where eventtype = 'DASHBOARD_VIEW'
and favoriteuid is not null and extract(year from timestamp) >= 
( extract(year from now()) -3 ) group by favoriteuid having count(*) >1);

--type: details
--uid: Dfjw69AKQln
--name: abandoned_dashboards_D
--description: Dashboards with 1 or fewer views over the past three years
SELECT uid,name from dashboard 
where uid not in (select favoriteuid 
from datastatisticsevent where eventtype = 'DASHBOARD_VIEW'
and favoriteuid is not null and extract(year from timestamp) >= 
( extract(year from now()) -3 ) group by favoriteuid having count(*) >1)
ORDER BY name;
