-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_OAGetProperty
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipu_OAGetProperty]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipu_OAGetProperty.'
	Drop procedure [dbo].[ipu_OAGetProperty]
end
print '**** Creating Stored Procedure dbo.ipu_OAGetProperty...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

CREATE PROCEDURE dbo.ipu_OAGetProperty  
			@pnObjectToken 		int,	
			@psPropertyName		nvarchar(4000),
			@pnPropertyValue	int out,
			@pnIndex			int 	= null
WITH EXECUTE AS 'INPROTECH_BUILTIN'
as
-- PROCEDURE :	ipu_OAGetProperty 
-- VERSION :	1
-- DESCRIPTION:	A wrapper for sp_OAGetProperty  
-- COPYRIGHT:	Copyright 1993 - 2013 CPA Global
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27/05/2013	DL		13158	1		Procedure created

declare @nErrorCode	int

exec @nErrorCode =  sp_OAGetProperty @pnObjectToken, @psPropertyName, @pnPropertyValue OUT, @pnIndex

return @nErrorCode


go

grant execute on dbo.ipu_OAGetProperty   to public
go
