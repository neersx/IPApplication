----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_LicenceServer
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ip_LicenceServer]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_LicenceServer.'
	Drop procedure dbo.ip_LicenceServer
End
Print '**** Creating Stored Procedure dbo.ip_LicenceServer...'
Print ''
go

SET QUOTED_IDENTIFIER OFF 
go

CREATE PROCEDURE dbo.ip_LicenceServer
(
	-- Standard parameters
	@pnUserIdentityId		int,
	@psCulture			nvarchar(10) 	= null,
	-- Input parameters
	@psComputerIdentifier		nvarchar(100)	= null,		-- name of computer / IP address
	@psProgramName			nvarchar(40),  			-- name of application being run
	@pbInvokedByCentura		bit		= 0, 
	-- Output parameters
	@pbBlockUser			bit 		= null output, -- Flag to indicate that the user should not be allowed to continue
	@pnFailReason			int		= null output,
        @psModule			nvarchar(40)	= null output  -- licensing module to which application belongs
)
with ENCRYPTION
AS

-- PROCEDURE:	ip_LicenceServer
-- VERSION:	16
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the result of the Licensing check.
-- NOTES:	@pbBlockUser returns 0 = user is allowed to continue
--                                   1 = User is blocked from continuing
--
--              @pnFailReason        0 = License check succeeded.
--                                   1 = Total number of live cases is greater than the allowed amount. (warning)
--                                   2 = User is already using application on another machine (block)
--                                   3 = Total number of users is greater than the allowed number (block)
--                                   4 = User/Firm not licensed to use the current module
--				     5 = License does not match the firm's name or not found

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 16 Mar 2004	Dw	9758	1	stub procedure created (as placeholder)
-- 18 Mar 2004  JB              2       added explanation of parameters in NOTES
-- 5  Apr 2004  JB	7660	3	Filled out stored procedure
-- 13 May 2004  VL	7660	4	implement review feedback
-- 24 May 2004 	JB	7660	5	Extend date of kick-in to 1/10/2004
-- 10 Aug 2004	VL	9983	6	do not check license when running 'SECURE'
-- 11 Aug 2004	VL	10334	7	make enhancements to the stored procedure
-- 18 Aug 2004	VL	10334	8	LICENSE table to nvarchar(254) and only insert into
--					MODULEUSAGE table if a row doesnt already exist.
-- 02 Sep 2004	VL	10334	9	only get licence for first module.
-- 10 Sep 2004	VL	10334	10	do not block when live cases exceeded and do all block checks first.
--					and include case with STATUSCODE null for live case check.
-- 28 Oct 2004	TM	RFC870	11	Change the @psComputerIdentifier parameter to be optional.
-- 05 Nov 2004	MF	10624	12	Duplicate key error occuring on insert into MODULEUSAGE on rare occassions.
--					Tighten code by using explicit Transaction and Commit.
-- 08 Nov 2004	VL	10517	13	Licensing is not recognising Financial Interface as a stand alone module.
-- 29 May 2006	vql	11588	14	Add Expiry Date Check.
-- 14 Mar 2008	JS	14826	15	Check for old unlimited consultants licences.
-- 05 Jan 2008	vql	16320	16	Cater for upgrading licences from Client Server to WorkBenches

--
-- Remember to update the version number at the top!

-- NOTE THAT NO ENCRYPTION HAS BEEN DONE AND A FUNCTION SHOULD BE WRITTEN TO DECRYPT DATA
-- AND THIS SHOULD BE EMBEDDED INTO THIS STORED PROCEDURE WHEN AVAILABLE

Set nocount on
Set concat_null_yields_null off

Declare @nErrorCode 		int
Declare	@TranCountStart 	int
Declare @bAllDone		bit
Declare @nPricingModel		smallint	
Declare @sFirmName		nvarchar(210)   
Declare @sModuleIds 		nvarchar(100)
Declare @nModuleId		int
Declare @nModuleUsers 		int
Declare @nMaxCases 		int
Declare	@dtExpiryDate	 	datetime
Declare	@bExpiryAction		bit
Declare	@nExpiryWarningDays	int

Declare @bDataExists	bit
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
Set @pbBlockUser = 1
Set @pnFailReason = 5
Set @bAllDone = 0

-- --------------------------------------------------------
-- Check: Only do checks if the program being run is not security
If @psProgramName = 'SECURE'
Begin
	-- No further checks are required
	Set @bAllDone = 1
	Set @pbBlockUser = 0
	Set @pnFailReason = 0
End

-- -------------------------------------------------------
-- Check: Only do anything if the date is after 5/10/2004
If getdate() < CONVERT(smalldatetime, '2004-10-05', 21)
Begin
	-- No further checks are required
	Set @bAllDone = 1
	Set @pbBlockUser = 0
	Set @pnFailReason = 0
End
Else Begin
--	Print 'Getting the valid module IDs and Firm License Data'
	Declare @nFirstModule 	int
	Declare @sModuleIdsCopy	nvarchar(100)

	Set @sModuleIds = dbo.fn_GetModuleId(@psProgramName)
	-- find licence for modules this program is part of.
	
	Set @sModuleIdsCopy = @sModuleIds
	-- program may be part of more than one module. so need to check all relevant licenses. 
	While LEN(@sModuleIdsCopy) > 0
	Begin
		Set @nFirstModule = cast(left(@sModuleIdsCopy, 2) as int)
		If dbo.fn_IsModuleLicensed( @pnUserIdentityId, @nFirstModule ) = 1
			Break
		Else
			Set @sModuleIdsCopy = SUBSTRING(@sModuleIdsCopy, 4, 100)
	End

	-- Need to find out the firm license details
	Exec @nErrorCode = ip_GetLicenseData
		@pnPricingModel 	= @nPricingModel output,
		@pnMaxCases 		= @nMaxCases output,
		@psFirmName 		= @sFirmName output,
		@pnModuleId  		= @nFirstModule,
		@pnUserIdentityId	= @pnUserIdentityId
End

-- ---------------------------------------------------------
-- Check that the firm (model 1 unlimited users) or user (other models)
-- is allowed to use the current module (whichever that is)
If @nErrorCode = 0 and @bAllDone != 1
Begin
	--Print 'Checking Module Access'

	While LEN(@sModuleIds) > 0
	Begin
		Set @nModuleId = cast(left(@sModuleIds, 2) as int)

		If @nPricingModel = 1
		Begin
			-- We need to find any valid module (for the current program) that 
			-- the firm is licensed for (useridentity is ignored)
			Exec @nErrorCode = ip_GetLicenseData
				@pnPricingModel 	= @nPricingModel output,
				@pnMaxCases 		= @nMaxCases output,
				@psFirmName 		= @sFirmName output,
				@pnModuleUsers		= @nModuleUsers output,
				@dtExpiryDate	 	= @dtExpiryDate	output,
				@bExpiryAction		= @bExpiryAction output,
				@nExpiryWarningDays	= @nExpiryWarningDays output,
				@pnModuleId  		= @nModuleId,
				@pnUserIdentityId	= @pnUserIdentityId

		End
		Else
		Begin
			Set @sSQLString = "
				Select @bDataExists = 1
				from LICENSEDUSER
				where MODULEID = @nModuleId
				and USERIDENTITYID = @pnUserIdentityId"

			Exec @nErrorCode = sp_executesql @sSQLString,
					N'@bDataExists		bit OUTPUT,
					  @nModuleId		int,
					  @pnUserIdentityId	int',
					  @bDataExists		=@bDataExists OUTPUT,
					  @nModuleId		=@nModuleId,
					  @pnUserIdentityId	=@pnUserIdentityId

			If @bDataExists = 1
			Begin
				-- And check that they are actually licensed to use it
				Exec @nErrorCode = ip_GetLicenseData
					@pnPricingModel 	= @nPricingModel output,
					@pnMaxCases 		= @nMaxCases output,
					@psFirmName 		= @sFirmName output,
					@pnModuleUsers		= @nModuleUsers output,
					@dtExpiryDate	 	= @dtExpiryDate	output,
					@bExpiryAction		= @bExpiryAction output,
					@nExpiryWarningDays	= @nExpiryWarningDays output,
					@pnModuleId  		= @nModuleId,
					@pnUserIdentityId	= @pnUserIdentityId
			End
		End

		If @nModuleUsers is not null
			Break
		Else
			Set @sModuleIds = SUBSTRING(@sModuleIds, 4, 100)

	End

	If @nModuleUsers is  null -- no one is licensed to use the modules (model 1) 
				  -- or this user is not licensed to use the modules (other models)
				  -- that this program belongs to.
	Begin
		Set @bAllDone = 1
		Set @pbBlockUser = 1
		Set @pnFailReason = 4
	End
End

-- ---------------------------------------------------------
-- Check: For Pricing Models other than 1 check the number of users
If @nErrorCode = 0 and @bAllDone != 1 and @nPricingModel != 1
Begin
	--Print 'Checking Number of Users'

	Declare @nUsersUsingModule int

	-- If there site has module 28 do check differently.
	If @nModuleId = 28
	Begin
	    Set @sSQLString = "
		    Select @nUsersUsingModule = count(*)
		    from LICENSEDUSER
		    where MODULEID in (21,2)"
	End
	Else
	Begin
	    Set @sSQLString = "
		    Select @nUsersUsingModule = count(*)
		    from LICENSEDUSER
		    where MODULEID = @nModuleId"
	End

	Exec @nErrorCode = sp_executesql @sSQLString,
			      N'@nUsersUsingModule	int OUTPUT,
				@nModuleId		int',
				@nUsersUsingModule 	=@nUsersUsingModule OUTPUT,
				@nModuleId		=@nModuleId

	If @nUsersUsingModule > @nModuleUsers 
	Begin
		Set @bAllDone = 1
		Set @pbBlockUser = 1
		Set @pnFailReason = 3
	End	
End

-- ----------------------------------------------------------
-- Check: If Expiry Date is less than today and flagged to BLOCK then block user.
If @nErrorCode = 0 and @bAllDone != 1  and @dtExpiryDate is not null
Begin
	If @dtExpiryDate < getdate( ) and @bExpiryAction = 1
	Begin
		Set @bAllDone = 1
		Set @pbBlockUser = 1
		Set @pnFailReason = 6
	End
End	

-- Rest of the Expiry Date checks are done after the live property cases check.

-- ---------------------------------------------------------
-- Check: Number of live property cases exceeded the number licensed
If @nErrorCode = 0 and @bAllDone != 1
Begin
	If @nMaxCases != -1	-- if unlimited cases dont check
	Begin
		--Print 'Checking Total Number of Live Cases'
		Declare @nLiveCases int

		-- lower the locking level to the lowest level.  This will ensure
		-- the Select will not be blocked by other database activity	
		set transaction isolation level read uncommitted
	
		Set @sSQLString = "
			Select @nLiveCases = COUNT(*)
			from CASES C
			left join STATUS ST      on ST.STATUSCODE=C.STATUSCODE
			join PROPERTY P     on P.CASEID=C.CASEID
			left join STATUS RS on RS.STATUSCODE=P.RENEWALSTATUS
			where isnull(ST.LIVEFLAG,1)<>0 
			and isnull(RS.LIVEFLAG,1)<>0
			and C.CASETYPE = 'A'"
		
		Exec @nErrorCode = sp_executesql @sSQLString,
					      N'@nLiveCases	int OUTPUT',
						@nLiveCases 	=@nLiveCases OUTPUT
	
		-- Reset the locking level	
		set transaction isolation level read committed
	
		If @nLiveCases > @nMaxCases
		Begin
			Set @bAllDone = 1
			Set @pbBlockUser = 0
			Set @pnFailReason = 1
		End
	End
End

-- ----------------------------------------------------------
-- Check: If expiry date is less than  today + warning days and if they are going to be blocked then give warning.
-- 	  Do not block yet. 
--	  Note that we only give this message when the Expiry Action is to block the user.
--	  Note also that we dont bother checking if @dtExpiryDate is null. This means there is no expiry date.
If @nErrorCode = 0 and @bAllDone != 1 and @dtExpiryDate is not null
Begin
	If ( @dtExpiryDate < getdate( ) + @nExpiryWarningDays ) and ( @dtExpiryDate >= getdate( ) ) and ( @bExpiryAction = 1 )
	Begin
		Set @bAllDone = 1
		Set @pbBlockUser = 0
		Set @pnFailReason = 8
	End
End
	
-- Check: If Expiry Date is less than today and flagged to warn.
If @nErrorCode = 0 and @bAllDone != 1  and @dtExpiryDate is not null
Begin
	If @dtExpiryDate < getdate( ) and @bExpiryAction = 0
	Begin
		Set @bAllDone = 1
		Set @pbBlockUser = 0
		Set @pnFailReason = 7
	End
End	

-- Check: If this is an old unlimited consultants licence then block user. 
If @nErrorCode = 0 and @bAllDone != 1
Begin
	If @sFirmName = 'CPA Software Solutions Pty Limited' and @dtExpiryDate is null and @nPricingModel = 1 
	Begin
		Set @bAllDone = 1
		Set @pbBlockUser = 1
		Set @pnFailReason = 9
	End
End	

-- ----------------------------------------------------------
-- Check: User running the same module on different machines.
--	  check only logs to MODULEUSAGE not enforced anymore.
If @nErrorCode = 0 and @bAllDone != 1
Begin
	If @nErrorCode=0
	Begin
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION
	End

	-- Firstly clean out any data that is out of date this keeps 
	-- the database clean and makes the query simpler
	Delete 
	from MODULEUSAGE
	where dateadd(minute, 20, USAGETIME)  < GETDATE()

	Set @nErrorCode = @@error

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End
	
-- ----------------------------------------------------------
-- All checks have been done and passed if at this point @bAllDone is not equal to 1.
-- so set @pnFailReason to 0 and @pbBlockUser to 0.
If @nErrorCode = 0 and @bAllDone != 1
Begin
	Set @bAllDone = 1
	Set @pbBlockUser = 0
	Set @pnFailReason = 0
End

-- ----------------------------------------------------------
-- Add an entry to USAGELOG
If  @nErrorCode = 0 
and @pnFailReason = 0
Begin
	If  @nModuleId is not null
	and @pnUserIdentityId is not null
	and @psComputerIdentifier is not null
	Begin
		-- Begin an explicit transaction
		If @nErrorCode=0
		Begin
			Select @TranCountStart = @@TranCount
			BEGIN TRANSACTION
		End

		Set @sSQLString = "
		Insert into MODULEUSAGE (MODULEID, IDENTITYID, USAGETIME, COMPUTERIDENTIFIER)
		Select @nModuleId, @pnUserIdentityId, GETDATE(), @psComputerIdentifier
		where not exists
		(select * from MODULEUSAGE
		 where MODULEID=@nModuleId
		 and IDENTITYID=@pnUserIdentityId)"
	
		Exec @nErrorCode = sp_executesql @sSQLString,
					      N'@nModuleId		int,
						@pnUserIdentityId	int,
						@psComputerIdentifier	nvarchar(100)',
						@nModuleId 		=@nModuleId,
						@pnUserIdentityId	=@pnUserIdentityId,
						@psComputerIdentifier	=@psComputerIdentifier

		-- Commit or Rollback the transaction
		
		If @@TranCount > @TranCountStart
		Begin
			If @nErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End
End

-- ----------------------------------------------------------
-- Wrap-up 

-- Find out the Module Name to pass back

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select @psModule = MODULENAME
		from LICENSEMODULE
		where MODULEID = @nModuleId"

	Exec @nErrorCode = sp_executesql @sSQLString,
					      N'@psModule		nvarchar(40) OUTPUT,
						@nModuleId		int',
						@psModule		=@psModule OUTPUT,
						@nModuleId 		=@nModuleId
End

-- Return the results if called from Centura

If @pbInvokedByCentura = 1
Begin
	Select	@pbBlockUser AS BLOCKUSER, 
		@pnFailReason AS FAILREASON, 
		@psModule AS MODULE,
		@dtExpiryDate AS EXPIRYDATE
End	

Return @nErrorCode
go

Grant execute on dbo.ip_LicenceServer to public
go
