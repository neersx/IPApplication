-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_UtilCreateCaseType
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'dbo.ipu_UtilCreateCaseType') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipu_UtilCreateCaseType.'
	Drop procedure dbo.ipu_UtilCreateCaseType
End
Print '**** Creating Stored Procedure dbo.ipu_UtilCreateCaseType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipu_UtilCreateCaseType
(
			@psCaseType		nchar(1),
			@psDescription		nvarchar(50),
			@pbUserDefinedRule	bit	= 1
)
as
-- PROCEDURE:	ipu_UtilCreateCaseType
-- VERSION:	1
-- SCOPE:	Inprotech
-- DESCRIPTION:	Adds a CASETYPE to the database and generates the default ScreenControl
--		rules by copying from CriteriaNo -900
-- COPYRIGHT:	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 20-Dec-2006  MF		1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @ErrorCode 	int
Declare @TranCountStart	int
Declare @nCriteriaNo	int

Declare @sSQLString	nvarchar(4000)

Set @ErrorCode      = 0

Set @TranCountStart = @@TranCount

Begin TRANSACTION

-- Insert or update the CASETYPE row
	
If exists(select 1 from CASETYPE where CASETYPE=@psCaseType)
and @ErrorCode=0
Begin
	Set @sSQLString="
	Update CASETYPE
	Set CASETYPEDESC=@psDescription
	where CASETYPE=@psCaseType
	and isnull(CASETYPEDESC,'')<>@psDescription"

	exec sp_executesql @sSQLString,
				N'@psCaseType		nchar(1),
				  @psDescription	nvarchar(50)',
				  @psCaseType=@psCaseType,
				  @psDescription=@psDescription
End
Else If @ErrorCode=0
Begin
	Set @sSQLString="insert into CASETYPE(CASETYPE, CASETYPEDESC) values (@psCaseType,@psDescription)"

	exec sp_executesql @sSQLString,
				N'@psCaseType		nchar(1),
				  @psDescription	nvarchar(50)',
				  @psCaseType=@psCaseType,
				  @psDescription=@psDescription
End
 
If @ErrorCode=0
Begin

GetCriteriaNo:

	-- Check if a Criteria to hold the default Screens exists
	If not exists ( Select 1 from CRITERIA
			where PURPOSECODE='S'
			and CASETYPE     =@psCaseType
			and PROGRAMID    ='CASE'
			and PROPERTYTYPE    is null
			and PROPERTYUNKNOWN is null
			and COUNTRYCODE     is null
			and COUNTRYUNKNOWN  is null
			and CASECATEGORY    is null
			and CATEGORYUNKNOWN is null
			and SUBTYPE         is null
			and SUBTYPEUNKNOWN  is null)
	begin
		-- Get the next CriteriaNo to use depending on 
		-- whether this is a user defined Case Type
		Set @sSQLString="
		Update LASTINTERNALCODE
		set INTERNALSEQUENCE = INTERNALSEQUENCE + CASE WHEN(@pbUserDefinedRule=1) THEN 1 ELSE -1 END,
		    @nCriteriaNo     = INTERNALSEQUENCE + CASE WHEN(@pbUserDefinedRule=1) THEN 1 ELSE -1 END
		Where (TABLENAME = 'CRITERIA'       and @pbUserDefinedRule=1)
		   OR (TABLENAME = 'CRITERIA_MAXIM' and @pbUserDefinedRule=0)"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nCriteriaNo		int		OUTPUT,
					  @pbUserDefinedRule	bit',
					  @nCriteriaNo		=@nCriteriaNo	OUTPUT,
					  @pbUserDefinedRule	=@pbUserDefinedRule
	End

End

-- Now insert the CRITERIA row that will hold the 
-- default Screens
If @nCriteriaNo is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	insert into CRITERIA (CRITERIANO, PURPOSECODE, CASETYPE, PROGRAMID, PROPERTYTYPE, PROPERTYUNKNOWN, COUNTRYCODE, COUNTRYUNKNOWN, CASECATEGORY, CATEGORYUNKNOWN, SUBTYPE, SUBTYPEUNKNOWN, BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, USERDEFINEDRULE, RULEINUSE, PARENTCRITERIA)
	select @nCriteriaNo, PURPOSECODE, @psCaseType,  PROGRAMID, PROPERTYTYPE, PROPERTYUNKNOWN, COUNTRYCODE, COUNTRYUNKNOWN, CASECATEGORY, CATEGORYUNKNOWN, SUBTYPE, SUBTYPEUNKNOWN, BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, @pbUserDefinedRule, RULEINUSE, PARENTCRITERIA
	from CRITERIA
	where CRITERIANO=-900"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nCriteriaNo		int,
				  @psCaseType		nchar(1),
				  @pbUserDefinedRule	bit',
				  @nCriteriaNo		=@nCriteriaNo,
				  @psCaseType		=@psCaseType,
				  @pbUserDefinedRule	=@pbUserDefinedRule
	-- If a duplicate row is discovered then get the
	-- next CriteriaNo and repeat
	If @ErrorCode=2601
	   Goto GetCriteriaNo

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Insert into SCREENCONTROL (CRITERIANO, SCREENNAME, SCREENID, SCREENTITLE, DISPLAYSEQUENCE, INHERITED)
		Select @nCriteriaNo, SCREENNAME, SCREENID, SCREENTITLE, DISPLAYSEQUENCE, INHERITED
		from SCREENCONTROL
		where CRITERIANO=-900"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nCriteriaNo		int',
					  @nCriteriaNo		=@nCriteriaNo
	End
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

Grant execute on dbo.ipu_UtilCreateCaseType to public
GO
