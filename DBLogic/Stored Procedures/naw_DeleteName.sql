-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteName.'
	Drop procedure [dbo].[naw_DeleteName]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.naw_DeleteName
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory

	@psOldNameCode			nvarchar(20)	= null,
	@pbOldIsIndividual		bit		= null,
	@pbOldIsOrganisation		bit		= null,
	@pbOldIsStaff			bit		= null,
	@pbOldIsClient			bit		= null,
	@pbOldIsSupplier		bit		= null,
	@psOldName			nvarchar(254)	= null,
	@psOldTitle			nvarchar(20)	= null,
	@psOldInitials			nvarchar(10)	= null,
	@psOldFirstName			nvarchar(50)	= null,
	@psOldExtendedName		ntext		= null,
	@psOldSearchKey1		nvarchar(20)	= null,
	@psOldSearchKey2		nvarchar(20)	= null,
	@psOldNationalityCode		nvarchar(3)	= null,
	@pdtOldDateCeased		datetime	= null,
	@psOldRemarks			nvarchar(254)	= null,
	@pnOldGroupKey			smallint	= null,
	@pnOldNameStyleKey		int		= null,
	@psOldInstructorPrefix		nvarchar(10)	= null,
	@pnOldCaseSequence		smallint	= null,

	@pbIsNameCodeInUse		bit	 	= 0,
	@pbIsIndividualInUse		bit		= 0,
	@pbIsStaffInUse			bit		= 0,
	@pbIsClientInUse		bit		= 0,
	@pbIsSupplierInUse		bit		= 0,
	@pbIsNameInUse			bit	 	= 0,
	@pbIsTitleInUse			bit	 	= 0,
	@pbIsInitialsInUse		bit		= 0,
	@pbIsFirstNameInUse		bit		= 0,
	@pbIsExtendedNameInUse		bit		= 0,
	@pbIsSearchKey1InUse		bit		= 0,
	@pbIsSearchKey2InUse		bit		= 0,
	@pbIsNationalityCodeInUse	bit		= 0,
	@pbIsDateCeasedInUse		bit		= 0,
	@pbIsRemarksInUse		bit		= 0,
	@pbIsGroupKeyInUse		bit		= 0,
	@pbIsNameStyleKeyInUse		bit		= 0,
	@pbIsInstructorPrefixInUse	bit		= 0,
	@pbIsCaseSequenceInUse		bit		= 0	
)
as
-- PROCEDURE:	naw_DeleteName
-- VERSION:	9
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Name if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 18 Apr 2006	SW	RFC3503	1	Procedure created
-- 15 May 2006	SW	RFC3503	2	Add @pdtDateCeased and @psRemarks
-- 18 Dec 2007	SW	RFC5740	3	Add new columns @pnSource, @pdEstimatedRev and @pnStatus
-- 19 Dec 2007	AT	RFC4079	4	Updated procedure logic to include c/s logic and error checking
-- 02 Jan 2008	SW	RFC5740	5	Change column STATUS to NAMESTATUS, add new column CRMONLY
-- 11 Jan 2008	SW	RFC5740	6	Change column SOURCE to NAMESOURCE
-- 07 Jul 2008	SF	RFC6508	7	Remove references to CRM related columns that have been relocated.
-- 30 Jul 2008	AT	RFC6877	8	Added trans count check to transaction processing. 
--					Added delete to NAMETYPECLASSIFICATION.
-- 19 May 2014	KR	R13964	9	Made name code length 40 (from 10)

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sSelectStatement	nvarchar(500)
Declare @sDeleteStatement	nvarchar(500)
Declare @sWhereString		nvarchar(4000)
Declare @sAnd			nchar(5)
Declare @nRowCount		int
Declare @nOrphanAddressCount	int
Declare @nOrphanTeleCount	int
Declare @sAlertXML 		nvarchar(400)
Declare @nTranCountStart	int

-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount = 1 -- anything not 0 to bypass checking if not deleting name text

-- Only proceeds if no concurrency/other error when delete @psOldExtendedName. 
If @nRowCount > 0 and @nErrorCode = 0
Begin
	Set @sAnd = " and "

	Set @sSelectStatement = "Select 1 from NAME where"
	Set @sDeleteStatement = "Delete from NAME where "

	Set @sWhereString = @sWhereString+CHAR(10)+" NAMENO = @pnNameKey "

	If @pbIsNameCodeInUse = 1
	Begin
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"NAMECODE = @psOldNameCode"
	End

	If (@pbIsIndividualInUse = 1 or @pbIsStaffInUse = 1 or @pbIsClientInUse = 1)
	Begin

		If @pbIsIndividualInUse = 1
		Begin
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"USEDASFLAG & 1 = coalesce(@pbOldIsIndividual, ~@pbOldIsOrganisation, 0) * 1"
		End
	
		If @pbIsStaffInUse = 1
		Begin
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"USEDASFLAG & 2 = isnull(@pbOldIsStaff, 0) * 2"
		End
	
		If @pbIsClientInUse = 1
		Begin
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"USEDASFLAG & 4 = isnull(@pbOldIsClient, 0) * 4"
		End
		
	End

	If @pbIsSupplierInUse = 1
	Begin
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"(SUPPLIERFLAG = isnull(@pbOldIsSupplier, 0)"

		if @pbOldIsSupplier = 0
		Begin
			Set @sWhereString = @sWhereString + "or SUPPLIERFLAG is null"
		End
		Set @sWhereString = @sWhereString + ")"
	End

	If @pbIsNameInUse = 1
	Begin
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"NAME = @psOldName"
	End

	If @pbIsTitleInUse = 1
	Begin
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"TITLE = @psOldTitle"
		
	End

	If @pbIsInitialsInUse = 1
	Begin
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"INITIALS = @psOldInitials"
		
	End

	If @pbIsFirstNameInUse = 1
	Begin
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"FIRSTNAME = @psOldFirstName"
		
	End

	If @pbIsSearchKey1InUse = 1
	Begin
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"SEARCHKEY1 = @psOldSearchKey1"
		
	End

	If @pbIsSearchKey2InUse = 1
	Begin
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"SEARCHKEY2 = @psOldSearchKey2"
		
	End

	If @pbIsNationalityCodeInUse = 1
	Begin
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"NATIONALITY = @psOldNationalityCode"
		
	End

	If @pbIsDateCeasedInUse = 1
	Begin
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"DATECEASED = @pdtOldDateCeased"
	End

	If @pbIsRemarksInUse = 1
	Begin
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"REMARKS = @psOldRemarks"
	End

	If @pbIsGroupKeyInUse = 1
	Begin
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"FAMILYNO = @pnOldGroupKey"
	End

	If @pbIsNameStyleKeyInUse = 1
	Begin
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"NAMESTYLE = @pnOldNameStyleKey"
	End

	If @pbIsInstructorPrefixInUse = 1
	Begin
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"INSTRUCTORPREFIX = @psOldInstructorPrefix"
	End

	If @pbIsCaseSequenceInUse = 1
	Begin
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CASESEQUENCE = @pnOldCaseSequence"
	End

	Set @sSQLString = @sSelectStatement + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey		int,
			@psOldNameCode		nvarchar(20),
			@pbOldIsIndividual	bit,
			@pbOldIsOrganisation	bit,
			@pbOldIsStaff		bit,
			@pbOldIsClient		bit,
			@pbOldIsSupplier	bit,
			@psOldName		nvarchar(254),
			@psOldTitle		nvarchar(20),
			@psOldInitials		nvarchar(10),
			@psOldFirstName		nvarchar(50),
			@psOldSearchKey1	nvarchar(20),
			@psOldSearchKey2	nvarchar(20),
			@psOldNationalityCode	nvarchar(3),
			@pdtOldDateCeased	datetime,
			@psOldRemarks		nvarchar(254),
			@pnOldGroupKey		int,
			@pnOldNameStyleKey	int,
			@psOldInstructorPrefix	nvarchar(10),
			@pnOldCaseSequence	smallint',

			@pnNameKey	 	= @pnNameKey,
			@psOldNameCode		= @psOldNameCode,
			@pbOldIsIndividual	= @pbOldIsIndividual,
			@pbOldIsOrganisation	= @pbOldIsOrganisation,
			@pbOldIsStaff		= @pbOldIsStaff,
			@pbOldIsClient		= @pbOldIsClient,
			@pbOldIsSupplier	= @pbOldIsSupplier,
			@psOldName	 	= @psOldName,
			@psOldTitle	 	= @psOldTitle,
			@psOldInitials	 	= @psOldInitials,
			@psOldFirstName	 	= @psOldFirstName,
			@psOldSearchKey1	= @psOldSearchKey1,
			@psOldSearchKey2	= @psOldSearchKey2,
			@psOldNationalityCode	= @psOldNationalityCode,
			@pdtOldDateCeased	= @pdtOldDateCeased,
			@psOldRemarks		= @psOldRemarks,
			@pnOldGroupKey	 	= @pnOldGroupKey,
			@pnOldNameStyleKey	= @pnOldNameStyleKey,
			@psOldInstructorPrefix	= @psOldInstructorPrefix,
			@pnOldCaseSequence	= @pnOldCaseSequence

	Set @nRowCount = @@rowcount
	
	If (@nRowCount <= 0)
	Begin
		-- Could not find the name
		Set @nErrorCode = 1
		Set @sAlertXML = dbo.fn_GetAlertXML('NA49', 'Name Not Found. The Name may have been updated or deleted since you opened Name Maintenance.',
						null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
	End
End

-- Make sure name is not associated to any cases
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select 1 from CASENAME WHERE NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnNameKey	int',
		@pnNameKey = @pnNameKey

	If (@@rowcount > 0)
	Begin
		-- Name is still associated to a case
		Set @nErrorCode = 1
		Set @sAlertXML = dbo.fn_GetAlertXML('NA45', 'The Name is used by one or more Cases. Cannot delete the name.',
						null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
	End
End

-- Make sure name is not associated to any other names
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select 1 from ASSOCIATEDNAME WHERE NAMENO = @pnNameKey
						OR RELATEDNAME = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnNameKey	int',
		@pnNameKey = @pnNameKey

	If (@@rowcount > 0)
	Begin
		-- Name is still associated to another name
		Set @nErrorCode = 1
		Set @sAlertXML = dbo.fn_GetAlertXML('NA46', 'The Name is associated to one or more Names. Cannot delete the name.',
						null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
	End
End

If @nErrorCode = 0
Begin
	-- Start the actual deleting of data
	Select @nTranCountStart = @@TranCount
	BEGIN TRANSACTION
End

-- Only delete the name if there are no concurrency errors
If @nErrorCode = 0
Begin
	If @pbIsExtendedNameInUse = 1 and @psOldExtendedName is not null
	Begin
		-- Remove @psOldExtendedName by dbo.naw_DeleteNameText
		Exec @nErrorCode = dbo.naw_DeleteNameText
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pnNameKey		= @pnNameKey,
			@psTextTypeKey		= 'N',
			@ptOldText		= @psOldExtendedName
	
		set @nRowCount = @@rowcount

		If (@nRowCount <= 0)
		Begin
			-- Could not delete the old extended name
			Set @nErrorCode = 1
			Set @sAlertXML = dbo.fn_GetAlertXML('NA47', 'Could not delete old extended name. The Name Text, Old Extended Name could not be deleted. The Name has not been deleted.',
							null, null, null, null, null)
			RAISERROR(@sAlertXML, 14, 1)
		End
	End
End

-- Delete NameAddresses
If @nErrorCode = 0
Begin
	-- Store any addresses that will be orphaned when the name is deleted
	If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = '#ORPHANADDRESSCODES' )
	Begin
		DROP TABLE #ORPHANADDRESSCODES
	End

	CREATE TABLE #ORPHANADDRESSCODES(CODE INT)

	INSERT INTO #ORPHANADDRESSCODES(CODE)
	SELECT A.ADDRESSCODE FROM ADDRESS A
	JOIN NAMEADDRESS NA ON (NA.ADDRESSCODE = A.ADDRESSCODE
				AND NA.NAMENO = @pnNameKey)
	where A.ADDRESSCODE NOT IN
		(SELECT ADDRESSCODE FROM NAMEADDRESS
		WHERE ADDRESSCODE IN (SELECT ADDRESSCODE FROM NAMEADDRESS WHERE NAMENO = @pnNameKey)
		AND NAMENO != @pnNameKey
		GROUP BY ADDRESSCODE
		HAVING count(NAMENO) > 0)
	
	Set @nOrphanAddressCount = @@rowcount
	
	-- delete the name addresses
	DELETE FROM NAMEADDRESS WHERE NAMENO = @pnNameKey

	Set @nErrorCode = @@Error
End

-- Delete NameTelecom
If @nErrorCode = 0
Begin
	-- Store any telecodes that will be orphaned when the name is deleted
	If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = '#ORPHANTELECODES' )
	Begin
		DROP TABLE #ORPHANTELECODES
	End

	CREATE TABLE #ORPHANTELECODES(CODE INT)

	INSERT INTO #ORPHANTELECODES(CODE)
	SELECT T.TELECODE FROM TELECOMMUNICATION T
	JOIN NAMETELECOM NT ON (NT.TELECODE = T.TELECODE
				AND NT.NAMENO = @pnNameKey)
	where T.TELECODE NOT IN
		(SELECT TELECODE FROM NAMETELECOM
		WHERE TELECODE IN (SELECT TELECODE FROM NAMETELECOM WHERE NAMENO = @pnNameKey)
		AND NAMENO != @pnNameKey
		GROUP BY TELECODE
		HAVING count(NAMENO) > 0)
	
	Set @nOrphanTeleCount = @@rowcount

	-- delete the name addresses
	DELETE FROM NAMETELECOM WHERE NAMENO = @pnNameKey

	Set @nErrorCode = @@Error
End

if @nErrorCode = 0
begin
	-- There are cascade deletes for Individual, Employee and IPName
	-- but not for Organisation and Creditor.  Delete the organisation, if any, first.

	delete from ORGANISATION where NAMENO = @pnNameKey

	select @nErrorCode = @@Error	
end

if @nErrorCode = 0
begin
	delete from CREDITOR where NAMENO = @pnNameKey

	select @nErrorCode = @@Error	
end

if @nErrorCode = 0
begin
	delete from TABLEATTRIBUTES 
	where 	PARENTTABLE = 'NAME'
	and	GENERICKEY = cast(@pnNameKey as nvarchar(20))

	select @nErrorCode = @@Error
end

if @nErrorCode = 0
begin
	delete from ASSOCIATEDNAME
	where 	RELATEDNAME = @pnNameKey
	or	NAMENO	= @pnNameKey
	or 	CONTACT	= @pnNameKey

	select @nErrorCode = @@Error
end

if @nErrorCode = 0
begin
	delete from NAMETYPECLASSIFICATION
	where 	NAMENO	= @pnNameKey

	select @nErrorCode = @@Error
end

If @nErrorCode = 0
Begin
	Set @sSQLString = @sDeleteStatement + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey		int,
			@psOldNameCode		nvarchar(20),
			@pbOldIsIndividual	bit,
			@pbOldIsOrganisation	bit,
			@pbOldIsStaff		bit,
			@pbOldIsClient		bit,
			@pbOldIsSupplier	bit,
			@psOldName		nvarchar(254),
			@psOldTitle		nvarchar(20),
			@psOldInitials		nvarchar(10),
			@psOldFirstName		nvarchar(50),
			@psOldSearchKey1	nvarchar(20),
			@psOldSearchKey2	nvarchar(20),
			@psOldNationalityCode	nvarchar(3),
			@pdtOldDateCeased	datetime,
			@psOldRemarks		nvarchar(254),
			@pnOldGroupKey		int,
			@pnOldNameStyleKey	int,
			@psOldInstructorPrefix	nvarchar(10),
			@pnOldCaseSequence	smallint',
			@pnNameKey	 	= @pnNameKey,
			@psOldNameCode		= @psOldNameCode,
			@pbOldIsIndividual	= @pbOldIsIndividual,
			@pbOldIsOrganisation	= @pbOldIsOrganisation,
			@pbOldIsStaff		= @pbOldIsStaff,
			@pbOldIsClient		= @pbOldIsClient,
			@pbOldIsSupplier	= @pbOldIsSupplier,
			@psOldName	 	= @psOldName,
			@psOldTitle	 	= @psOldTitle,
			@psOldInitials	 	= @psOldInitials,
			@psOldFirstName	 	= @psOldFirstName,
			@psOldSearchKey1	= @psOldSearchKey1,
			@psOldSearchKey2	= @psOldSearchKey2,
			@psOldNationalityCode	= @psOldNationalityCode,
			@pdtOldDateCeased	= @pdtOldDateCeased,
			@psOldRemarks		= @psOldRemarks,
			@pnOldGroupKey	 	= @pnOldGroupKey,
			@pnOldNameStyleKey	= @pnOldNameStyleKey,
			@psOldInstructorPrefix	= @psOldInstructorPrefix,
			@pnOldCaseSequence	= @pnOldCaseSequence

		if @nErrorCode!=0
		Begin
			--Name is referenced somewhere else
			Set @nErrorCode = @@Error
			Set @sAlertXML = dbo.fn_GetAlertXML('NA48', 'The requested Name cannot be deleted as it is essential to other existing information.',
							null, null, null, null, null)
			RAISERROR(@sAlertXML, 14, 1)
		End
End

if @nOrphanAddressCount > 0 AND @nErrorCode = 0
Begin
	-- delete the orphaned addresses
	DELETE FROM ADDRESS
	WHERE ADDRESSCODE IN (SELECT CODE FROM #ORPHANADDRESSCODES)

	select @nErrorCode = @@Error
End

if @nOrphanTeleCount > 0 AND @nErrorCode = 0
Begin
	-- delete the orphaned telecoms
	DELETE FROM TELECOMMUNICATION
	WHERE TELECODE IN (SELECT CODE FROM #ORPHANTELECODES)

	select @nErrorCode = @@Error
End

If @nErrorCode = 0
Begin
	-- delete name text
	delete from NAMETEXT WHERE NAMENO = @pnNameKey

	select @nErrorCode = @@Error
End

If @nErrorCode = 0
Begin
	-- clear main contact links to this name.
	update NAME set MAINCONTACT = NULL where MAINCONTACT = @pnNameKey

	select @nErrorCode = @@Error
End

-- Commit the transaction if something was deleted/updated.
If @@TranCount > @nTranCountStart
Begin
	If @nErrorCode = 0
	Begin
		COMMIT TRANSACTION
	End
	Else
	Begin
		-- rollback translation changes if there was an error (concurrency failed)
		ROLLBACK TRANSACTION
	End
End

If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = '#ORPHANADDRESSCODES' )
Begin
	DROP TABLE #ORPHANADDRESSCODES
End

If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = '#ORPHANTELECODES' )
Begin
	DROP TABLE #ORPHANTELECODES
End


Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteName to public
GO