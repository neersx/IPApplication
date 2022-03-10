-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_OADestroy
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipu_OADestroy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipu_OADestroy.'
	Drop procedure [dbo].[ipu_OADestroy]
end
print '**** Creating Stored Procedure dbo.ipu_OADestroy...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go


CREATE PROCEDURE dbo.ipu_OADestroy  
			@pnObjectToken 		int
WITH EXECUTE AS 'INPROTECH_BUILTIN'
as
-- PROCEDURE :	ipu_OADestroy 
-- VERSION :	1
-- DESCRIPTION:	A wrapper for sp_OADestroy
-- COPYRIGHT:	Copyright 1993 - 2013 CPA Global
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27/05/2013	DL		13158		1		Procedure created


declare @nErrorCode	int

exec @nErrorCode = sp_OADestroy @pnObjectToken

return @nErrorCode

go


grant execute on dbo.ipu_OADestroy to public
go
