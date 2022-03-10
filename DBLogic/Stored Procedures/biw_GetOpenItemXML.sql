-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetOpenItemXML] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetOpenItemXML]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetOpenItemXML].'
	drop procedure dbo.[biw_GetOpenItemXML]
end
print '**** Creating procedure dbo.[biw_GetOpenItemXML]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go
SET CONCAT_NULL_YIELDS_NULL OFF
go 

create procedure dbo.[biw_GetOpenItemXML]
				@pnUserIdentityId	int,		-- Mandatory
				@psCulture		nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnItemEntityKey		int,		-- Mandatory
				@pnItemTransNo		int,		-- Mandatory
				@pnXMLType		tinyint
as
-- PROCEDURE :	biw_GetOpenItemXML
-- VERSION :	1
-- DESCRIPTION:	A procedure to get open item xml data for e-billing.
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions Australia Pty Limited
-- MODIFICATION
-- Date		Who	RFC	Version Description
-- -----------	-------	------	------- ----------------------------------------------- 
-- 04 Aug 2010	AT	RFC9556	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @sSQLString nvarchar(4000)
declare @nErrorCode int

Set @nErrorCode = 0

Set @sSQLString = "Select OPENITEMXML 
		from OPENITEMXML
		where ITEMENTITYNO = @pnItemEntityKey
		and ITEMTRANSNO = @pnItemTransNo
		and XMLTYPE = @pnXMLType"

exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnItemEntityKey	int,
		@pnItemTransNo		int,
		@pnXMLType		tinyint',
		@pnItemEntityKey	= @pnItemEntityKey,
		@pnItemTransNo		= @pnItemTransNo,
		@pnXMLType		= @pnXMLType

return @nErrorCode
go

grant execute on dbo.[biw_GetOpenItemXML]  to public
go
