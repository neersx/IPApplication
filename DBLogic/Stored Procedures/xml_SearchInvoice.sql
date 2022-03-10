-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_SearchInvoice
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[xml_SearchInvoice]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.xml_SearchInvoice.'
	drop procedure dbo.xml_SearchInvoice
	print '**** Creating procedure dbo.xml_SearchInvoice...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.xml_SearchInvoice
	@pCaseIds		varchar(254)
AS

-- PROCEDURE :	xml_SearchInvoice
-- VERSION :	2.3.0
-- DESCRIPTION:	Collects search criteria for the Invoice
-- CALLED BY :	SQLT_SearchInvoice SQLTemplate 

-- Date		MODIFICATION HISTORY
-- ====         ===================
-- 17/09/2002	AvdA			Procedure created
-- 21/10/2002	AvdA			Simplify implementation

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

declare @ErrorCode	int
declare	@sSQLString	nvarchar(4000)


begin
	set @sSQLString="select 1 as TAG, 0 as parent,
			CASES.IRN as [CaseReference!1!!element]
			FROM    CASES
			WHERE CASES.CASEID in ( " + @pCaseIds + ")
			FOR XML EXPLICIT"
	Exec(@sSQLString)
	set @ErrorCode=@@error
end

RETURN @ErrorCode
go

grant execute on dbo.xml_SearchInvoice  to public
go
