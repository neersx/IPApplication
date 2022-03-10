-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_OACreate --
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipu_OACreate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipu_OACreate.'
	Drop procedure [dbo].[ipu_OACreate]
end
print '**** Creating Stored Procedure dbo.ipu_OACreate...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

CREATE PROCEDURE dbo.ipu_OACreate  
			@psProgId			nvarchar(4000),
			@pnObjectToken 			int    out,				
			@pnContext			int 	= null
WITH EXECUTE AS 'INPROTECH_BUILTIN'
as
-- PROCEDURE :	ipu_OACreate 
-- VERSION :	2
-- DESCRIPTION:	A wrapper for sp_OACreate
-- COPYRIGHT:	Copyright 1993 - 2013 CPA Global
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27/05/2013	DL	13158	1	Procedure created
-- 23/05/2016	DL	61539	2	Error on adding an Official no. to a Case.  (restore param @psProgId from nvarchar(max) to nvarchar(4000))		

declare @nErrorCode	int

exec @nErrorCode = sp_OACreate @psProgId, @pnObjectToken out

return @nErrorCode

go

grant execute on dbo.ipu_OACreate   to public
go
