if object_id('[dbo].[TaskTimeouts]') is not null 
   drop table [dbo].[TaskTimeouts];

-- timeout (sec) per task
create table [dbo].[TaskTimeouts] 
(
       TaskName varchar(100)
     , TimeoutSeconds int
     , constraint [PK_TaskTimeouts] primary key(TaskName)
);
go

if object_id('[dbo].[AsyncTaskStates]') is not null 
   drop table [dbo].[AsyncTaskStates];

-- task state for a process. In this case the interesting states are 0=pending, 1=complete, 4=timeout
create table [dbo].[AsyncTaskStates] 
(
       ProcessId uniqueidentifier
     , TaskName varchar(100)
     , StateId tinyint
     , StartedAt datetime
     , CompletedAt datetime
     , constraint [PK_AsyncTaskStates] primary key(ProcessId, TaskName)
);
go

-- proposed index to support fnding pending tasks for timeout
create nonclustered index [IX_AsyncTaskStates_StartedAt] 
on    [dbo].[AsyncTaskStates]
      (
           [StartedAt] ASC
      )
      where 
      (
           [StateId]=(0)
      );
go

insert into [dbo].[TaskTimeouts] (TaskName, TimeoutSeconds)
values ('AsyncTask1', 10)
     , ('AsyncTask2', 10)
     , ('AsyncTask3', 10)
     , ('AsyncTask4', 10)
     , ('AsyncTask5', 10)
go

set nocount on;
declare @processId uniqueidentifier
      , @taskName varchar(100)
      , @i int = 0;

declare @tasks table(TaskName varchar(100));

while @i < 1000 begin
-- create process id as newid()
-- there may be 0-5 async tasks either complete (state=1) or still pending (state=0)
-- tasks will be created forward dated to simplify the data selection in tests later
   set @processId = newid();
   insert into @tasks
   select top(convert(int, floor(rand() * 1000)) %6) Taskname from dbo.TaskTimeouts;
   
   while exists(select 1 from @tasks) begin
      select top 1 @taskName = TaskName from @tasks;
      insert into [dbo].[AsyncTaskStates] (ProcessId, TaskName, StateId, StartedAt)
      select @processId, @taskName
           , convert(int, floor(rand() * 1000)) % 2
           , dateadd(s, convert(int, floor(rand() * 1000)), getdate());
      delete from @tasks where TaskName = @taskName;
   end
   
   set @i +=1;
end
go


-- select to verify proposed index
declare @minTimeoutSec int = (select min(TimeoutSeconds) from [dbo].[TaskTimeouts]);

select s.ProcessId, s.Taskname, s.StartedAt
from   [dbo].[AsyncTaskStates] s
join   [dbo].[TaskTimeouts] t on s.TaskName = t.TaskName 
where  s.StateId = 0
and    s.StartedAt < cast(dateadd(second, -@minTimeoutSec, getdate()) as datetime2(3))
and    datediff(second, s.StartedAt, getdate()) > t.TimeoutSeconds;
go


-- update implemented to find pending tasks for timeout 
declare @minTimeoutSec int = (select min(TimeoutSeconds) from [dbo].[TaskTimeouts]);

update s
set    CompletedAt = getdate()
     , StateId = 4

from   [dbo].[AsyncTaskStates] s
join   [dbo].[TaskTimeouts] t on s.TaskName = t.TaskName 
where  s.StateId = 0
and    s.StartedAt < cast(dateadd(second, -@minTimeoutSec, getdate()) as datetime2(3))
and    datediff(second, s.StartedAt, getdate()) > t.TimeoutSeconds;
go

-- index amendment
create nonclustered index [IX_AsyncTaskStates_StartedAt] 
on    [dbo].[AsyncTaskStates] 
      (
           [StartedAt] ASC
      )
      include
      (
           [StateId]
      )
      where 
      (
           [StateId]=(0)
      )
with  (drop_existing = on)
go
