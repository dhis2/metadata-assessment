--type: summary
--uid: hN9QvyXRdQC
--name: des_no_orgunits_S
--description: Aggregate data elements assigned to 1 or less orgunit
--detail_uid: xdx9XquVi30
WITH des_no_orgunits AS (
select uid,name from dataelement where (dataelementid not in (select dataelementid from datasetelement)) 
or (dataelementid in
 (select dataelementid from datasetelement where datasetid not in (select datasetid from datasetsource))
 or  (dataelementid in (select dataelementid from dataelement de left join datasetelement dse using (dataelementid)
 left join datasetsource dss using (datasetid) group by dataelementid having count(dss.*) = 1))) order by name
)
SELECT 'des_no_orgunits' as indicator,
COUNT(*) as value,
ROUND(( COUNT(*)::numeric / ( SELECT COUNT(*) FROM dataelement where domaintype = 'AGGREGATE' )::numeric) * 100)::varchar || '%' as percent,
'Aggregate data elements assigned to 1 or less orgunit' as description
FROM des_no_orgunits;


--type: details
--uid: xdx9XquVi30
--name: des_no_orgunits_D
--description: Aggregate data elements assigned to 1 or less orgunit
select uid,name from dataelement where (dataelementid not in (select dataelementid from datasetelement)) 
or (dataelementid in
 (select dataelementid from datasetelement where datasetid not in (select datasetid from datasetsource))
 or  (dataelementid in (select dataelementid from dataelement de left join datasetelement dse using (dataelementid)
 left join datasetsource dss using (datasetid) group by dataelementid having count(dss.*) = 1))) order by name
