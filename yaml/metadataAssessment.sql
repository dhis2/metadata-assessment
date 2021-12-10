-- DATA SET
with ds_lastupdate as (select datasetid, avg(date_part('day', pe.enddate::timestamp - pe.startdate::timestamp))::int as interval from dataset ds left join period pe using(periodtypeid) group by datasetid), 
ds_period as (select datasetid, dataelementid, periodid from dataset ds left join period pe using(periodtypeid) left join datasetelement using(datasetid) where date_part('day', now() - pe.enddate::timestamp)::int <= 3*date_part('day', pe.enddate::timestamp - pe.startdate::timestamp)::int)

select 'dataset_count' as indicator, count(*)::varchar as value,'100%' as percent, 'Total number of data sets' as description from dataset

union all

select 'dataset_abandoned',count(*)::varchar , (100*count(*)/(select count(*) from dataset))||'%' as percent, 'Data sets that have not been changed in last 100 days and are assigned to 1 or less orgunits' from dataset where date_part('day', now() - lastupdated::date) > 100 and (datasetid not in (select datasetid from datasetsource) or datasetid in (select datasetid from datasetsource group by datasetid having count(*) = 1))

union all

select 'dataset_noupdateddata', count(*)::varchar, (100*count(*)/(select count(*) from dataset))::varchar || '%', 'Data sets with no data values with lastupdated date within the last 3 periods (based on data set period type). Note: this is not taking into account the reporting period.' from dataset ds where datasetid not in (select datasetid from datasetelement left join datavalue dv using(dataelementid) left join ds_lastupdate using(datasetid) where date_part('day', now() - dv.lastupdated::timestamp) < ds_lastupdate.interval*3)

union all 

select 'dataset_nonewdata', count(*)::varchar, (100*count(*)/(select count(*) from dataset))::varchar || '%', 'Data sets with no data values in the last 3 periods (based on data set period type).' from dataset where datasetid not in (select distinct datasetid from ds_period where (dataelementid,periodid) in (select dataelementid, periodid from datavalue) group by datasetid);


-- DATA ELEMENT
with ds_period as (select datasetid, dataelementid, periodid from dataset ds left join period pe using(periodtypeid) left join datasetelement using(datasetid) where date_part('day', now() - pe.enddate::timestamp)::int <= 3*date_part('day', pe.enddate::timestamp - pe.startdate::timestamp)::int)

select 'dataelement_count' as indicator, count(*)::varchar as value,'100%' as percent, 'Total number of data elements' as description from dataelement

union all

select 'dataelement_nongrouped', count(*)::varchar, (100*count(*)/(select count(*) from dataelement))::varchar || '%', 'Data elements not in any data element groups.' from dataelement where domaintype = 'AGGREGATE' and dataelementid not in (select dataelementid from dataelementgroupmembers)

union all

select 'dataelement_abandoned',count(*)::varchar , (100*count(*)/(select count(*) from dataelement where domaintype = 'AGGREGATE'))||'%' as percent, 'Aggregate data elements that have not been changed in last 100 days and do not have any data values' from dataelement where domaintype = 'AGGREGATE' and dataelementid not in (select dataelementid from datavalue group by dataelementid) and date_part('day', now() - lastupdated::date) > 100

union all

select 'dataelement_noassign',count(*)::varchar , (100*count(*)/(select count(*) from dataelement where domaintype = 'AGGREGATE'))||'%' as percent, 'Aggregate data elements assigned to 1 or less orgunit' from dataelement where (dataelementid not in (select dataelementid from datasetelement)) or (dataelementid in (select dataelementid from datasetelement where datasetid not in (select datasetid from datasetsource)) or  (dataelementid in (select dataelementid from dataelement de left join datasetelement dse using(dataelementid) left join datasetsource dss using(datasetid) group by dataelementid having count(dss.*) = 1)))


union all

select 'dataelement_nongrouped_newdata', count(*)::varchar, (100*count(*)/(select count(*) from dataelement where domaintype = 'AGGREGATE' ))::varchar || '%', 'Aggregate data elements with data values in the last 3 periods (based on data set period type) that are not in any groups.'  from dataelement where domaintype = 'AGGREGATE' and dataelementid in (select distinct dataelementid from ds_period where (dataelementid,periodid) in (select dataelementid, periodid from datavalue) group by dataelementid) and dataelementid not in (select dataelementid from dataelementgroupmembers)

union all

select 'dataelement_nodata', count(*)::varchar , (100*count(*)/(select count(*) from dataelement where domaintype = 'AGGREGATE'))||'%' as percent, 'Aggregate data elements with NO data values' from dataelement where domaintype = 'AGGREGATE' and dataelementid not in (select dataelementid from datavalue group by dataelementid)

union all

select 'dataelement_nonewdata', count(*)::varchar, (100*count(*)/(select count(*) from dataelement where domaintype = 'AGGREGATE' ))::varchar || '%', 'Aggregate data elements with no data values in the last 3 periods (based on data set period type).' from dataelement where domaintype = 'AGGREGATE' and dataelementid not in (select distinct dataelementid from ds_period where (dataelementid,periodid) in (select dataelementid, periodid from datavalue) group by dataelementid)

union all

select 'dataelement_noanalysis', count(*)::varchar , (100*count(*)/(select count(*) from dataelement where domaintype = 'AGGREGATE'))||'%' as percent, 'Aggregate data elements that are not used in any favourites, either directly or through indicators' from dataelement where domaintype = 'AGGREGATE' and dataelementid not in (select de.dataelementid from dataelement de left join indicator ind on (ind.numerator like '%'||de.uid||'%' or ind.denominator like '%'||de.uid||'%') where ind.name is not null and ind.indicatorid in (select indicatorid from datadimensionitem where indicatorid > 0)) and dataelementid not in (select dataelementoperand_dataelementid from datadimensionitem where dataelementoperand_dataelementid > 0) and dataelementid not in (select dataelementid from datadimensionitem where dataelementid > 0);


-- INDICATOR
select 'indicator_count' as indicator, count(*)::varchar as value, '100%' as percent, 'Total number of indicators' as description from indicator

union all

select 'indicator_nongrouped',count(*)::varchar, (100*count(*)/(select count(*) from indicator))||'%', 'Indicators not in any groups' from indicator where indicatorid not in (select indicatorid from indicatorgroupmembers)

union all

select 'indicator_nouse',count(*)::varchar, (100*count(*)/(select count(*) from indicator))||'%', 'Indicators not used in favourites OR data sets' from indicator where indicatorid not in (select indicatorid from datadimensionitem where indicatorid > 0) and indicatorid not in (select indicatorid from datasetindicators)

union all

select 'indicator_noanalysis',count(*)::varchar, (100*count(*)/(select count(*) from indicator))||'%', 'Indicators not used in favourites' from indicator where indicatorid not in (select indicatorid from datadimensionitem where indicatorid > 0);


-- USERS
select 'user_count' as indicator, count(*)::varchar as value, '100%' as percent, 'Total number of users' as description from users

union all

select 'user_active', count(*)::varchar , (100*count(*)/(select count(*) from users))||'%', 'Users logged in during last 30 days' from users where date_part('day', now() - lastlogin::date) <= 30

union all

select 'user_active1y', count(*)::varchar , (100*count(*)/(select count(*) from users))||'%', 'Users logged in during last 365 days' from users where date_part('day', now() - lastlogin::date) <= 365

union all

select 'user_active1yenabled', count(*)::varchar , (100*count(*)/(select count(*) from users))||'%', 'Users not logged in during last 365 days, but are not disabled' from users where date_part('day', now() - lastlogin::date) > 365 and disabled = false;


-- ORGUNITS
with orgunit_compulsory_group_count as (select organisationunitid as orgunitid,count(ogs.orgunitgroupsetid) as actual,(select count(*) as expected from orgunitgroupset where compulsory = true) from orgunitgroupsetmembers ogsm left join orgunitgroupset ogs using(orgunitgroupsetid) left join orgunitgroupmembers ogm using(orgunitgroupid) where ogs.compulsory = true group by ogm.organisationunitid) 

select 'orgunit_count' as indicator, count(*)::varchar as value, '100%' as percent, 'Total number of orgunits' as description from organisationunit

union all

select 'orgunit_assignment' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from organisationunit))||'%', 'Orgunits at level 5 or below with no data sets assigned' as description from organisationunit where hierarchylevel > 4 and organisationunitid not in (select sourceid from datasetsource)

union all

select 'orgunit_notincompulsory', count(*)::varchar , (100*count(*)/(select count(*) from organisationunit))||'%', 'Orgunits that are not in all compulsory orgunit group sets' from orgunit_compulsory_group_count where actual != expected

union all

select 'orgunit_assignednotused_combo', 
count(*)::varchar , 
(100*count(*)/(select count(*) from datasetsource))||'%',
 'Orgunit-dataset combinations with no complete data sets' from
  datasetsource where (datasetid,sourceid) 
  not in (select datasetid,sourceid from completedatasetregistration group by datasetid,sourceid)

union all

select 'orgunit_assignednotused', count(*)::varchar , (100*count(*)/(select count(*) from organisationunit))||'%', 'Orgunits that have not reported on all data sets that are assigned to them.' from organisationunit where organisationunitid in (select sourceid from datasetsource where (datasetid,sourceid) not in (select datasetid,sourceid from completedatasetregistration group by datasetid,sourceid));

-- DASHBOARD
select 'dashboard_count' as indicator, count(*)::varchar as value, '100%' as percent, 'Total number of dashboards' as description from dashboard

union all

select 'dashboard_empty', count(*)::varchar, (100*count(*)/(select count(*) from dashboard))||'%', 'Dashboards with no content' from dashboard where dashboardid not in (select dashboardid from dashboard_items)

union all 

select 'dashboard_private', count(*)::varchar, (100*count(*)/(select count(*) from dashboard))||'%', 'Dashboards that are private' from dashboard where publicaccess = '--------' and dashboardid not in (select dashboardid from dashboardusergroupaccesses union select dashboardid from dashboarduseraccesses)

union all

select 'dashboard_shared10+', 
count(*)::varchar, 
(100*count(*)/(select count(*) from dashboard))||'%',
 'Dashboards shared with 10 or more people' 
 from dashboard where dashboardid 
 in (select dash.dashboardid from dashboardusergroupaccesses
  left join dashboard dash using(dashboardid) 
  left join usergroupaccess uga using (usergroupaccessid) 
  left join usergroupmembers ugm using (usergroupid) 
  group by dash.dashboardid having count(*) >= 5) OR publicaccess like 'r%'

union all

select 'dashboard_used' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from dashboard))||'%', 'Dashboards that have been viewed 1 time or less after 2017' as description from dashboard where uid not in (select favoriteuid from datastatisticsevent where eventtype = 'DASHBOARD_VIEW' and favoriteuid is not null and extract(year from timestamp) >= 2018 group by favoriteuid having count(*) >1)

union all 

select 'dashboard_used1y' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from dashboard))||'%', 'Dashboards that have not been opened in the last 12 months' as description from dashboard where not uid in (select favoriteuid from datastatisticsevent where eventtype = 'DASHBOARD_VIEW' and favoriteuid is not null and timestamp > (now() - INTERVAL '12 months') group by favoriteuid)

union all 

select 'dashboard_public' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from dashboard))||'%', 'Dashboards that are publicly viewable' as description from dashboard where publicaccess like 'r%'

union all

select 'dashboard_used_public' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from dashboard where publicaccess like 'r%'))||'%', 'Public dashboards that have been viewed 1 time or less after 2017' as description from dashboard where publicaccess like 'r%' and uid not in (select favoriteuid from datastatisticsevent where eventtype = 'DASHBOARD_VIEW' and favoriteuid is not null and extract(year from timestamp) >= 2018 group by favoriteuid having count(*) >1)

union all

select 'dashboard_used1y_public' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from dashboard where publicaccess like 'r%'))||'%', 'Public dashboards that have not been opened in the last 12 months' as description from dashboard where publicaccess like 'r%' and uid not in (select favoriteuid from datastatisticsevent where eventtype = 'DASHBOARD_VIEW' and favoriteuid is not null and timestamp > (now() - INTERVAL '12 months') group by favoriteuid);


-- CHARTS
select 'chart_count' as indicator, count(*)::varchar as value, '100%' as percent, 'Total number of charts' as description from chart

union all

select 'chart_used' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from chart))||'%', 'Charts that have been viewed 1 time or less after 2017' as description from chart where uid not in (select favoriteuid from datastatisticsevent where eventtype = 'CHART_VIEW' and favoriteuid is not null and extract(year from timestamp) >= 2018 group by favoriteuid having count(*) >1)

union all 

select 'chart_used1y' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from chart))||'%', 'Charts that have not been opened in the last 12 months' as description from chart where uid not in (select favoriteuid from datastatisticsevent where eventtype = 'CHART_VIEW' and favoriteuid is not null and timestamp > (now() - INTERVAL '12 months') group by favoriteuid)

union all 

select 'chart_public' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from chart))||'%', 'Charts that are publicly viewable' as description from chart where publicaccess like 'r%'

union all

select 'chart_used_public' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from chart where publicaccess like 'r%'))||'%', 'Public charts that have been viewed 1 time or less after 2017' as description from chart where publicaccess like 'r%' and uid not in (select favoriteuid from datastatisticsevent where eventtype = 'CHART_VIEW' and favoriteuid is not null and extract(year from timestamp) >= 2018 group by favoriteuid having count(*) >1)

union all

select 'chart_used1y_public' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from chart where publicaccess like 'r%'))||'%', 'Public charts that have not been opened in the last 12 months' as description from chart where publicaccess like 'r%' and uid not in (select favoriteuid from datastatisticsevent where eventtype = 'CHART_VIEW' and favoriteuid is not null and timestamp > (now() - INTERVAL '12 months') group by favoriteuid);



-- REPORT TABLES
select 'reporttable_count' as indicator, count(*)::varchar as value, '100%' as percent, 'Total number of report tables' as description from reporttable

union all

select 'reporttable_used' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from reporttable))||'%', 'Pivot tables that have been viewed 1 time or less after 2017' as description from reporttable where uid not in (select favoriteuid from datastatisticsevent where eventtype = 'REPORT_TABLE_VIEW' and favoriteuid is not null and extract(year from timestamp) >= 2018 group by favoriteuid having count(*) >1)

union all 

select 'reporttable_used1y' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from reporttable))||'%', 'Pivot tables that have not been opened in the last 12 months' as description from reporttable where uid not in (select favoriteuid from datastatisticsevent where eventtype = 'REPORT_TABLE_VIEW' and favoriteuid is not null and timestamp > (now() - INTERVAL '12 months') group by favoriteuid)

union all 

select 'reporttable_public' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from reporttable))||'%', 'Pivot tables that are publicly viewable' as description from reporttable where publicaccess like 'r%'

union all

select 'reporttable_used_public' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from reporttable where publicaccess like 'r%'))||'%', 'Public pivot tables that have been viewed 1 time or less after 2017' as description from reporttable where publicaccess like 'r%' and uid not in (select favoriteuid from datastatisticsevent where eventtype = 'REPORT_TABLE_VIEW' and favoriteuid is not null and extract(year from timestamp) >= 2018 group by favoriteuid having count(*) >1)

union all

select 'reporttable_used1y_public' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from reporttable where publicaccess like 'r%'))||'%', 'Public pivot tables that have not been opened in the last 12 months' as description from reporttable where publicaccess like 'r%' and uid not in (select favoriteuid from datastatisticsevent where eventtype = 'REPORT_TABLE_VIEW' and favoriteuid is not null and timestamp > (now() - INTERVAL '12 months') group by favoriteuid);



-- MAP
select 'map_count' as indicator, count(*)::varchar as value, '100%' as percent, 'Total number of maps' as description from map

union all

select 'map_used' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from map))||'%', 'maps that have viewed 1 time or less after 2017' as description from map where uid not in (select favoriteuid from datastatisticsevent where eventtype = 'MAP_VIEW' and favoriteuid is not null and extract(year from timestamp) >= 2018 group by favoriteuid having count(*) >1)

union all 

select 'map_used1y' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from map))||'%', 'maps that have not been opened in the last 12 months' as description from map where uid not in (select favoriteuid from datastatisticsevent where eventtype = 'MAP_VIEW' and favoriteuid is not null and timestamp > (now() - INTERVAL '12 months') group by favoriteuid)

union all 

select 'map_public' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from map))||'%', 'maps that are publicly viewable' as description from map where publicaccess like 'r%'

union all

select 'map_used_public' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from map where publicaccess like 'r%'))||'%', 'Public maps that have been viewed 1 time or less after 2017' as description from map where publicaccess like 'r%' and uid not in (select favoriteuid from datastatisticsevent where eventtype = 'MAP_VIEW' and favoriteuid is not null and extract(year from timestamp) >= 2018 group by favoriteuid having count(*) >1)

union all

select 'map_used1y_public' as indicator, count(*)::varchar as value, (100*count(*)/(select count(*) from map where publicaccess like 'r%'))||'%', 'Public maps that have not been opened in the last 12 months' as description from map where publicaccess like 'r%' and uid not in (select favoriteuid from datastatisticsevent where eventtype = 'MAP_VIEW' and favoriteuid is not null and timestamp > (now() - INTERVAL '12 months') group by favoriteuid);