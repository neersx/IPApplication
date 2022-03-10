-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cc_ChangeCaseCategory
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cc_ChangeCaseCategory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cc_ChangeCaseCategory.'
	Drop procedure [dbo].[cc_ChangeCaseCategory]
	Print '**** Creating Stored Procedure dbo.cc_ChangeCaseCategory...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cc_ChangeCaseCategory
(
	@psCaseType		nchar(1),
	@psOldCaseCategory	nvarchar(2),
	@psNewCaseCategory	nvarchar(2)
)
as
-- PROCEDURE:	cc_ChangeCaseCategory
-- VERSION:	5
-- SCOPE:	Inproma
-- DESCRIPTION:	Used to modify the CaseCategory from one value to another.
--		The CaseCategory is used in multiply places and referential integrity
--		will stop it from just being updated in the base CASECATEGORY table.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17-APR-2005  MF		1	Procedure created
-- 07-JUL-2005	VL	11011	2	Make CaseCategory variables and parameters nvarch(2)
-- 26-MAY-2005	MF	12742	3	Include change of table VALIDBASISEX
-- 30-MAR-2010	MF	RFC9081	4	Include change of table VALIDATENUMBERS
-- 27-AUG-2010	MF	RFC9316	5	Include change of table DATAVALIDATION


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @ErrorCode 	int
Declare @TranCountStart	int

Declare @sSQLString	nvarchar(4000)

Set 	@ErrorCode      = 0

Select @TranCountStart = @@TranCount

Begin TRANSACTION

-- Copy the details of the existing CASECATEGORY row using the NewCaseCategory if it does not already exist.

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into CASECATEGORY(CASETYPE, CASECATEGORY, CASECATEGORYDESC, CONVENTIONLITERAL, CASECATEGORYDESC_TID)
	select C.CASETYPE, @psNewCaseCategory, C.CASECATEGORYDESC, C.CONVENTIONLITERAL, C.CASECATEGORYDESC_TID
	from CASECATEGORY C
	left join CASECATEGORY N on (N.CASETYPE=C.CASETYPE
				and  N.CASECATEGORY=@psNewCaseCategory)
	where C.CASECATEGORY=@psOldCaseCategory
	and C.CASETYPE=@psCaseType
	and N.CASECATEGORY is null"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCaseCategory	nvarchar(2),
					  @psNewCaseCategory	nvarchar(2),
					  @psCaseType		nchar(1)',
					  @psOldCaseCategory,
					  @psNewCaseCategory,
					  @psCaseType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	insert into VALIDCATEGORY(COUNTRYCODE, PROPERTYTYPE, CASETYPE, CASECATEGORY, CASECATEGORYDESC, PROPERTYEVENTNO, CASECATEGORYDESC_TID)
	select V.COUNTRYCODE, V.PROPERTYTYPE, V.CASETYPE, @psNewCaseCategory, V.CASECATEGORYDESC, V.PROPERTYEVENTNO, V.CASECATEGORYDESC_TID
	from VALIDCATEGORY V
	left join VALIDCATEGORY N	on (N.COUNTRYCODE =V.COUNTRYCODE
					and N.PROPERTYTYPE=V.PROPERTYTYPE
					and N.CASETYPE    =V.CASETYPE
					and N.CASECATEGORY=@psNewCaseCategory)
	where V.CASECATEGORY=@psOldCaseCategory
	and V.CASETYPE=@psCaseType
	and N.CASECATEGORY is null"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCaseCategory	nvarchar(2),
					  @psNewCaseCategory	nvarchar(2),
					  @psCaseType		nchar(1)',
					  @psOldCaseCategory,
					  @psNewCaseCategory,
					  @psCaseType
End

-- Delete any ValidSubType rows that already exist with the New CaseCategory.
if @ErrorCode=0
Begin
	Set @sSQLString="
	Delete VALIDSUBTYPE
	from VALIDSUBTYPE V
	where V.CASECATEGORY=@psOldCaseCategory
	and V.CASETYPE=@psCaseType
	and exists
	(select * from VALIDSUBTYPE N
	 where N.COUNTRYCODE =V.COUNTRYCODE
	 and   N.PROPERTYTYPE=V.PROPERTYTYPE
	 and   N.CASETYPE    =V.CASETYPE
	 and   N.CASECATEGORY=@psNewCaseCategory
	 and   N.SUBTYPE     =V.SUBTYPE)"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCaseCategory	nvarchar(2),
					  @psNewCaseCategory	nvarchar(2),
					  @psCaseType		nchar(1)',
					  @psOldCaseCategory,
					  @psNewCaseCategory,
					  @psCaseType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDSUBTYPE
	set CASECATEGORY=@psNewCaseCategory
	where CASECATEGORY=@psOldCaseCategory
	and CASETYPE=@psCaseType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCaseCategory	nvarchar(2),
					  @psNewCaseCategory	nvarchar(2),
					  @psCaseType		nchar(1)',
					  @psOldCaseCategory,
					  @psNewCaseCategory,
					  @psCaseType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update INTERNALREFSTEM
	set CASECATEGORY=@psNewCaseCategory
	where CASECATEGORY=@psOldCaseCategory
	and CASETYPE=@psCaseType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCaseCategory	nvarchar(2),
					  @psNewCaseCategory	nvarchar(2),
					  @psCaseType		nchar(1)',
					  @psOldCaseCategory,
					  @psNewCaseCategory,
					  @psCaseType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update NARRATIVERULE
	set CASECATEGORY=@psNewCaseCategory
	where CASECATEGORY=@psOldCaseCategory
	and CASETYPE=@psCaseType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCaseCategory	nvarchar(2),
					  @psNewCaseCategory	nvarchar(2),
					  @psCaseType		nchar(1)',
					  @psOldCaseCategory,
					  @psNewCaseCategory,
					  @psCaseType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update POLICING
	set CASECATEGORY=@psNewCaseCategory
	where CASECATEGORY=@psOldCaseCategory
	and CASETYPE=@psCaseType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCaseCategory	nvarchar(2),
					  @psNewCaseCategory	nvarchar(2),
					  @psCaseType		nchar(1)',
					  @psOldCaseCategory,
					  @psNewCaseCategory,
					  @psCaseType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CASES
	set CASECATEGORY=@psNewCaseCategory
	where CASECATEGORY=@psOldCaseCategory
	and CASETYPE=@psCaseType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCaseCategory	nvarchar(2),
					  @psNewCaseCategory	nvarchar(2),
					  @psCaseType		nchar(1)',
					  @psOldCaseCategory,
					  @psNewCaseCategory,
					  @psCaseType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CRITERIA
	set CASECATEGORY=@psNewCaseCategory
	where CASECATEGORY=@psOldCaseCategory
	and CASETYPE=@psCaseType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCaseCategory	nvarchar(2),
					  @psNewCaseCategory	nvarchar(2),
					  @psCaseType		nchar(1)',
					  @psOldCaseCategory,
					  @psNewCaseCategory,
					  @psCaseType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update DATAVALIDATION
	set CASECATEGORY=@psNewCaseCategory
	where CASECATEGORY=@psOldCaseCategory"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCaseCategory	nvarchar(2),
					  @psNewCaseCategory	nvarchar(2)',
					  @psOldCaseCategory,
					  @psNewCaseCategory
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDBASISEX
	set CASECATEGORY=@psNewCaseCategory
	where CASECATEGORY=@psOldCaseCategory
	and CASETYPE=@psCaseType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCaseCategory	nvarchar(2),
					  @psNewCaseCategory	nvarchar(2),
					  @psCaseType		nchar(1)',
					  @psOldCaseCategory,
					  @psNewCaseCategory,
					  @psCaseType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDATENUMBERS
	set CASECATEGORY=@psNewCaseCategory
	where CASECATEGORY=@psOldCaseCategory
	and CASETYPE=@psCaseType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCaseCategory	nvarchar(2),
					  @psNewCaseCategory	nvarchar(2),
					  @psCaseType		nchar(1)',
					  @psOldCaseCategory,
					  @psNewCaseCategory,
					  @psCaseType
End

if @ErrorCode=0
Begin	
	Set @sSQLString="
	delete VALIDCATEGORY
	where CASECATEGORY=@psOldCaseCategory
	and CASETYPE=@psCaseType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCaseCategory	nvarchar(2),
					  @psCaseType		nchar(1)',
					  @psOldCaseCategory,
					  @psCaseType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	delete from CASECATEGORY
	where CASECATEGORY=@psOldCaseCategory
	and CASETYPE=@psCaseType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldCaseCategory	nvarchar(2),
					  @psCaseType		nchar(1)',
					  @psOldCaseCategory,
					  @psCaseType
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

Grant execute on dbo.cc_ChangeCaseCategory to public
GO
