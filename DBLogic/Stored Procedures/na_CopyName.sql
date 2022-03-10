-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_CopyName
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[na_CopyName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)

begin
	Print '**** Drop Stored Procedure dbo.na_CopyName.'
	Drop procedure [dbo].[na_CopyName]
end
Print '**** Creating Stored Procedure dbo.na_CopyName...'
Print ''
GO



SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE  PROCEDURE dbo.na_CopyName 
	@pnUserIdentityId		int,		
	@psCulture			nvarchar(10) 	= null,
	@pnCopyFromNameNo		int,
	@psFirstName			nvarchar(50),
	@psLastName			nvarchar(254),  
	@pbLinkAddress			bit,			-- inherit address from Copy From Name
	@pbGenerateNameCode		bit,
	@psSoundex			nvarchar(10),
	@pbCalledFromCentura		bit = 0,
	@pnNewNameNo			int OUTPUT,
	@pbCopyAddress			bit = 0			-- copy the address (either as new address or linked address)

AS
-- PROCEDURE :	na_CopyName
-- VERSION :	13
-- DESCRIPTION:	Create a new name by copy from an existing name with NAMENO = @pnCopyFromNameNo
--
-- COPYRIGHT: 	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 23/01/2007	DL	12524	1	Procedure created
-- 05/05/2007	CR	12548	2	Extended to include the new State Tax No and Code
--					for IPNAMEs and ORGANISATIONs	
-- 29/11/2007	CR	14649	3	Extended to include ServPerformedIn for IPNAMEs			
--					for IPNAMEs and ORGANISATIONs
-- 15/01/2008	Dw	9782	4	Tax No and State Tax No have both been moved to NAME table.				
-- 15/01/2009	Dw	17279	5	Initials were being derived incorrectly.
-- 27/01/2009	Dw	17319	6	Extended to include NAMETYPECLASSIFICATION settings.
-- 18/03/2009	Dw	17495	7	DATECHANGED and DATEENTERED should not be copied from existing name.
-- 11/08/2009	Dw	17614	8	Exclude the EDE identifier name alias when copying names
-- 04 Jun 2010	MF	18703	9	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE so these need to also be copied.
-- 18 Jul 2011	Dw	19797	10	allow option to copy name using same address but with address/telecom not inherited
-- 15 Jun 2012	KR	R12005	11	added CASETYPE and WIPCODE to DISCOUNT table.
-- 01 Apr 2014	Dw	22008	12	extended name text is deliberately not copied so EXTENDEDNAMEFLAG should be set to zero.
-- 01 Jun 2015	MS	R35907	13	Added COUNTRYCODE to the Discount calculation


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF


Declare 	@sSQLString 		nvarchar(4000),
		@nErrorCode		int,
		@sNameCode		nvarchar(10),
		@sSearchKey1		nvarchar(20),	
		@sSearchKey2		nvarchar(20),
		@sNameInitials		nvarchar(10),
		@sName			nvarchar(300),
		@nUsedAsFlag		smallint,	
		@nSupplierFlag		bit,
		@bDebug			bit,
		@nTranCountStart	int



Set @nErrorCode = 0 
Set @bDebug = 0



-- Data preparation
If @nErrorCode = 0
Begin
	-- the interface should ensure this
	If @pbLinkAddress = 1
	Begin	
	     Set @pbCopyAddress = 1
	End

	-- Generate NAME.NAMENO
	Exec @nErrorCode = dbo.ip_GetLastInternalCode
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@psTable		= 'NAME',
		@pnLastInternalCode	= @pnNewNameNo		OUTPUT

	-- Generate NAME.NAMECODE
	If @nErrorCode = 0 and @pbGenerateNameCode = 1
	Begin
		Exec @nErrorCode = dbo.na_GenerateNameCode
			@psNameCode			= @sNameCode OUTPUT,
			@pnUserIdentityId	= @pnUserIdentityId
	End


	-- Generate NAME.INITIALS
	If @nErrorCode = 0
	Begin
		-- SQA17279
		If @psFirstName is null
                   Begin
                        Set @sNameInitials = NULL
                   End
                Else
                   Begin
		      Set @sName = COALESCE(@psFirstName, '')

		      Set @sSQLString = "Select @sNameInitials = dbo.fn_GetInitials(@sName)"
		      Exec @nErrorCode=sp_executesql @sSQLString,
			      N'      @sNameInitials	nvarchar(10) OUTPUT,	
				      @sName		nvarchar(300)',
				      @sNameInitials = @sNameInitials OUTPUT,
				      @sName		= @sName
                    End
	End


	-- Generate NAME.SEARCHKEY1 & 2
	If @nErrorCode = 0
	Begin
		Exec @nErrorCode = dbo.na_GenerateSearchKey
			@psSearchKey1		= @sSearchKey1 OUTPUT,	
			@psSearchKey2		= @sSearchKey2 OUTPUT,	
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@psName				= @psLastName,
			@psGivenNames		= @psFirstName,
			@psInitials			= @sNameInitials
	End

	-- Get existing name useage flag
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Select @nUsedAsFlag = N.USEDASFLAG,
		@nSupplierFlag = N.SUPPLIERFLAG  
		from NAME N 
		where N.NAMENO = @pnCopyFromNameNo"
		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@nUsedAsFlag			smallint OUTPUT,	
				@nSupplierFlag			bit OUTPUT,
				@pnCopyFromNameNo		int',
				@nUsedAsFlag 			= @nUsedAsFlag OUTPUT,
				@nSupplierFlag			= @nSupplierFlag OUTPUT,
				@pnCopyFromNameNo		= @pnCopyFromNameNo
	End

End



-- Create name and details
If @nErrorCode = 0
Begin
	-- Start a new transaction
	-- SQA22008
	Select @nTranCountStart = @@TranCount
	Begin TRANSACTION


	-- NAME
	Set @sSQLString = "
		Insert into NAME 
		(NAMENO, NAMECODE, SUPPLIERFLAG, MAINEMAIL, 
		NAME, INITIALS, FIRSTNAME, SEARCHKEY1, 
		SEARCHKEY2, SOUNDEX, NATIONALITY, REMARKS, MAINCONTACT, 
		MAINPHONE, FAX, POSTALADDRESS, STREETADDRESS, 
		DATECHANGED, TAXNO, STATETAXNO,
		DATEENTERED, DATECEASED, USEDASFLAG, EXTENDEDNAMEFLAG, FAMILYNO, 
		NAMESTYLE, INSTRUCTORPREFIX, CASESEQUENCE, REMARKS_TID) 

		Select @pnNewNameNo, @sNameCode, SUPPLIERFLAG, MAINEMAIL, 
		@psLastName, @sNameInitials, @psFirstName, @sSearchKey1,
		@sSearchKey2, @psSoundex, NATIONALITY, REMARKS, MAINCONTACT, 
		Case when @pbLinkAddress = 1 then MAINPHONE else null end as MAINPHONE, 
		Case when @pbLinkAddress = 1 then FAX else null end as FAX, 
		Case when @pbLinkAddress = 1 then POSTALADDRESS else null end as POSTALADDRESS, 
		Case when @pbLinkAddress = 1 then STREETADDRESS else null end as STREETADDRESS, 
		null, TAXNO, STATETAXNO,
		getdate(), DATECEASED, USEDASFLAG, 0, FAMILYNO, 
		NAMESTYLE, INSTRUCTORPREFIX, CASESEQUENCE, REMARKS_TID

		from NAME N 
		where N.NAMENO = @pnCopyFromNameNo"
	Exec @nErrorCode=sp_executesql @sSQLString,
		N'	@pnNewNameNo		int,
			@sNameCode			nvarchar(10),
			@psLastName			nvarchar(254),
			@sNameInitials		nvarchar(10),
			@psFirstName		nvarchar(50),
			@sSearchKey1		nvarchar(20),	
			@sSearchKey2		nvarchar(20),
			@psSoundex			nvarchar(10),
			@pbLinkAddress		bit,
			@pnCopyFromNameNo	int',
			@pnNewNameNo		= @pnNewNameNo,
			@sNameCode			= @sNameCode,
			@psLastName			= @psLastName,
			@sNameInitials		= @sNameInitials,
			@psFirstName		= @psFirstName,
			@sSearchKey1		= @sSearchKey1,	
			@sSearchKey2		= @sSearchKey2,
			@psSoundex			= @psSoundex,
			@pbLinkAddress		= @pbLinkAddress,
			@pnCopyFromNameNo	= @pnCopyFromNameNo
	
	If @bDebug = 1
		print 'NAME: ' + @sSQLString

	-- ORGANISATION.  Only applicable if name is an organisation.
	-- NAME.USEDASFLAG & 1 = 1 is Individual, = 0 is Organisation.
	If @nErrorCode = 0 and @nUsedAsFlag & 1 = 0
	Begin
		Set @sSQLString = "
			Insert into ORGANISATION 
			(NAMENO, REGISTRATIONNO, INCORPORATED, PARENT, INCORPORATED_TID)
			Select @pnNewNameNo, REGISTRATIONNO, INCORPORATED, PARENT, INCORPORATED_TID		
			from ORGANISATION O 
			where O.NAMENO = @pnCopyFromNameNo"
		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo
		If @bDebug = 1
			print 'ORGANISATION: ' + @sSQLString
	End

	-- INDIVIDUAL.  Only applicable if name is an individual.
	-- NAME.USEDASFLAG & 1 = 1 is Individual, = 0 is Organisation.
	If @nErrorCode = 0 and @nUsedAsFlag & 1 = 1
	Begin
		Set @sSQLString = "
			Insert into INDIVIDUAL 
			(NAMENO, SEX, FORMALSALUTATION, CASUALSALUTATION)
			Select @pnNewNameNo, NULL, NULL, NULL		
			from INDIVIDUAL 
			where NAMENO = @pnCopyFromNameNo"
		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo
		If @bDebug = 1
			print 'INDIVIDUAL: ' + @sSQLString
	End


	-- Copy addresses
	If @nErrorCode = 0 and @pbCopyAddress = 1
	Begin
		Set @sSQLString = "
			Insert into NAMEADDRESS 
			(NAMENO, ADDRESSTYPE, ADDRESSCODE,  ADDRESSSTATUS, DATECEASED, OWNEDBY)
			Select @pnNewNameNo, ADDRESSTYPE, ADDRESSCODE, ADDRESSSTATUS, DATECEASED, 0
			from NAMEADDRESS NA 
			where NA.NAMENO = @pnCopyFromNameNo"

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo

		If @bDebug = 1
			print 'NAMEADDRESS: ' + @sSQLString

		If (@nErrorCode = 0) and (@pbLinkAddress = 0)
		-- SQA19797 unlink addresses
		Begin
			If (@bDebug = 1)
				print ' -- unlinking addresses'

			Declare @nOldAddressCode 	int,
				@nNewAddressCode 	int,
				@nAddressType		int,
				@nIndex			int,
				@nMaxIndex		int

			-- a temporary table will store link between new and original address codes
			Create table #TEMPNAMEADDRESS (
			OLDADDRESSCODE		int		NOT NULL,
			NEWADDRESSCODE		int		NULL,
			ADDRESSTYPE		int		NOT NULL,
			ROWNUMBER		int	identity(1,1)
			)

			Set @sSQLString = "
			Insert into #TEMPNAMEADDRESS 
			(OLDADDRESSCODE, NEWADDRESSCODE, ADDRESSTYPE)
			Select ADDRESSCODE, NULL, ADDRESSTYPE
			from NAMEADDRESS NA 
			where NA.NAMENO = @pnCopyFromNameNo"

			Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnCopyFromNameNo	int',
				@pnCopyFromNameNo	= @pnCopyFromNameNo

			select @nMaxIndex = count(*) from #TEMPNAMEADDRESS
			Set @nIndex = 1

			-- loop through the addresses
			While (@nIndex <= @nMaxIndex)
			Begin
				If (@nErrorCode = 0)
				Begin
					-- check if we already know the new Address Code
					Set @sSQLString = "Select @nOldAddressCode = OLDADDRESSCODE, 
								  @nNewAddressCode = NEWADDRESSCODE, 
								  @nAddressType = ADDRESSTYPE
								  from #TEMPNAMEADDRESS 
								  where ROWNUMBER = @nIndex"

					exec @nErrorCode=sp_executesql @sSQLString,
								N'@nOldAddressCode	int OUTPUT,
								  @nNewAddressCode	int OUTPUT,
								  @nAddressType		int OUTPUT,
								  @nIndex		int',
								  @nOldAddressCode	= @nOldAddressCode OUTPUT,
								  @nNewAddressCode	= @nNewAddressCode OUTPUT,
								  @nAddressType		= @nAddressType OUTPUT,
								  @nIndex		= @nIndex
					
					If (@bDebug = 1)
					Begin
						Select @nNewAddressCode AS NEWADDRESSCODE
					End
				End

				If (@nErrorCode = 0) and (@nNewAddressCode is null)
				Begin
					-- we don't have the new address code so create one
					Exec @nErrorCode = dbo.ip_GetLastInternalCode
						@pnUserIdentityId	= @pnUserIdentityId,
						@psCulture		= @psCulture,
						@psTable		= 'ADDRESS',
						@pnLastInternalCode	= @nNewAddressCode OUTPUT
					
					-- insert a new address with same details as old address
					Set @sSQLString = "
						Insert into ADDRESS 
						(ADDRESSCODE, CITY, CITY_TID, COUNTRYCODE, FAX, POSTCODE, STATE, STATE_TID, STREET1, STREET1_TID, STREET2, TELEPHONE)
						Select @nNewAddressCode, CITY, CITY_TID, COUNTRYCODE, FAX, POSTCODE, STATE, STATE_TID, STREET1, STREET1_TID, STREET2, TELEPHONE
						from ADDRESS A 
						where A.ADDRESSCODE = @nOldAddressCode"

					exec @nErrorCode=sp_executesql @sSQLString,
								N'@nOldAddressCode	int,
								  @nNewAddressCode	int',
								  @nOldAddressCode	= @nOldAddressCode,
								  @nNewAddressCode	= @nNewAddressCode	

					-- update temp table
					update #TEMPNAMEADDRESS
					set NEWADDRESSCODE =  @nNewAddressCode
					where OLDADDRESSCODE = @nOldAddressCode
					
					If (@bDebug = 1)
					Begin
						select 'new addresscode created'
						Select @nNewAddressCode AS NEWADDRESSCODE
					End
				End

		
				If (@nErrorCode = 0) 
				Begin
					-- update NAMEADDRESS row with new address code
					Set @sSQLString = "UPDATE NAMEADDRESS
							SET ADDRESSCODE = @nNewAddressCode,
							    OWNEDBY = 1
							Where NAMENO = @pnNewNameNo
							and ADDRESSCODE = @nOldAddressCode
							and ADDRESSTYPE = @nAddressType"
					
					exec @nErrorCode=sp_executesql @sSQLString, 
								N'@nNewAddressCode int,
								  @pnNewNameNo	int,
								  @nOldAddressCode int,
								  @nAddressType	int',
								  @nNewAddressCode = @nNewAddressCode,
								  @pnNewNameNo = @pnNewNameNo,
								  @nOldAddressCode = @nOldAddressCode,
								  @nAddressType = @nAddressType
					
					If (@bDebug = 1)
					Begin
						select 'Updated NAMEADDRESS row'
					End
				End
				
				
				Set @nIndex = @nIndex + 1
				
			End
			
			
			If (@nErrorCode = 0) 
				Begin
					-- update NAME row with new address codes
					Set @sSQLString = "UPDATE NAME
							SET POSTALADDRESS = 
							(select distinct T.NEWADDRESSCODE
							FROM NAME N
							join #TEMPNAMEADDRESS T on (T.OLDADDRESSCODE = N.POSTALADDRESS)
							Where N.NAMENO = @pnCopyFromNameNo),
							STREETADDRESS = 
							(select distinct T.NEWADDRESSCODE
							FROM NAME N
							join #TEMPNAMEADDRESS T on (T.OLDADDRESSCODE = N.STREETADDRESS)
							Where N.NAMENO = @pnCopyFromNameNo)
							Where NAMENO = @pnNewNameNo"

					
					Exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNewNameNo		int,
					@pnCopyFromNameNo	int',
					@pnNewNameNo		= @pnNewNameNo,
					@pnCopyFromNameNo	= @pnCopyFromNameNo
					
					If (@bDebug = 1)
					Begin
						select 'Updated NAME row'
					End
				End
				
			If (@bDebug = 1)
			begin
				select 'unlink address completed'
				select @nErrorCode as ERRORCODE
			End
		End
	End

	-- Copy Telecom
	If @nErrorCode = 0 and @pbCopyAddress = 1
	Begin
		Set @sSQLString = "
			Insert into NAMETELECOM 
			(NAMENO, TELECODE, TELECOMDESC, OWNEDBY, TELECOMDESC_TID)
			Select @pnNewNameNo, TELECODE, TELECOMDESC, 0, TELECOMDESC_TID
			from NAMETELECOM NT 
			where NT.NAMENO = @pnCopyFromNameNo"
		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo
		If @bDebug = 1
			print 'NAMETELECOM: ' + @sSQLString
	
		If (@nErrorCode = 0) and (@pbLinkAddress = 0)
		-- SQA19797 unlink telecom data
		Begin
			If (@bDebug = 1)
				print ' -- unlinking telecom'

			Declare @nOldTeleCode 	int,
				@nNewTeleCode 	int	

			-- a temporary table will store link between new and original telecodes
			Create table #TEMPNAMETELECOM (
			OLDTELECODE		int		NOT NULL,
			NEWTELECODE		int		NULL,
			ROWNUMBER		int	identity(1,1)
			)

			Set @sSQLString = "
			Insert into #TEMPNAMETELECOM 
			(OLDTELECODE, NEWTELECODE)
			Select TELECODE, NULL
			from NAMETELECOM NT 
			where NT.NAMENO = @pnCopyFromNameNo"

			Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnCopyFromNameNo	int',
				@pnCopyFromNameNo	= @pnCopyFromNameNo

			select @nMaxIndex = count(*) from #TEMPNAMETELECOM
			Set @nIndex = 1

			-- loop through the telecom rows
			While (@nIndex <= @nMaxIndex)
			Begin
				If (@nErrorCode = 0)
				Begin
					Set @sSQLString = "Select @nOldTeleCode = OLDTELECODE, 
								  @nNewTeleCode = NEWTELECODE 
								  from #TEMPNAMETELECOM 
								  where ROWNUMBER = @nIndex"

					exec @nErrorCode=sp_executesql @sSQLString,
								N'@nOldTeleCode	int OUTPUT,
								  @nNewTeleCode	int OUTPUT,
								  @nIndex	int',
								  @nOldTeleCode	= @nOldTeleCode OUTPUT,
								  @nNewTeleCode	= @nNewTeleCode OUTPUT,
								  @nIndex	= @nIndex
					
					If (@bDebug = 1)
					Begin
						Select @nNewTeleCode AS NEWTELECODE
					End
				End

				If (@nErrorCode = 0) and (@nNewTeleCode is null)
				Begin
					-- we don't have a new telecode so create one
					Exec @nErrorCode = dbo.ip_GetLastInternalCode
						@pnUserIdentityId	= @pnUserIdentityId,
						@psCulture		= @psCulture,
						@psTable		= 'TELECOMMUNICATION',
						@pnLastInternalCode	= @nNewTeleCode OUTPUT
					
					-- insert a new telecom with same details as old telecom
					Set @sSQLString = "
						Insert into TELECOMMUNICATION 
						(TELECODE, AREACODE, CARRIER, EXTENSION, ISD, REMINDEREMAILS, TELECOMNUMBER, TELECOMTYPE)
						Select @nNewTeleCode, AREACODE, CARRIER, EXTENSION, ISD, REMINDEREMAILS, TELECOMNUMBER, TELECOMTYPE
						from TELECOMMUNICATION T 
						where T.TELECODE = @nOldTeleCode"

					exec @nErrorCode=sp_executesql @sSQLString,
								N'@nOldTeleCode	int,
								  @nNewTeleCode	int',
								  @nOldTeleCode	= @nOldTeleCode,
								  @nNewTeleCode	= @nNewTeleCode	

					-- update temp table
					update #TEMPNAMETELECOM
					set NEWTELECODE =  @nNewTeleCode
					where OLDTELECODE = @nOldTeleCode
					
					If (@bDebug = 1)
					Begin
						select 'new telecode created'
						Select @nNewTeleCode AS NEWTELECODE
					End
				End

		
				If (@nErrorCode = 0) 
				Begin
					-- update NAMETELECOM row with new telecode
					Set @sSQLString = "UPDATE NAMETELECOM
							SET TELECODE = @nNewTeleCode,
							    OWNEDBY = 1
							Where NAMENO = @pnNewNameNo
							and TELECODE = @nOldTeleCode"
					
					exec @nErrorCode=sp_executesql @sSQLString, 
								N'@nNewTeleCode int,
								  @pnNewNameNo	int,
								  @nOldTeleCode int',
								  @nNewTeleCode = @nNewTeleCode,
								  @pnNewNameNo = @pnNewNameNo,
								  @nOldTeleCode = @nOldTeleCode
					
					If (@bDebug = 1)
					Begin
						select 'Updated NAMETELECOM row'
					End
				End
				
				
				Set @nIndex = @nIndex + 1
				
			End
			
			
			If (@nErrorCode = 0) 
				Begin
					-- update NAME row with new telecodes
					Set @sSQLString = "UPDATE NAME
							SET MAINPHONE = 
							(select distinct T.NEWTELECODE
							FROM NAME N
							join #TEMPNAMETELECOM T on (T.OLDTELECODE = N.MAINPHONE)
							Where N.NAMENO = @pnCopyFromNameNo),
							FAX = 
							(select distinct T.NEWTELECODE
							FROM NAME N
							join #TEMPNAMETELECOM T on (T.OLDTELECODE = N.FAX)
							Where N.NAMENO = @pnCopyFromNameNo),
							MAINEMAIL = 
							(select distinct T.NEWTELECODE
							FROM NAME N
							join #TEMPNAMETELECOM T on (T.OLDTELECODE = N.MAINEMAIL)
							Where N.NAMENO = @pnCopyFromNameNo)
							Where NAMENO = @pnNewNameNo"

					
					Exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNewNameNo		int,
					@pnCopyFromNameNo	int',
					@pnNewNameNo		= @pnNewNameNo,
					@pnCopyFromNameNo	= @pnCopyFromNameNo
					
					If (@bDebug = 1)
					Begin
						select 'Updated NAME row'
					End
				End
				
			If (@bDebug = 1)
				select 'unlink telecom completed'
		End
	End


	-- ASSOCIATEDNAME
	If @nErrorCode = 0 
	Begin
		Set @sSQLString = "
			Insert into ASSOCIATEDNAME 
			(NAMENO, RELATIONSHIP, RELATEDNAME, SEQUENCE, PROPERTYTYPE, COUNTRYCODE, 
			ACTION, CONTACT, JOBROLE, USEINMAILING, CEASEDDATE, POSITIONCATEGORY, POSITION, 
			TELEPHONE, FAX, MAINORGANISATION, POSTALADDRESS, STREETADDRESS, USEINFORMAL, 
			VALEDICTION, NOTES, NOTES_TID, POSITION_TID)

			Select @pnNewNameNo, AN.RELATIONSHIP, RELATEDNAME, AN.SEQUENCE, AN.PROPERTYTYPE, AN.COUNTRYCODE, 
			AN.ACTION, AN.CONTACT, AN.JOBROLE, AN.USEINMAILING, AN.CEASEDDATE, AN.POSITIONCATEGORY, AN.POSITION, 
			AN.TELEPHONE, AN.FAX, AN.MAINORGANISATION, AN.POSTALADDRESS, AN.STREETADDRESS, AN.USEINFORMAL, 
			AN.VALEDICTION, AN.NOTES, AN.NOTES_TID, AN.POSITION_TID 
			from ASSOCIATEDNAME AN
			where AN.NAMENO = @pnCopyFromNameNo
			and AN.RELATIONSHIP != 'CON'
			union 
			Select @pnNewNameNo, AN.RELATIONSHIP, RELATEDNAME, AN.SEQUENCE, AN.PROPERTYTYPE, AN.COUNTRYCODE, 
			AN.ACTION, AN.CONTACT, AN.JOBROLE, AN.USEINMAILING, AN.CEASEDDATE, AN.POSITIONCATEGORY, AN.POSITION, 
			AN.TELEPHONE, AN.FAX, AN.MAINORGANISATION, AN.POSTALADDRESS, AN.STREETADDRESS, AN.USEINFORMAL, 
			AN.VALEDICTION, AN.NOTES, AN.NOTES_TID, AN.POSITION_TID 
			from ASSOCIATEDNAME AN
			join NAME N on (N.NAMENO = AN.NAMENO)
			where AN.NAMENO = @pnCopyFromNameNo 
			and AN.RELATIONSHIP = 'CON'
			and N.USEDASFLAG & 1 = 1
			union  -- reverse relationship
			Select NAMENO, AN.RELATIONSHIP, @pnNewNameNo, AN.SEQUENCE, AN.PROPERTYTYPE, AN.COUNTRYCODE, 
			AN.ACTION, AN.CONTACT, AN.JOBROLE, AN.USEINMAILING, AN.CEASEDDATE, AN.POSITIONCATEGORY, AN.POSITION, 
			AN.TELEPHONE, AN.FAX, AN.MAINORGANISATION, AN.POSTALADDRESS, AN.STREETADDRESS, AN.USEINFORMAL, 
			AN.VALEDICTION, AN.NOTES, AN.NOTES_TID, AN.POSITION_TID 
			from ASSOCIATEDNAME AN
			where AN.RELATEDNAME = @pnCopyFromNameNo
			and AN.RELATIONSHIP != 'CON'
			union 
			Select AN.NAMENO, AN.RELATIONSHIP, @pnNewNameNo, AN.SEQUENCE, AN.PROPERTYTYPE, AN.COUNTRYCODE, 
			AN.ACTION, AN.CONTACT, AN.JOBROLE, AN.USEINMAILING, AN.CEASEDDATE, AN.POSITIONCATEGORY, AN.POSITION, 
			AN.TELEPHONE, AN.FAX, AN.MAINORGANISATION, AN.POSTALADDRESS, AN.STREETADDRESS, AN.USEINFORMAL, 
			AN.VALEDICTION, AN.NOTES, AN.NOTES_TID, AN.POSITION_TID 
			from ASSOCIATEDNAME AN
			join NAME N on (N.NAMENO = AN.RELATEDNAME)
			where AN.RELATEDNAME = @pnCopyFromNameNo 
			and AN.RELATIONSHIP = 'CON'
			and N.USEDASFLAG & 1 = 1
			"


		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo

		If @bDebug = 1
			print 'ASSOCIATEDNAME: ' + @sSQLString
	End


	-- TABLEATTRIBUTES
	If @nErrorCode = 0 
	Begin
		Set @sSQLString = "
			Insert into TABLEATTRIBUTES 
		 	(PARENTTABLE, GENERICKEY, TABLECODE, TABLETYPE)
			Select TA.PARENTTABLE, @pnNewNameNo, TA.TABLECODE, TA.TABLETYPE
			from TABLEATTRIBUTES TA
			where TA.PARENTTABLE = 'NAME'
			and TA.GENERICKEY = @pnCopyFromNameNo "

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo

		If @bDebug = 1
			print 'TABLEATTRIBUTES: ' + @sSQLString
	End


	-- NAMETEXT  - Exclude extended name text type (N)
	If @nErrorCode = 0 
	Begin
		Set @sSQLString = "
			Insert into NAMETEXT 
		 	(NAMENO, TEXTTYPE, TEXT, TEXT_TID)
			Select @pnNewNameNo, NT.TEXTTYPE, NT.TEXT, NT.TEXT_TID
			from NAMETEXT NT
			where NT.NAMENO = @pnCopyFromNameNo 
			and NT.TEXTTYPE != 'N'"

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo

		If @bDebug = 1
			print 'NAMETEXT: ' + @sSQLString
	End


	-- NAMEIMAGE
	If @nErrorCode = 0 
	Begin
		Set @sSQLString = "
			Insert into NAMEIMAGE 
		 	(NAMENO, IMAGEID, IMAGETYPE, IMAGESEQUENCE, NAMEIMAGEDESC)
			Select @pnNewNameNo, IMAGEID, IMAGETYPE, IMAGESEQUENCE, NAMEIMAGEDESC
			from NAMEIMAGE
			where NAMENO = @pnCopyFromNameNo "

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo
		If @bDebug = 1
			print 'NAMEIMAGE: ' + @sSQLString
	End


	-- NAMEALIAS
	-- 17614 exclude EDE identifier alias since this is unique
	If @nErrorCode = 0 
	Begin
		Set @sSQLString = "
			Insert into NAMEALIAS 
		 	(NAMENO, ALIAS, ALIASTYPE, PRIORITY, COUNTRYCODE, PROPERTYTYPE)
			Select @pnNewNameNo, ALIAS, ALIASTYPE, PRIORITY, COUNTRYCODE, PROPERTYTYPE
			from NAMEALIAS
			where NAMENO = @pnCopyFromNameNo 
			and ALIASTYPE != '_E'"

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo
		If @bDebug = 1
			print 'NAMEALIAS: ' + @sSQLString
	End

	-- CREDITOR. (only applicable if name is a supplier)
	If @nErrorCode = 0 and @nSupplierFlag = 1
	Begin
		Set @sSQLString = "
			Insert into CREDITOR 
		 	(NAMENO, SUPPLIERTYPE, INSTRUCTIONS_TID, EXCHSCHEDULEID, DEFAULTTAXCODE, TAXTREATMENT, PURCHASECURRENCY, PAYMENTTERMNO, CHEQUEPAYEE, INSTRUCTIONS, EXPENSEACCOUNT, PROFITCENTRE, PAYMENTMETHOD, BANKNAME, BANKBRANCHNO, BANKACCOUNTNO, BANKACCOUNTNAME, BANKACCOUNTOWNER, BANKNAMENO, BANKSEQUENCENO, RESTRICTIONID, RESTNREASONCODE, PURCHASEDESC, DISBWIPCODE, BEIBANKCODE, BEICOUNTRYCODE, BEILOCATIONCODE, BEIBRANCHCODE)
			Select @pnNewNameNo, SUPPLIERTYPE, INSTRUCTIONS_TID, EXCHSCHEDULEID, DEFAULTTAXCODE, TAXTREATMENT, PURCHASECURRENCY, PAYMENTTERMNO, CHEQUEPAYEE, INSTRUCTIONS, EXPENSEACCOUNT, PROFITCENTRE, PAYMENTMETHOD, BANKNAME, BANKBRANCHNO, BANKACCOUNTNO, BANKACCOUNTNAME, BANKACCOUNTOWNER, BANKNAMENO, BANKSEQUENCENO, RESTRICTIONID, RESTNREASONCODE, PURCHASEDESC, DISBWIPCODE, BEIBANKCODE, BEICOUNTRYCODE, BEILOCATIONCODE, BEIBRANCHCODE
			from CREDITOR
			where NAMENO = @pnCopyFromNameNo "

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo
		If @bDebug = 1
			print 'CREDITOR: ' + @sSQLString
	End



	-- CRENTITYDETAIL
	If @nErrorCode = 0 and @nSupplierFlag = 1
	Begin
		Set @sSQLString = "
			Insert into CRENTITYDETAIL 
		 	(NAMENO, ENTITYNAMENO, BANKNAMENO, SEQUENCENO, SUPPLIERACCOUNTNO)
			Select @pnNewNameNo, ENTITYNAMENO, BANKNAMENO, SEQUENCENO, SUPPLIERACCOUNTNO
			from CRENTITYDETAIL
			where NAMENO = @pnCopyFromNameNo "

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo
		If @bDebug = 1
			print 'CRENTITYDETAIL: ' + @sSQLString
	End



	-- IPNAME. (only applicable if name is a client)
	If @nErrorCode = 0 and ( @nUsedAsFlag = 4 or @nUsedAsFlag = 5)
	Begin
		Set @sSQLString = "
			Insert into IPNAME 
		 	(NAMENO, TAXCODE, BADDEBTOR, CURRENCY, DEBITCOPIES, CONSOLIDATION, DEBTORTYPE, USEDEBTORTYPE, CORRESPONDENCE, CATEGORY, PURCHASEORDERNO, LOCALCLIENTFLAG, AIRPORTCODE, TRADINGTERMS, BILLINGFREQUENCY, CREDITLIMIT, CORRESPONDENCE_TID, EXCHSCHEDULEID, STATETAXCODE, SERVPERFORMEDIN)
			Select @pnNewNameNo, TAXCODE, BADDEBTOR, CURRENCY, DEBITCOPIES, CONSOLIDATION, DEBTORTYPE, USEDEBTORTYPE, CORRESPONDENCE, CATEGORY, PURCHASEORDERNO, LOCALCLIENTFLAG, AIRPORTCODE, TRADINGTERMS, BILLINGFREQUENCY, CREDITLIMIT, CORRESPONDENCE_TID, EXCHSCHEDULEID, STATETAXCODE, SERVPERFORMEDIN
			from IPNAME
			where NAMENO = @pnCopyFromNameNo "

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo
		If @bDebug = 1
			print 'IPNAME: ' + @sSQLString
	End


	-- DISCOUNT. (only applicable if name is a client)
	If @nErrorCode = 0 and ( @nUsedAsFlag = 4 or @nUsedAsFlag = 5)
	Begin
		Set @sSQLString = "
			Insert into DISCOUNT 
		 	(NAMENO, SEQUENCE, PROPERTYTYPE, ACTION, DISCOUNTRATE, WIPCATEGORY, BASEDONAMOUNT, WIPTYPEID, EMPLOYEENO, PRODUCTCODE, CASEOWNER, WIPCODE, CASETYPE, COUNTRYCODE)
			Select @pnNewNameNo, SEQUENCE, PROPERTYTYPE, ACTION, DISCOUNTRATE, WIPCATEGORY, BASEDONAMOUNT, WIPTYPEID, EMPLOYEENO, PRODUCTCODE, CASEOWNER, WIPCODE, CASETYPE, COUNTRYCODE
			from DISCOUNT
			where NAMENO = @pnCopyFromNameNo "

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo
		If @bDebug = 1
			print 'DISCOUNT: ' + @sSQLString
	End


	-- NAMEINSTRUCTIONS. (only applicable if name is a client)
	If @nErrorCode = 0 and ( @nUsedAsFlag = 4 or @nUsedAsFlag = 5)
	Begin
		Set @sSQLString = "
			Insert into NAMEINSTRUCTIONS 
		 	(NAMENO, INTERNALSEQUENCE, RESTRICTEDTONAME, INSTRUCTIONCODE, CASEID, COUNTRYCODE, PROPERTYTYPE, PERIOD1AMT, PERIOD1TYPE, PERIOD2AMT, PERIOD2TYPE, PERIOD3AMT, PERIOD3TYPE, ADJUSTMENT, ADJUSTDAY, ADJUSTSTARTMONTH, ADJUSTDAYOFWEEK, ADJUSTTODATE)
			Select @pnNewNameNo, INTERNALSEQUENCE, RESTRICTEDTONAME, INSTRUCTIONCODE, CASEID, COUNTRYCODE, PROPERTYTYPE, PERIOD1AMT, PERIOD1TYPE, PERIOD2AMT, PERIOD2TYPE, PERIOD3AMT, PERIOD3TYPE, ADJUSTMENT, ADJUSTDAY, ADJUSTSTARTMONTH, ADJUSTDAYOFWEEK, ADJUSTTODATE
			from NAMEINSTRUCTIONS
			where NAMENO = @pnCopyFromNameNo "

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo
		If @bDebug = 1
			print 'NAMEINSTRUCTIONS: ' + @sSQLString
	End


	-- FILESIN. (only applicable if name is a client)
	If @nErrorCode = 0 and ( @nUsedAsFlag = 4 or @nUsedAsFlag = 5)
	Begin
		Set @sSQLString = "
			Insert into FILESIN 
		 	(NAMENO, COUNTRYCODE, NOTES, NOTES_TID)
			Select @pnNewNameNo, COUNTRYCODE, NOTES, NOTES_TID
			from FILESIN
			where NAMENO = @pnCopyFromNameNo "

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo
		If @bDebug = 1
			print 'FILESIN: ' + @sSQLString
	End



	-- NAMELANGUAGE
	If @nErrorCode = 0 
	Begin
		Set @sSQLString = "
			Insert into NAMELANGUAGE 
		 	(NAMENO, SEQUENCENO, LANGUAGE, ACTION, PROPERTYTYPE)
			Select @pnNewNameNo, SEQUENCENO, LANGUAGE, ACTION, PROPERTYTYPE
			from NAMELANGUAGE
			where NAMENO = @pnCopyFromNameNo "

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo
		If @bDebug = 1
			print 'NAMELANGUAGE: ' + @sSQLString
	End


	-- EMPLOYEE (only applicable if staff)
	If @nErrorCode = 0 and  @nUsedAsFlag = 3
	Begin
		Set @sSQLString = "
			Insert into EMPLOYEE 
		 	(EMPLOYEENO, ABBREVIATEDNAME, STAFFCLASS, SIGNOFFTITLE, SIGNOFFNAME, STARTDATE, ENDDATE, CAPACITYTOSIGN, PROFITCENTRECODE, RESOURCENO, SIGNOFFNAME_TID, SIGNOFFTITLE_TID)
			Select @pnNewNameNo, NULL, STAFFCLASS, SIGNOFFTITLE, @psFirstName + ' ' + @psLastName, STARTDATE, ENDDATE, CAPACITYTOSIGN, PROFITCENTRECODE, RESOURCENO, NULL, SIGNOFFTITLE_TID
			from EMPLOYEE E
			where E.EMPLOYEENO = @pnCopyFromNameNo "

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@psFirstName		nvarchar(50),
				@psLastName			nvarchar(254),
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@psFirstName		= @psFirstName,
				@psLastName			= @psLastName,
				@pnCopyFromNameNo	= @pnCopyFromNameNo
		If @bDebug = 1
			print 'EMPLOYEE: ' + @sSQLString
	End



	-- NAMEMARGINPROFILE. (only applicable if name is a client)
	If @nErrorCode = 0 and ( @nUsedAsFlag = 4 or @nUsedAsFlag = 5)
	Begin
		Set @sSQLString = "
			Insert into NAMEMARGINPROFILE 
		 	(NAMENO, NAMEMARGINSEQNO, CATEGORYCODE, WIPTYPEID, MARGINPROFILENO)
			Select @pnNewNameNo, NAMEMARGINSEQNO, CATEGORYCODE, WIPTYPEID, MARGINPROFILENO
			from NAMEMARGINPROFILE
			where NAMENO = @pnCopyFromNameNo "

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo
		If @bDebug = 1
			print 'NAMEMARGINPROFILE: ' + @sSQLString
	End

        -- NAMETYPECLASSIFICATION
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
			Insert into NAMETYPECLASSIFICATION 
		 	(NAMENO, NAMETYPE, ALLOW)
			Select @pnNewNameNo, NAMETYPE, ALLOW
			from NAMETYPECLASSIFICATION
			where NAMENO = @pnCopyFromNameNo "

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnNewNameNo		int,
				@pnCopyFromNameNo	int',
				@pnNewNameNo		= @pnNewNameNo,
				@pnCopyFromNameNo	= @pnCopyFromNameNo
		If @bDebug = 1
			print 'NAMETYPECLASSIFICATION: ' + @sSQLString
	End

	-- Commit entire transaction if successful
	If @@TranCount > @nTranCountStart
	Begin
		If @nErrorCode = 0
		Begin
			COMMIT TRANSACTION
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End

End




If @nErrorCode != 0
	set @pnNewNameNo = null


-- Centura expects return via a result set
If @nErrorCode = 0 and @pbCalledFromCentura = 1
	Select @pnNewNameNo

RETURN @nErrorCode

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


grant execute on dbo.na_CopyName to public
GO

