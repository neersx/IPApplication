-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_OAStop
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipu_OAStop]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipu_OAStop.'
	Drop procedure [dbo].[ipu_OAStop]
end
print '**** Creating Stored Procedure dbo.ipu_OAStop...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

CREATE PROCEDURE dbo.ipu_OAStop
WITH EXECUTE AS 'INPROTECH_BUILTIN'
as
-- PROCEDURE :	ipu_OAStop
-- VERSION :	1
-- DESCRIPTION:	A wrapper for sp_OAStop
-- COPYRIGHT:	Copyright 1993 - 2013 CPA Global
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27/05/2013	DL		13158	1		Procedure created
-- 29/05/2013	AT		13158	2		Removed trailing spaces in sp name

declare @nErrorCode	int

exec @nErrorCode =  sp_OAStop

return @nErrorCode

go

grant execute on dbo.ipu_OAStop   to public
go
