-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_SearchName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[xml_SearchName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.xml_SearchName.'
	drop procedure dbo.xml_SearchName
	print '**** Creating procedure dbo.xml_SearchName...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.xml_SearchName
	@pnNameNo			int
AS

-- PROCEDURE :	xml_SearchName
-- VERSION :	2.3.0
-- DESCRIPTION:	Collects search criteria for the Name
-- CALLED BY :	SQLT_SearchName SQLTemplate 

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
			NAME.NAMECODE as [NameCode!1!!element]
			FROM    NAME
			WHERE NAME.NAMENO =  " + cast(@pnNameNo as varchar)+ "
			FOR XML EXPLICIT"
	Exec(@sSQLString)
	set @ErrorCode=@@error
end

RETURN @ErrorCode
go

grant execute on dbo.xml_SearchName  to public
go
