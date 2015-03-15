if object_id('tempdb..#space_used') is null
   create table #space_used
   (
          database_name varchar(128) not null
        , schema_name varchar(128) not null
        , table_name varchar(128) not null
        , index_id int  not null
        , index_name varchar(128) not null
        , row_count bigint not null
        , alloc_type_desc varchar(50) not null
        , reserved_mb decimal(10, 3) not null
        , data_mb decimal(10, 3) not null
        , data_pages	bigint not null   
        , non_data_mb decimal(10, 3) not null    
        , unused_mb decimal(10, 3) not null
        , compression_desc varchar(10) not null
        , stats_last_updated datetime null
   )
else
   truncate table #space_used;

insert into #space_used 
select 
       db_name() [database_name]
     , object_schema_name(t.object_id) [schema_name]
     , t.name [table_name]
     , p.index_id
     , case when p.index_id > 0 then i.name else 'HEAP' end [index_name]
     , p.rows [row_count]
     , au.type_desc [alloc_type_desc]
     , convert(decimal(10, 3), au.total_pages /128.) [reserved_mb]
     , convert(decimal(10, 3), au.data_pages /128.) [data_mb]
     , au.data_pages
     , convert(decimal(10, 3), (au.used_pages - au.data_pages) /128.) [non_data_mb]
     , convert(decimal(10, 3), (au.total_pages - au.used_pages) /128.) [unused_mb]
     , p.data_compression_desc [compression_desc]
     , stats_date(t.object_id, p.index_id) [stats_last_updated]
from   sys.tables t 
join   sys.partitions p on p.object_id = t.object_id
join   sys.allocation_units au on p.hobt_id = au.container_id
join   sys.indexes i on p.object_id = i.object_id and p.index_id = i.index_id;
go

select * from #space_used
--where  schema_name in ('', '')
--order  by reserved_mb desc