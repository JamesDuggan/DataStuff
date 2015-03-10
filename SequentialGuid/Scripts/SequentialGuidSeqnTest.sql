use SequentialGuid;
go
/**
create a set of guids with int row id. 
On resorting data by inserted guid its accuracy can be determined by distance of new row id from inserted one.
**/
if object_id('SequentialGuidSeqnResults') is not null 
   truncate table SequentialGuidSeqnResults
else
   create table SequentialGuidSeqnResults (Id int not null, SequentialGuid uniqueidentifier not null);
go

with t1(i) as (select 1 union select 2)
   , t2(i) as (select t1.i from t1 cross join t1 t)
   , t3(i) as (select t2.i from t2 cross join t2 t)
   , t4(i) as (select t3.i from t3 cross join t3 t)
   , t5(i) as (select t4.i from t4 cross join t4 t)
   , t(Id) as (select row_number() over(order by (select null)) from t5)

insert into SequentialGuidSeqnResults 
select [Id]
     , dbo.NewSequentialGuidSeqn() [SequentialGuid]
from   t;
go

-- sequential guild distance summary
select [GuidType], min(Distance) [min_distance], max(Distance) [max_distance], avg(Distance) [avg_distance], isnull(stdev(Distance), 0) [stdev_distance]
from  (
      select 'SequentialGuidSeqn' [GuidType], abs(Id - row_number() over(order by [SequentialGuid])) Distance
      from   SequentialGuidSeqnResults
      ) t
group by 
      [GuidType];
       
-- output insert id and caculcated sequential guid order for graping
select Id [InsertOrder]
     , row_number() over(order by [SequentialGuid]) [SequentialGuidOrder]
from   SequentialGuidSeqnResults
order  by
       Id;
