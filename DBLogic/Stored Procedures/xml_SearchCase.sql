-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_SearchCase
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[xml_SearchCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.xml_SearchCase.'
	drop procedure dbo.xml_SearchCase
	print '**** Creating procedure dbo.xml_SearchCase...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.xml_SearchCase
	@pnCaseId			int			-- the CaseId whose data is being retrieved
AS

-- PROCEDURE :	xml_SearchCase
-- VERSION :	2.3.0
-- DESCRIPTION:	Collects search criteria for the case
-- CALLED BY :	SQLT_SearchCase SQLTemplate 

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
			WHERE CASES.CASEID = " + cast(@pnCaseId as varchar)+ "
			FOR XML EXPLICIT"
	Exec(@sSQLString)
	set @ErrorCode=@@error
end

RETURN @ErrorCode
go

grant execute on dbo.xml_SearchCase  to public
go
