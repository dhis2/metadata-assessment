--type: summary
--uid: BsJqjX8CK2y
--name: assessment_dashboards_no_views_1y_S
--description: Dashboards not viewed in the past one year
--detail_uid: dEwPGTpXYY2
select 'dashboard_used1y' as indicator,
count(*)::varchar as value,
(100*count(*)/(select count(*) from dashboard))||'%', 'Dashboards that have not been
                opened in the last 12 months' as description from
                 dashboard where not uid in (select favoriteuid
                  from datastatisticsevent where eventtype =
                   'DASHBOARD_VIEW' and favoriteuid is not null 
                   and timestamp > (now() - INTERVAL '12 months') 
                   group by favoriteuid);

--type: details
--uid: dEwPGTpXYY2
--name:  assessment_dashboards_no_views_1y_D
--description:  Dashboards not viewed in the past year
SELECT uid,name from dashboard 
where not uid in (select favoriteuid
                  from datastatisticsevent where eventtype =
                   'DASHBOARD_VIEW' and favoriteuid is not null 
                   and timestamp > (now() - INTERVAL '12 months') 
                   group by favoriteuid);

