-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipr_ArrangeChecklistItemSeq
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipr_ArrangeChecklistItemSeq]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipr_ArrangeChecklistItemSeq.'
	drop procedure dbo.ipr_ArrangeChecklistItemSeq
	print '**** Creating procedure dbo.ipr_ArrangeChecklistItemSeq...'
	print ''
end
go

create procedure dbo.ipr_ArrangeChecklistItemSeq 
	@pCriteriaNo	int,
	@pQuestionNo	int,
	@pReturnCode	int OUTPUT
as

-- PROCEDURE 	: ipr_ArrangeChecklistItemSeq
-- VERSION 	: 2.1.0
-- DESCRIPTION	: Given the Criteriano and the Questionno, the procedure arranges all instances of  
-- 		  the same checklistitem inherited in the descendent criteria to one below the 
--		  closest ChecklistItem in the given criteria before the given ChecklistItem that exists 
--		  in both the given criteria and the descendent criteria. 
-- CALLED BY 	:	
-- MODIFICATIONS:
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13/12/2000	SF

	declare @ErrorCode int
	
	if @pCriteriaNo is NULL
		return -100

	if @pQuestionNo is NULL
		return -100

	if not exists( select * from CRITERIA where CRITERIANO = @pCriteriaNo )
		/* the given CRITERIANO does not exist in the CRITERIA table */
		return -100

	if not exists( select * from CHECKLISTITEM where CRITERIANO = @pCriteriaNo and QUESTIONNO = @pQuestionNo)
		/* the given CRITERIANO and CHECKLIST does not exist in the CHECKLISTITEM table */
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
			-- and also contains the passed QUESTIONNO with the INHERITED flag on.
			
			while (@@rowcount >0)AND (@@error = 0)
			begin
				insert	into #PARENTS
				select	distinct I1.CRITERIANO
				from	#PARENTS P1
				join	INHERITS I1 on (I1.FROMCRITERIA=P1.PARENT)
				join	INHERITS I2 on (I2.FROMCRITERIA=I1.CRITERIANO)
				join 	CHECKLISTITEM CL on (CL.CRITERIANO = I1.CRITERIANO)
				where 	CL.QUESTIONNO = @pQuestionNo
				and	CL.INHERITED = 1
				and	not exists
					(select * from #PARENTS P2
					 where P2.PARENT=I1.CRITERIANO)
			 end
			/* must find out if the above have caused any errors */
			select @ErrorCode = @@Error
		end
	
		if @ErrorCode = 0
		begin
	
			update	CHECKLISTITEM
			set	SEQUENCENO = 
			            case   QUESTIONNO 
						/* When the ChecklistIte, being updated is equal to the Given ChecklistItem 	*/
						/* set the SEQUENCENO to the position after the ChecklistItem that exists	*/
						/* immediately before the Given ChecklistItem in the Parent criteria and	*/
						/* also exists in the Child criteria.						*/
			                        when  @pQuestionNo
						/* Note that if no ChecklistItem exists in the Child criteria that also exists	*/
						/* before the inserted Question in the Parent criteria then the given ChecklistItem*/
						/* will be positioned at the top of the list with SEQUENCENO=0.	*/
			         		then (	select isnull(max( CHILD.SEQUENCENO )+1,0)
							from	CHECKLISTITEM PARENT,
								CHECKLISTITEM CHILD
							where	PARENT.CRITERIANO = @pCriteriaNo
							and	CHILD.CRITERIANO  = CL.CRITERIANO
							and	PARENT.QUESTIONNO <> @pQuestionNo
							and	PARENT.QUESTIONNO = CHILD.QUESTIONNO
							and	PARENT.SEQUENCENO = (
									/* Find the highest SEQUENCENO of the	*/
									/* Screen that exists in both the Child and the	*/
									/* Parent criteria and falls before the Given 	*/
									/* ChecklistItem.					*/
									select max(PARENT2.SEQUENCENO)
									from	CHECKLISTITEM PARENT2,
										CHECKLISTITEM CHILD2,
										CHECKLISTITEM NEW
									where	PARENT2.CRITERIANO=PARENT.CRITERIANO
									and	CHILD2.CRITERIANO =CHILD.CRITERIANO
									and	NEW.CRITERIANO    =PARENT.CRITERIANO
									and	NEW.QUESTIONNO	  = @pQuestionNo
									and	PARENT2.QUESTIONNO <> NEW.QUESTIONNO
									and	CHILD2.QUESTIONNO = PARENT2.QUESTIONNO
									and	PARENT2.SEQUENCENO<=NEW.SEQUENCENO)
			                                    )
						/* When the Screen is not the same as the newly Given ChecklistItem then	*/
						/* increment the SEQUENCENO by 1 to make room for the given ChecklistItem.	*/
						else CL.SEQUENCENO + 1
			            end
			from	CHECKLISTITEM CL
			join	INHERITS I on I.CRITERIANO = CL.CRITERIANO
			join	#PARENTS P on P.PARENT 	   = I.FROMCRITERIA
				/* Return the ChecklistItem within a Criteria whose current position falls on or after the	*/
				/* next position down from the ChecklistItem that exists in both the Parent and Child criteria	*/
				/* and has the highest SEQUENCENO before the Given ChecklistItem.				*/
			where	(CL.SEQUENCENO >= (
					select	isnull(max( CHILD.SEQUENCENO)+1, 0)
					from	CHECKLISTITEM PARENT, 
						CHECKLISTITEM CHILD
					where	PARENT.CRITERIANO = @pCriteriaNo
					and	CHILD.CRITERIANO  = CL.CRITERIANO
					and	PARENT.QUESTIONNO  <> @pQuestionNo
					and	PARENT.QUESTIONNO   = CHILD.QUESTIONNO
					and	PARENT.SEQUENCENO = (
						select max(PARENT2.SEQUENCENO)
						from	CHECKLISTITEM PARENT2,
							CHECKLISTITEM CHILD2,
							CHECKLISTITEM NEW
						where	PARENT2.CRITERIANO=PARENT.CRITERIANO
						and	CHILD2.CRITERIANO =CHILD.CRITERIANO
						and	NEW.CRITERIANO    =PARENT.CRITERIANO
						and	NEW.QUESTIONNO	  = @pQuestionNo
						and	PARENT2.QUESTIONNO <> NEW.QUESTIONNO
						and	CHILD2.QUESTIONNO = PARENT2.QUESTIONNO
						and	PARENT2.SEQUENCENO<=NEW.SEQUENCENO)
			            ) or
				/* The Given ChecklistItem exists before the designated location */
				CL.QUESTIONNO	= @pQuestionNo
				)
				/* The only Criteria that are to have their ChecklistItem shuffled are those	*/
				/* where the Given ChecklistItem has been inherited.			*/
			and	exists (select	* from CHECKLISTITEM CL1
					where	CL1.CRITERIANO=CL.CRITERIANO
					and	CL1.QUESTIONNO=@pQuestionNo
					and	CL1.INHERITED=1)
		select @ErrorCode = @@Error	
		end
	
		if (@ErrorCode = 0)
			commit transaction
		else
			rollback transaction
	
	-- end begin block	
	end	
	select @pReturnCode = @ErrorCode
	return @ErrorCode
go

grant execute on dbo.ipr_ArrangeChecklistItemSeq to public
go
