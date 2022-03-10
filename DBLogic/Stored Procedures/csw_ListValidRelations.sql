-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListValidRelations
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListValidRelations]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.csw_ListValidRelations.'
	drop procedure [dbo].[csw_ListValidRelations]
	print '**** Creating Stored Procedure dbo.csw_ListValidRelations...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListValidRelations
(
	@pnRowCount			int		= null output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnCaseKey  			int		= null,		-- Either @pnCaseKey or @pnScreenCriteriaKey must be Mandatory
	@pnScreenCriteriaKey	        int		= null,		-- Either @pnCaseKey or @pnScreenCriteriaKey must be Mandatory
	@pbCalledFromCentura	        bit		= 0,
        @pbShowHiddenRelations          bit             = 0
)
-- PROCEDURE:	csw_ListValidRelations
-- VERSION:	8
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of valid relationships of the case.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17 Oct 2005  TM	RFC3144	1	Procedure created
-- 09 Dec 2005	TM	RFC3275	2	Return new EventKey and EventDescription columns.
-- 24 Jul 2009	MF	16548	3	The DISPLAYEVENTNO or FROMEVENTNO will now identify the Event from a related Case for a given relationship.
-- 29 Mar 2010	SF	RFC6549	4	Use @pnScreenCriteriaKey to return valid relationship based on criteria 
-- 17 Sep 2010	MF	RFC9777	5	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 30 Nov 2010  MS      RFC100429 6     Remove OPENACTION join for CRITERIA
-- 26 Jul 2016  MS      R64482  7       Show hidden relationships if @@pbShowHiddenRelations is true
-- 25 Jun 2018	LP	R72814	8	Return base relationships if Criteria does not have Property Type specified.

AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString		nvarchar(4000)
Declare @nErrorCode		int
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
	
If @nErrorCode = 0
Begin
	if (@pnScreenCriteriaKey is not null 
		and @pnCaseKey is null
		and not exists (SELECT 1 from CRITERIA where CRITERIANO = @pnScreenCriteriaKey and PROPERTYTYPE IS NOT NULL))
	begin 
		Set @sSQLString="
		select 	CR.RELATIONSHIP		as RelationshipCode,
			"+dbo.fn_SqlTranslatedColumn('CASERELATION','RELATIONSHIPDESC',null,'CR',@sLookupCulture,@pbCalledFromCentura)
					+ " as RelationshipDescription,
			isnull(CR.DISPLAYEVENTNO,CR.FROMEVENTNO) as EventKey,
			COALESCE(	"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+",
					"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+")
						as EventDescription
		from CASERELATION CR
		left join EVENTS E on (E.EVENTNO = isnull(CR.DISPLAYEVENTNO,CR.FROMEVENTNO)) 
		left join EVENTCONTROL EC	on (EC.CRITERIANO=@pnScreenCriteriaKey
						and EC.EVENTNO   =E.EVENTNO)
		where (CR.SHOWFLAG = 1 or @pbShowHiddenRelations = 1)
		order by RelationshipDescription"
	end
	else begin
		Set @sSQLString="
		select 	VR.RELATIONSHIP		as RelationshipCode,
			"+dbo.fn_SqlTranslatedColumn('CASERELATION','RELATIONSHIPDESC',null,'CR',@sLookupCulture,@pbCalledFromCentura)
					+ " as RelationshipDescription,
			isnull(CR.DISPLAYEVENTNO,CR.FROMEVENTNO) as EventKey,
			COALESCE(	"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+",
					"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+")
						as EventDescription" + 
		case when @pnCaseKey is null then
		"
		from	CRITERIA C"
		else
		"
		from 	CASES C"
		end + "
		join  	VALIDRELATIONSHIPS VR	on (VR.PROPERTYTYPE = C.PROPERTYTYPE
						and VR.COUNTRYCODE = (	Select min(VR1.COUNTRYCODE)
									from VALIDRELATIONSHIPS VR1
									where VR1.PROPERTYTYPE = VR.PROPERTYTYPE
									and   VR1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))
		join 	CASERELATION CR 	on (CR.RELATIONSHIP = VR.RELATIONSHIP
							and (@pbShowHiddenRelations = 1 or CR.SHOWFLAG = 1))
		left join EVENTS E 		on (E.EVENTNO = isnull(CR.DISPLAYEVENTNO,CR.FROMEVENTNO)) " +
		case when @pnCaseKey is not null then
		"
		left join OPENACTION OA		on (OA.CASEID = C.CASEID
						and OA.ACTION = E.CONTROLLINGACTION)
		left join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO
						and EC.EVENTNO   =E.EVENTNO)
		where C.CASEID = @pnCaseKey"
		else
		"
		left join EVENTCONTROL EC	on (EC.CRITERIANO=C.CRITERIANO
						and EC.EVENTNO   =E.EVENTNO)
		where C.CRITERIANO = @pnScreenCriteriaKey"
		end + "		
		order by RelationshipDescription"
	end

        exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey	        int,
					  @pnScreenCriteriaKey  int,
                                          @pbShowHiddenRelations bit',
					  @pnCaseKey,
					  @pnScreenCriteriaKey,
                                          @pbShowHiddenRelations
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
go

grant execute on dbo.csw_ListValidRelations  to public
go
