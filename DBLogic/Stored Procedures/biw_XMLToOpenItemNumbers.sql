-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_XMLToOpenItemNumbers] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_XMLToOpenItemNumbers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_XMLToOpenItemNumbers].'
	drop procedure dbo.[biw_XMLToOpenItemNumbers]
end
print '**** Creating procedure dbo.[biw_XMLToOpenItemNumbers]...'
print ''
go

set QUOTED_IDENTIFIER OFF
go
set ANSI_NULLS ON
go

CREATE PROCEDURE dbo.[biw_XMLToOpenItemNumbers]
(
	@pnUserIdentityId		int		= null,
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@psOpenItemList			nvarchar(max)
)				
as
-- PROCEDURE :	biw_XMLToOpenItemNumbers
-- VERSION :	1
-- DESCRIPTION:	A procedure that returns all of the bill lines associated to an OpenItem
--
-- COPYRIGHT:	Copyright 1993 - 2009 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 07-May-2010	MS	RFC9088		1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int
Declare @hDoc 		int
Declare @sSql		nvarchar(1000)

Set @nErrorCode = 0

Exec @nErrorCode = sp_xml_preparedocument @hDoc OUTPUT, @psOpenItemList
	
	
If @nErrorCode = 0
Begin
	Set @sSql =	"Select O.ITEMENTITYNO, 
				O.OPENITEMNO, 
				O.ITEMTYPE 
			FROM OPENITEM O 
			join OPENXML( @phDoc, 'PrintBill/Bill', 2 )
			With	(ITEMNO nvarchar(12) 'ItemNo/text()',
				 ENTITYNO int 'EntityNo/text()') as X
			on (X.ITEMNO = O.OPENITEMNO and X.ENTITYNO = O.ITEMENTITYNO)"		
	
	Exec @nErrorCode = sp_executesql @sSql, N'@phDoc Int', @hDoc

End

Exec sp_xml_removedocument @hDoc

Return @nErrorCode
GO

grant execute on dbo.[biw_XMLToOpenItemNumbers]  to public
GO
