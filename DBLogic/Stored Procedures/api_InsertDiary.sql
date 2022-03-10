-----------------------------------------------------------------------------------------------------------------------------
-- Creation of api_InsertDiary
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'dbo.api_InsertDiary') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.api_InsertDiary.'
	drop procedure dbo.api_InsertDiary
	print '**** Creating Stored Procedure dbo.api_InsertDiary...'
	print ''
end
GO

set QUOTED_IDENTIFIER on -- this is required for the XML Nodes method
go
SET ANSI_NULLS ON 
GO

create procedure dbo.api_InsertDiary
	@pnUserIdentityId		int		= null,	-- optional identifier of the user
	@pnStaffMemberId		int,			-- Mandatory
	@pdtEntryDate			datetime,		-- Mandatory Date (no time) in which time is to be recorded for
	@pnCaseId			int		= null,
	@psActivityCode			nvarchar(6),		-- Mandatory
	@pdtTimePeriod			datetime,		-- Mandatory
	@pdtStartTime			datetime	= null,
	@pdtEndTime			datetime	= null,
	@psNarrative			nvarchar(max)	= null
as
-- PROCEDURE :	api_InsertDiary
-- VERSION :	4
-- DESCRIPTION:	Creates an unposted but fully costed time line in the
--		Inprotech timesheet based upon the information provided.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 27 Mar 2014	MF	32616	1	Procedure created
-- 14 Jul 2014	MF	37308	2	UserIdentityId should be determined from the StaffMemberId provided if
--					it UserIdentityId is not explicitly provided.
-- 20 Oct 2015  MS      R53933  3       Changed exchange rate size from decimal(8,4) to decimal(11,4)
-- 12 Jan 2018	MF	73284	4	Restrictions that would apply when entering a diary entry are to be applied.

set nocount on

declare @tblDebtors		table (
	NAMENO			int		NOT NULL,
	BILLPERCENTAGE		decimal(5,2)	NOT NULL,
	NARRATIVENO		int		NULL,
	LANGUAGEKEY		int		NULL,
	SEQUENCE		tinyint		identity(1,1)
	)
	
declare @tbDebtorSplitDiary	table (
	EMPLOYEENO		int		NOT NULL,
	NAMENO			int		NOT NULL,
	TIMEVALUE		decimal(10,2)	NULL,
	CHARGEOUTRATE		decimal(10,2)	NULL,
	NARRATIVENO		int		NULL, 
	NARRATIVE		nvarchar(max)	collate database_default NULL, 
	DISCOUNTVALUE		decimal(10,2)	NULL, 
	FOREIGNCURRENCY		nvarchar(3)	NULL, 
	FOREIGNVALUE		decimal(11,2)	NULL,
	EXCHRATE		decimal(11,4)	NULL, 
	FOREIGNDISCOUNT		decimal(11,2)	NULL,
	COSTCALCULATION1	decimal(11,2)	NULL, 
	COSTCALCULATION2	decimal(11,2)	NULL,
	MARGINNO		int		NULL,
	SPLITPERCENTAGE		decimal(5,2)	NULL
	)

declare	@sSQLString		nvarchar(max)

-- Data used in transaction logging
declare	@bHexNumber		varbinary(128)
declare @nOfficeID		int
declare	@nLogMinutes		int 
declare	@nTransNo		int
declare	@nBatchNo		int		-- place holder only as not used here

-- Variables
declare @sTime			char(8)
declare @nMinutes		decimal(7,2)	-- defined as decimal to aid in conversion to Units
declare @nHours			tinyint
declare @nSeconds		tinyint
declare	@nUnitsPerHour		tinyint
declare @nUnits			smallint
declare	@nEntryNo		int
declare	@bRoundUp		bit
declare @bCountSeconds		bit
declare @bWIPSplit		bit
declare	@bBillRenewal		bit
declare @bTranslate		bit

declare @sNameType		nvarchar(3)
declare @sNarrative		nvarchar(max)
declare @sFirstNarrative	nvarchar(max)
declare @nNarrativeNo		int
declare	@nLanguageKey		int
declare @nDebtor		int
declare @nBillPercentage	decimal(5,2)
declare @nSequence		tinyint
declare	@nRestictionSeverity	tinyint


	-- Hours based services calculations
	-- Either @pdtHours or @pnTimeUnits should be provided, the other is derived.
declare	@dtHours		datetime
declare	@nTimeUnits		int
declare	@nChargeOutRate		dec(10,2)

	-- Calculations based on value supplied by the user.
	-- Either local or foreign (and @psCurrencyCode) should be provided.
declare	@nLocalValuePreMargin	dec(11,2)
declare	@nForeignValuePreMargin	dec(11,2)

	-- Value of the WIP
declare	@sCurrencyCode		nvarchar(3)
declare	@nExchangeRate		dec(11,4)
declare	@nLocalValue		dec(11,2)
declare	@nForeignValue		dec(11,2)

	-- Margin
declare	@nMarginValue		dec(11,2)	-- Expressed in @psCurrencyCode
declare	@nMarginNo		int

	-- Discount
declare	@nLocalDiscount		dec(11,2)
declare	@nForeignDiscount	dec(11,2)
	
	-- Discounts for margin 
declare	@nLocalDiscForMargin	decimal(11,2)
declare	@nForeignDiscForMargin	decimal(11,2)

	-- Costs
declare	@nLocalCost1		dec(11,2)
declare	@nLocalCost2		dec(11,2)

	-- Totals for split debtors
declare @nTotalLocalValue	dec(11,2)
declare @nTotalLocalDiscount	dec(11,2)
declare @nTotalLocalCost1	dec(11,2)
declare @nTotalLocalCost2	dec(11,2)

declare @nErrorCode		int
declare	@nRowCount		int
declare @TranCountStart		int

-----------------------
-- Initialise Variables
-----------------------
set @nErrorCode         =0
Set @nTotalLocalValue   =0
Set @nTotalLocalDiscount=0
Set @nTotalLocalCost1   =0
Set @nTotalLocalCost2   =0

--------------------------------------------------
-- D A T A   V A L I D A T I O N
-- Validate the input parameters before attempting
-- to create a Diary entry for recorded time.
--------------------------------------------------

------------------------
-- Validate Staff Member
------------------------
If @nErrorCode = 0
Begin
	If @pnStaffMemberId is null
	OR not exists (select 1 from EMPLOYEE where EMPLOYEENO=@pnStaffMemberId)
	Begin	
		RAISERROR('@pnStaffMemberId must identify a Name marked as staff and exist in the EMPLOYEE table', 14, 1)
		Set @nErrorCode = -1
	End	
End

------------------------
-- Validate Date is not
-- in the future.
------------------------
If  @nErrorCode = 0
and @pdtEntryDate>getdate()
Begin
	RAISERROR('@pdtEntryDate must not be after the current system date', 14, 1)
	Set @nErrorCode = -2
End

------------------------
-- Validate CaseId if it 
-- has been supplied.
------------------------
If  @nErrorCode = 0
and @pnCaseId is not null
Begin
	If not exists (select 1 from CASES where CASEID=@pnCaseId)
	Begin	
		RAISERROR('@pnCaseId must identify a Case within the CASES table', 14, 1)
		Set @nErrorCode = -3
	End
End

------------------------
-- Validate Activity
------------------------
If @nErrorCode = 0
Begin
	If @psActivityCode is null
	OR not exists (select 1 from WIPTEMPLATE where WIPCODE=@psActivityCode)
	Begin	
		RAISERROR('@psActivityCode must exist within the WIPTEMPLATE table', 14, 1)
		Set @nErrorCode = -4
	End	
End

-------------------------------
-- Check that the Time Period, 
-- Start Time and End Time are 
-- correctly formatted.
-------------------------------
If @nErrorCode = 0
Begin
	----------------------------------------
	-- Time Period to be recorded must be in 
	-- the format HH:MM. Ignore seconds.
	-- The format is enforced by the data
	-- type of the parameter (datetime).
	----------------------------------------
	Set @sTime        =CONVERT(CHAR(8),@pdtTimePeriod,108)
	set @pdtTimePeriod='1899-01-01 '+@sTime

	Set @nHours  =cast(substring(@sTime,1,2) as tinyint)
	Set @nMinutes=cast(substring(@sTime,4,2) as tinyint) + @nHours*60
	Set @nSeconds=cast(substring(@sTime,7,2) as tinyint)
	
	if  @pdtStartTime is not null
	and @pdtEndTime   is not null
	Begin
		-------------------------------------------
		-- Check that Start and End Time are on the
		-- same calendar day.
		-------------------------------------------
		if convert(nvarchar,@pdtStartTime,112)<>convert(nvarchar,@pdtEndTime,112)
		and @nErrorCode=0
		begin		
			RAISERROR('Start Time and End Time must be on the same calendar day.', 14, 1)
			Set @nErrorCode = -5
		End
		
		-------------------------------------------
		-- Check that Start Time is earlier than
		-- the End Time.
		-------------------------------------------
		if @pdtStartTime>@pdtEndTime
		and @nErrorCode=0
		begin		
			RAISERROR('Start Time must be earlier than End Time.', 14, 1)
			Set @nErrorCode = -6
		End
		
		-------------------------------------------
		-- If both Start and End Time are provided
		-- then check that the time difference in
		-- minutes matches the provided time period
		-------------------------------------------
		if DATEDIFF(mi,@pdtStartTime,@pdtEndTime)<>@nMinutes
		and @nErrorCode=0
		begin		
			RAISERROR('Time difference between the Start and End Time does not match the provided Time Period', 14, 1)
			Set @nErrorCode = -7
		End
	End
	
	If @nErrorCode=0
	begin
		if  @pdtStartTime is not null
		and @pdtEndTime   is null
		Begin
			-------------------------------------------
			-- Calculate the End Time from the provided
			-- time period and Start Time
			-------------------------------------------
			Set @pdtEndTime=DATEADD(mi,@nMinutes,@pdtStartTime)
		End
		Else if  @pdtStartTime is null
		     and @pdtEndTime   is not null
		Begin
			---------------------------------------------
			-- Calculate the Start Time from the provided
			-- time period and End Time
			---------------------------------------------
			Set @pdtStartTime=DATEADD(mi,@nMinutes*-1,@pdtEndTime)
		End
		Else If  @pdtStartTime is null
		     and @pdtEndTime   is null
		Begin
			---------------------------------------------
			-- Use the Entry Date only if no Start or End
			-- Time has been provided.
			---------------------------------------------
			Set @pdtStartTime=@pdtEntryDate
			Set @pdtEndTime  =@pdtEntryDate
		End
	End
End


-------------------------------------
-- Validate the supplied or defaulted
-- UserIdentity
-------------------------------------
If @nErrorCode=0
Begin
	If (@pnUserIdentityId is null
	 or @pnUserIdentityId='')
	Begin
		---------------------------------------
		-- Get the UserIdentity associated with
		-- current login if it has not been
		-- supplied.
		---------------------------------------
		Select @pnUserIdentityId=min(IDENTITYID)
		from USERIDENTITY
		where NAMENO=@pnStaffMemberId

		Set @nErrorCode=@@ERROR
	End
	
	If @pnUserIdentityId is null
	OR not exists (select 1 from USERIDENTITY where IDENTITYID=@pnUserIdentityId)
	Begin
		RAISERROR('@pnUserIdentityId must exist in USERIDENTITY table', 14, 1)
		Set @nErrorCode = -8
	End
End

-------------------------------------------------
-- Is there a name restriction for the @pnCaseId
-- that will block the entry from being posted?
-------------------------------------------------
If  @nErrorCode = 0
and @pnCaseId is not null
Begin
	select  @nRestictionSeverity =
		case D.ACTIONFLAG
			when 0 then 2 	-- Display Error => User Error
			when 1 then 1 	-- Display Warning => Warning
			when 2 then 2 	-- Password => User Error
			else 1		-- Warning by default
		end
	from	DEBTORSTATUS D
	where	D.BADDEBTOR =
		(select	substring(
			max(cast(case D.ACTIONFLAG
				when 0 then 2 	-- Display Error => User Error
				when 1 then 1 	-- Display Warning => Warning
				when 2 then 2 	-- Password => User Error
				else 1		-- Warning by default
				end as char(1))+
			    cast(D.BADDEBTOR as char(8))
			   ),2,8)
		from	NAMETYPE NT
		join 	CASENAME CN	on (CN.CASEID = @pnCaseId
					and CN.NAMETYPE = NT.NAMETYPE
					and (CN.EXPIRYDATE>getdate() or CN.EXPIRYDATE IS NULL))
		join	IPNAME IP	on (IP.NAMENO = CN.NAMENO)
		join	DEBTORSTATUS D	on (D.BADDEBTOR = IP.BADDEBTOR)
		where 	NT.NAMERESTRICTFLAG=1
		--	Exclude No Action
		and	D.ACTIONFLAG <> 3)

	Set @nErrorCode=@@ERROR
	
	If @nRestictionSeverity = 2
	Begin
		RAISERROR('Restrictions against one or more names associated with Case are blocking the recording of time against the Case', 14, 1)
		Set @nErrorCode = -9
	End
End

--------------------------------------------
--
-- P R E P A R E   A U D I T   L O G G I N G
--
--------------------------------------------

--------------------------------------
-- Initialise variables that will be 
-- loaded into CONTEXT_INFO for access
-- by the audit triggers
--------------------------------------

If @nErrorCode=0
Begin
	Select @nOfficeID=COLINTEGER
	from SITECONTROL
	where CONTROLID='Office For Replication'

	Select @nLogMinutes=COLINTEGER
	from SITECONTROL
	where CONTROLID='Log Time Offset'

	Set @nErrorCode=@@ERROR
End

--------------------------------------------------
-- Get Transaction Number for use in audit records.
---------------------------------------------------
If @nErrorCode=0
Begin
	-----------------------------------------------------------------------------
	-- A separate database transaction will be used to insert the TRANSACTIONINFO
	-- row to ensure the lock on the database is kept to a minimum as this table
	-- will be used extensively by other processes.
	-----------------------------------------------------------------------------

	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Allocate a transaction id that can be accessed by the audit logs
	-- for inclusion.

	Insert into TRANSACTIONINFO(TRANSACTIONDATE) values(getdate())
	Select @nTransNo  =SCOPE_IDENTITY(),
	       @nErrorCode=@@ERROR	

	--------------------------------------------------------------
	-- Load a common area accessible from the database server with
	-- the UserIdentityId and the TransactionNo just generated.
	-- This will be used by the audit logs.
	--------------------------------------------------------------
	If @nErrorCode=0
	Begin
		Set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4)+ 
				substring(cast(isnull(@nTransNo,'') as varbinary),1,4)+ 
				substring(cast(isnull(@nBatchNo,'') as varbinary),1,4) +
				substring(cast(isnull(@nOfficeID,'') as varbinary),1,4) +
				substring(cast(isnull(@nLogMinutes,'') as varbinary),1,4)
		SET CONTEXT_INFO @bHexNumber
	End

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

----------------------------------------
-- P R E P A R E   T R A N S A C T I O N
----------------------------------------
If @nErrorCode=0
Begin					  
	Select @bWIPSplit     = S1.COLBOOLEAN,
	       @bBillRenewal  = S2.COLBOOLEAN,
	       @bTranslate    = S3.COLBOOLEAN
	from SITECONTROL S1
	left join SITECONTROL S2 on (S2.CONTROLID='Bill Renewal Debtor')
	left join SITECONTROL S3 on (S3.CONTROLID='Narrative Translate')
	where S1.CONTROLID='WIP Split Multi Debtor'
	
	Set @nErrorCode=@@ERROR
End

--If  @nErrorCode=0
--and @nUnitsPerHour>0
--Begin
--	------------------------------------
--	-- Consider the number of seconds
--	-- of recorded time depending on 
--	-- whether it is 30 seconds or more,
--	-- or whether no minutes have been
--	-- recorded.
--	------------------------------------
--	If @nSeconds>=30
--		Set @nMinutes=@nMinutes+1
--	Else
--	If  @nMinutes=0
--	and @bCountSeconds=1		-- site control
--	and @nSeconds>0
--		Set @nMinutes = 1

--	--------------------------------------	
--	-- Calculate the number of Units to
--	-- be recorded by using the number of
--	-- units per hour
--	--------------------------------------
	
--	Set @nUnits = ceiling(@nMinutes*@nUnitsPerHour/60) -- Round up to next whole unit
--End

-----------------------------------------------------------------------------------------------
-- D I A R Y  C R E A T I O N
-- All the inserts to the database are to be applied as a single transaction so that the entire
-- transaction can be rolled back should a failure occur.
-----------------------------------------------------------------------------------------------

If  @nErrorCode=0
Begin
	-------------------------------------
	-- C A S E   U N K N O W N 
	-------------------------------------
	--
	-- If the @pnCaseId has not been 
	-- provided then no rate calculations
	-- can be determined and so a partial
	-- DIARY row with missing detail will
	-- be created.
	-------------------------------------
	
	If @pnCaseId is null
	Begin
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION
		
		exec @nErrorCode=ts_InsertTime 
					@pnEntryNo		=@nEntryNo	 output,
					@pnUserIdentityId	=@pnUserIdentityId,
					@psCulture		=default,
					@pnStaffKey		=@pnStaffMemberId,
					@pdtStartDateTime	=@pdtStartTime,
					@pdtFinishDateTime	=@pdtEndTime,
					@pnNameKey		=default,
					@pnCaseKey		=@pnCaseId,
					@psActivityKey		=@psActivityCode,
					@pnTotalUnits		=@nUnits,
					@pdtTotalTime		=@pdtTimePeriod,
					@pnUnitsPerHour		=@nUnitsPerHour,
					@pnChargeOutRate	=default,
					@pnLocalValue		=default,
					@pnLocalDiscount	=default,
					@pnCostCalculation1	=default,
					@pnCostCalculation2	=default,
					@psForeignCurrencyCode	=default,
					@pnExchangeRate		=default,
					@pnForeignValue		=default,
					@pnForeignDiscount	=default,
					@pdtTimeCarriedForward	=default,
					@pnParentEntryNo	=default,
					@pnNarrativeKey		=default,
					@ptNarrative		=@psNarrative,
					@psNotes		=default,
					@pnProductKey		=default,
					@pnIsTimer		=0,
					@pnMarginNo		=default,
					@pnFileLocationKey	=default
		----------------------------------------
		-- Commit or Rollback the transaction
		-- This will save the basic Case details
		-- to the database
		----------------------------------------
		If @@TranCount > @TranCountStart
		Begin
			If @nErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End
	

	-------------------------------------
	-- C A S E   I S   K N O W N 
	-------------------------------------
	--
	-- If the @pnCaseId has been provided 
	-- then determine the debtor(s) and 
	-- then cost the charge. 
	-------------------------------------
	Else Begin
		
		-------------------------
		-- Determine the NAMETYPE
		-- to use as the debtor.
		-------------------------
		
		Set @sNameType='D'
		
		If @bBillRenewal=1
		and exists(select 1
			   from WIPTEMPLATE
			   where WIPCODE=@psActivityCode
			   and RENEWALFLAG=1)
		Begin
			Set @sNameType='Z'	-- Renewal Debtor
		End
		
		----------------------------------
		-- Get the debtors associated with
		-- the Case and load into a table
		-- variable
		----------------------------------
		If @bWIPSplit=1
		Begin
			insert into @tblDebtors(NAMENO, BILLPERCENTAGE)
			select NAMENO, BILLPERCENTAGE
			from CASENAME
			where CASEID=@pnCaseId
			and NAMETYPE=@sNameType
			and BILLPERCENTAGE>0
			and (EXPIRYDATE is null or EXPIRYDATE > getdate())
			order by SEQUENCE, NAMENO
			
			select @nErrorCode=@@Error,
			       @nRowCount =@@Rowcount
		End
		Else Begin
			-------------------------------------
			-- Only the first debtor is required
			-- if WIP is not being split. Set the
			-- BILLPERCENTAGE to 100 to calculate
			-- entire WIP value for that debtor.
			-------------------------------------
			insert into @tblDebtors(NAMENO, BILLPERCENTAGE)
			select top 1 NAMENO, 100
			from CASENAME
			where CASEID=@pnCaseId
			and NAMETYPE=@sNameType
			and (EXPIRYDATE is null or EXPIRYDATE > getdate())
			order by SEQUENCE, NAMENO
			
			select @nErrorCode=@@Error,
			       @nRowCount =@@Rowcount
		End
		
		-------------------------------------
		-- Loop through each debtor to value
		-- the time and collect other default
		-- values for that debtor.
		-------------------------------------
		Set @nSequence=1
		
		While @nSequence<=@nRowCount
		and   @nErrorCode=0
		Begin
			-----------------------------
			-- Get the Debtor details for
			-- the row to be valued.
			-----------------------------
			Select @nDebtor=NAMENO,
			       @nBillPercentage=BILLPERCENTAGE
			from @tblDebtors
			where SEQUENCE=@nSequence
			
			Set @nErrorCode=@@ERROR
			
			If @nErrorCode=0
			Begin
				----------------------------
				-- Get the default NARRATIVE
				-- using the Best Fit search
				----------------------------
				select @nNarrativeNo   =
					convert(int,
					substring(
					max (
					CASE WHEN (NR.DEBTORNO           IS NULL) THEN '0' ELSE '1' END +
					CASE WHEN (NR.EMPLOYEENO         IS NULL) THEN '0' ELSE '1' END +
					CASE WHEN (NR.CASETYPE           IS NULL) THEN '0' ELSE '1' END +
					CASE WHEN (NR.COUNTRYCODE        IS NULL) THEN '0' ELSE '1' END +
					CASE WHEN (NR.LOCALCOUNTRYFLAG   IS NULL) THEN '0' ELSE '1' END +
					CASE WHEN (NR.FOREIGNCOUNTRYFLAG IS NULL) THEN '0' ELSE '1' END +
					CASE WHEN (NR.PROPERTYTYPE       IS NULL) THEN '0' ELSE '1' END +
					CASE WHEN (NR.CASECATEGORY       IS NULL) THEN '0' ELSE '1' END +
					CASE WHEN (NR.SUBTYPE            IS NULL) THEN '0' ELSE '1' END +
					CASE WHEN (NR.TYPEOFMARK         IS NULL) THEN '0' ELSE '1' END +
					convert(varchar,NR.NARRATIVENO)), 11,20))
				from NARRATIVERULE NR
				join CASES C on (C.CASEID=@pnCaseId)
				------------------------------
				-- Check to see if any Country
				-- has been flagged as local
				------------------------------
				left join (SELECT distinct 1 as HASCOUNTRYATTRIBUTE
				           from TABLEATTRIBUTES
				           where PARENTTABLE='COUNTRY'
				           and   TABLECODE  =5002) TA1 on (TA1.HASCOUNTRYATTRIBUTE=1)
				------------------------------
				-- Check to see Cases.Country
				-- has been flagged as local
				------------------------------
				left join TABLEATTRIBUTES TA2	on (TA1.HASCOUNTRYATTRIBUTE=1
								and TA2.PARENTTABLE='COUNTRY'
								and TA2.GENERICKEY =C.COUNTRYCODE
								and TA2.TABLECODE  =5002)
				where NR.WIPCODE = @psActivityCode
				and  (NR.DEBTORNO          =@nDebtor                   OR NR.DEBTORNO           is NULL)
				and  (NR.EMPLOYEENO        =@pnStaffMemberId           OR NR.EMPLOYEENO         is NULL)
				and  (NR.CASETYPE          =C.CASETYPE                 OR NR.CASETYPE           is NULL)
				and  (NR.COUNTRYCODE       =C.COUNTRYCODE              OR NR.COUNTRYCODE        is NULL)
				and  (NR.LOCALCOUNTRYFLAG  =cast(TA2.TABLECODE as bit) OR NR.LOCALCOUNTRYFLAG   is NULL)
				and  (NR.FOREIGNCOUNTRYFLAG=CASE WHEN(TA1.HASCOUNTRYATTRIBUTE=1) THEN CASE WHEN(TA2.TABLECODE=5002) THEN 0 ELSE 1 END
				 			    END                        OR NR.FOREIGNCOUNTRYFLAG is NULL)
				and  (NR.PROPERTYTYPE      =C.PROPERTYTYPE             OR NR.PROPERTYTYPE       is NULL)
				and  (NR.CASECATEGORY      =C.CASECATEGORY             OR NR.CASECATEGORY       is NULL)
				and  (NR.SUBTYPE           =C.SUBTYPE                  OR NR.SUBTYPE            is NULL)
				and  (NR.TYPEOFMARK        =C.TYPEOFMARK               OR NR.TYPEOFMARK         is NULL)
				------------------------------------------------------------------------------------------
				-- As there could be multiple Narrative rules for a WIP Code with the same best fit score, 
				-- a NarrativeKey and other Narrative columns should only be defaulted if there is only 
				-- a single row with the maximum best fit score.
				------------------------------------------------------------------------------------------
				and not exists (Select 1
						from NARRATIVERULE NR2
						where   NR2.WIPCODE		= @psActivityCode
						AND (	NR2.DEBTORNO 		= NR.DEBTORNO		OR (NR2.DEBTORNO 	   IS NULL AND NR.DEBTORNO 	     IS NULL) )
						AND (	NR2.EMPLOYEENO 	        = NR.EMPLOYEENO	        OR (NR2.EMPLOYEENO 	   IS NULL AND NR.EMPLOYEENO 	     IS NULL) )
						AND (	NR2.CASETYPE		= NR.CASETYPE		OR (NR2.CASETYPE 	   IS NULL AND NR.CASETYPE	     IS NULL) )
						AND (	NR2.COUNTRYCODE	        = NR.COUNTRYCODE	OR (NR2.COUNTRYCODE 	   IS NULL AND NR.COUNTRYCODE        IS NULL) )
						AND (	NR2.LOCALCOUNTRYFLAG	= NR.LOCALCOUNTRYFLAG	OR (NR2.LOCALCOUNTRYFLAG   IS NULL AND NR.LOCALCOUNTRYFLAG   IS NULL) )
						AND (	NR2.FOREIGNCOUNTRYFLAG	= NR.FOREIGNCOUNTRYFLAG	OR (NR2.FOREIGNCOUNTRYFLAG IS NULL AND NR.FOREIGNCOUNTRYFLAG IS NULL) )
						AND (	NR2.PROPERTYTYPE 	= NR.PROPERTYTYPE 	OR (NR2.PROPERTYTYPE 	   IS NULL AND NR.PROPERTYTYPE 	     IS NULL) )
						AND (	NR2.CASECATEGORY 	= NR.CASECATEGORY 	OR (NR2.CASECATEGORY 	   IS NULL AND NR.CASECATEGORY 	     IS NULL) )
						AND (	NR2.SUBTYPE 		= NR.SUBTYPE 		OR (NR2.SUBTYPE 	   IS NULL AND NR.SUBTYPE            IS NULL) )
						AND (	NR2.TYPEOFMARK		= NR.TYPEOFMARK	        OR (NR2.TYPEOFMARK	   IS NULL AND NR.TYPEOFMARK         IS NULL) )
						AND     NR2.NARRATIVERULENO <> NR.NARRATIVERULENO)
			End
	
			------------------------------------------
			-- Find out if the narrative text needs to
			-- be translated and which language to use
			------------------------------------------
			If  @psNarrative is not null
			Begin
				Set @sNarrative=@psNarrative
			End
			Else Begin
				Set @sNarrative = null
				
				If  @nNarrativeNo is not null
				Begin
					If  @bTranslate=1
					and @nErrorCode=0
					Begin
						--------------------------------
						-- Determine if the debtor has a
						-- language requirement for the
						-- narrative
						--------------------------------
						exec @nErrorCode=dbo.bi_GetBillingLanguage
								@pnLanguageKey		= @nLanguageKey output,	
								@pnUserIdentityId	= @pnUserIdentityId,
								@pnDebtorKey		= @nDebtor,	
								@pnCaseKey		= @pnCaseId, 
								@pbDeriveAction		= 1
					End
					
					If @nLanguageKey is not null
					and @nErrorCode=0
					Begin
						-------------------------------
						-- Get the translated Narrative
						-- if it exists
						-------------------------------
						Select @sNarrative=TRANSLATEDTEXT
						from NARRATIVETRANSLATE
						where NARRATIVENO=@nNarrativeNo
						  and LANGUAGE   =@nLanguageKey
						 
						Set @nErrorCode=@@ERROR
					End
					
					If @sNarrative is null
					and @nErrorCode=0
					Begin
						-------------------------------
						-- Get the Narrative text if
						-- no translation was extracted
						-------------------------------
						Select @sNarrative=NARRATIVETEXT
						from NARRATIVE
						where NARRATIVENO=@nNarrativeNo
						 
						Set @nErrorCode=@@ERROR
					End
				End
			End
			------------------------------
			-- Need to keep the narrative
			-- of the first debtor for the
			-- DIARY row
			------------------------------
			If @nSequence=1
				Set @sFirstNarrative = @sNarrative

			If @nErrorCode=0
			Begin
				--------------------------------
				-- Reset OUTPUT variables before
				--calculating WIP values
				--------------------------------
				Set @nChargeOutRate	  = null
				Set @nLocalValuePreMargin = null
				Set @sCurrencyCode	  = null
				Set @nExchangeRate	  = null
				Set @nLocalValue	  = null
				Set @nForeignValue	  = null
				Set @nMarginValue	  = null
				Set @nLocalDiscount	  = null
				Set @nForeignDiscount	  = null
				Set @nLocalCost1	  = null
				Set @nLocalCost2	  = null
				Set @nMarginNo		  = null
				Set @nLocalDiscForMargin  = null
				Set @nForeignDiscForMargin= null
							
				exec @nErrorCode=wp_GetWipCost 
							@pnUserIdentityId		=@pnUserIdentityId,
							@pbCalledFromCentura		=0,
							@pdtTransactionDate		=@pdtEntryDate,
							@pnEntityKey			=null,
							@pnStaffKey			=@pnStaffMemberId,
							@pnNameKey			=@nDebtor,
							@pnCaseKey			=@pnCaseId,
							@psDebtorNameTypeKey		=@sNameType,
							@psWipCode			=@psActivityCode,
							@pnProductKey			=null,
							@pbIsChargeGeneration		=0,
							@pbIsServiceCharge		=null,
							@pbUseSuppliedValues		=null,
							@pdtHours			=@pdtTimePeriod		output,
							@pnTimeUnits			=@nUnits		output,
							@pnUnitsPerHour			=@nUnitsPerHour		output,
							@pnChargeOutRate		=@nChargeOutRate	output,
							@pnLocalValueBeforeMargin	=@nLocalValuePreMargin	output,
							@pnForeignValueBeforeMargin	=@nForeignValuePreMargin,
							@psCurrencyCode			=@sCurrencyCode		output,
							@pnExchangeRate			=@nExchangeRate		output,
							@pnLocalValue			=@nLocalValue		output,
							@pnForeignValue			=@nForeignValue		output,
							@pbMarginRequired		=1,
							@pnMarginValue			=@nMarginValue		output,
							@pnLocalDiscount		=@nLocalDiscount	output,
							@pnForeignDiscount		=@nForeignDiscount	output,
							@pnLocalCost1			=@nLocalCost1		output,
							@pnLocalCost2			=@nLocalCost2		output,
							@pnSupplierKey			=null,
							@pnStaffClassKey		=null,
							@psActionKey			=null,
							@pnMarginNo			=@nMarginNo		output,
							@pnLocalDiscountForMargin	=@nLocalDiscForMargin	output,
							@pnForeignDiscountForMargin	=@nForeignDiscForMargin	output,
							@pbSplitTimeByDebtor		=@bWIPSplit
			End
	
			If  @nErrorCode=0
			and @nRowCount>1
			Begin
				---------------------------------------------------------
				-- If there are more than one debtors to process for the
				-- time entry, then insert each row into a table variable
				-- so they can be loaded into the DEBTORSPLITDIARY once
				-- the DIARY row is created.
				---------------------------------------------------------
				
				Insert into @tbDebtorSplitDiary(EMPLOYEENO, NAMENO, TIMEVALUE, CHARGEOUTRATE, NARRATIVENO, NARRATIVE, DISCOUNTVALUE, FOREIGNCURRENCY, FOREIGNVALUE, EXCHRATE, FOREIGNDISCOUNT, COSTCALCULATION1, COSTCALCULATION2, MARGINNO, SPLITPERCENTAGE)
				Values (@pnStaffMemberId, @nDebtor, @nLocalValue, @nChargeOutRate, @nNarrativeNo, @sNarrative, @nLocalDiscount, @sCurrencyCode, @nForeignValue, @nExchangeRate, @nForeignDiscount, @nLocalCost1, @nLocalCost2, @nMarginNo, @nBillPercentage)
				
				Set @nErrorCode=@@ERROR
			End
				
			If @nErrorCode=0
			Begin
				Set @nTotalLocalValue   =@nTotalLocalValue   +isnull(@nLocalValue   ,0)
				Set @nTotalLocalDiscount=@nTotalLocalDiscount+isnull(@nLocalDiscount,0)
				Set @nTotalLocalCost1   =@nTotalLocalCost1   +isnull(@nLocalCost1   ,0)
				Set @nTotalLocalCost2   =@nTotalLocalCost2   +isnull(@nLocalCost2   ,0)
			End
		
			-------------------------
			-- Increment the Sequence
			-------------------------
			Set @nSequence=@nSequence + 1
			
		End	-- End of Loop

		If @nErrorCode=0
		Begin
			Select @TranCountStart = @@TranCount
			BEGIN TRANSACTION

			If @nRowCount=1
			Begin
				exec @nErrorCode=ts_InsertTime 
						@pnEntryNo		=@nEntryNo	 output,
						@pnUserIdentityId	=@pnUserIdentityId,
						@psCulture		=default,
						@pnStaffKey		=@pnStaffMemberId,
						@pdtStartDateTime	=@pdtStartTime,
						@pdtFinishDateTime	=@pdtEndTime,
						@pnNameKey		=default,
						@pnCaseKey		=@pnCaseId,
						@psActivityKey		=@psActivityCode,
						@pnTotalUnits		=@nUnits,
						@pdtTotalTime		=@pdtTimePeriod,
						@pnUnitsPerHour		=@nUnitsPerHour,
						@pnChargeOutRate	=@nChargeOutRate,
						@pnLocalValue		=@nTotalLocalValue,
						@pnLocalDiscount	=@nTotalLocalDiscount,
						@pnCostCalculation1	=@nTotalLocalCost1,
						@pnCostCalculation2	=@nTotalLocalCost2,
						@psForeignCurrencyCode	=@sCurrencyCode,
						@pnExchangeRate		=@nExchangeRate,
						@pnForeignValue		=@nForeignValue,
						@pnForeignDiscount	=@nForeignDiscount,
						@pdtTimeCarriedForward	=default,
						@pnParentEntryNo	=default,
						@pnNarrativeKey		=@nNarrativeNo,
						@ptNarrative		=@sFirstNarrative,
						@psNotes		=default,
						@pnProductKey		=default,
						@pnIsTimer		=0,
						@pnMarginNo		=@nMarginNo,
						@pnFileLocationKey	=default
			End
			Else Begin
				-----------------------------------------------------
				-- More than one debtor means the details for each
				-- debtor will be held in the DEBTORSPLITDIARY table.
				-----------------------------------------------------
				exec @nErrorCode=ts_InsertTime 
						@pnEntryNo		=@nEntryNo	 output,
						@pnUserIdentityId	=@pnUserIdentityId,
						@psCulture		=default,
						@pnStaffKey		=@pnStaffMemberId,
						@pdtStartDateTime	=@pdtStartTime,
						@pdtFinishDateTime	=@pdtEndTime,
						@pnNameKey		=default,
						@pnCaseKey		=@pnCaseId,
						@psActivityKey		=@psActivityCode,
						@pnTotalUnits		=@nUnits,
						@pdtTotalTime		=@pdtTimePeriod,
						@pnUnitsPerHour		=@nUnitsPerHour,
						@pnChargeOutRate	=default,
						@pnLocalValue		=@nTotalLocalValue,
						@pnLocalDiscount	=@nTotalLocalDiscount,
						@pnCostCalculation1	=@nTotalLocalCost1,
						@pnCostCalculation2	=@nTotalLocalCost2,
						@psForeignCurrencyCode	=default,
						@pnExchangeRate		=default,
						@pnForeignValue		=default,
						@pnForeignDiscount	=default,
						@pdtTimeCarriedForward	=default,
						@pnParentEntryNo	=default,
						@pnNarrativeKey		=@nNarrativeNo,
						@ptNarrative		=@sFirstNarrative,
						@psNotes		=default,
						@pnProductKey		=default,
						@pnIsTimer		=0,
						@pnMarginNo		=default,
						@pnFileLocationKey	=default
						
				If  @nErrorCode=0
				Begin
					---------------------------------------------------------
					-- If there are more than one debtors to process for the
					-- time entry, insert each row into DEBTORSPLITDIARY as
					-- a child of the just inserted DIARY row is created.
					---------------------------------------------------------
					
					Insert into DEBTORSPLITDIARY(EMPLOYEENO, ENTRYNO, NAMENO, TIMEVALUE, CHARGEOUTRATE, NARRATIVENO, NARRATIVE, DISCOUNTVALUE, FOREIGNCURRENCY, FOREIGNVALUE, EXCHRATE, FOREIGNDISCOUNT, COSTCALCULATION1, COSTCALCULATION2, MARGINNO, SPLITPERCENTAGE)
					Select EMPLOYEENO, @nEntryNo, NAMENO, TIMEVALUE, CHARGEOUTRATE, NARRATIVENO, NARRATIVE, DISCOUNTVALUE, FOREIGNCURRENCY, FOREIGNVALUE, EXCHRATE, FOREIGNDISCOUNT, COSTCALCULATION1, COSTCALCULATION2, MARGINNO, SPLITPERCENTAGE
					from @tbDebtorSplitDiary
					
					Set @nErrorCode=@@ERROR
				End
			End
	
			----------------------------------------
			-- Commit or Rollback the transaction
			-- This will save the basic Case details
			-- to the database
			----------------------------------------
			If @@TranCount > @TranCountStart
			Begin
				If @nErrorCode = 0
					COMMIT TRANSACTION
				Else
					ROLLBACK TRANSACTION
			End
		End		
	End	-- @pnCaseId is provided
End

return @nErrorCode
go

grant execute on dbo.api_InsertDiary to public
go
