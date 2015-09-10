create schema [RememberToDeleteMe] authorization [dbo];
go

create procedure [RememberToDeleteMe].[SomethingToTest]
as

select 'I worked' [Result]
go