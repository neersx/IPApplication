
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of nt_ChangeNumberType
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[nt_ChangeNumberType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.nt_ChangeNumberType.'
	Drop procedure [dbo].[nt_ChangeNumberType]
	Print '**** Creating Stored Procedure dbo.nt_ChangeNumberType...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.nt_ChangeNumberType
(
	@psOldNumberType	nvarchar(3),
	@psNewNumberType	nvarchar(3)
)
as
-- PROCEDURE:	nt_ChangeNumberType
-- VERSION:	1
-- SCOPE:	Inprotech
-- DESCRIPTION:	Used to modify the NumberType from one value to another.
--		The NumberType is used in multiply places and referential integrity
--		will stop it from just being updated in the base NUMBERTYPES table.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
--  29-Jan-2015	MF	12980	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @ErrorCode 	int
Declare @TranCountStart	int

Declare @sSQLString	nvarchar(max)

Set 	@ErrorCode      = 0

Select @TranCountStart = @@TranCount

Begin TRANSACTION

-- If the new NumberType already exists in the NUMBERTYPES table
-- then set the @ErrorCode to terminate processing
	
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @ErrorCode=count(*)
	from NUMBERTYPES
	where NumberType=@psNewNumberType"

	exec sp_executesql @sSQLString,
				N'@ErrorCode		int		OUTPUT,
				  @psNewNumberType	nvarchar(3)',
				  @ErrorCode	  =@ErrorCode		OUTPUT,
				  @psNewNumberType=@psNewNumberType
End

-----------------------------------------
-- Copy the details of the existing
-- NUMBERTYPES row with the NewNumberType 
-----------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into NUMBERTYPES(NUMBERTYPE, DESCRIPTION, RELATEDEVENTNO, ISSUEDBYIPOFFICE, DISPLAYPRIORITY, DESCRIPTION_TID)
	select @psNewNumberType, N.DESCRIPTION, N.RELATEDEVENTNO, N.ISSUEDBYIPOFFICE, N.DISPLAYPRIORITY, N.DESCRIPTION_TID	
	from NUMBERTYPES N
	where N.NUMBERTYPE=@psOldNumberType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldNumberType	nvarchar(3),
					  @psNewNumberType	nvarchar(3)',
					  @psOldNumberType,
					  @psNewNumberType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update DETAILCONTROL
	set NUMBERTYPE=@psNewNumberType
	from DETAILCONTROL
	where NUMBERTYPE=@psOldNumberType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldNumberType	nvarchar(3),
					  @psNewNumberType	nvarchar(3)',
					  @psOldNumberType,
					  @psNewNumberType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update EDERULEOFFICIALNUMBER
	set NUMBERTYPE=@psNewNumberType
	from EDERULEOFFICIALNUMBER
	where NUMBERTYPE=@psOldNumberType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldNumberType	nvarchar(3),
					  @psNewNumberType	nvarchar(3)',
					  @psOldNumberType,
					  @psNewNumberType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update EVENTCONTROL
	set LOADNUMBERTYPE=@psNewNumberType
	from EVENTCONTROL
	where LOADNUMBERTYPE=@psOldNumberType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldNumberType	nvarchar(3),
					  @psNewNumberType	nvarchar(3)',
					  @psOldNumberType,
					  @psNewNumberType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update FEELISTCASE
	set NUMBERTYPE=@psNewNumberType
	from FEELISTCASE
	where NUMBERTYPE=@psOldNumberType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldNumberType	nvarchar(3),
					  @psNewNumberType	nvarchar(3)',
					  @psOldNumberType,
					  @psNewNumberType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update OFFICIALNUMBERS
	set NUMBERTYPE=@psNewNumberType
	from OFFICIALNUMBERS
	where NUMBERTYPE=@psOldNumberType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldNumberType	nvarchar(3),
					  @psNewNumberType	nvarchar(3)',
					  @psOldNumberType,
					  @psNewNumberType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDATENUMBERS
	set NUMBERTYPE=@psNewNumberType
	from VALIDATENUMBERS
	where NUMBERTYPE=@psOldNumberType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldNumberType	nvarchar(3),
					  @psNewNumberType	nvarchar(3)',
					  @psOldNumberType,
					  @psNewNumberType
End

---------------------------------
-- Now remove the Old Number Type
---------------------------------
if @ErrorCode=0
Begin
	Set @sSQLString="
	delete from NUMBERTYPES
	where NUMBERTYPE=@psOldNumberType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldNumberType	nvarchar(3)',
					  @psOldNumberType
End

-----------------------------------
-- Commit the transaction if it has 
-- successfully completed
-----------------------------------
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

Grant execute on dbo.nt_ChangeNumberType to public
GO