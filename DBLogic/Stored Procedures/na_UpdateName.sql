-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.na_UpdateName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_UpdateName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_UpdateName.'
	Drop procedure [dbo].[na_UpdateName]
	Print '**** Creating Stored Procedure dbo.na_UpdateName...'
	Print ''
End
go

SET QUOTED_IDENTIFIER off
go

CREATE procedure dbo.na_UpdateName
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@psNameKey			varchar(11),	-- Mandatory (KEY) = NAMENO
	@psNameCode			nvarchar(10) 	= null,
	@pnEntityType			int 		= null,
	@pnNameUsedAs			int 		= null,
	@psName				nvarchar(254) 	= null,	
	@psGivenNames			nvarchar(50) 	= null,
	@psTitleKey			nvarchar(20) 	= null,
	@psFormalSalutation		nvarchar(50) 	= null, 
	@psCasualSalutation		nvarchar(50) 	= null, 
	@psIncorporated			nvarchar(254) 	= null,
	@psNationalityKey		nvarchar(3) 	= null,
	@pdtDateCeased			datetime 	= null,
	@pbIsCPAReportable		decimal(1,0) 	= null,	
	@psTaxNumber			nvarchar(20) 	= null, 
	@psRemarks			nvarchar(254) 	= null,

	@pnNameCodeModified		int 		= null,
	@pnEntityTypeModified		int 		= null,
	@pnNameUsedAsModified		int 		= null,
	@pnNameModified			int 		= null,
	@pnGivenNamesModified		int 		= null,
	@pnTitleKeyModified		int 		= null,
	@pnFormalSalutationModified	int 		= null,
	@pnCasualSalutationModified	int 		= null,
	@pnIncorporatedModified		int 		= null,
	@pnNationalityKeyModified	int 		= null,
	@pnDateCeasedModified		int 		= null,
	@pnIsCPAReportableModified	int 		= null,
	@pnTaxNumberModified		int 		= null,
	@pnRemarksModified		int 		= null

)
as
-- PROCEDURE:	na_UpdateName
-- VERSION :	25
-- SCOPE:	CPA.net
-- DESCRIPTION:	Update the name table and its child tables

-- MODIFICATIONS :
-- Date		Who	Version	Change	Description
-- ------------	-------	-------	-------	---------------------------------------- 
-- 20 Jun 2002  SF	1		Procedure created
-- 01 Jul 2002	JB	2		Extended to include other updates
-- 18 Jul 2002	JB	3 		Added CPA Reportable
-- 02 Aug 2002	SF	4		1. USEDAS flag not updating. fixed.
--					2. subtable values not updating.  fixed.
--					3. '?' sqluser.  fixed
-- 25 Oct 2002 	SF	8		Added code to pad name code and generate searchkey.
-- 30 Oct 2002	SF	9 		Use the generated searchkey in the insert statement.  
-- 27 Nov 2003 	SF	12		Cater for Staff/Client
-- 06 Dec 2002	SF	13		Back out 345 change.
-- 09 Dec 2002	SF	14		Re implement NameUsedAs Staff/Client with some modification.
-- 10 Mar 2003	JEK	15	RFC082	Localise stored procedure errors.
-- 17 Mar 2003	SF	16	RFC084	Call ip_InsertPolicing
-- 17 May 2003  TM      17	RFC175	Update of Name clears search key in some circumstances 
-- 22 May 2003  TM      18      RFC179	Name Code and Case Family Case Sensitivity
-- 15 Feb 2007	SW	19	RFC4757	Update NAME.SOUNDEX column by fn_SoundsLike function.
-- 16 Jan 2008	Dw	20	9782	TAXNO moved from Organisation to Name table.
-- 09 May 2008	Dw	21	16326	Extended salutation columns
-- 11 Dec 2008	MF	22	17136	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 07 Jul 2011	DL	23	RFC10830 Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 24 Oct 2011	ASH	 24	R11460 Cast integer columns as nvarchar(11) data type.
-- 15 Apr 2013	DV	25	R13270 Increase the length of nvarchar to 11 when casting or declaring integer


Begin
		
	-- requires that NameKey exists and maps to NAME.NAMENO.
	Declare @nErrorCode int
	Declare @nNameNo int
	Declare @nNameUsedAs int
	Declare @sSearchKey1 nvarchar(20)
	Declare @sSearchKey2 nvarchar(20)
	Declare @nOrigUsedAsFlag int
	Declare @sAlertXML nvarchar(400)

	Set @psNameCode	= upper(@psNameCode)	--Ensure name code is upper case
	Set @nErrorCode = 0
	If @nErrorCode = 0
	Begin
		-- Used multiple times
		select @nNameNo = Cast(@psNameKey as int)
		select @nErrorCode = @@ERROR
	End

	/*
		@pnEntityType 
			Organisation =1 (0x0008)
			Individual =2 (0x0001)
		
		in InProma 
			0 = Organisation
			1 = Individual
			3 = Staff
			4 = Organisation / Client
			5 = Individual / Client
	*/
	Declare @bIsIndividual bit
	Select 	@nOrigUsedAsFlag = USEDASFLAG 
	from	NAME
	where	NAMENO = @nNameNo
	Set @bIsIndividual = 
		Case when (@nOrigUsedAsFlag & 0x0001) = 0x0001 
			then 1 				-- Indive
			else 0 				-- Org
		end
	
	declare @bEntityTypeChange int
	set @bEntityTypeChange = 0

	if (@pnEntityType = 2 and @bIsIndividual = 0)	-- Indiv in Dataset 	-- Org in InProma
	or (@pnEntityType = 1 and @bIsIndividual = 1) 	-- Org in Dataset 	-- Indiv in InProma
	begin
		set @bEntityTypeChange = 1
	end

	Set @nNameUsedAs = 0

	If @pnEntityType = 1
		Set @nNameUsedAs = @nNameUsedAs | 0x0000 	-- Organisation (0x0000)				
	Else
		Set @nNameUsedAs = @nNameUsedAs | 0x0001	-- Individual (0x0001)

	if @pnNameUsedAs is null
		Set @pnNameUsedAs = 0

	Set @nNameUsedAs = 
		Case @pnNameUsedAs
			When 1 then @nNameUsedAs | 0x0002	-- Staff (0x0002)
			When 3 then @nNameUsedAs | 0x0004	-- Client (0x0004)
		Else
			@nNameUsedAs
		End

	-- ---------------------------------------------
	-- Stage 1 of 3 Child Deletes (if there are any)
	-- ---------------------------------------------

	if (@bEntityTypeChange = 1) 
	--If (sf) (@pnEntityTypeModified = 1)  the program is not distinguishing this properly.
	Begin	
		If (@pnEntityType = 1) 
		-- from Individual to Organisation = delete I, insert O
		Begin	
			
			If @nErrorCode = 0
			Begin
				Delete 	from 	INDIVIDUAL 
					where 	NAMENO = @nNameNo
				Set @nErrorCode = @@ERROR
			End

			If @nErrorCode = 0
			Begin
				-- (JB) maybe replace this with a seperate stored procedure?
				Insert into ORGANISATION( NAMENO, INCORPORATED)
					values (@nNameNo, @psIncorporated)

				-- Reset flag to prevent update in stage 3
				Set @pnIncorporatedModified = null
				Set @nErrorCode = @@ERROR		
			End

			If @nErrorCode = 0
			Begin
				-- We need to clear these columns
				Set @psGivenNames = null
				Set @psTitleKey = null
				-- Force update of the name record
				Set @pnGivenNamesModified = 1
				Set @pnTitleKeyModified = 1

			End				
		End
		Else

		Begin	-- from Organisation to Individual
			If @nErrorCode = 0
			Begin
				Delete 	from ORGANISATION
					where NAMENO = @nNameNo
	
				Set @nErrorCode = @@ERROR
			End

			If @nErrorCode = 0
			Begin
				Insert into INDIVIDUAL( NAMENO, FORMALSALUTATION, CASUALSALUTATION)
					values (@nNameNo, @psFormalSalutation, @psCasualSalutation)

				-- Update flag to prevent update in Stage 3
				Set @pnFormalSalutationModified = null
				Set @pnCasualSalutationModified = null
				Set @nErrorCode = @@ERROR		
			End

		End
	End

	If @nErrorCode = 0
	and (@nNameUsedAs <> @nOrigUsedAsFlag)
	Begin
		If ((@nOrigUsedAsFlag & 0x0002)=0x0002)
		Begin
						
			Delete
			from 	EMPLOYEE
			where	EMPLOYEENO = @nNameNo
		
		End
		Else
		If ((@nOrigUsedAsFlag & 0x0004)=0x0004)
		Begin
			Delete 
			from 	IPNAME
			where	NAMENO = @nNameNo
		End		

		Set @nErrorCode = @@Error

		If @nErrorCode = 0
		Begin
		
			if ((@nNameUsedAs & 0x0002)=0x0002)
			and ((@nNameUsedAs & 0x0001) = 0x0001)
			Begin
				-- To Staff	
				Insert EMPLOYEE (EMPLOYEENO,ENDDATE)
				values	(
					@nNameNo,
					@pdtDateCeased
				)					
			End
			Else
			if ((@nNameUsedAs & 0x0004)=0x0004)
			Begin
				-- to client
				Insert IPNAME (NAMENO)
				values	(
					@nNameNo
				)		
			End
				
			Set @nErrorCode =@@error
		End
	End

	-- ---------------------------------------------
	-- Stage 2 of 3 Parent table update
	-- ---------------------------------------------
	If @nErrorCode = 0
	and @pnNameCodeModified is not null	
	Begin
		-- Name Validation Add in.
		If IsNumeric(@psNameCode)=1
		Begin
			Select @psNameCode=Replicate('0',S.COLINTEGER-len(@psNameCode))+@psNameCode
			From 	SITECONTROL S
			Where	S.CONTROLID='NAMECODELENGTH'

			Set @nErrorCode = @@Error
		End

		If @nErrorCode = 0		
		and Exists(Select * from NAME where NAMECODE=@psNameCode)
		Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('NA1', 'Name code {0} is already in use.',
			'%s', null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1, @psNameCode)
			Set @nErrorCode = @@ERROR		
		End
	End

	If @nErrorCode = 0
	and (@pnGivenNamesModified is not null
	or   @pnNameModified       is not null)
	
	Begin
		-- Name Validation Add in.
		Set @sSearchKey1 = null
		Set @sSearchKey2 = null

		Exec @nErrorCode = dbo.na_GenerateSearchKey 
				@psSearchKey1 = @sSearchKey1 OUTPUT,
				@psSearchKey2 = @sSearchKey2 OUTPUT,
				@pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@psName = @psName,
				@psGivenNames = @psGivenNames
	End


	If @nErrorCode = 0
	and (@sSearchKey1 is not null
	or   @sSearchKey2 is not null
        or   @pnNameModified is not null
	or   @pnGivenNamesModified is not null)
	
	Begin
		Update NAME Set
	       		[NAME] = CASE WHEN (@pnNameModified=1) THEN @psName ELSE [NAME] END,
			[FIRSTNAME]	= CASE WHEN (@pnGivenNamesModified=1) THEN @psGivenNames ELSE [FIRSTNAME] END,
			[SEARCHKEY1]	= @sSearchKey1,
			[SEARCHKEY2]	= @sSearchKey2,
			[SOUNDEX]	= dbo.fn_SoundsLike(CASE WHEN (@pnNameModified=1) THEN @psName ELSE [NAME] END),
			[DATECHANGED]	= GetDate()
		Where	NAMENO		= @nNameNo
	End
	Set @nErrorCode = @@ERROR
	
	If @nErrorCode = 0
	and (@pnNameCodeModified is not null 
	or   @pnTitleKeyModified is not null
	or   @pnNationalityKeyModified is not null
	or   @pnDateCeasedModified is not null
	or   @pnRemarksModified is not null
	or   @pnEntityTypeModified is not null  -- (JB) @bEntityTypeChange = 1
	or   @pnNameUsedAsModified is not null
	or   @pnTaxNumberModified is not null		/* (SF) so that the DATECHANGED */
	or   @pnIncorporatedModified is not null	/* (SF) so that the DATECHANGED */
	or   @pnFormalSalutationModified is not null	/* (SF) so that the DATECHANGED */
	or   @pnCasualSalutationModified is not null)	/* (SF) so that the DATECHANGED */
	Begin
		Update NAME Set
			[NAMECODE] 	= CASE WHEN (@pnNameCodeModified=1) THEN @psNameCode ELSE [NAMECODE] End, 
			[TITLE]		= CASE WHEN (@pnTitleKeyModified=1) THEN @psTitleKey ELSE [TITLE] END,
			[NATIONALITY]	= CASE WHEN (@pnNationalityKeyModified=1) THEN @psNationalityKey ELSE [NATIONALITY] END,
			[DATECEASED] 	= CASE WHEN (@pnDateCeasedModified=1) THEN @pdtDateCeased ELSE [DATECEASED] END,
			[REMARKS]	= CASE WHEN (@pnRemarksModified=1) THEN @psRemarks ELSE [REMARKS] END,
			[TAXNO]		= CASE WHEN (@pnTaxNumberModified=1) THEN @psTaxNumber ELSE [TAXNO] END,
			[USEDASFLAG]	= CASE WHEN ((@pnEntityTypeModified=1)or(@pnNameUsedAsModified=1)) THEN @nNameUsedAs ELSE [USEDASFLAG] END, /* (SF) pnNameUsedAsModified is never changed */
			[DATECHANGED]	= GetDate()
		Where	NAMENO		= @nNameNo

	End
	Set @nErrorCode = @@ERROR
	

	-- ---------------------------------------------
	-- Stage 3 of 3 Child table insert / update
	-- ---------------------------------------------

	If @nErrorCode = 0
	Begin
		-- Individual / Organisation?
		If (@pnEntityType = 1)
		begin
			If @pnIncorporatedModified is not null
			begin
				Update	[ORGANISATION] 
				Set	[INCORPORATED]	= @psIncorporated
				where	[NAMENO]	= @nNameNo
			end
		end
		else
		begin
			If @pnFormalSalutationModified is not null
			or @pnCasualSalutationModified is not null
			begin
				Update 	[INDIVIDUAL] 
				Set	[FORMALSALUTATION]	= @psFormalSalutation,
					[CASUALSALUTATION] 	= @psCasualSalutation
				Where 	[NAMENO]		= @nNameNo
			end
		end
		Set @nErrorCode = @@ERROR
	End	

	If @nErrorCode = 0 and @pnIsCPAReportableModified = 1
	Begin

		-- Get the code from the sitecontrol
		Declare @bNeedsPolicing bit
		Declare @nCPACode int
		Select @nCPACode = [COLINTEGER] 
			From [SITECONTROL]
			Where [CONTROLID] = 'CPA Reportable Instr'

		If @pbIsCPAReportable = 1 and not exists (
			Select * From [NAMEINSTRUCTIONS] 
				Where [NAMENO] = @nNameNo)
		Begin			
			Exec @nErrorCode = na_InsertNameInstructions 
				@pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@pnNameNo = @nNameNo,
				@pnInstructionCode = @nCPACode
			Set @bNeedsPolicing =1 
		End

		If @pbIsCPAReportable != 1 and exists (
			Select * From [NAMEINSTRUCTIONS] 
				Where [NAMENO] = @nNameNo)
		Begin
			Exec na_DeleteNameInstructions
				@pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@pnNameNo = @nNameNo,
				@pnInstructionCode = @nCPACode
			Set @bNeedsPolicing =1 
		End

		If (@bNeedsPolicing = 1) 
		Begin
		
			-- Unique for DateEntered
			Declare @nLastSeq int
			declare @sSQLUser nvarchar(18)

			select 	@sSQLUser = LEFT(LOGINID, 18)
			from 	USERIDENTITY
			where 	IDENTITYID = @pnUserIdentityId

			Select 	@nLastSeq = isnull(MAX(POLICINGSEQNO), 0)
			from 	[POLICING]
			where 	[DATEENTERED] = dbo.fn_DateOnly(GETDATE())

			Declare @tPolicingRequests table
				(	[IDENT] 	int IDENTITY (1, 1),
					[ACTION] 	nvarchar(2) collate database_default,
					[CASEID] 	int, 
					[CRITERIANO] 	int, 
					[CYCLE] 	smallint, 
					[EVENTNO]	int
				)
			
			set @nErrorCode = @@error

			declare @nRowCount int
			declare @nCounter int

			if @nErrorCode = 0
			begin			
				Insert into @tPolicingRequests
					Select OA.[ACTION], OA.[CASEID], OA.[CRITERIANO], 
						OA.[CYCLE], EC.[EVENTNO] 
					From  	[OPENACTION] OA
					Join 	[CASENAME] CN ON CN.[CASEID] = OA.[CASEID ]
					Join 	[INSTRUCTIONTYPE] IT ON IT.[NAMETYPE] = CN.[NAMETYPE]
						and IT.[INSTRUCTIONTYPE] = 'R'
					Join 	[EVENTCONTROL] EC ON EC.[CRITERIANO] = OA.[CRITERIANO]
						and EC.[INSTRUCTIONTYPE] = 'R'
					Where	OA.[POLICEEVENTS] = 1
						and CN.[NAMENO] = @nNameNo
						and not exists
						( Select * FROM [CASEEVENT] CE 
							where CE.CASEID = OA.CASEID
							and CE.EVENTNO = EC.EVENTNO
							and CE.CYCLE = OA.CYCLE
							and CE.OCCURREDFLAG > 0 )
				
				select @nRowCount = @@rowcount, @nErrorCode = @@error
			end
		
			Set @nCounter = 0
			Declare @sCurrentAction nvarchar(2)
			Declare @sCurrentCaseKey nvarchar(11)
			Declare @sCurrentEventKey nvarchar(11)
			Declare @nCurrentCycle int
			Declare @nCurrentCriteriaNo int			

			While 	(@nCounter < @nRowCount
			and	@nErrorCode = 0)
			Begin
				-- collect policing information.

				Select 	@sCurrentAction = ACTION,
					@sCurrentCaseKey = Cast(CASEID as nvarchar(11)),
					@sCurrentEventKey = Cast(EVENTNO as nvarchar(11)),
					@nCurrentCycle = CYCLE,
					@nCurrentCriteriaNo = CRITERIANO
				from 	@tPolicingRequests
				where 	IDENT = @nCounter

				Set @nCounter = @nCounter + 1

				Exec @nErrorCode = dbo.ip_InsertPolicing
					@pnUserIdentityId = @pnUserIdentityId,
					@psCulture = @psCulture,
					@psCaseKey = @sCurrentCaseKey,
					@psEventKey = @sCurrentEventKey,
					@pnCycle = @nCurrentCycle,
					@pnTypeOfRequest = 6, -- Police Due Recalc
					@psAction = @sCurrentAction,
					@pnCriteriaNo = @nCurrentCriteriaNo,
					@pnPolicingBatchNo = null				
			end

		End 	-- (@bNeedsPolicing = 1)

	End		-- @pnIsCPAReportableModified = 1

End

RETURN @nErrorCode
GO

Grant execute on dbo.na_UpdateName to public
GO
