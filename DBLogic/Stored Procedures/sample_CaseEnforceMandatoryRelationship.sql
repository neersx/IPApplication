-----------------------------------------------------------------------------------------------------------------------------
-- Creation of sample_CaseEnforceMandatoryRelationship 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[sample_CaseEnforceMandatoryRelationship]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.sample_CaseEnforceMandatoryRelationship.'
	drop procedure dbo.sample_CaseEnforceMandatoryRelationship
end
print '**** Creating procedure dbo.sample_CaseEnforceMandatoryRelationship...'
print ''
go

set QUOTED_IDENTIFIER off -- this is required for the XML Nodes method
go
set ANSI_NULLS on
go

create procedure [dbo].[sample_CaseEnforceMandatoryRelationship]	
		@pnCaseId		int		= null,	-- identifies a specific Case to be validated
		@pnTransactionNo	int		= null,	-- identifies the DB transaction that the validation is to be restricted to
		@psTableName		nvarchar(60)	= null,	-- the name of a table containing CASEIDs to be validated
		@pnValidationId		int		= null	-- the VALIDATIONID to filter the CASEIDs from the @psTableName.
		  
as
---PROCEDURE :	sample_CaseEnforceMandatoryRelationship
-- VERSION :	1
-- DESCRIPTION:	This is a user defined validation for checking the existence of mandatory related case
--		for a given relationship configured through the Screen Designer.
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
--			The output must consist of two NAMED columns. The names of the columns 
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
-- 11 Jan 2016	MF	38924	1	Procedure created.
		
set nocount on

Create table #TEMP_VALIDATECASES
			(CASEID		int		not null,
			 CRITERIANO	int		not null )

Declare	@sSQLString		nvarchar(max)
Declare @sProgram		nvarchar(50)

Declare	@ErrorCode		int
Declare @nCriteriaNo		int
Declare @nIdentityId		int
Declare @nProfileId		int

------------------------------
--
-- I N I T I A L I S A T I O N
--
------------------------------
Set @ErrorCode = 0

If @ErrorCode = 0
Begin
	---------------------------------------------------
	-- Determine the IdentityId of the user 
	-- that is executing this validation procedure.
	-- This is required to determine the users Profile
	-- and default Case program to determine the Screen
	-- Designer rules for the Case(s) being validated.
	---------------------------------------------------	
	select	@nIdentityId=CASE WHEN(substring(context_info,1,4) <>0x0000000) THEN cast(substring(context_info,1,4)  as int) END
	from master.dbo.sysprocesses
	where spid=@@SPID
	and substring(context_info,1, 4)<>0x0000000
	
	Set @ErrorCode=@@ERROR

	If @ErrorCode=0
	Begin
		----------------------------------------
		-- Now get the PROFILEID associated with
		-- the User and the Default Case Program
		----------------------------------------
		select @nProfileId=UI.PROFILEID,
		       @sProgram  =PA.ATTRIBUTEVALUE
		from USERIDENTITY UI
		join PROFILEATTRIBUTES PA on (PA.PROFILEID=UI.PROFILEID
					  and PA.ATTRIBUTEID=2)
		where UI.IDENTITYID=@nIdentityId
	
		Set @ErrorCode=@@ERROR
	End

	If @ErrorCode=0
	and @sProgram is null
	Begin
		------------------------------------
		-- Get a default Program to use if
		-- one was not able to be determined
		-------------------------------------
		If exists(select 1 from PROGRAM where PROGRAMID='CASENTRY')
			set @sProgram='CASENTRY'
		Else
		If exists(select 1 from PROGRAM where PROGRAMID='CASMAINT')
			set @sProgram='CASMAINT'
		Else
		If exists(select 1 from PROGRAM where PROGRAMID='TAKEOVER')
			set @sProgram='TAKEOVER'
		Else
			Select @sProgram=MIN(P.PROGRAMID)
			from PROFILEATTRIBUTES PA
			join PROGRAM P on (P.PROGRAMID=PA.ATTRIBUTEVALUE
			               and P.PROGRAMGROUP='C')
			where PA.ATTRIBUTEID=2
	End
	
	If @ErrorCode=0
	and @sProgram is not null
	Begin
		If @pnCaseId is not null
		Begin
			insert into #TEMP_VALIDATECASES(CASEID, CRITERIANO)
			select @pnCaseId, dbo.fn_GetCriteriaNo(@pnCaseId,'W',@sProgram, default, @nProfileId)
			where dbo.fn_GetCriteriaNo(@pnCaseId,'W',@sProgram, default, @nProfileId) is not null
			
			set @ErrorCode=@@ERROR
		End
		Else If	 @psTableName is not null
		Begin
			If @pnValidationId is not null
				Set @sSQLString="
				insert into #TEMP_VALIDATECASES(CASEID, CRITERIANO)
				Select CASEID, dbo.fn_GetCriteriaNo(CASEID,'W',@sProgram, default, @nProfileId)
				from "+@psTableName+"
				where VALIDATIONID=@pnValidationId
				and dbo.fn_GetCriteriaNo(CASEID,'W',@sProgram, default, @nProfileId) is not null
				order by 2"
			Else
				Set @sSQLString="
				insert into #TEMP_VALIDATECASES(CASEID, CRITERIANO)
				Select CASEID, dbo.fn_GetCriteriaNo(CASEID,'W',@sProgram, default, @nProfileId)
				from "+@psTableName+"
				where dbo.fn_GetCriteriaNo(CASEID,'W',@sProgram, default, @nProfileId) is not null
				order by 2"
			
			exec @ErrorCode=sp_executesql @sSQLString, 
						N'@sProgram		nvarchar(60),
						  @nProfileId		int,
						  @pnValidationId	int',
						  @sProgram		= @sProgram,
						  @nProfileId		= @nProfileId,
						  @pnValidationId	= @pnValidationId  
		End						  
	End
End

IF @ErrorCode=0
Begin
	---------------------------------------
	-- Checking for Cases where a mandatory
	-- relationship to an other case is 
	-- missing.
	---------------------------------------
	Set @sSQLString="
	select	distinct
		C.CASEID as CASEID,
		CR.RELATIONSHIPDESC+ ' is missing from this Case.' as Result
	from #TEMP_VALIDATECASES C
	join TOPICDEFAULTSETTINGS DS	on (DS.CRITERIANO=C.CRITERIANO
					and DS.TOPICNAME ='Case_RelatedCaseTopic')
					
	join CASERELATION CR		on (CR.RELATIONSHIP=DS.FILTERVALUE)	-- The mandatory Relationship
	
	left join RELATEDCASE RC	on (RC.CASEID=C.CASEID			-- Is the case related to another case by the mandatory relationship?
					and RC.RELATIONSHIP=CR.RELATIONSHIP
					and(RC.RELATEDCASEID is not null OR RC.OFFICIALNUMBER is not null))
	where RC.CASEID is null"
	
	-----------------------------------------------
	-- Now execute the dynamically constructed SQL.
	-- Passing the parameters, even if they have 
	-- not been used.
	-----------------------------------------------

	exec @ErrorCode=sp_executesql @sSQLString
End

return @ErrorCode
go

grant execute on dbo.sample_CaseEnforceMandatoryRelationship  to public
go

