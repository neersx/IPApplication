-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipr_ArrangeDetailDatesSeq
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'dbo.ipr_ArrangeDetailDatesSeq') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipr_ArrangeDetailDatesSeq.'
	Drop procedure dbo.ipr_ArrangeDetailDatesSeq
End
Print '**** Creating Stored Procedure dbo.ipr_ArrangeDetailDatesSeq...'
Print ''
GO

create procedure dbo.ipr_ArrangeDetailDatesSeq
	@pCriteriaNo	int,
	@pEntryNumber	int,
	@pEventNo	int,
	@pReturnCode	int OUTPUT
as
-- PROCEDURE :	ipr_ArrangeDetailDatesSeq
-- VERSION :	3
-- COPYRIGHT: 	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Given the Criteriano Entry Number and Eventno, the procedure arranges all instances of  
-- 		the same Event inherited in the descendent criteria to one below the 
--		closest Event in the given criteria before the given Event that exists 
--		in both the given criteria and the descendent criteria. 

-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 13/12/2000	SF		1	Creation
-- 13/12/2004	AB	10793	2	Add go to end of grant statement
-- 23 Sep 2015	MF	52404	3	The resequencing of DETAILDATES rows was incorrectly not being 
--					contained to the specific ENTRYNUMBER row.

	declare @ErrorCode int
	
	if @pCriteriaNo is NULL
		return -100

	if @pEntryNumber is NULL
		return -100

	if @pEventNo is NULL
		return -100

	if not exists( select * from CRITERIA where CRITERIANO = @pCriteriaNo )
		-- the given CRITERIANO does not exist in the CRITERIA table */
		return -100

	if not exists( select * from DETAILDATES where CRITERIANO = @pCriteriaNo and ENTRYNUMBER = @pEntryNumber and EVENTNO = @pEventNo )
		-- the given CRITERIANO and EVENTNO, ENTRYNUMBER do not exist in the DETAILDATES table */
		return -100

	select @ErrorCode = 0
	if @ErrorCode = 0
	begin
		begin transaction

		if @ErrorCode = 0
		begin
			set nocount on
			-- Create a temporary table to hold the Criteria that have children
			-- Load the first parent Criteriano into it. 
			
			select	distinct PARENT=I1.FROMCRITERIA
			into	#PARENTS
			from	INHERITS I1
			where	I1.FROMCRITERIA = @pCriteriaNo
			
			-- Loop through each row in the temporary table and load any Criteria that is
			-- the child of the rows in the temporary table and has its own descendants 
			-- and also contains the passed Screen with the Inherited Flag on ( added )
			
			while (@@rowcount >0)AND (@@error = 0)
			begin
				insert	into #PARENTS
				select	distinct I1.CRITERIANO
				from	#PARENTS P1
				join	INHERITS I1 on (I1.FROMCRITERIA=P1.PARENT)
				join	INHERITS I2 on (I2.FROMCRITERIA=I1.CRITERIANO)
				join	DETAILDATES DD on (DD.CRITERIANO=I1.CRITERIANO)
				where 	DD.ENTRYNUMBER = @pEntryNumber
				and	DD.EVENTNO = @pEventNo
				and not exists
					(select * from #PARENTS P2
					 where P2.PARENT=I1.CRITERIANO)
			 end
			-- must find out if the above have caused any errors */
			select @ErrorCode = @@Error
		end	

		if @ErrorCode = 0
		begin
	
			update	DD
			set	DISPLAYSEQUENCE = 
				-- When the Event being updated is equal to the Given Event
				-- set the DISPLAYSEQUENCE to the position after the Event that exists
				-- immediately before the Given Event in the Parent criteria entry and
				-- also exists in the Child criteria.
				-- Note that if no Events exists in the Child criteria that also exists	
				-- before the inserted Event in the Parent criteria then the given Event
				-- will be positioned at the top of the list with DisplaySequence=0.
				case when(EVENTNO=@pEventNo)
		         		then (	select isnull(max( CHILD.DISPLAYSEQUENCE )+1,0)
						from	DETAILDATES PARENT,
							DETAILDATES CHILD
						where	PARENT.CRITERIANO = @pCriteriaNo
						and	CHILD.CRITERIANO  = DD.CRITERIANO
						and	not ( PARENT.EVENTNO = @pEventNo     and PARENT.ENTRYNUMBER = @pEntryNumber)
						and	    ( PARENT.EVENTNO = CHILD.EVENTNO and PARENT.ENTRYNUMBER = CHILD.ENTRYNUMBER)
						and	PARENT.DISPLAYSEQUENCE = (
								-- Find the highest DisplaySequence of the
								-- Event that exists in both the Child and the	
								-- Parent criteria entry and falls before the Given 	
								-- Event.
								select max(PARENT2.DISPLAYSEQUENCE)
								from	DETAILDATES PARENT2
								join	DETAILDATES CHILD2 on (CHILD2.CRITERIANO =CHILD.CRITERIANO)
								join	DETAILDATES NEW    on (NEW.CRITERIANO    =PARENT.CRITERIANO)
								where	PARENT2.CRITERIANO=PARENT.CRITERIANO
								and	NEW.EVENTNO     = @pEventNo       
								and	NEW.ENTRYNUMBER = @pEntryNumber
								and	PARENT2.EVENTNO <>NEW.EVENTNO
								and	CHILD2.EVENTNO    = PARENT2.EVENTNO 
								and	CHILD2.ENTRYNUMBER= PARENT2.ENTRYNUMBER
								and	PARENT2.DISPLAYSEQUENCE<=NEW.DISPLAYSEQUENCE)
		                                    )
					else DD.DISPLAYSEQUENCE + 1
				end
			
			from #PARENTS P
			join INHERITS I		on (I.FROMCRITERIA=P.PARENT)
			join DETAILDATES DD	on (DD.CRITERIANO =I.CRITERIANO
						and DD.ENTRYNUMBER=@pEntryNumber)
			
			where (DD.DISPLAYSEQUENCE >= (
					-- Return the Events within a Criteria Entry whose current position falls on or after the
					-- next position down from the Event that exists in both the Parent and Child criteria	entry
					-- and has the highest DisplaySequence before the given Event.
			     
					select	isnull(max( CHILD.DISPLAYSEQUENCE)+1, 0)
					from	DETAILDATES PARENT
					join	DETAILDATES CHILD on (CHILD.CRITERIANO = DD.CRITERIANO)
					where	PARENT.CRITERIANO = @pCriteriaNo
					and	PARENT.EVENTNO <> @pEventNo
					and	PARENT.EVENTNO = CHILD.EVENTNO 
					and	PARENT.ENTRYNUMBER = CHILD.ENTRYNUMBER
					and	PARENT.DISPLAYSEQUENCE = (
						select max(PARENT2.DISPLAYSEQUENCE)
						from	DETAILDATES PARENT2
						join	DETAILDATES CHILD2 on (CHILD2.CRITERIANO =CHILD.CRITERIANO)
						join	DETAILDATES NEW    on (NEW.CRITERIANO    =PARENT.CRITERIANO)
						where	PARENT2.CRITERIANO=PARENT.CRITERIANO
						and	NEW.EVENTNO     = @pEventNo       
						and	NEW.ENTRYNUMBER = @pEntryNumber
						and	PARENT2.EVENTNO <> NEW.EVENTNO
						and	CHILD2.EVENTNO  = PARENT2.EVENTNO 
						and	CHILD2.ENTRYNUMBER = PARENT2.ENTRYNUMBER
						and	PARENT2.DISPLAYSEQUENCE<=NEW.DISPLAYSEQUENCE)
			            )
				-- The given Event exists before the designated location 
				OR DD.EVENTNO	= @pEventNo
				)
				-- The only Criteria that are to have their Events shuffled are those
				-- where the Given Screen has been inherited.
			and	exists (select	* from DETAILCONTROL DC
					where	DC.CRITERIANO=DD.CRITERIANO
					and	DC.ENTRYNUMBER=DD.ENTRYNUMBER
					and	DC.INHERITED=1)
		
			select @ErrorCode = @@error	
		end

		if (@ErrorCode = 0)
			commit transaction
		else
			rollback transaction
	-- end the begin transaction block
	end
	select @pReturnCode = @ErrorCode
	return @ErrorCode
go

grant execute on dbo.ipr_ArrangeDetailDatesSeq to public
go
