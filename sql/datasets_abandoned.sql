--type: summary
--uid: jliUzKxgkkH
--name: datasets_abandoned_S
--description: Data sets that have not been changed in last 100 days and are assigned to 1 or less orgunits
--detail_uid: Uj63Zrxixeq
select 'dataset_abandoned' as indicator,
count(*)::varchar as value ,
(100*count(*)/(select count(*) from dataset)) || '%' as percent,
'Data sets that have not been changed in last 100 days and are assigned to 1 or less orgunits' as description
from dataset
where date_part('day', now() - lastupdated::date) > 100 and
(datasetid not in (select datasetid from datasetsource)
or datasetid in (select datasetid from datasetsource group by datasetid having count(*) = 1));


--type: details
--uid: Uj63Zrxixeq
--name: datasets_abandoned_D
--description: Abandoned datasets
SELECT uid,name from dataset
where date_part('day', now() - lastupdated::date) > 100 and
(datasetid not in (select datasetid from datasetsource)
or datasetid in (select datasetid from datasetsource group by datasetid having count(*) = 1));
ORDER BY name;
