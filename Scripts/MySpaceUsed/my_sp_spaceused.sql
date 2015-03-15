declare @schema sysname = ''
      , @table  sysname = ''

select quotename(OBJECT_SCHEMA_NAME(p.object_id)) + '.' + quotename(OBJECT_NAME(p.object_id)) [table_name] 
     , p.index_id
     , i.name [index_name]
     , p.rows
     , au.type_desc
     , convert(decimal(10, 3), au.total_pages /128.) [reserved_mb]
     , convert(decimal(10, 3), au.data_pages /128.) [data_mb]
     , au.data_pages
     , convert(decimal(10, 3), (au.used_pages - au.data_pages) /128.) [non_data_mb]
     , convert(decimal(10, 3), (au.total_pages - au.used_pages) /128.) [unused_mb]
from   sys.partitions p
join   sys.allocation_units au on p.hobt_id = au.container_id
join   sys.indexes i on p.object_id = i.object_id and p.index_id = i.index_id
where  p.object_id = object_id(@schema + '.' + @table);
