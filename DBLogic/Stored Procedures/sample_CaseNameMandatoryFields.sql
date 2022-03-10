-----------------------------------------------------------------------------------------------------------------------------
-- Creation of sample_CaseNameMandatoryFields 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[sample_CaseNameMandatoryFields]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.sample_CaseNameMandatoryFields.'
	drop procedure dbo.sample_CaseNameMandatoryFields
end
print '**** Creating procedure dbo.sample_CaseNameMandatoryFields...'
print ''
go

set QUOTED_IDENTIFIER off -- this is required for the XML Nodes method
go
set ANSI_NULLS on
go

create procedure dbo.sample_CaseNameMandatoryFields	
		@pnCaseId		int		= null,	-- identifies a specific Case to be validated
		@pnTransactionNo	int		= null,	-- identifies the DB transaction that the validation is to be restricted to
		@psTableName		nvarchar(60)	= null,	-- the name of a table containing CASEIDs to be validated
		@pnValidationId		int		= null	-- the VALIDATIONID to filter the CASEIDs from the @psTableName.
		  
as
---PROCEDURE :	sample_CaseNameMandatoryFields
-- VERSION :	3
-- DESCRIPTION:	This is a user defined validation for checking the existence of mandatory CaseName
--		fields that have been configured through the Screen Designer for specific Name Types.
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
-- 05 Aug 2014	MF	R38221	1	Procedure created.
-- 04 Sep 2014	MF	R38221	2	Correction to set collation on temporary table.
-- 16 Jan 2017	MF	69889	3	When checking the CASENAME, the EXPIRYDATE must either be null or a future date.
		
set nocount on

Create table #TEMP_VALIDATECASES
			(CASEID		int		not null,
			 CRITERIANO	int		not null )
			
Create table #TEMPNAMETYPE(
			CASEID		int		not null,
			NAMETYPE	nvarchar(3)	collate database_default not null )

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

	---------------------------
	-- Get the first CriteriaNo 
	---------------------------
	Select @nCriteriaNo=MIN(CRITERIANO)
	from #TEMP_VALIDATECASES
	
	Set @ErrorCode=@@ERROR
	----------------------------------------------
	-- For each CRITERINAO get all of the possible 
	-- NameTypes configured in the Screen Designer
	----------------------------------------------
	While @nCriteriaNo is not null
	and   @ErrorCode=0
	Begin
		insert into #TEMPNAMETYPE(CASEID, NAMETYPE)
		select CASEID, NAMETYPE
		from #TEMP_VALIDATECASES
		cross join fnw_ScreenCriteriaNameTypes(@nCriteriaNo)
		where CRITERIANO=@nCriteriaNo
		
		Set @ErrorCode=@@ERROR
		
		Select @nCriteriaNo=min(CRITERIANO)
		from #TEMP_VALIDATECASES
		where CRITERIANO>@nCriteriaNo
		
		Set @ErrorCode=@@ERROR
	End
End

IF @ErrorCode=0
Begin
	------------------------------------------
	-- I am using dynamically constructed SQL
	-- that will vary depending upon the input
	-- parameters passed to this procedure.
	------------------------------------------
	Set @sSQLString="
	--------------------------------------
	-- Checking for columns marked as 
	-- Mandatory where the data is missing
	--------------------------------------
	select	CN.CASEID as CASEID,
		Case When(EC.ELEMENTNAME like 'txtCaseNameTopic%Reference%'     ) Then NT.DESCRIPTION+ ' missing mandatory Reference.'
		     When(EC.ELEMENTNAME like 'pkCaseNameTopic%AttentionName'   ) Then NT.DESCRIPTION+ ' missing mandatory Attention.'
		     When(EC.ELEMENTNAME like 'txtCaseNameTopic%BillPercent'    ) Then NT.DESCRIPTION+ ' missing mandatory Billing Percentage.'
		     When(EC.ELEMENTNAME like 'pkCaseNameTopic%CaseAddress'     ) Then NT.DESCRIPTION+ ' missing mandatory Address.'
		     When(EC.ELEMENTNAME like 'dtCaseNameTopic%Start'           ) Then NT.DESCRIPTION+ ' missing mandatory Commence Date.'
		     When(EC.ELEMENTNAME like 'dtCaseNameTopic%End'             ) Then NT.DESCRIPTION+ ' missing mandatory End Date.'
		     When(EC.ELEMENTNAME like 'dtCaseNameTopic%Assigned'        ) Then NT.DESCRIPTION+ ' missing mandatory Assigned Date.'
		     When(EC.ELEMENTNAME like 'xtaCaseNameTopic%Remarks'        ) Then NT.DESCRIPTION+ ' missing mandatory Comments.'
		     When(EC.ELEMENTNAME like 'pkCaseNameTopic%NameVariant'     ) Then NT.DESCRIPTION+ ' missing mandatory Name Variant.'
		     When(EC.ELEMENTNAME like 'pklCaseNameTopic%CorrespReceived') Then NT.DESCRIPTION+ ' missing mandatory Correspondence Received.'
		End  as Result
	from #TEMP_VALIDATECASES C
	join WINDOWCONTROL WC  on (WC.CRITERIANO=C.CRITERIANO
			       and WC.WINDOWNAME='CaseNameMaintenance')
	join TOPICCONTROL TC   on (TC.WINDOWCONTROLNO=WC.WINDOWCONTROLNO
			       and TC.FILTERNAME='NameTypeCode')
	join ELEMENTCONTROL EC on (EC.TOPICCONTROLNO=TC.TOPICCONTROLNO)
	join CASENAME CN on (CN.CASEID=C.CASEID
			 and CN.NAMETYPE=TC.FILTERVALUE
			 and(CN.EXPIRYDATE is null OR CN.EXPIRYDATE>getdate()))
	join NAMETYPE NT on (NT.NAMETYPE=CN.NAMETYPE)
	where EC.ISHIDDEN=0
	and   EC.ISREADONLY=0
	and   EC.ISMANDATORY=1
	and(( EC.ELEMENTNAME like 'txtCaseNameTopic%Reference%'      and CN.REFERENCENO            is null and NT.COLUMNFLAGS&4   =   4) -- Also check the COLUMNFLAG for field is turned on
	 OR ( EC.ELEMENTNAME like 'pkCaseNameTopic%AttentionName'    and CN.CORRESPONDNAME         is null and NT.COLUMNFLAGS&1   =   1)
	 OR ( EC.ELEMENTNAME like 'txtCaseNameTopic%BillPercent'     and CN.BILLPERCENTAGE         is null and NT.COLUMNFLAGS&64  =  64)
	 OR ( EC.ELEMENTNAME like 'pkCaseNameTopic%CaseAddress'      and CN.ADDRESSCODE            is null and NT.COLUMNFLAGS&2   =   2)
	 OR ( EC.ELEMENTNAME like 'dtCaseNameTopic%Start'            and CN.COMMENCEDATE           is null and NT.COLUMNFLAGS&16  =  16)
	 OR ( EC.ELEMENTNAME like 'dtCaseNameTopic%End'              and CN.EXPIRYDATE             is null and NT.COLUMNFLAGS&32  =  32)
	 OR ( EC.ELEMENTNAME like 'dtCaseNameTopic%Assigned'         and CN.ASSIGNMENTDATE         is null and NT.COLUMNFLAGS&8   =   8)
	 OR ( EC.ELEMENTNAME like 'xtaCaseNameTopic%Remarks'         and CN.REMARKS                is null and NT.COLUMNFLAGS&1024=1024)
	 OR ( EC.ELEMENTNAME like 'pkCaseNameTopic%NameVariant'      and CN.NAMEVARIANTNO          is null and NT.COLUMNFLAGS&512 = 512)
	 OR ( EC.ELEMENTNAME like 'pklCaseNameTopic%CorrespReceived' and CN.CORRESPONDENCERECEIVED is null and NT.COLUMNFLAGS&2048=2048)
	   )
	UNION
	--------------------------------------
	-- Checking for NameTypes where the 
	-- number of Names is incorrect
	--------------------------------------
	select	C.CASEID as CASEID,
		Case When(CN.NAMECOUNT>NT.MAXIMUMALLOWED             ) Then NT.DESCRIPTION+ ' has been recorded '+ cast(CN.NAMECOUNT as nvarchar)+' times, when only a maximum of '+ cast(NT.MAXIMUMALLOWED as nvarchar)+' is allowed.'
		     When(CN.NAMECOUNT is null and NT.MANDATORYFLAG=1) Then NT.DESCRIPTION+ ' is mandatory for the Case but is missing.'
		End  as Result
	from #TEMPNAMETYPE C
	join NAMETYPE NT on (NT.NAMETYPE=C.NAMETYPE)
	left join (select CASEID, NAMETYPE, count(*) as NAMECOUNT
	           from CASENAME
	           where (EXPIRYDATE is null or EXPIRYDATE>getdate())
	           group by CASEID, NAMETYPE) CN 
			on (CN.CASEID=C.CASEID
			and CN.NAMETYPE=NT.NAMETYPE)
	where CN.NAMECOUNT>NT.MAXIMUMALLOWED
	 OR ( CN.NAMECOUNT is null and NT.MANDATORYFLAG=1)"
	
	-----------------------------------------------
	-- Now execute the dynamically constructed SQL.
	-- Passing the parameters, even if they have 
	-- not been used.
	-----------------------------------------------

	exec @ErrorCode=sp_executesql @sSQLString
End

return @ErrorCode
go

grant execute on dbo.sample_CaseNameMandatoryFields  to public
go

