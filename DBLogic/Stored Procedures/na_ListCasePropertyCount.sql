-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_ListCaseCount
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[na_ListCasePropertyCount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.na_ListCasePropertyCount.'
	drop procedure dbo.na_ListCasePropertyCount
	print '**** Creating procedure dbo.na_ListCasePropertyCount...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.na_ListCasePropertyCount
	@pnRowCount			int output,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnNameNo			int			-- The NAMENO that the count is to be returned for
	
AS

-- PROCEDURE :	na_ListCasePropertyCount
-- VERSION :	2.3.3
-- DESCRIPTION:	Returns the number of cases that exist for the NameNo passed as a parameter by the NameType and
--		PropertyType.
--		Note: The absense of a Status will be included in the overall Case count but will not be
--		      included as any of Pending, Registered or Dead
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 28/04/2003	MF		Procedure created

set nocount on

declare @ErrorCode	int
declare @sSQLString	nvarchar(4000)

set @ErrorCode=0

If @ErrorCode=0
Begin
	Set @sSQLString="
	SELECT NT.DESCRIPTION, P.PROPERTYNAME, 
	count(*) as Total,
	sum(CASE WHEN(R.LIVEFLAG=1 OR R.STATUSCODE is null) AND S.REGISTEREDFLAG=0 AND S.LIVEFLAG=1 THEN 1 ELSE 0 END) as Pending,
	sum(CASE WHEN(R.LIVEFLAG=1 OR R.STATUSCODE is null) AND S.REGISTEREDFLAG=1 AND S.LIVEFLAG=1 THEN 1 ELSE 0 END) as Registered,
	sum(CASE WHEN(R.LIVEFLAG=0 OR S.LIVEFLAG=0) THEN 1 ELSE 0 END) as Dead
	FROM CASENAME CN
	join NAMETYPE NT	on (NT.NAMETYPE=CN.NAMETYPE)
	join CASES C		on (C.CASEID=CN.CASEID)
	join PROPERTYTYPE P	on (P.PROPERTYTYPE=C.PROPERTYTYPE)
	left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
	left join PROPERTY PR	on (PR.CASEID=C.CASEID)
	left join STATUS R	on (R.STATUSCODE=PR.RENEWALSTATUS)
	WHERE (CN.NAMENO = @pnNameNo   OR CN.CORRESPONDNAME = @pnNameNo)   
	GROUP  BY NT.DESCRIPTION, P.PROPERTYNAME   
	ORDER BY 2 ASC, 3 DESC, 1 ASC"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnNameNo	int',
					  @pnNameNo=@pnNameNo
	Set @pnRowCount=@@Rowcount
End


RETURN @ErrorCode
go

grant execute on dbo.na_ListCasePropertyCount  to public
go
