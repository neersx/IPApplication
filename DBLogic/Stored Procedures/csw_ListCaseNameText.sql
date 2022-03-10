-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseNameText
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseNameText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseNameText.'
	Drop procedure [dbo].[csw_ListCaseNameText]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseNameText...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListCaseNameText
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,
	@pnScreenCriteriaKey	int,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	csw_ListCaseNameText
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return Name Text information for a given Case.
--		If there are multiple Names for a particular Name Type, then the Name with highest priority (i.e. least SEQUENCE) will be returned.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Jun 2013	LP	DR-53	1	Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).
-- 20 Mar 2018	LP	R73658	3	Return for all Case Names for this specified Case, regardless of SequenceNo.
-- 07 Sep 2018	AV	74738	4	Set isolation level to read uncommited.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare	@nErrorCode	int
declare @nScreenCriteriaKey int
declare @sSQLString	nvarchar(max)
Declare @sCaseTypeKey 		nchar(1)
Declare @sCRMProgramName	nvarchar(8)

Set @nErrorCode = 0
If @nErrorCode = 0
Begin
	set @sSQLString = "select @sCaseTypeKey = CASETYPE
			from CASES where CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'	@pnCaseKey	int,
						@sCaseTypeKey	nchar(1) output',	
						@pnCaseKey		= @pnCaseKey,
						@sCaseTypeKey		= @sCaseTypeKey output
End

If @nErrorCode = 0
Begin

	set @sSQLString = "select @sCRMProgramName = COLCHARACTER
			from SITECONTROL where UPPER(CONTROLID) = 'CRM SCREEN CONTROL PROGRAM'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'	@sCRMProgramName  nvarchar(8) output',
						@sCRMProgramName = @sCRMProgramName output
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select DISTINCT 
	convert(nvarchar,CN.CASEID) +'^'+ convert(nvarchar,CN.NAMENO)+'^'+ convert(nvarchar,CN.NAMETYPE)+'^'+ convert(nvarchar,TTF.TEXTTYPE) as RowKey,
	NT.DESCRIPTION as NameTypeDescription, 
	NT.NAMETYPE as NameTypeKey,
	CN.CASEID as CaseKey,
	CN.NAMENO as NameKey, 
	dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL) as DisplayName,
	N.NAMECODE as NameCode,
	cast(NTX.TEXT as nvarchar(max)) as Text,
	TTF.TEXTTYPE as TextTypeKey,
	TTF.TEXTDESCRIPTION as TextTypeDescription,
	NTX.LOGDATETIMESTAMP as DateModified,
	dbo.fn_FormatNameUsingNameNo(UN.NAMENO, NULL) as LastModifiedBy,
	CN.SEQUENCE as Sequence
	from (SELECT FN.FILTERVALUE as NameTypeKey,
			  FT.FILTERVALUE as TextTypeKey 
			from TOPICCONTROL TC
			join TOPICCONTROLFILTER FN on (TC.TOPICCONTROLNO = FN.TOPICCONTROLNO and FN.FILTERNAME = 'NameTypeKey')
			join TOPICCONTROLFILTER FT on (TC.TOPICCONTROLNO = FT.TOPICCONTROLNO and FT.FILTERNAME = 'TextTypeKey')		
			where TC.WINDOWCONTROLNO in (select WINDOWCONTROLNO
								from WINDOWCONTROL WCX
								where WCX.CRITERIANO = @pnScreenCriteriaKey
								and WCX.WINDOWNAME = 'CaseDetails')
			) TFN 		
	join TEXTTYPE TTF on (TTF.TEXTTYPE = TFN.TextTypeKey)	
	join NAMETYPE NT on (NT.NAMETYPE = TFN.NameTypeKey)
	left join CASENAME CN on (CN.NAMETYPE = NT.NAMETYPE 
					and CN.CASEID = @pnCaseKey)
	left join NAME N on (CN.NAMENO = N.NAMENO)	
	left join NAMETEXT NTX on (NTX.NAMENO = CN.NAMENO
				and NTX.TEXTTYPE = TTF.TEXTTYPE)
	left join USERIDENTITY U on (U.IDENTITYID = NTX.LOGIDENTITYID)				
	left join NAME UN on (UN.NAMENO = U.NAMENO)
	join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,@psCulture,0,@pbCalledFromCentura) FNT 
					on (FNT.NAMETYPE = CN.NAMETYPE
					and (FNT.BULKENTRYFLAG = 0 or FNT.BULKENTRYFLAG IS NULL))"

	if (exists (select 1 from CASETYPE CT where CT.CASETYPE = @sCaseTypeKey and CT.CRMONLY = 1))
	Begin
		-- If CRM Case, filter names from screen control
		Set @sSQLString = @sSQLString + "
		join dbo.fnw_GetScreenControlNameTypes(@pnUserIdentityId, @pnCaseKey, @sCRMProgramName) SCNT
					on (SCNT.NameTypeKey = CN.NAMETYPE)"
	End
	Set @sSQLString = @sSQLString + "where CN.CASEID = @pnCaseKey order by Sequence"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			    @pnUserIdentityId		int,
			    @psCulture			nvarchar(10),
			    @pbCalledFromCentura	bit,			    
			    @pnCaseKey			int,
			    @pnScreenCriteriaKey	int,
			    @sCRMProgramName		nvarchar(8)',
			    @pnUserIdentityId		= @pnUserIdentityId,
			    @psCulture			= @psCulture,			    
			    @pbCalledFromCentura	= @pbCalledFromCentura,
			    @pnCaseKey			= @pnCaseKey,
			    @pnScreenCriteriaKey	= @pnScreenCriteriaKey,
			    @sCRMProgramName		= @sCRMProgramName
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseNameText to public
GO
