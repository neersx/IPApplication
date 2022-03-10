-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_OAMethod
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipu_OAMethod]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipu_OAMethod.'
	Drop procedure [dbo].[ipu_OAMethod]
end
print '**** Creating Stored Procedure dbo.ipu_OAMethod...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go


CREATE PROCEDURE dbo.ipu_OAMethod  
			@pnObjectToken 		int,	
			@psMethodName		nvarchar(4000),
			@pnReturnValue		int	out,
			@psParameterName	nvarchar(4000) 
WITH EXECUTE AS 'INPROTECH_BUILTIN'
as
-- PROCEDURE :	ipu_OAMethod 
-- VERSION :	1
-- DESCRIPTION:	A wrapper for sp_OAMethod
-- COPYRIGHT:	Copyright 1993 - 2013 CPA Global
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27/05/2013	DL		13158		1		Procedure created

declare @nErrorCode	int

exec @nErrorCode =  sp_OAMethod @pnObjectToken, @psMethodName, @pnReturnValue out, @psParameterName 

return @nErrorCode



go

grant execute on dbo.ipu_OAMethod to public
go
