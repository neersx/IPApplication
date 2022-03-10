-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListEntryScreens
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListEntryScreens]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListEntryScreens.'
	Drop procedure [dbo].[csw_ListEntryScreens]
End
Print '**** Creating Stored Procedure dbo.csw_ListEntryScreens...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListEntryScreens
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCriteriaKey			int,
	@pnEntryNumber			int
)
as
-- PROCEDURE:	csw_ListEntryScreens
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Given criteria key and entry number, return screens appropriate for
--				the current workflow in proper order.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 NOV 2008	SF		RFC3392	1		Procedure created
-- 05 MAY 2009	SF		RFC7631	2		Retrieve Screentip
-- 10 JUN 2009	SF		RFC7918	3		Retrieve Name Type result set
-- 14 may 2013	ASH		R13437	4		Retrieve Translated value of UserInstructions column and remove redundant Screentip column.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @sLookupCulture nvarchar(5)

-- Initialise variables
Set @nErrorCode = 0
set @sLookupCulture= dbo.fn_GetLookupCulture(@psCulture, null, 0)

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	Cast(SC.CRITERIANO as nvarchar(15)) + '^' + 
				Cast(SC.ENTRYNUMBER as nvarchar(15)) + '^' +
				SC.SCREENNAME + Cast(SC.SCREENID as nvarchar(15))
												as RowKey,
				SC.CRITERIANO					as CriteriaKey,
				SC.SCREENNAME					as ScreenName,
				SC.SCREENID						as ScreenKey,
				SC.ENTRYNUMBER					as EntryNumber, " + 
				dbo.fn_SqlTranslatedColumn('SCREENCONTROL','SCREENTITLE',null,'SC',@sLookupCulture,0) + 
								"				as ScreenTitle,
				SC.DISPLAYSEQUENCE				as DisplaySequence,
				SC.CHECKLISTTYPE				as ChecklistTypeKey,
				SC.TEXTTYPE						as TextTypeKey,
				SC.NAMETYPE						as NameTypeKey,
				SC.NAMEGROUP					as NameGroupKey,
				SC.FLAGNUMBER					as FlagNumber,
				SC.CREATEACTION					as CreateAction,
				SC.RELATIONSHIP					as Relationship,				
				SC.PROFILENAME					as ProfileName,
				cast(SC.INHERITED as bit)		as IsInherited,
				cast(SC.MANDATORYFLAG as bit)	as IsMandatory,
				SC.GENERICPARAMETER				as GenericParameter,"+
				dbo.fn_SqlTranslatedColumn('SCREENCONTROL','SCREENTIP',null,'SC',@sLookupCulture,0) + 				
				                "				as UserInstructions

		from	SCREENCONTROL SC
		where	SC.CRITERIANO = @pnCriteriaKey
		and		SC.ENTRYNUMBER = @pnEntryNumber
		order by SC.DISPLAYSEQUENCE
		"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCriteriaKey	int,
					  @pnEntryNumber	int',
					  @pnCriteriaKey	= @pnCriteriaKey,
					  @pnEntryNumber 	= @pnEntryNumber
End

If @nErrorCode = 0
Begin
	-- return all Name Types relevant for the current Entry Screen Rules

	Set @sSQLString = "
		Select distinct SC.SCREENNAME	as ScreenName, 
						SC.SCREENID		as ScreenKey,
						NT.NAMETYPE		as NameTypeKey, " +
				dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura) + "	as NameTypeDescription,
						NG.NAMEGROUP	as NameGroupKey, " + 
				dbo.fn_SqlTranslatedColumn('NAMEGROUPS','GROUPDESCRIPTION',null,'NG',@sLookupCulture,@pbCalledFromCentura) + "	as NameGroupDescription
		from NAMETYPE NT 
		left join SCREENCONTROL SC on (SC.SCREENNAME in ('frmInstructor', 'frmNames', 'frmNameGrp'))
		left join NAMEGROUPS NG on (SC.NAMEGROUP = NG.NAMEGROUP)
		left join GROUPMEMBERS GM on (NG.NAMEGROUP = GM.NAMEGROUP)
		left join SITECONTROL SCAS on (SCAS.CONTROLID = 'Additional Internal Staff')
		left join NAMETYPE frmInstructor on (
							SC.SCREENNAME = 'frmInstructor' 
						and (	frmInstructor.NAMETYPE in ('I','A','EMP','SIG') OR
								frmInstructor.NAMETYPE = SCAS.COLCHARACTER))
		where	SC.CRITERIANO = @pnCriteriaKey
		and		SC.ENTRYNUMBER = @pnEntryNumber
		and	(
				(NT.NAMETYPE = SC.NAMETYPE)
				or (NT.NAMETYPE = GM.NAMETYPE)
				or (frmInstructor.NAMETYPE = NT.NAMETYPE)
		)
	"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCriteriaKey	int,
					  @pnEntryNumber	int',
					  @pnCriteriaKey	= @pnCriteriaKey,
					  @pnEntryNumber 	= @pnEntryNumber
	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListEntryScreens to public
GO
