--type: summary
--uid: mQ8XfW10fOQ
--name: empty_dashboards_S
--description: Total number of dashboards with no items
--detail_uid: NMZhvSZpTtW

select 'dashboard_empty' as indicator, 
count(*)::varchar as value,
       (100*count(*)/(select count(*) from dashboard))||'%' as percent,
        'Dashboards with no content' as description from dashboard where
         dashboardid not in (select dashboardid from dashboard_items);
      
--type: details
--uid: NMZhvSZpTtW
--name: empty_dashboards_D
--description: List of dashboards with no items

SELECT uid,name from dashboard WHERE
dashboardid not in (select dashboardid from dashboard_items);
