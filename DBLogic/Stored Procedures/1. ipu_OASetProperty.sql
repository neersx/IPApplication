-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_OASetProperty
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipu_OASetProperty]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipu_OASetProperty.'
	Drop procedure [dbo].[ipu_OASetProperty]
end
print '**** Creating Stored Procedure dbo.ipu_OASetProperty...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

CREATE PROCEDURE dbo.ipu_OASetProperty  
			@pnObjectToken 		int,	
			@psPropertyName		nvarchar(4000),
			@psNewValue			nvarchar(4000),
			@pnIndex			int 	= null
WITH EXECUTE AS 'INPROTECH_BUILTIN'
as
-- PROCEDURE :	ipu_OASetProperty 
-- VERSION :	1
-- DESCRIPTION:	A wrapper for sp_OASetProperty  
-- COPYRIGHT:	Copyright 1993 - 2013 CPA Global
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27/05/2013	DL		13158	1		Procedure created

declare @nErrorCode	int

exec @nErrorCode =  sp_OASetProperty @pnObjectToken, @psPropertyName, @psNewValue

return @nErrorCode


go

grant execute on dbo.ipu_OASetProperty   to public
go
