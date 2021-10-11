--type: summary
--uid: SdTkaAOPwFM
--name: dataset_summary_S
--description: Total number of data sets
--detail_uid: Ijyn3sXlmgw
with ds_lastupdate as (select datasetid, avg(date_part('day', pe.enddate::timestamp - pe.startdate::timestamp))::int as interval from dataset ds
left join period pe using(periodtypeid) group by datasetid),
ds_period as (select datasetid, dataelementid, periodid from dataset ds
left join period pe using(periodtypeid)
left join datasetelement using(datasetid) where date_part('day', now() - pe.enddate::timestamp)::int <= 
3*date_part('day', pe.enddate::timestamp - pe.startdate::timestamp)::int)
select 'dataset_count' as indicator,
count(*)::varchar as value,
'100%' as percent,
'Total number of data sets' as description from dataset;


--type: details
--uid: Ijyn3sXlmgw
--name: dataset_summary_D
--description: Datasets in the system
SELECT uid,name from dataset
ORDER BY name;
