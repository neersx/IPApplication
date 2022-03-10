-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_InsertCaseName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_InsertCaseName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_InsertCaseName.'
	Drop procedure [dbo].[cs_InsertCaseName]
	Print '**** Creating Stored Procedure dbo.cs_InsertCaseName...'
	Print ''
End
GO
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE procedure dbo.cs_InsertCaseName
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 		= null, 
	@psCaseKey		nvarchar(11) 		= null, 
	@pnNameTypeId		int 			= null,
	@psNameTypeKey		nvarchar(3) 		= null,
	@psNameTypeDescription	nvarchar(50) 		= null,
	@psNameKey		nvarchar(11), 		-- Mandatory
	@psDisplayName		nvarchar(254) 		= null,
	@pnNameSequence		int 			= null,
	@psReferenceNo		nvarchar(80)		= null
)
-- PROCEDURE :	cs_InsertCaseName
-- VERSION :	10
-- DESCRIPTION:	See CaseData.doc
-- CALLED BY :	
--
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 12/07/2002	JB			Procedure created
-- 16/07/2002	SF			Finishing up
-- 08/08/2002	SF			When there is no BillPercentage required by the NameType, 
--					the BillPercentage column is being set to 0 - it should be null.
-- 08 Nov 2002	JEK		5	Default NameTypeKey from NameTypeId before using it.
-- 12 FEB 2003	SF		6	RFC5 - Implement Instructor Defaults
-- 23 Jul 2004	TM	RFC1610	7	Increase the datasize of the @psReferenceNo from nvarchar(50) to nvarchar(80).	
-- 17 May 2006	IB	RFC3690	8	Derive case name attention.
-- 26 Apr 2006	JS	14323	9	Pass new parameter NameType to fn_GetDerivedAttnNameNo.
-- 15 Apr 2013	DV	R13270	10  Increase the length of nvarchar to 11 when casting or declaring integer

as
begin
/* -- ---------------
 * Minimum data
 * (JB) think we need @psCaseKey and @psNameTypeKey as well!
 * 
 */

	declare @nCaseId 		int
	declare @nColumnFlags 		smallint
	declare @bGetsBill 		bit
	declare @bKeepStreet 		bit
	declare @nAddressCode 		int
	declare @nErrorCode 		int
	declare @nCorrespondName	int
	declare @nDerivedCorrName	bit

	set @nErrorCode = 0

	if @psNameKey is null or @psNameKey = ''
		set @nErrorCode = -1
	
	set @nCaseId = CAST(@psCaseKey AS int)

	set @nErrorCode = 0

--	Convert NameTypeId to NameTypeKey
	if @nErrorCode = 0 and @psNameTypeKey is null
	begin
		set @psNameTypeKey = 			
			case @pnNameTypeId
				WHEN 1 		THEN 'I'
				WHEN 2 		THEN 'O'
				WHEN 3 		THEN 'EMP'
				WHEN 4 		THEN 'J'
			else
				null
			end

		if @psNameTypeKey is null
			set @nErrorCode = -1
		else
			set @nErrorCode = @@error				
	end

	if @nErrorCode = 0
	begin
		/* Generate a new sequence number */
		select 	@pnNameSequence = [SEQUENCE]
		from 	[CASENAME]
		where 	[CASEID] = @nCaseId
		and 	[NAMETYPE] = @psNameTypeKey

		if 	@pnNameSequence is null
		begin
			set @pnNameSequence = 0
		end
		else
		begin
			set @pnNameSequence = @pnNameSequence + 1
		end

		set @nErrorCode = @@error
	end
	
	/*
	 * Nametype rules
	 *
	 */ 

	if @nErrorCode = 0
	begin

		select 	@nColumnFlags = [COLUMNFLAGS], 
			@bKeepStreet = [KEEPSTREETFLAG]
		from 	[NAMETYPE]
		where 	[NAMETYPE] = @psNameTypeKey

		if (@nColumnFlags & 0x0040 = 0x0040)
			set @bGetsBill = 1
		else
			set @bGetsBill = null

		set @nErrorCode = @@error
	end
		
	if @nErrorCode = 0 and @bKeepStreet = 1
	begin
		select 	@nAddressCode = [STREETADDRESS]
		from 	[NAME]
		where 	[NAMENO] = CAST(@psNameKey as int)
	
		set @nErrorCode = @@error
	end

	-- Derive case name attention
	If @nErrorCode = 0
	Begin
		Select @nCorrespondName = dbo.fn_GetDerivedAttnNameNo(CAST(@psNameKey as int), @nCaseId, @psNameTypeKey)		
		
		Set @nDerivedCorrName = 1
	End

	/*
	 *  Create Relationship
	 *
	 */

	if @nErrorCode = 0
	begin
		INSERT INTO CASENAME
			(	[CASEID],
				[NAMETYPE],
				[NAMENO],
				[SEQUENCE],
				[REFERENCENO],
				[INHERITED],
				[BILLPERCENTAGE],
				[ADDRESSCODE],
				[CORRESPONDNAME],
				[DERIVEDCORRNAME]
			)
		VALUES	(	@nCaseId,
				@psNameTypeKey,		
				CAST(@psNameKey as int),
				@pnNameSequence,
				@psReferenceNo,
				0,
				CASE WHEN @bGetsBill = 1 THEN 100 ELSE null END,
				@nAddressCode,
				@nCorrespondName,
				@nDerivedCorrName
			)

		set @nErrorCode = @@error
	end

	/*
	 * Default from Instructor 
	 *
	 *
	 */

	If @nErrorCode = 0
	and @psNameTypeKey = 'I'
	Begin
		If exists(Select * from CASES where CASEID = @nCaseId and LOCALCLIENTFLAG is null)
		Begin

			Declare @bLocalClientFlag bit
			
			Select 	@bLocalClientFlag = LOCALCLIENTFLAG 
			from 	IPNAME
			where	NAMENO = Cast(@psNameKey as int)

			If (Select top 1 A.COUNTRYCODE
			From 	ADDRESS A
			join	NAMEADDRESS NA on (
					A.ADDRESSCODE = NA.ADDRESSCODE
					and NA.NAMENO = cast(@psNameKey as int)
					and NA.ADDRESSTYPE = 301)) = (Select 	COLCHARACTER 
									from 	SITECONTROL 
									where 	CONTROLID = 'HOMECOUNTRY')
			Begin
				Set @bLocalClientFlag = 1
			End

			Update 	CASES 
			Set 	LOCALCLIENTFLAG = isnull(@bLocalClientFlag, 0) -- default to 0 if null.
			where 	CASEID = @nCaseId		
		End
		Else
		Begin
			Update 	CASES 
			Set 	LOCALCLIENTFLAG = 0
			where 	CASEID = @nCaseId		
		End
		Set @nErrorCode = @@error
	End

	return @nErrorCode
end
GO

grant execute on dbo.cs_InsertCaseName to public
go
