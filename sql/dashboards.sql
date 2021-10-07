--type: summary
--uid: G7Z1WmUiuuR
--name: assessment_dashboards_S
--description: Total number of dashboards in the system
--detail_uid: WAgKp3hIWzF

select 'dashboard_count' as indicator,
count(*)::varchar as value,
'100%' as percent, 
'Total number of dashboards' as description
from dashboard;

--type: details
--uid: WAgKp3hIWzF
--name: assessment_dashboards_D
--description: List of dashboards

select uid,name
from dashboard
LIMIT 1000;
