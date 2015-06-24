create procedure [HorseAndCart].[DeleteXEventTargetFile]
       @targetFilePath [nvarchar](4000)
     , @sessionName [nvarchar](4000)
with execute as caller
as
external name [TheCartBeforeTheHorseClr].[TheCartBeforeTheHorse].[DeleteXEventSessionFile];
go
