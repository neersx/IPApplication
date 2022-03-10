-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipr_ArrangeEvntCntrlSeq
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipr_ArrangeEvntCntrlSeq]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipr_ArrangeEvntCntrlSeq'
	drop procedure dbo.ipr_ArrangeEvntCntrlSeq
	print '**** Creating procedure dbo.ipr_ArrangeEvntCntrlSeq...'
	print ''
end
go

create procedure dbo.ipr_ArrangeEvntCntrlSeq
	@pCriteriaNo int,
	@pEventNo int,
	@pReturnCode int OUTPUT
as

-- PROCEDURE 	: ipr_ArrangeEvntCntrlSeq
-- VERSION 	: 
-- DESCRIPTION	:Given the Criteriano and Eventno, the procedure arranges all instances of  
-- 		 the same eventno inherited in the descendent criteria to one below the 
--		 closest event in the given criteria before the given eventno that exists 
--		 in both the given criteria and the descendent criteria. 
-- CALLED BY 	:

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13/12/2000	SF			

	declare @ErrorCode int

	if @pCriteriaNo is NULL
		return -100

	if @pEventNo is NULL
		return -100

	if not exists( select * from CRITERIA where CRITERIANO = @pCriteriaNo )
			/* the given CRITERIANO does not exist in the CRITERIA table */
		return -100

	if not exists( select * from EVENTCONTROL where CRITERIANO = @pCriteriaNo and EVENTNO = @pEventNo )
			/* the given CRITERIANO and EVENTNO does not exist in the EVENTCONTROL table */
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
			-- and also contains the passed EVENTNO with the INHERITED flag on.
			
			while (@@rowcount >0)AND (@@error = 0)
			begin
				insert	into #PARENTS
				select	distinct I1.CRITERIANO
				from	#PARENTS P1						
				join	INHERITS I1 on (I1.FROMCRITERIA=P1.PARENT)		
				join	INHERITS I2 on (I2.FROMCRITERIA=I1.CRITERIANO)		
				join	EVENTCONTROL EC on (EC.CRITERIANO=I1.CRITERIANO)	
				where 	EC.EVENTNO = @pEventNo					
				and	EC.INHERITED = 1
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
			update	EVENTCONTROL
			set	DISPLAYSEQUENCE = 
				case   EVENTNO 
						/* When the EVENT being updated is equal to the Given Event 		*/
						/* set the DISPLAYSEQUENCE to the position after the Event that exists	*/
						/* immediately before the Given Event in the Parent criteria and	*/
						/* also exists in the Child criteria.					*/
			                        when  @pEventNo 
						/* Note that if no Event exists in the Child criteria that also exists	*/
						/* before the inserted Event in the Parent criteria then the new Event	*/
						/* will be positioned at the top of the list with DisplaySequence=0.	*/
			         		then (	select isnull(max( CHILD.DISPLAYSEQUENCE )+1,0)
							from	EVENTCONTROL PARENT,
								EVENTCONTROL CHILD
							where	PARENT.CRITERIANO = @pCriteriaNo
							and	CHILD.CRITERIANO  = EC.CRITERIANO
							and	PARENT.EVENTNO   <> @pEventNo
							and	PARENT.EVENTNO    = CHILD.EVENTNO
							and	PARENT.DISPLAYSEQUENCE = (
									/* Find the highest DisplaySequence of the	*/
									/* Event that exists in both the Child and the	*/
									/* Parent criteria and falls before the Event	*/
									/* just insered.				*/
									select max(PARENT2.DISPLAYSEQUENCE)
									from	EVENTCONTROL PARENT2,
										EVENTCONTROL CHILD2,
										EVENTCONTROL NEW
									where	PARENT2.CRITERIANO=PARENT.CRITERIANO
									and	CHILD2.CRITERIANO =CHILD.CRITERIANO
									and	NEW.CRITERIANO    =PARENT.CRITERIANO
									and	NEW.EVENTNO	  = @pEventNo
									and	PARENT2.EVENTNO	 <> NEW.EVENTNO
									and	CHILD2.EVENTNO	  = PARENT2.EVENTNO
									and	PARENT2.DISPLAYSEQUENCE<=NEW.DISPLAYSEQUENCE)
			                                    )
						/* When the Event is not the same as the newly Given Event then		*/
						/* increment the DisplaySequence by 1 to make room for the new event.	*/
						else EC.DISPLAYSEQUENCE + 1
			            end
			from	EVENTCONTROL EC									
			join	INHERITS I on I.CRITERIANO = EC.CRITERIANO
			join	#PARENTS P on P.PARENT 	   = I.FROMCRITERIA					
				/* Return the Events within a Criteria whose current position falls on or after the	*/
				/* next position down from the Event that exists in both the Parent and Child criteria	*/
				/* and has the highest DisplaySequence before the newly Given Event.			*/
			where	(EC.DISPLAYSEQUENCE >= (
					select	isnull(max( CHILD.DISPLAYSEQUENCE)+1, 0)
					from	EVENTCONTROL PARENT, 
						EVENTCONTROL CHILD
					where	PARENT.CRITERIANO = @pCriteriaNo
					and	CHILD.CRITERIANO  = EC.CRITERIANO
					and	PARENT.EVENTNO   <> @pEventNo
					and	PARENT.EVENTNO    = CHILD.EVENTNO
					and	PARENT.DISPLAYSEQUENCE = (
						select max(PARENT2.DISPLAYSEQUENCE)
						from	EVENTCONTROL PARENT2,
							EVENTCONTROL CHILD2,
							EVENTCONTROL NEW
						where	PARENT2.CRITERIANO=PARENT.CRITERIANO
						and	CHILD2.CRITERIANO =CHILD.CRITERIANO
						and	NEW.CRITERIANO    =PARENT.CRITERIANO
						and	NEW.EVENTNO	  = @pEventNo
						and	PARENT2.EVENTNO	 <> NEW.EVENTNO
						and	CHILD2.EVENTNO	  = PARENT2.EVENTNO
						and	PARENT2.DISPLAYSEQUENCE<=NEW.DISPLAYSEQUENCE)
			            ) or
				/* The Given Event exists before the designated location */
				EC.EVENTNO = @pEventNo
				)
				/* The only Criteria that are to have their Events shuffled are those	*/
				/* where the newly Given Event has been inherited.			*/
			and	exists (select	* from EVENTCONTROL EC1
					where	EC1.CRITERIANO=EC.CRITERIANO
					and	EC1.EVENTNO=@pEventNo
					and	EC1.INHERITED=1)
		
			select @ErrorCode = @@error	
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

grant execute on dbo.ipr_ArrangeEvntCntrlSeq to public
go
