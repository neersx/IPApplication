-----------------------------------------------------------------------------------------------------------------------------
-- Creation of sample_DataValidationProcedure 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[sample_DataValidationProcedure]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.sample_DataValidationProcedure.'
	drop procedure dbo.sample_DataValidationProcedure
end
print '**** Creating procedure dbo.sample_DataValidationProcedure...'
print ''
go

set QUOTED_IDENTIFIER off -- this is required for the XML Nodes method
go
set ANSI_NULLS on
go

create procedure dbo.sample_DataValidationProcedure	
		@pnCaseId		int		= null,	-- identifies a specific Case to be validated
		@pnTransactionNo	int		= null,	-- identifies the DB transaction that the validation is to be restricted to
		@psTableName		nvarchar(60)	= null,	-- the name of a table containing CASEIDs to be validated
		@pnValidationId		int		= null	-- the VALIDATIONID to filter the CASEIDs from the @psTableName.
		  
as
---PROCEDURE :	sample_DataValidationProcedure
-- VERSION :	1
-- DESCRIPTION:	This procedure is used as an illustration of the structure required for a used defined
--		stored procedure to perform validations.
--
--		INPUT PARAMETERS:
--		================
--			Four optional iput parameters MUST be define,
--			The parameters may be named anything as the procedure will not be 
--			called using named parameters. The purpose of the parameters must 
--			conform to the following :
--
--			Parameter 1	Either @pnCaseId OR @pnNameNo	INT	= NULL 
--					Identifies either a specific 
--					CASE or a specific NAME to be 
--					validated.
--
--			Parameter 2	@pnTransactionNo		INT	= NULL
--					Optionally identifies the
--					database transaction that
--					resulted in the validation. This
--					can then be used in the validation
--					to focus on specific data or
--					look at the audit logs to identify
--					specific changes.
--
--			Parameter 3	@pnTableName			nvarchar(60)=NULL
--					If multiple Cases or Names are
--					to be validated then the NAME
--					of the table will be provided
--					that can be joined to on either
--					NAMENO or CASEID.
--
--			Parameter 4	@pnValidationId			INT	= NULL
--					This will be used in conjunction
--					with Parameter 3 when the name
--					of the table is provided. A
--					second column named VALIDATIONID
--					will exist in the name table.
--					Only rows from that table whose
--					VALIDATIONID matches the value
--					passed in this parameter are 
--					required to be validated by the
--					stored procedure.
--		OUTPUT RESULT:
--		==============
--			The output must consist of two NAMED columns. THe names of the columns 
--			may be anything as long as they are used.
--
--			Examples :	Select C.CASEID as CASEID, 1 as Result
--					Select N.NAMENO, 'Email address must be entered' as Result
--
--			Multiple rows are allowed although repeating values should be
--			removed to ensure they are not repeated in the user interface.
--
--			Output is only required when the validation test has FAILED.
--			The columns returned do not require a specific name however their content must 
--			conform to the following:
--
--			Column 1	This column will identify the record the validation has occurred
--					against.  It will contain :
--						CASEID	- when Case(s) are being validated
--						NAMENO	- when Name(s) are being validated.
--					A value in this column indicates that the validation has failed. By
--					default the message to be returned to the user will be the message
--					that has been defined against the Data Validation rule in the field
--					called "Display Message". If language translation versions of this
--					message have been provided then the Display Message will be shown in
--					user required language.
--
--			Column 2	
--					An optional text message may be returned by the SELECT or stored procedure.
--					If a value is returned then it will replace the display message defined
--					against the Data Validation rule. The advantage of this approach is that the 
--					message can vary depending on specific data and can also embed 
--					data that was extracted from the record being validated.
--
--					No language translation occurs using this method.
--					One or more rows of data may be returned.
--					The message is effectively unlimited in size as it may return
--					a string of data as NVARCHAR(max) in length.
	
-- MODIFICATION
-- Date		Who	No	Version	Description
-- ====         ===	=== 	=======	=====================================================================
-- 13 Aug 2010	MF	9316	1	Procedure created.
		
set nocount on
		 	
Declare	@ErrorCode		int
Declare	@sSQLString		nvarchar(max)

------------------------------
--
-- I N I T I A L I S A T I O N
--
------------------------------
Set @ErrorCode = 0

IF @ErrorCode=0
Begin
	------------------------------------------
	-- I am using dynamically constructed SQL
	-- that will vary depending upon the input
	-- parameters passed to this procedure.
	------------------------------------------
	Set @sSQLString="
	Select	C.CASEID, 
		'1' as Result	-- The 1 indicates the Case failed the test. Alternatively a message could have been returned.
	from CASES C 
	join CASEEVENT CE on (CE.CASEID=C.CASEID 
			  and CE.EVENTNO=-4 ) 
	left join CASEEVENT CE1 on (CE1.CASEID=C.CASEID 
				and CE1.EVENTNO=-1 
				and CE1.EVENTDATE is not null)"

	If @psTableName is not null
	and @pnValidationId is not null
	Begin
		Set @sSQLString=@sSQLString+char(10)+
		"	join "+@psTableName+" T on (T.CASEID=C.CASEID"+char(10)+
		"				and T.VALIDATIONID=@pnValidationId)"
	End

	Set @sSQLString=@sSQLString+"
	where C.CASETYPE='A' 
	and CE1.EVENTDATE is null"

	If @pnCaseId is not null
	Begin
		Set @sSQLString=@sSQLString+char(10)+
		"	Where C.CASEID=@psCaseId"
	End

	If @pnTransactionNo is not null
	Begin
		Set @sSQLString=@sSQLString+char(10)+
		"	Where C.LOGTRANSACTIONNO=@pnTransactionNo"
	End
	----------------------------------------------
	-- No execute the dynamically constructed SQL.
	-- Remember to psss the parameters, even if 
	-- they have not been used.
	----------------------------------------------
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseId		int,
				  @pnValidationId	int,
				  @pnTransactionNo	int',
				  @pnCaseId	  =@pnCaseId,
				  @pnValidationId =@pnValidationId,
				  @pnTransactionNo=@pnTransactionNo
End

return @ErrorCode
go

grant execute on dbo.sample_DataValidationProcedure  to public
go

