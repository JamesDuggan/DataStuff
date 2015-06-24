-- as a pre-deploy script target db is database context
declare @assembly varbinary(max) = %assembly_hex%
      , @load bit = 'false';
      
-- most expensive operation is assembly load. And assembly must be loaded to verify if SNK has changed.
-- is assembly must be loaded then for simplicity recreate anew
if exists(select 1 from sys.assemblies where name = '$(TheCartBeforeTheHorseClr)') begin
   -- has the assembly changed
   if not exists(select 1 from sys.assembly_files where name = '$(TheCartBeforeTheHorseClr)' and content = @assembly) begin
      -- assembly has changed.
      set @load = 'true';      
   end
end
else begin
   set @load = 'true'; 
end

declare @template nvarchar(max) =
N'
use master;
if exists(select 1 from sys.server_principals where name = ''$(TheCartBeforeTheHorseClr)_Login'') begin
   raiserror(''(master) dropping login [$(TheCartBeforeTheHorseClr)_Login]'', 10, 1) with nowait;
   drop login [$(TheCartBeforeTheHorseClr)_Login];
end 
if exists(select 1 from sys.asymmetric_keys where name = ''$(TheCartBeforeTheHorseClr)_Key'') begin
   raiserror(''(master) dropping asymmetric key [$(TheCartBeforeTheHorseClr)_Key]'', 10, 1) with nowait;
   drop asymmetric key [$(TheCartBeforeTheHorseClr)_Key]; 
end 
if exists(select 1 from sys.assemblies where name = ''$(TheCartBeforeTheHorseClr)'') begin
   raiserror(''(master) dropping assembly [$(TheCartBeforeTheHorseClr)]'', 10, 1) with nowait;
   drop assembly [$(TheCartBeforeTheHorseClr)];
end
begin try
raiserror(''(master) loading assembly [$(TheCartBeforeTheHorseClr)]'', 10, 1) with nowait;
create assembly [$(TheCartBeforeTheHorseClr)]
from ' + convert(nvarchar(max), @assembly, 1) +
N'  
with   permission_set = safe;

raiserror(''(master) creating asymmetric key [$(TheCartBeforeTheHorseClr)_Key]'', 10, 1) with nowait;
create asymmetric key [$(TheCartBeforeTheHorseClr)_Key] from assembly [$(TheCartBeforeTheHorseClr)]; 

raiserror(''(master) creating login [$(TheCartBeforeTheHorseClr)_Login]'', 10, 1) with nowait;
create login [$(TheCartBeforeTheHorseClr)_Login] from asymmetric key [$(TheCartBeforeTheHorseClr)_Key]; 
grant external access assembly to [$(TheCartBeforeTheHorseClr)_Login]; 

-- clean up the assembly
raiserror(''(master) cleanup: removing assembly [$(TheCartBeforeTheHorseClr)]'', 10, 1) with nowait;
drop assembly [$(TheCartBeforeTheHorseClr)];
end try
begin catch
   declare @errNumber int = ERROR_NUMBER()
         , @errSeverity int = ERROR_SEVERITY()
         , @errState int = ERROR_STATE()
         , @errProcedure sysname = isnull(ERROR_PROCEDURE(), ''unknown'')
         , @errLine int = ERROR_LINE()
         , @errMessage varchar(8000) = ERROR_MESSAGE();

   raiserror(''Error %d:%d:%d (%s @line:%d): %s'', 16, 1, @errNumber, @errSeverity, @errState, @errProcedure, @errLine, @errMessage); 
end catch
'

if @load = 'true'
   exec(@template);    
