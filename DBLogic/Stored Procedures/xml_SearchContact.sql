-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_SearchContact
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[xml_SearchContact]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.xml_SearchContact.'
	drop procedure dbo.xml_SearchContact
	print '**** Creating procedure dbo.xml_SearchContact...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.xml_SearchContact
	@pnActivityNo			int
AS

-- PROCEDURE :	xml_SearchContact
-- VERSION :	2.3.0
-- DESCRIPTION:	Collects search criteria for the Activity
-- CALLED BY :	SQLT_SearchContact SQLTemplate 

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
			N.NAMECODE as [Activity!1!NameCode!element],
			IRN AS [Activity!1!IRN!element]
			from ACTIVITY A
			LEFT JOIN [NAME] N ON (N.NAMENO =A.NAMENO)
			LEFT JOIN CASES C ON (C.CASEID = A.CASEID)
			WHERE ACTIVITYNO = " + cast(@pnActivityNo as varchar)+ " 
			FOR XML EXPLICIT"
	Exec(@sSQLString)
	set @ErrorCode=@@error
end

RETURN @ErrorCode
go

grant execute on dbo.xml_SearchContact  to public
go
