--type: summary
--uid: lY1DmLxMl7h
--name: aggregate_des_no_analysis_S
--description: Aggregate data elements not used in any favourites (directly or through indicators)
--detail_uid: EFyNHwRu9w8
WITH des_no_analysis AS (
select name,uid from dataelement where domaintype = 'AGGREGATE' and
dataelementid not in (select de.dataelementid from dataelement de
left join indicator ind on (ind.numerator like '%'||de.uid||'%' or
ind.denominator like '%'||de.uid||'%') where ind.name is not null
and ind.indicatorid in (select indicatorid from datadimensionitem where indicatorid > 0))
and dataelementid not in (select dataelementoperand_dataelementid from datadimensionitem
where dataelementoperand_dataelementid > 0) and dataelementid
not in (select dataelementid from datadimensionitem where dataelementid > 0) order by name
)
SELECT 'agg_des_no_analysis' as indicator,
COUNT(*) as value,
ROUND(( COUNT(*)::numeric / ( SELECT COUNT(*) FROM dataelement where domaintype = 'AGGREGATE' )::numeric) * 100)::varchar || "%" as percent,
'Aggregate data elements not used in any favourites (directly or through indicators)' as description
FROM des_no_analysis;


--type: details
--uid: EFyNHwRu9w8
--name: aggregate_des_no_analysis_D
--description: Dashboards with 1 or fewer views over the past three years
select name,uid from dataelement where domaintype = 'AGGREGATE' and
dataelementid not in (select de.dataelementid from dataelement de
left join indicator ind on (ind.numerator like '%'||de.uid||'%' or
ind.denominator like '%'||de.uid||'%') where ind.name is not null
and ind.indicatorid in (select indicatorid from datadimensionitem where indicatorid > 0))
and dataelementid not in (select dataelementoperand_dataelementid from datadimensionitem
where dataelementoperand_dataelementid > 0) and dataelementid
not in (select dataelementid from datadimensionitem where dataelementid > 0) order by name
