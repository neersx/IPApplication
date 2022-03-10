-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fl_InsertFeeListCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fl_InsertFeeListCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.fl_InsertFeeListCase.'
	Drop procedure [dbo].[fl_InsertFeeListCase]
End
Print '**** Creating Stored Procedure dbo.fl_InsertFeeListCase...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.fl_InsertFeeListCase
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	=null,
 	@psFeeType		nvarchar(6),	-- Mandatory	Indicates the type of fee being paid
 	@pnFeeListNo		int		=null,		-- This will normally be NULL except when Fee is being added to an explicit FeeList
 	@pnCaseId		int		=null,		-- The Case being paid (optional entry because Official Number may be used)
 	@psOfficialNumber	nvarchar(36)	=null,		-- Official Number payment is against. Can be determined from CaseId
 	@psNumberType		nvarchar(3)	=null,		-- Type of official number. Can be determined from CaseId
 	@pnBaseFeeAmount	decimal(11,2)	=0,		-- Base fee being paid
 	@pnAdditionalFee	decimal(11,2)	=0,		-- Component of fee calculated from @pnQuantityInCalc
 	@pnForeignFeeAmount	decimal(11,2)	=null,		-- Total Fee in foreign currency it is to be paid in
 	@psCurrency		nvarchar(3)	=null,		-- The foreign currency the fee is being paid in. Null assumes local currency.
 	@psOwnerName		nvarchar(50)	=null,		-- Name of the first owner/applicant of Case. Can be determined from CaseId
 	@pnQuantityInCalc	int		=0,		-- Quantity used to caculate @pnAdditionalFee
 	@pnQuantityDesc		int		=null,		-- NOT IMPLEMENTED 
 	@pbToBePaid		bit		=1,		-- Indicates that fee is ready to be paid when set to 1.
 	@psTaxCode		nvarchar(3)	=null,		-- Tax code associated with Fee.
 	@pnTaxAmount		decimal(11,2)	=0,		-- Tax amount of the Fee
 	@pnTotalFee		decimal(11,2)	=0,		-- The total fee to be paid in local currency @pnBaseFeeAmount+@pnAdditionalFee+@pnTaxAmount
 	@pnAgeOfCase		smallint	=null,		-- The annuity number of the Case being paid.
 	@pdtWhenRequested	datetime	= null		-- This is current date/time which will be passed from wp_PostWIP so that the same date can be passed to wpw_PerformBankWithdrawal
)
as
-- PROCEDURE:	fl_InsertFeeListCase
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Inserts details into FEELISTCASE for later inclusion on the Fees List
--		that goes to the IP Office for payment of fees.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Mar 2009	MF	RFC6478	1	Procedure created.
-- 18 Mar 2009	MS	RFC6478	2	Changed @pnTotalFee calculation 
-- 02 Jun 2015	KR	R47797	3	Adjust logic so the save proceeds when the @pnTotalFee is not null
--					Also accept @pdtWhenRequested as input than using getdate() directly here.
--					This is so the same can be passed to wpw_PerformBankWithdrawal so concurrency issues will not happen
-- 02 Nov 2015	vql	R53910	4	Adjust formatted names logic (DR-15543).
-- 19 May 2020	DL	DR-58943	5	Ability to enter up to 3 characters for Number type code via client server	


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare	@nRowCount		int
declare @sSQLString		nvarchar(4000)
declare @sAlertXML		nvarchar(400)

declare @nTranCountStart	int

-- Initialise variables
Set @nErrorCode	= 0
Set @nRowCount  = 0

---------------------------------------------------------
--
-- I N P U T   P A R A M E T E R   V A L I D A T I O N 
--
---------------------------------------------------------

---------------------------------------------------------
-- If @pnCaseId has not been supplied then check that 
-- @psOfficialNumber and @psNumberType have been supplied
---------------------------------------------------------
If @nErrorCode = 0
and @pnCaseId is null
and (@psOfficialNumber is null OR @psNumberType is null)
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('FL01', 'If @pnCaseId is not supplied then BOTH of @psOfficialNumber and @psNumberType are required ',
					null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

---------------------------------------------------------
-- May only create a Fee List entry if there is a non 
-- zero value
---------------------------------------------------------
If @nErrorCode = 0
and (@pnBaseFeeAmount+@pnAdditionalFee)=0 and (@pnTotalFee = 0)
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('FL02', 'Fee list amount must be a non zero value.',null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode=@@ERROR
End

---------------------------------------------------------
--
-- G E T   M I S S I N G   C A S E   D E T A I L S
--
---------------------------------------------------------
If @nErrorCode = 0
and @pnCaseId is not null
Begin
	If @psOfficialNumber is null
	Begin
		----------------------------------
		-- Get the current Official Number
		-- for the Case.
		----------------------------------
		Set @sSQLString="
		Select	@psOfficialNumber=O.OFFICIALNUMBER,
			@psNumberType   =O.NUMBERTYPE
		from OFFICIALNUMBERS O
		join NUMBERTYPES NT on (NT.NUMBERTYPE=O.NUMBERTYPE
				    and NT.ISSUEDBYIPOFFICE=1
				    and NT.DISPLAYPRIORITY=(	select min(NT1.DISPLAYPRIORITY)
								from NUMBERTYPES NT1
								join OFFICIALNUMBERS O1 on (O1.NUMBERTYPE=NT1.NUMBERTYPE)
								where NT1.ISSUEDBYIPOFFICE=1
								and O1.ISCURRENT=1
								and O1.CASEID=O.CASEID)
					)
		where O.CASEID=@pnCaseId
		and O.ISCURRENT=1"
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@psOfficialNumber	nvarchar(36)	OUTPUT,
						  @psNumberType		nvarchar(3)	OUTPUT,
						  @pnCaseId		int',
						  @psOfficialNumber = @psOfficialNumber	OUTPUT,
						  @psNumberType	   = @psNumberType	OUTPUT,
						  @pnCaseId	   = @pnCaseId
	End
	
	If @psOwnerName is null
	and @nErrorCode=0
	Begin
		-----------------------------------
		-- Get the first owner for the Case
		-- for "property" Cases.
		-----------------------------------
		Set @sSQLString="
		Select @psOwnerName= left(rtrim(dbo.fn_FormatNameUsingNameNo(N.NAMENO,default)),50)
		from CASES C
		join CASENAME CN on (CN.CASEID=C.CASEID)
		join (	select CASEID, min(SEQUENCE) as SEQUENCE
			from CASENAME
			where NAMETYPE='O'
			and (EXPIRYDATE>getdate() or EXPIRYDATE is null)
			group by CASEID) CN1	on (CN1.CASEID=CN.CASEID
						and CN1.SEQUENCE=CN.SEQUENCE)
		join NAME N	on (N.NAMENO=CN.NAMENO)
		where C.CASEID=@pnCaseId
		and   C.CASETYPE='A'	-- only get the Owner name for Property Case
		and  CN.NAMETYPE='O'
		and (CN.EXPIRYDATE>getdate() or CN.EXPIRYDATE is null)"
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@psOwnerName		nvarchar(50)	OUTPUT,
						  @pnCaseId		int',
						  @psOwnerName		= @psOwnerName	OUTPUT,
						  @pnCaseId		= @pnCaseId
	End
End

If @nErrorCode=0
and @psCurrency is null
Begin
	-----------------------------------
	-- Get the default currency
	-----------------------------------
	Set @sSQLString="
	Select @psCurrency=S.COLCHARACTER
	from SITECONTROL S
	where S.CONTROLID='CURRENCY'"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psCurrency	nvarchar(3)	OUTPUT',
					  @psCurrency=@psCurrency	OUTPUT
End

If @nErrorCode=0
and isnull(@pnTotalFee,0)=0
Begin
	Set @pnTotalFee= Isnull(@pnBaseFeeAmount,0)+
			Isnull(@pnAdditionalFee,0)+
			Isnull(@pnTaxAmount,0)
End

If @nErrorCode = 0
Begin
	if @pdtWhenRequested is null
		Set @pdtWhenRequested = getdate()
	--------------------------------
	-- Begin processing of the batch
	--------------------------------
	Select @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	INSERT INTO FEELISTCASE
			(WHENREQUESTED
			,FEELISTITEM
			,TAXCODE
			,FEELISTNO
			,FEETYPE
			,CASEID
			,OFFICIALNUMBER
			,NUMBERTYPE
			,BASEFEEAMOUNT
			,ADDITIONALFEE
			,FOREIGNFEEAMOUNT
			,CURRENCY
			,OWNERNAME
			,QUANTITYINCALC
			,QUANTITYDESC
			,TOBEPAID
			,TAXAMOUNT
			,TOTALFEE
			,AGEOFCASE)
	Select		@pdtWhenRequested,
			isnull(FL.FEELISTITEM,-1)+1,
 			@psTaxCode,
 			@pnFeeListNo,
			@psFeeType,
 			@pnCaseId,
 			@psOfficialNumber,
 			@psNumberType,
 			@pnBaseFeeAmount,
 			@pnAdditionalFee,
 			@pnForeignFeeAmount,
 			@psCurrency,
 			@psOwnerName,
 			@pnQuantityInCalc,
 			@pnQuantityDesc,
 			@pbToBePaid,
 			@pnTaxAmount,
 			@pnTotalFee,
 			@pnAgeOfCase
 	From FEETYPES F
 	left join (	select max(isnull(FEELISTITEM,-1)) as FEELISTITEM
 			from FEELISTCASE
 			where WHENREQUESTED=@pdtWhenRequested) FL on (FL.FEELISTITEM=FL.FEELISTITEM)
 	Where F.FEETYPE=@psFeeType

	Select  @nErrorCode=@@Error,
		@nRowCount=@@Rowcount

	-- Check the rowcount to determine if
	-- a row was successfully inserted.
	If @nRowCount=0
	and @nErrorCode=0
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('FL03', 'Fee list not inserted because supplied Fee Type invalid.',@psFeeType, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
	End

	-- Commit transaction if successful
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

Return @nErrorCode
GO

Grant execute on dbo.fl_InsertFeeListCase to public
GO
