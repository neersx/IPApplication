-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListChecklistTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListChecklistTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListChecklistTypes.'
	Drop procedure [dbo].[ipw_ListChecklistTypes]
End
Print '**** Creating Stored Procedure dbo.ipw_ListChecklistTypes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListChecklistTypes
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey			int			= null,
	@pnChecklistType	int			= null
)
as
-- PROCEDURE:	ipw_ListChecklistTypes
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List checklists defined in the system
--				Returns Valid checklists if valid combination rule are met

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 Nov 2007	SF		RFC5776	1		Procedure created
-- 12 Feb 2007	SF		RFC6189	2		Add @pnCaseKey parameter, filter by valid checklist if valid combination rule met
-- 29 Nov 2010	SF		RFC7284	3		Return CaseKey and indicate whether checklist criteria is defined

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)
Declare @nProfileKey	int
-- Initialise variables
Set @nErrorCode = 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0


-- Get the ProfileKey for the current user
If @nErrorCode = 0
and @pnCaseKey is not null
Begin
	Set @sSQLString = "
		Select @nProfileKey = PROFILEID
		from USERIDENTITY
		where IDENTITYID = @pnUserIdentityId
	"
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@nProfileKey int output,
					  @pnUserIdentityId	int',					  
					  @nProfileKey = @nProfileKey output,
					  @pnUserIdentityId	= @pnUserIdentityId
End
	
If @pnCaseKey is not null 
Begin
	
	If exists(	select	*
			from CASES C
			join VALIDCHECKLISTS VCL on (VCL.PROPERTYTYPE	= C.PROPERTYTYPE
								and VCL.CASETYPE	= C.CASETYPE
								and VCL.COUNTRYCODE=(
												select min(VCL1.COUNTRYCODE)
												from VALIDCHECKLISTS VCL1
												where VCL1.PROPERTYTYPE=C.PROPERTYTYPE
												and VCL1.CASETYPE     = C.CASETYPE
												and VCL1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))												
			where C.CASEID = @pnCaseKey
			and ((@pnChecklistType is not null and @pnChecklistType =VCL.CHECKLISTTYPE)
			or	(@pnChecklistType is null)))
	Begin
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			select	VCL.CHECKLISTTYPE as 'ChecklistType',
			"+dbo.fn_SqlTranslatedColumn('VALIDCHECKLISTS','CHECKLISTDESC',null,'VCL',@sLookupCulture,@pbCalledFromCentura)
						+ " as 'ChecklistTypeDescription',
					C.CASEID		as 'CaseKey',
					dbo.fn_GetCriteriaNo(C.CASEID, 'C', VCL.CHECKLISTTYPE, null, @nProfileKey)
									as 'ChecklistCriteriaKey'
			from CASES C
			join VALIDCHECKLISTS VCL on (VCL.PROPERTYTYPE	= C.PROPERTYTYPE
									and VCL.CASETYPE	= C.CASETYPE
									and VCL.COUNTRYCODE=(
													select min(VCL1.COUNTRYCODE)
													from VALIDCHECKLISTS VCL1
													where VCL1.PROPERTYTYPE=C.PROPERTYTYPE
													and VCL1.CASETYPE     = C.CASETYPE
													and VCL1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))												
			where C.CASEID = @pnCaseKey
			order by ChecklistTypeDescription"	
			
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@pnCaseKey	int,
							  @nProfileKey	int',					  
							  @pnCaseKey	= @pnCaseKey,
							  @nProfileKey	= @nProfileKey
		End
	End
	Else
	Begin
		Set @sSQLString = "
		select C.CHECKLISTTYPE as 'ChecklistType',
			"+dbo.fn_SqlTranslatedColumn('CHECKLISTS','CHECKLISTDESC',null,'C',@sLookupCulture,@pbCalledFromCentura)
					+ " as 'ChecklistTypeDescription',
				@pnCaseKey	as 'CaseKey',
				dbo.fn_GetCriteriaNo(@pnCaseKey, 'C', C.CHECKLISTTYPE, null, @nProfileKey)
							as 'ChecklistCriteriaKey'
		from CHECKLISTS C
		order by ChecklistTypeDescription"

		exec @nErrorCode = sp_executesql @sSQLString,
							N'@pnCaseKey	int,
							  @nProfileKey	int',					  
							  @pnCaseKey	= @pnCaseKey,
							  @nProfileKey	= @nProfileKey
	End
	
End 
Else 
Begin	
	Set @sSQLString = "
	select C.CHECKLISTTYPE as 'ChecklistType',
		"+dbo.fn_SqlTranslatedColumn('CHECKLISTS','CHECKLISTDESC',null,'C',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ChecklistTypeDescription',
			NULL	as 'CaseKey',
			NULL	as 'ChecklistCriteriaKey'
	from CHECKLISTS C
	order by ChecklistTypeDescription"

	exec @nErrorCode = sp_executesql @sSQLString
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_ListChecklistTypes to public
GO
