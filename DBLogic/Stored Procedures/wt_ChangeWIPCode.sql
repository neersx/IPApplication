
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wt_ChangeWIPCode
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wt_ChangeWIPCode]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wt_ChangeWIPCode.'
	Drop procedure [dbo].[wt_ChangeWIPCode]
	Print '**** Creating Stored Procedure dbo.wt_ChangeWIPCode...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.wt_ChangeWIPCode
(
	@psOldWIPCode	nvarchar(6),
	@psNewWIPCode	nvarchar(6)
)
as
-- PROCEDURE:	wt_ChangeWIPCode
-- VERSION:	3
-- SCOPE:	Inprotech
-- DESCRIPTION:	Used to modify the WIPCode from one value to another.
--		The WIPCode is used in multiply places and referential integrity
--		will stop it from just being updated in the base WIPTEMPLATE table.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
--  1-SEP-2004	MF		1	Procedure created
--  1-SEP-2004	MF	10425	2	Left BILLLINE table out.
-- 14-Nov-2005	MF	12063	3	Removal of Delete triggers means we can remove the 
--					disabling of the triggers that were improving performance.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @ErrorCode 	int
Declare @TranCountStart	int

Declare @sSQLString	nvarchar(4000)

Set 	@ErrorCode      = 0

Select @TranCountStart = @@TranCount

Begin TRANSACTION

-- If the new WIPCode already exists in the WIPTEMPLATE table
-- then set the @ErrorCode to terminate processing
	
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @ErrorCode=count(*)
	from WIPTEMPLATE
	where WIPCODE=@psNewWIPCode"

	exec sp_executesql @sSQLString,
				N'@ErrorCode		int		OUTPUT,
				  @psNewWIPCode		nvarchar(6)',
				  @ErrorCode=@ErrorCode	OUTPUT,
				  @psNewWIPCode=@psNewWIPCode
End

-- Copy the details of the existing WIPTEMPLATE row with the NewWIPCode 
--if it does not already exist.

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into WIPTEMPLATE(WIPCODE,WIPTYPEID, DESCRIPTION, WIPATTRIBUTE, CONSOLIDATE, TAXCODE, ENTERCREDITWIP, REINSTATEWIP, ACTION, NARRATIVENO, CASETYPE, COUNTRYCODE, PROPERTYTYPE, WIPCODESORT, USEDBY, TOLERANCEPERCENT, TOLERANCEAMT, CREDITWIPCODE, DESCRIPTION_TID )
	select @psNewWIPCode,W.WIPTYPEID, W.DESCRIPTION, W.WIPATTRIBUTE, W.CONSOLIDATE, W.TAXCODE, W.ENTERCREDITWIP, W.REINSTATEWIP, W.ACTION, W.NARRATIVENO, W.CASETYPE, W.COUNTRYCODE, W.PROPERTYTYPE, W.WIPCODESORT, W.USEDBY, W.TOLERANCEPERCENT, W.TOLERANCEAMT, W.CREDITWIPCODE, W.DESCRIPTION_TID 
	from WIPTEMPLATE W
	where W.WIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CASEBUDGET
	set WIPCODE=@psNewWIPCode
	from CASEBUDGET C
	where C.WIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update COSTRATE
	set WIPCODE=@psNewWIPCode
	from COSTRATE C
	where C.WIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update COSTTRACKLINE
	set WIPCODE=@psNewWIPCode
	from COSTTRACKLINE C
	where C.WIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CREDITOR
	set DISBWIPCODE=@psNewWIPCode
	from CREDITOR C
	where C.DISBWIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update DEFAULTACTIVITY
	set WIPCODE=@psNewWIPCode
	from DEFAULTACTIVITY D
	where D.WIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update DIARY
	set ACTIVITY=@psNewWIPCode
	from DIARY D
	where D.ACTIVITY=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update FEESCALCULATION
	set VARWIPCODE=@psNewWIPCode
	from FEESCALCULATION F
	where F.VARWIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update FEESCALCULATION
	set SERVWIPCODE=@psNewWIPCode
	from FEESCALCULATION F
	where F.SERVWIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update FEESCALCULATION
	set DISBWIPCODE=@psNewWIPCode
	from FEESCALCULATION F
	where F.DISBWIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update FEETYPES
	set WIPCODE=@psNewWIPCode
	from FEETYPES F
	where F.WIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update GLACCOUNTMAPPING
	set WIPCODE=@psNewWIPCode
	from GLACCOUNTMAPPING G
	where G.WIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update NARRATIVERULE
	set WIPCODE=@psNewWIPCode
	from NARRATIVERULE N
	where N.WIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update QUOTATIONWIPCODE
	set WIPCODE=@psNewWIPCode
	from QUOTATIONWIPCODE Q
	where Q.WIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update TIMECOSTING
	set ACTIVITY=@psNewWIPCode
	from TIMECOSTING T
	where T.ACTIVITY=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update TRANSADJUSTMENT
	set TOWIPCODE=@psNewWIPCode
	from TRANSADJUSTMENT T
	where T.TOWIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update TRUSTACCOUNT
	set WIPCODE=@psNewWIPCode
	from TRUSTACCOUNT T
	where T.WIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update WIPTEMPLATE
	set CREDITWIPCODE=@psNewWIPCode
	from WIPTEMPLATE W
	where W.CREDITWIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update WORKINPROGRESS
	set WIPCODE=@psNewWIPCode
	from WORKINPROGRESS W
	where W.WIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

-- Commit the transaction up to this point if it has successfully completed
-- The transaction has been split because the update of the WORKHISTORY
-- table will take a long time and cause locks.

If @@TranCount > @TranCountStart
Begin
	If @ErrorCode = 0
	Begin
		COMMIT TRANSACTION
	End
	Else Begin
		ROLLBACK TRANSACTION
	End
End

-- Begin a new transaction for the  update of the 
-- WORKHISTORY & BILLLINE tables and Delete from WIPTEMPLATE

Select @TranCountStart = @@TranCount

Begin TRANSACTION

if @ErrorCode=0
Begin
	Set @sSQLString="
	update WORKHISTORY
	set WIPCODE=@psNewWIPCode
	from WORKHISTORY W
	where W.WIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update BILLLINE
	set WIPCODE=@psNewWIPCode
	from BILLLINE B
	where B.WIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6),
					  @psNewWIPCode	nvarchar(6)',
					  @psOldWIPCode,
					  @psNewWIPCode
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	delete from WIPTEMPLATE
	where WIPCODE=@psOldWIPCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldWIPCode	nvarchar(6)',
					  @psOldWIPCode
End

-- Commit the transaction if it has successfully completed

If @@TranCount > @TranCountStart
Begin
	If @ErrorCode = 0
	Begin
		COMMIT TRANSACTION
	End
	Else Begin
		ROLLBACK TRANSACTION
	End
End

Return @ErrorCode
GO

Grant execute on dbo.wt_ChangeWIPCode to public
GO