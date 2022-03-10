-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNameWhereUsed
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameWhereUsed]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameWhereUsed.'
	Drop procedure [dbo].[naw_ListNameWhereUsed]
End
Print '**** Creating Stored Procedure dbo.naw_ListNameWhereUsed...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListNameWhereUsed
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnNameKey			int, 		-- Mandatory
	@pbCalledFromCentura		bit		= 0
)
as
-- PROCEDURE:	naw_ListNameWhereUsed
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists where a Name is used.  
--		Populates NameWhereUsedData dataset ("NameTypeCaseCount" and "PropertyCaseCount")

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-----	-------	-------	----------------------------------------------- 
-- 28 Aug 2006	SF	RFC4214	1	Procedure created. 
--					Moved from naw_ListNameDetail, Added RowKey.
-- 23 Apr 2007	SW	RFC4345	2	Exclude Draft Cases from NameTypeCaseCount and PropertyCaseCount result sets.
-- 29 May 2007	SW	RFC4345	3	Define Draft Cases as ACTUALCASETYPE IS NULL
-- 17 Nov 2008	AT	RFC7296	4	Return search Context with PropertyCaseCount and filter out I & S name types for CRM Cases.
-- 11 Apr 2013	DV	R13270	5	Increase the length of nvarchar to 11 when casting or declaring integer 
-- 12 May 2014  SW      R34088  6       Performance improvement by modifying inner join on CASETYPE and moving Site Control Evaluation
--                                      outside of select statement. 
-- 13 Dec 2016	MF	70088	7	Should consider Cases where the name is also used in the Correspondence (attention) name against the Case.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)
Declare @sPropTypeCampaign      nvarchar(10)
Declare @sPropTypeMktEvent      nvarchar(10)

If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select @sPropTypeCampaign = COLCHARACTER
	from SITECONTROL 	
	where CONTROLID = 'Property Type Campaign'"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@sPropTypeCampaign	nvarchar(10)	OUTPUT',
				  @sPropTypeCampaign	= @sPropTypeCampaign	OUTPUT
End

If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select @sPropTypeMktEvent = COLCHARACTER
	from SITECONTROL 	
	where CONTROLID = 'Property Type Marketing Event'"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@sPropTypeMktEvent	nvarchar(10)	OUTPUT',
				  @sPropTypeMktEvent	= @sPropTypeMktEvent	OUTPUT
End

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Initialise variables
Set @nErrorCode = 0
-- Populating NameTypeCaseCount result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select 	CAST(CASE WHEN(CN.NAMENO=@pnNameKey) THEN CN.NAMENO ELSE CN.CORRESPONDNAME END as nvarchar(11)) + '^' + NT.NAMETYPE as 'RowKey',
		CASE WHEN(CN.NAMENO=@pnNameKey) THEN CN.NAMENO ELSE CN.CORRESPONDNAME END	
				as 'NameKey',
		NT.NAMETYPE	as 'NameTypeKey',
		"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'NameType',    
		count(*) 	as 'Total',   
		sum(CASE WHEN ((S.LIVEFLAG = 1 and S.REGISTEREDFLAG = 0) 
		        	or S.STATUSCODE is null) 
				and (R.LIVEFLAG = 1 or R.STATUSCODE is null) THEN 1 ELSE 0 END) 
				as 'Pending',
		sum(CASE WHEN S.LIVEFLAG = 1 and S.REGISTEREDFLAG = 1
		      		and (R.LIVEFLAG = 1 or R.STATUSCODE is null) THEN 1 ELSE 0 END) 
				as 'Registered',
		sum(CASE WHEN (S.LIVEFLAG = 0 or R.LIVEFLAG = 0) THEN 1 ELSE 0 END) 
				as 'Dead'                                        
	from CASENAME CN   
	join NAMETYPE NT 	on (NT.NAMETYPE = CN.NAMETYPE)   
	join CASES C  		on (C.CASEID = CN.CASEID)
	join CASETYPE CT	on (CT.CASETYPE=C.CASETYPE
				and CT.ACTUALCASETYPE IS NULL
				and ((CT.CRMONLY = 1 and (CN.NAMETYPE <> 'I' or CN.NAMETYPE <> 'S'))
					or (ISNULL(CT.CRMONLY,0) = 0))
				)
	left join STATUS S  	on (S.STATUSCODE = C.STATUSCODE)   
	left join PROPERTY PR 	on (PR.CASEID = C.CASEID)   
	left join STATUS R  	on (R.STATUSCODE = PR.RENEWALSTATUS)   
	where (CN.NAMENO = @pnNameKey OR CN.CORRESPONDNAME = @pnNameKey)      
	group by CASE WHEN(CN.NAMENO=@pnNameKey) THEN CN.NAMENO ELSE CN.CORRESPONDNAME END, 
		 NT.NAMETYPE, NT.DESCRIPTION"+
	-- NT.DESCRIPTION_TID needs to be included in the Group by if it is used.
	case 	when  dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura) <> 'NT.DESCRIPTION'
		then  ", "+dbo.fn_GetTranslatedTIDColumn('NAMETYPE','DESCRIPTION') end+"
	order by 'Total' DESC, 'NameType' ASC"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int',
					  @pnNameKey		= @pnNameKey
End

-- Populating the PropertyCaseCount result set.
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select 	CAST(CASE WHEN(CN.NAMENO=@pnNameKey) THEN CN.NAMENO ELSE CN.CORRESPONDNAME END as nvarchar(11)) + '^' + NT.NAMETYPE + '^' + CT.CASETYPE + '^' + P.PROPERTYTYPE as 'RowKey',
		CASE WHEN(CN.NAMENO=@pnNameKey) THEN CN.NAMENO ELSE CN.CORRESPONDNAME END
				as 'NameKey',
		NT.NAMETYPE	as 'NameTypeKey',
		"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'NameType',
		CT.CASETYPE	as 'CaseTypeKey',
		"+dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'CaseTypeDescription',
		P.PROPERTYTYPE	as 'PropertyTypeKey',
		"+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'P',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'PropertyType',  
		count(*) 	as Total,   
		sum(CASE WHEN ((S.LIVEFLAG = 1 and S.REGISTEREDFLAG = 0) 
		        	or S.STATUSCODE is null) 
				and (R.LIVEFLAG = 1 or R.STATUSCODE is null) THEN 1 ELSE 0 END) 
				as Pending,
		sum(CASE WHEN S.LIVEFLAG = 1 and S.REGISTEREDFLAG = 1
		      		and (R.LIVEFLAG = 1 or R.STATUSCODE is null) THEN 1 ELSE 0 END) 
				as Registered,
		sum(CASE WHEN (S.LIVEFLAG = 0 OR R.LIVEFLAG = 0) THEN 1 ELSE 0 END) 
				as Dead,
		case when CT.CASETYPE = 'O' then 550
			when CT.CASETYPE = 'M' and C.PROPERTYTYPE = @sPropTypeCampaign then 560
			when CT.CASETYPE = 'M' and C.PROPERTYTYPE = @sPropTypeMktEvent then 570
			end as ContextKey
	from CASENAME CN
	join NAMETYPE NT 	on (NT.NAMETYPE=CN.NAMETYPE)
	join CASES C  		on (C.CASEID=CN.CASEID)
	join CASETYPE CT	on (CT.CASETYPE=C.CASETYPE
				and CT.ACTUALCASETYPE IS NULL
				and ((CT.CRMONLY = 1 and (CN.NAMETYPE <> 'I' or CN.NAMETYPE <> 'S'))
					or (ISNULL(CT.CRMONLY,0) = 0))
				)
	join PROPERTYTYPE P	on (P.PROPERTYTYPE = C.PROPERTYTYPE)
	left join STATUS S  	on (S.STATUSCODE=C.STATUSCODE)   
	left join PROPERTY PR 	on (PR.CASEID=C.CASEID)   
	left join STATUS R  	on (R.STATUSCODE=PR.RENEWALSTATUS)   
	where (CN.NAMENO = @pnNameKey OR CN.CORRESPONDNAME = @pnNameKey)      
	group by CASE WHEN(CN.NAMENO=@pnNameKey) THEN CN.NAMENO ELSE CN.CORRESPONDNAME END, 
		 NT.NAMETYPE, NT.DESCRIPTION, CT.CASETYPE, CT.CASETYPEDESC, P.PROPERTYTYPE, P.PROPERTYNAME, C.PROPERTYTYPE"+
	-- NT.DESCRIPTION_TID and P.PROPERTYTYPE_TID need to be included in the Group by if used.
	case 	when  dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura) <> 'NT.DESCRIPTION'
		then  ", "+dbo.fn_GetTranslatedTIDColumn('NAMETYPE','DESCRIPTION') end+
	case 	when  dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,@pbCalledFromCentura) <> 'CT.CASETYPEDESC'
		then  ", "+dbo.fn_GetTranslatedTIDColumn('CASETYPE','CASETYPEDESC') end+
	case 	when  dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'P',@sLookupCulture,@pbCalledFromCentura) <> 'P.PROPERTYNAME'
		then  ", "+dbo.fn_GetTranslatedTIDColumn('PROPERTYTYPE','PROPERTYNAME') end+"
	order by CaseTypeKey, PropertyType, Total DESC, NameType"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					@sPropTypeCampaign      nvarchar(10),
					@sPropTypeMktEvent      nvarchar(10)',
					@pnNameKey		= @pnNameKey,
					@sPropTypeCampaign      = @sPropTypeCampaign,
					@sPropTypeMktEvent      = @sPropTypeMktEvent	
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameWhereUsed to public
GO
