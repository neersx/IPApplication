-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_OAGetErrorInfo
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipu_OAGetErrorInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipu_OAGetErrorInfo.'
	Drop procedure [dbo].[ipu_OAGetErrorInfo]
end
print '**** Creating Stored Procedure dbo.ipu_OAGetErrorInfo...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go


CREATE PROCEDURE dbo.ipu_OAGetErrorInfo  
			@pnObjectToken 		int = null,	
			@psSource		nvarchar(4000) = null out,
			@psDescription		nvarchar(4000) = null out,
			@psHelpFile		nvarchar(4000) = null out,
			@pnHelpId		int 	= null out
WITH EXECUTE AS 'INPROTECH_BUILTIN'
as
-- PROCEDURE :	ipu_OAGetErrorInfo 
-- VERSION :	2
-- DESCRIPTION:	A wrapper for sp_OAGetErrorInfo  
-- COPYRIGHT:	Copyright 1993 - 2013 CPA Global
-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27/05/2013	DL		13158	1	Procedure created
-- 31/07/2013	vql		DR536	2	Do not make parameters mandatory. 

declare @nErrorCode	int

exec @nErrorCode =  sp_OAGetErrorInfo @pnObjectToken, @psSource out, @psDescription out, @psHelpFile out, @pnHelpId out

return @nErrorCode


go

grant execute on dbo.ipu_OAGetErrorInfo   to public
go
