-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListNameTypeLayout
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListNameTypeLayout]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListNameTypeLayout.'
	Drop procedure [dbo].[csw_ListNameTypeLayout]
End
Print '**** Creating Stored Procedure dbo.csw_ListNameTypeLayout...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListNameTypeLayout
(
	@pnUserIdentityId		int,
	@psCulture			nvarchar(10)	= null,
	@pnScreenCriteriaKey		int		= null,
	@pbInDesignerMode		bit = 0,
	@pbInWorkflowMode		bit = 0,
	@pbIncludeFilteredNameType	bit = 0
)
as
-- PROCEDURE:	csw_ListNameTypeLayout
-- VERSION:	19
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	The NameTypeLayoutData dataset is used to extract the rules for the 
--		layout of names for a particular case.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 09 May 2006	SW	RFC3301	1	Procedure created
-- 15 May 2006	SW	RFC3301	2	Change ordering sequence
-- 25 May 2006	JEK	RFC3301	3	Adjust sorting
-- 05 Jun 2006	SW	RFC3301	4	Bug fix on IsDefaultedFrom left join table
-- 14 Jun 2006	IB	RFC3720	5	Return FutureNameTypeDescription column
-- 18 Jul 2008	AT	RFC5749	6	Return Remarks ColumnFlag.
-- 28 Aug 2008	AT	RFC5712	7	Return Correspondence column flag.
--					Return BulkEntryFlag.
-- 20 Feb 2009	JC	RFC7209	8	Use fnw_ScreenCriteriaNameTypes
-- 17 Mar 2009	JC	RFC7756	9	Add NAMETYPEID to the resultset and do not filter NAMETYPE if in designer mode
-- 04 Jun 2009	SF	RFC7918 10	Use
-- 09 Oct 2009	DV	RFC8336 11	Add a codition to check if COLUMNFLAGS is not null
-- 02 Mar 2009	SF	RFC6547 12	Return IsMandatory
-- 26 Aug 2011  DV      R11139  13      Do not display CRM Name Types if the user does not have CRM licence
-- 13 May 2013	DV	R13446	14	Translate the Description column
-- 22 Jul 2013  SW	DR98    15      Translate NameType Description column
-- 09 Sep 2013	DV	R27884	16	Added to @pbIncludeFilteredNameType also include NameTypes added in filtered Topics 
-- 16 Sep 2014  SW      R27882  17      Passed @isEditMode as 1 to fnw_FilteredTopicNameTypes
-- 01 Oct 2014	LP	R9422	18	Cater for Marketing Module license
-- 11 Apr 2017  MS      R56196  19      Use NAMETYPE.PRIORITYORDER column for sort order


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, 0)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	N.NAMETYPEID						as	NameTypeKey,
				N.NAMETYPE							as	NameTypeCode,
				"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'N',@sLookupCulture,0)+"
													as	NameTypeDescription,
				Cast(N.COLUMNFLAGS & 4 as bit)		as	HasReferenceNo,
				Cast(N.COLUMNFLAGS & 1 as bit)		as	HasAttention,
				Cast(N.COLUMNFLAGS & 2 as bit)		as	HasAddress,
				Cast(N.COLUMNFLAGS & 16 as bit)		as	HasDateCommenced,
				Cast(N.COLUMNFLAGS & 32 as bit)		as	HasDateCeased,
				Cast(N.COLUMNFLAGS & 8 as bit)		as	HasAssignmentDate,
				Cast(N.COLUMNFLAGS & 128 as bit)	as	HasIsInherited,
				Cast(N.COLUMNFLAGS & 64 as bit)		as	HasBillPercent,
				Cast(N.COLUMNFLAGS & 512 as bit)	as	HasNameVariant,
				Cast(N.COLUMNFLAGS & 1024 as bit)	as 	HasRemarks,
				Cast(N.COLUMNFLAGS & 2048 as bit)	as 	HasCorrespondence,
				Cast(N.PICKLISTFLAGS & 2 as bit)	as	IsStaffName,
				Cast(	Case N.MAXIMUMALLOWED 
						when 1 then 1
						else 0
					end as bit)			as	IsSingleName,
				isnull(ED.IsExists, 0)			as	IsDefaultedFrom,
				"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'FNT',@sLookupCulture,0)+"
													as	FutureNameTypeDescription,
				isnull(N.BULKENTRYFLAG,0)		as	IsBulk,
				Cast(ISNULL(N.MANDATORYFLAG,0) as bit) as IsMandatory
		from		NAMETYPE N"
	
		IF @pbInDesignerMode = 0 and @pbInWorkflowMode = 0
		BEGIN
			Set @sSQLString = @sSQLString + " join	("+char(10)
			Set @sSQLString = @sSQLString + "Select NAMETYPE from dbo.fnw_ScreenCriteriaNameTypes(@pnScreenCriteriaKey)"+char(10)
			If @pbIncludeFilteredNameType = 1
				Set @sSQLString = @sSQLString + " UNION Select NAMETYPE from dbo.fnw_FilteredTopicNameTypes(@pnScreenCriteriaKey,1)"+char(10)
			Set @sSQLString = @sSQLString + ") CN on (CN.NAMETYPE = N.NAMETYPE)"
		END
	
		-- Check whether there are any name types that also apply for this case which inherit from this name type
		Set @sSQLString = @sSQLString + " 	left join	(Select	N1.PATHNAMETYPE, 1 as IsExists
				 from	NAMETYPE N1 " + 
			CASE WHEN @pbInWorkflowMode = 0
				THEN "
				 join 	dbo.fnw_ScreenCriteriaNameTypes(@pnScreenCriteriaKey) CN1 on (CN1.NAMETYPE = N1.NAMETYPE)" 
				ELSE "" END + "
				 where	N1.PATHNAMETYPE is not null
				 group by N1.PATHNAMETYPE) ED on (ED.PATHNAMETYPE = N.NAMETYPE)
		left join	NAMETYPE FNT on (FNT.NAMETYPE = N.FUTURENAMETYPE)
				 where N.COLUMNFLAGS is not null" +
		        CASE WHEN dbo.fn_IsLicensedForCRM(@pnUserIdentityId, getdate())=0
				 THEN char(10) + "	and N.PICKLISTFLAGS & 32 != 32" END +
				 "

		/* Order by the following sequence
                        -       PRIORITYORDER
			·	IsStaffName descending
			·	Is client name (PICKLISTFLAGS&4=4) descending
			·	NameTypeDescription
		*/
		order by	N.PRIORITYORDER,
                                IsStaffName Desc,
				Cast(N.PICKLISTFLAGS & 4 as bit) Desc,
				NameTypeDescription
	"

	Exec @nErrorCode = sp_executesql @sSQLString, 
		N'@pnScreenCriteriaKey		int',
		  @pnScreenCriteriaKey		= @pnScreenCriteriaKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListNameTypeLayout to public
GO
