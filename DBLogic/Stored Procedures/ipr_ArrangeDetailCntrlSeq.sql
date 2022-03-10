-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipr_ArrangeDetailCntrlSeq
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipr_ArrangeDetailCntrlSeq]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipr_ArrangeDetailCntrlSeq.'
	drop procedure dbo.ipr_ArrangeDetailCntrlSeq
end
print '**** Creating procedure dbo.ipr_ArrangeDetailCntrlSeq...'
print ''
go

create procedure dbo.ipr_ArrangeDetailCntrlSeq 
	@pCriteriaNo int,
	@pEntryNumber int,
	@pReturnCode int OUTPUT
as
-- PROCEDURE :	ipr_ArrangeDetailCntrlSeq
-- VERSION :	2
-- DESCRIPTION:	Given the Criteriano and Entry number, the procedure arranges all instances of  
--		the same Entry number inherited in the descendent criteria to one below the 
--		closest Entry in the given criteria before the given Entry number that exists 
--		in both the given criteria and the descendent criteria. 
-- AUTHOR : 	Siew Fai, Mike Fleming and Anna van der Aa
-- INPUT : 	DETAILCONTROL.CRITERIANO, DETAILCONTROL.ENTRYNUMBER
-- OUTPUT : 	0 if no errors.
-- COPYRIGHT: 	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited

-- Date		Who	SQA#	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 13/12/2000	SF		1
-- 13/12/2004	AB	10793	2	Add go statement to end of grant	

	declare @ErrorCode int

	if @pCriteriaNo is NULL
		return -100

	if @pEntryNumber is NULL
		return -100

	if not exists( select * from CRITERIA where CRITERIANO = @pCriteriaNo )
			/* the given CRITERIANO does not exist in the CRITERIA table */
		return -100

	if not exists( select * from DETAILCONTROL where CRITERIANO = @pCriteriaNo and ENTRYNUMBER = @pEntryNumber )
			/* the given CRITERIANO and ENTRYNUMBER does not exist in the DETAILCONTROL table */
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
			-- and also contains the passed ENTRYNUMBER with the INHERITED flag on.
			
			while (@@rowcount >0)AND (@@error = 0)
			begin
				insert	into #PARENTS
				select	distinct I1.CRITERIANO
				from	#PARENTS P1
				join	INHERITS I1 on (I1.FROMCRITERIA=P1.PARENT)
				join	INHERITS I2 on (I2.FROMCRITERIA=I1.CRITERIANO)
				join	DETAILCONTROL DC on (DC.CRITERIANO=I1.CRITERIANO)
				where 	DC.ENTRYNUMBER = @pEntryNumber
				and	DC.INHERITED = 1
				and not exists
					(select * from #PARENTS P2
					 where P2.PARENT=I1.CRITERIANO)
			 end
			/* must find out if the above have caused any errors */
			select @ErrorCode = @@Error					
		end
	
		if @ErrorCode = 0
		begin
			/* parent table is ready, carry on with the UPDATE */
			update	DETAILCONTROL
			set	DISPLAYSEQUENCE = 
				case   ENTRYNUMBER 
						/* When the EVENT being updated is equal to the Given Entry 		*/
						/* set the DISPLAYSEQUENCE to the position after the Entry that exists	*/
						/* immediately before the Given Entry in the Parent criteria and	*/
						/* also exists in the Child criteria.					*/
			                        when  @pEntryNumber 
						/* Note that if no Entry exists in the Child criteria that also exists	*/
						/* before the inserted Entry in the Parent criteria then the new Entry	*/
						/* will be positioned at the top of the list with DisplaySequence=0.	*/
			         		then (	select isnull(max( CHILD.DISPLAYSEQUENCE )+1,0)
							from	DETAILCONTROL PARENT,
								DETAILCONTROL CHILD
							where	PARENT.CRITERIANO = @pCriteriaNo
							and	CHILD.CRITERIANO  = DC.CRITERIANO
							and	PARENT.ENTRYNUMBER   <> @pEntryNumber
							and	PARENT.ENTRYNUMBER    = CHILD.ENTRYNUMBER
							and	PARENT.DISPLAYSEQUENCE = (
									/* Find the highest DisplaySequence of the	*/
									/* Entry that exists in both the Child and the	*/
									/* Parent criteria and falls before the Entry	*/
									/* just insered.				*/
									select max(PARENT2.DISPLAYSEQUENCE)
									from	DETAILCONTROL PARENT2,
										DETAILCONTROL CHILD2,
										DETAILCONTROL NEW
									where	PARENT2.CRITERIANO=PARENT.CRITERIANO
									and	CHILD2.CRITERIANO =CHILD.CRITERIANO
									and	NEW.CRITERIANO    =PARENT.CRITERIANO
									and	NEW.ENTRYNUMBER	  = @pEntryNumber
									and	PARENT2.ENTRYNUMBER	 <> NEW.ENTRYNUMBER
									and	CHILD2.ENTRYNUMBER	  = PARENT2.ENTRYNUMBER
									and	PARENT2.DISPLAYSEQUENCE<=NEW.DISPLAYSEQUENCE)
			                                    )
						/* When the Entry is not the same as the newly Given Entry then		*/
						/* increment the DisplaySequence by 1 to make room for the new Entry.	*/
						else DC.DISPLAYSEQUENCE + 1
			            end
			from	DETAILCONTROL DC
			join	INHERITS I on I.CRITERIANO = DC.CRITERIANO
			join	#PARENTS P on P.PARENT 	   = I.FROMCRITERIA
				/* Return the Entries within a Criteria whose current position falls on or after the	*/
				/* next position down from the Entry that exists in both the Parent and Child criteria	*/
				/* and has the highest DisplaySequence before the newly Given Entry.			*/
			where	(DC.DISPLAYSEQUENCE >= (
					select	isnull(max( CHILD.DISPLAYSEQUENCE)+1, 0)
					from	DETAILCONTROL PARENT, 
						DETAILCONTROL CHILD
					where	PARENT.CRITERIANO = @pCriteriaNo
					and	CHILD.CRITERIANO  = DC.CRITERIANO
					and	PARENT.ENTRYNUMBER   <> @pEntryNumber
					and	PARENT.ENTRYNUMBER    = CHILD.ENTRYNUMBER
					and	PARENT.DISPLAYSEQUENCE = (
						select max(PARENT2.DISPLAYSEQUENCE)
						from	DETAILCONTROL PARENT2,
							DETAILCONTROL CHILD2,
							DETAILCONTROL NEW
						where	PARENT2.CRITERIANO=PARENT.CRITERIANO
						and	CHILD2.CRITERIANO =CHILD.CRITERIANO
						and	NEW.CRITERIANO    =PARENT.CRITERIANO
						and	NEW.ENTRYNUMBER	  = @pEntryNumber
						and	PARENT2.ENTRYNUMBER	 <> NEW.ENTRYNUMBER
						and	CHILD2.ENTRYNUMBER	  = PARENT2.ENTRYNUMBER
						and	PARENT2.DISPLAYSEQUENCE<=NEW.DISPLAYSEQUENCE)
			            ) or
				/* The Given Entry exists before the designated location */
				DC.ENTRYNUMBER = @pEntryNumber
				)
				/* The only Criteria that are to have their Entries shuffled are those	*/
				/* where the newly Given Entry has been inherited.			*/
			and	exists (select	* from DETAILCONTROL DC1
					where	DC1.CRITERIANO=DC.CRITERIANO
					and	DC1.ENTRYNUMBER=@pEntryNumber
					and	DC1.INHERITED=1)
		
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

grant execute on dbo.ipr_ArrangeDetailCntrlSeq to public
go
