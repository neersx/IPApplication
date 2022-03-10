-----------------------------------------------------------------------------------------------------------------------------
-- Creation of rem_GetSatisfiedReminders
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[rem_GetSatisfiedReminders]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.rem_GetSatisfiedReminders.'
	Drop procedure [dbo].[rem_GetSatisfiedReminders]
End
Print '**** Creating Stored Procedure dbo.rem_GetSatisfiedReminders...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE PROCEDURE dbo.rem_GetSatisfiedReminders
(
	@pnUserIdentityId	int,			-- Mandatory
	@pnNameNo		int,			-- Mandatory NameNo who is viewing the reminders
	@pnCaseId		int		= null,
	@pbExternalUser		bit		= 0,
	@pbCalledFromCentura bit	= 1,
	@psParentProcTableName		nvarchar(60) = null
)
as
-- PROCEDURE:	rem_GetSatisfiedReminders
-- VERSION:	7
-- DESCRIPTION:	Get the EmployeeReminders that are no longer required.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Jul 2009	MF	17583	1	Procedure created
-- 24 Jul 2009	MF	17913	2	Removed named primary key constraint from #TEMPREMINDERS and replaced
--					with clustered index.
-- 02 Oct 2009	SF	5803	3	Retrieve results into a temporary table for use in ipw_ListDueDate
-- 08 Jan 2010	MF	18198	4	When Employee Reminders generated from an Ad Hoc alert are not to be satisfied by the Status associated
--					with the Case that is marked not to receive reminders.
-- 15 Feb 2011	SF	9824	5	Return the results if @pbCalledFromCentura = 0 and @psParentProcTableName is null
-- 20 Apr 2011	MF	RFC10333 6	Join EMPLOYEEREMINDER to ALERT using new ALERTNAMENO column which caters for Reminders that
--					have been sent to names that are different to the originating Alert.
-- 30 May 2011	MF	10724	7	When deleting EmployeeReminders need to consider the Source of the Reminder and not just whether an Event is
--					referenced or not.  This is because an Ad Hoc Alert may trigger a Reminder on the occurrence of an Event and
--					we want to avoid accidentally removing these reminders.

set nocount on
set concat_null_yields_null off

Create table #TEMPNAMES(EMPLOYEENO	int		not null Primary Key)

Create table #TEMPREMINDERS (
			EMPLOYEENO	int		not null,
			MESSAGESEQ	datetime	not null
			)

Create Clustered Index XPKTEMPREMINDERS ON #TEMPREMINDERS
		(	EMPLOYEENO,
			MESSAGESEQ)

Declare	@nErrorCode		int
Declare	@nNameCount		int
Declare @sSQLString		nvarchar(max)
Declare	@sFrom			nvarchar(1000)
Declare	@sWhere			nvarchar(1000)


-- Reduce locking level
set transaction isolation level read uncommitted

-- Initialise variables
Set @nErrorCode = 0

If  @nErrorCode=0
and @pbExternalUser is null
Begin
	------------------------------------------------
	-- Determine if the user is internal or external
	------------------------------------------------
	Set @sSQLString='
	Select	@pbExternalUser=isnull(ISEXTERNALUSER,0)
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId'

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@pbExternalUser	bit		OUTPUT,
				  @pnUserIdentityId	int',
				  @pbExternalUser=@pbExternalUser	OUTPUT,
				  @pnUserIdentityId=@pnUserIdentityId
End

If @nErrorCode=0
Begin
	If  @pnCaseId is not null
	Begin
		Set @sWhere=char(10)+"	and ER.CASEID=@pnCaseId"
	End
	Else Begin
		If  @pbExternalUser=0
		Begin
			-----------------------------------------------
			-- If not a specific Case and user is internal,
			-- get the Employees whose reminders are able 
			-- to be read.
			-- This uses Functional Security rules.
			-----------------------------------------------
			Set @sSQLString="
			Insert into #TEMPNAMES(EMPLOYEENO)
			select EMPLOYEENO  	
			from EMPLOYEE E  	
			join NAME N	on (N.NAMENO = @pnNameNo )  	
			left join FUNCTIONSECURITY F	
					on (F.FUNCTIONTYPE = 2
					and convert(varchar, F.SEQUENCENO) =
						    substring( (SELECT max(	CASE WHEN (F1.OWNERNO       is NULL) THEN '0' ELSE '1' END +
                        							CASE WHEN (F1.ACCESSSTAFFNO is NULL) THEN '0' ELSE '1' END +    				    		
                        							CASE WHEN (F1.ACCESSGROUP   is NULL) THEN '0' ELSE '1' END +  						
                        							convert(varchar,SEQUENCENO))  				
                        					FROM  FUNCTIONSECURITY F1  				
                        					WHERE F1.FUNCTIONTYPE = F.FUNCTIONTYPE  				
                        					and  (F1.OWNERNO = E.EMPLOYEENO OR F1.OWNERNO is NULL)  				
                        					and  (F1.ACCESSSTAFFNO = N.NAMENO OR F1.ACCESSSTAFFNO is NULL)  				
                        					and  (F1.ACCESSGROUP = N.FAMILYNO OR F1.ACCESSGROUP   is NULL)),4,5))  	
			where (ACCESSPRIVILEGES& 8 = 8 OR E.EMPLOYEENO = @pnNameNo )"
			
			Exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnNameNo	int',
							  @pnNameNo=@pnNameNo
			Set @nNameCount=@@rowcount
		End
		
		If @nErrorCode=0
		Begin
			If @nNameCount>0
				set @sFrom=char(10)+"	join #TEMPNAMES N on (N.EMPLOYEENO=ER.EMPLOYEENO)"
			Else
				set @sWhere=char(10)+"	and ER.EMPLOYEENO=@pnNameNo"
		End
	End
End

If @nErrorCode=0
Begin
	----------------------------------------------
	-- Now construct the SQL that determines which
	-- Employee Reminder rows have been satisfied
	-- and are no longer required.
	-- WARNING:
	-- This SQL has been constructed to address
	-- performance issues when there is a very 
	-- large number of rows in the tables.
	----------------------------------------------
	
	----------------------------------------------
	-- Employee Reminders associated with an Event
	-- where the due date against the reminder 
	-- is missing or CaseEvent row no long exists
	----------------------------------------------	
	Set @sSQLString="
	Insert into #TEMPREMINDERS(EMPLOYEENO, MESSAGESEQ)
	Select ER.EMPLOYEENO, ER.MESSAGESEQ     
	From EMPLOYEEREMINDER ER"+ 
	@sFrom+"
	left join CASEEVENT CE	on (CE.CASEID  = ER.CASEID
   				and CE.EVENTNO = ER.EVENTNO
   				and CE.CYCLE   = ER.CYCLENO)    
	Where ER.EVENTNO is not null  
	and   ER.SOURCE=0  
	and ( ER.DUEDATE is NULL OR CE.CASEID is NULL )"+
	@sWhere

	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameNo	int,
					  @pnCaseId	int',
					  @pnNameNo=@pnNameNo,
					  @pnCaseId=@pnCaseId
					  
	If @nErrorCode=0
	Begin
		----------------------------------------------
		-- System generated Reminders associated with
		-- a Case where the status of the Case does
		-- not allow reminders to be sent.
		----------------------------------------------	
		Set @sSQLString="
		Insert into #TEMPREMINDERS(EMPLOYEENO, MESSAGESEQ)
		Select ER.EMPLOYEENO, ER.MESSAGESEQ     
		From EMPLOYEEREMINDER ER"+ 
		@sFrom+"
		left join #TEMPREMINDERS TR	on (TR.EMPLOYEENO=ER.EMPLOYEENO
						and TR.MESSAGESEQ=ER.MESSAGESEQ)
		join CASES C	on (C.CASEID    = ER.CASEID)  
		join STATUS S	on (S.STATUSCODE=C.STATUSCODE)   
		Where S.REMINDERSALLOWED=0
		and ER.SOURCE=0
		and TR.EMPLOYEENO is null"+
		@sWhere
		
		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnNameNo	int,
						  @pnCaseId	int',
						  @pnNameNo=@pnNameNo,
						  @pnCaseId=@pnCaseId
	End
					  
	If @nErrorCode=0
	Begin
		----------------------------------------------
		-- Employee Reminders associated with an Event
		-- that is no longer due.
		----------------------------------------------	
		Set @sSQLString="
		Insert into #TEMPREMINDERS(EMPLOYEENO, MESSAGESEQ)
		Select ER.EMPLOYEENO, ER.MESSAGESEQ     
		From EMPLOYEEREMINDER ER"+ 
		@sFrom+"
		left join #TEMPREMINDERS TR	on (TR.EMPLOYEENO=ER.EMPLOYEENO
						and TR.MESSAGESEQ=ER.MESSAGESEQ)
		join CASEEVENT CE		on (CE.CASEID  = ER.CASEID
   						and CE.EVENTNO = ER.EVENTNO
   						and CE.CYCLE   = ER.CYCLENO) 
		Where CE.EVENTDATE is not null
		and ER.SOURCE=0
		and TR.EMPLOYEENO is null"+
		@sWhere
		
		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnNameNo	int,
						  @pnCaseId	int',
						  @pnNameNo=@pnNameNo,
						  @pnCaseId=@pnCaseId
	End
					  
	If @nErrorCode=0
	Begin
		----------------------------------------------
		-- Employee Reminders associated with an Event
		-- that is not associated with an Open Action.
		----------------------------------------------	
		Set @sSQLString="
		Insert into #TEMPREMINDERS(EMPLOYEENO, MESSAGESEQ)
		Select ER.EMPLOYEENO, ER.MESSAGESEQ     
		From EMPLOYEEREMINDER ER"+ 
		@sFrom+"
		left join #TEMPREMINDERS TR	on (TR.EMPLOYEENO=ER.EMPLOYEENO
						and TR.MESSAGESEQ=ER.MESSAGESEQ)
		join CASEEVENT CE		on (CE.CASEID  = ER.CASEID
   						and CE.EVENTNO = ER.EVENTNO
   						and CE.CYCLE   = ER.CYCLENO) 
		Where CE.EVENTDATE is null
		and ER.SOURCE=0
		and TR.EMPLOYEENO is null"+
		@sWhere+"
		and not exists
		(select 1
		 from OPENACTION OA
		 join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO
					and EC.EVENTNO=CE.EVENTNO)
		 join ACTIONS A		on (A.ACTION=OA.ACTION)
		 where OA.CASEID=CE.CASEID
		 and OA.POLICEEVENTS=1
		 and ((OA.CYCLE=CE.CYCLE and A.NUMCYCLESALLOWED>1) OR A.NUMCYCLESALLOWED=1) )"
		
		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnNameNo	int,
						  @pnCaseId	int',
						  @pnNameNo=@pnNameNo,
						  @pnCaseId=@pnCaseId
	End
					  
	If @nErrorCode=0
	Begin
		----------------------------------------------
		-- Employee Reminders associated with an Alert
		-- that has been removed.
		----------------------------------------------	
		Set @sSQLString="
		Insert into #TEMPREMINDERS(EMPLOYEENO, MESSAGESEQ)
		Select ER.EMPLOYEENO, ER.MESSAGESEQ     
		From EMPLOYEEREMINDER ER"+ 
		@sFrom+"
		left join #TEMPREMINDERS TR	on (TR.EMPLOYEENO=ER.EMPLOYEENO
						and TR.MESSAGESEQ=ER.MESSAGESEQ)  
		left join ALERT A		on ( A.EMPLOYEENO=ER.ALERTNAMENO 			
						and (A.CASEID = ER.CASEID   			 
						 or (A.REFERENCE = ER.REFERENCE and A.CASEID is null and ER.CASEID is null))   			
						and  A.SEQUENCENO=ER.SEQUENCENO 	)   
		Where ER.SOURCE=1
		and ER.ALERTNAMENO is not null
		and ER.EVENTNO is null
		and A.EMPLOYEENO is null
		and TR.EMPLOYEENO is null"+
		@sWhere
		
		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnNameNo	int,
						  @pnCaseId	int',
						  @pnNameNo=@pnNameNo,
						  @pnCaseId=@pnCaseId
	End			  
End

If @nErrorCode=0
and ((@pbCalledFromCentura = 1)
or (@pbCalledFromCentura = 0 and @psParentProcTableName is null))
Begin
	Set @sSQLString="
	Select * from #TEMPREMINDERS order by 1,2"
	
	exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode=0
and @psParentProcTableName is not null
and exists(select * from tempdb.dbo.sysobjects where name = @psParentProcTableName)
Begin

	Set @sSQLString = "Insert into "+@psParentProcTableName+" (EMPLOYEENO, MESSAGESEQ)
						select EMPLOYEENO, MESSAGESEQ
						from #TEMPREMINDERS"
	exec @nErrorCode=sp_executesql @sSQLString			
End


Return @nErrorCode
GO

Grant execute on dbo.rem_GetSatisfiedReminders to public
GO