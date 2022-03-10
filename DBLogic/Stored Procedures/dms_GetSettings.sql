-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dms_GetSettings
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dms_GetSettings]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dms_GetSettings.'
	Drop procedure [dbo].[dms_GetSettings]
End
Print '**** Creating Stored Procedure dbo.dms_GetSettings...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.dms_GetSettings
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int		= null,
	@psNameTypes		nvarchar(max)	= null,
	@pnNameKey		int		= null
)
as
-- PROCEDURE:	dms_GetSettings
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This stored procedure retrieves initial settings required to connect and 
--		then populate the documents held within that DMS, based on start up criteria
--		such as @pnCaseKey, @pnNameKey

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 OCT 2009	SF	RFC8535	1	Procedure created
-- 14 DEC 2009	JCLG	RFC8079	2	Add Name Types
-- 16 AUG 2010	JCLG	RFC9621	3	Include 'DMS Case Search Doc Item' Site Control
-- 18 MAR 2011	JCLG	R10371	4	Include 'DMS Name Types' Site Control
-- 02 Nov 2015	vql	R53910	5	Adjust formatted names logic (DR-15543).
-- 24 SEP 2019	SF 	DR-52536	6	Include 'DMS Name Search Doc Item' Site Control

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sCaseReference nvarchar(30)
declare @sNameCode nvarchar(30)
declare @sFormattedName nvarchar(1000)
declare @gstrEntryPoint nvarchar(30)
declare @sSQLString nvarchar(4000)
declare @sSQLDocItem nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	If @pnCaseKey is not null
	Begin

		Set @sSQLString = "
			select	@sCaseReference = C.IRN
			from CASES C
			where C.CASEID = @pnCaseKey"
		
		exec @nErrorCode=sp_executesql @sSQLString,
			N'	@sCaseReference	nvarchar(30) output,
				@pnCaseKey		int',
				@sCaseReference	= @sCaseReference output,
				@pnCaseKey		= @pnCaseKey
		
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
				Select @sSQLDocItem = I.SQL_QUERY
				from ITEM I, SITECONTROL SC
				where I.ITEM_NAME = SC.COLCHARACTER
				and SC.CONTROLID = 'DMS Case Search Doc Item'" 
				
			exec @nErrorCode=sp_executesql @sSQLString,
					N'	@sSQLDocItem	nvarchar(max) output',
						@sSQLDocItem	= @sSQLDocItem output
			
			If @nErrorCode = 0 and @sSQLDocItem is not null
			Begin
				Set @gstrEntryPoint = @sCaseReference
				Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','@gstrEntryPoint')
				
				Set @sSQLString = "Select @sCaseReference = (" + @sSQLDocItem + ")"

				exec @nErrorCode=sp_executesql @sSQLString,
					N'	@sCaseReference	nvarchar(30) output,
						@gstrEntryPoint nvarchar(30)',
						@sCaseReference	= @sCaseReference output,
						@gstrEntryPoint   = @gstrEntryPoint
			End		
			
		End

		Select	@pnCaseKey	as CaseKey,
			@sCaseReference	as CaseReference

		If @nErrorCode = 0 and	@psNameTypes is null
		Begin
			Set @sSQLString = "
				select	@psNameTypes = COLCHARACTER
				from SITECONTROL
				where CONTROLID = 'DMS Name Types'"
			
			exec @nErrorCode=sp_executesql @sSQLString,
				N'	@psNameTypes	nvarchar(max) output',
					@psNameTypes	= @psNameTypes output
		End
					
		If @nErrorCode = 0 and @psNameTypes is not null
		Begin
			Set @sSQLString = "
				Select DISTINCT
					CN.NAMENO	as NameKey,
					CN.NAMETYPE as NameType,
					N.NAMECODE	as NameCode,
					dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL) as DisplayName
				from CASENAME CN 
				join dbo.fn_Tokenise(@psNameTypes, ',') R on (CN.NAMETYPE = R.Parameter)	
				join NAME N	on (CN.NAMENO = N.NAMENO)
				where CN.CASEID = @pnCaseKey
				order by DisplayName" 
				
			exec @nErrorCode=sp_executesql @sSQLString,
					N'	@pnCaseKey	int,
					    @psNameTypes	nvarchar(max)',
						@pnCaseKey	= @pnCaseKey,
						@psNameTypes    = @psNameTypes
		
		End
	End
	Else If @pnNameKey is not null
	Begin
		
		Set @sSQLString = "
			select	@sNameCode = N.NAMECODE,
					@sFormattedName = dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL)
			from NAME N			
			where N.NAMENO = @pnNameKey"
		
		exec @nErrorCode=sp_executesql @sSQLString,
			N'	@sNameCode		nvarchar(30) output,
				@sFormattedName	nvarchar(1000) output,
				@pnNameKey		int',
				@sNameCode		= @sNameCode output,
				@sFormattedName = @sFormattedName output,
				@pnNameKey		= @pnNameKey
		
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
				Select @sSQLDocItem = I.SQL_QUERY
				from ITEM I, SITECONTROL SC
				where I.ITEM_NAME = SC.COLCHARACTER
				and SC.CONTROLID = 'DMS Name Search Doc Item'" 
				
			exec @nErrorCode=sp_executesql @sSQLString,
					N'	@sSQLDocItem	nvarchar(max) output',
						@sSQLDocItem	= @sSQLDocItem output
			
			If @nErrorCode = 0 and @sSQLDocItem is not null and @sNameCode is not null
			Begin
				Set @gstrEntryPoint = @sNameCode
				Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','@gstrEntryPoint')
				
				Set @sSQLString = "Select @sNameCode = (" + @sSQLDocItem + ")"

				exec @nErrorCode=sp_executesql @sSQLString,
					N'	@sNameCode		nvarchar(30) output,
						@gstrEntryPoint nvarchar(30)',
						@sNameCode		= @sNameCode output,
						@gstrEntryPoint = @gstrEntryPoint
			End					
		End

		Select	@pnNameKey	as NameKey,
				@sNameCode	as NameCode,
				@sFormattedName as DisplayName
	End
End


Return @nErrorCode
GO

Grant execute on dbo.dms_GetSettings to public
GO
