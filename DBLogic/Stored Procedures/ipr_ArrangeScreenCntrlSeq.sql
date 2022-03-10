-----------------------------------------------------------------------------------------------------------------------------
--  Creation of ipr_ArrangeScreenCntrlSeq
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipr_ArrangeScreenCntrlSeq]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipr_ArrangeScreenCntrlSeq.'
	drop procedure dbo.ipr_ArrangeScreenCntrlSeq
	print '**** Creating procedure dbo.ipr_ArrangeScreenCntrlSeq...'
	print ''
end
go

create procedure dbo.ipr_ArrangeScreenCntrlSeq 
	@pCriteriaNo	int,
	@pScreenName	varchar(32),
	@pScreenId	int,
	@pReturnCode	int OUTPUT
as
-- PROCEDURE 	: 
-- VERSION 	: 
-- DESCRIPTION	: Given the Criteriano ScreenID and ScreenName, the procedure arranges all instances of  
-- 		  the same screen inherited in the descendent criteria to one below the 
--		  closest screen in the given criteria before the given screen that exists 
--		  in both the given criteria and the descendent criteria. 
-- CALLED BY 	: 
-- MODIFICATIONS:
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13/12/2000	SF

	declare @ErrorCode int
	
	if @pCriteriaNo is NULL
		return -100

	if @pScreenName is NULL
		return -100

	if @pScreenId is NULL
		return -100

	if not exists( select * from CRITERIA where CRITERIANO = @pCriteriaNo )
		/* the given CRITERIANO does not exist in the CRITERIA table */
		return -100

	if not exists( select * from SCREENCONTROL where CRITERIANO = @pCriteriaNo and SCREENNAME = @pScreenName and SCREENID = @pScreenId )
		/* the given CRITERIANO and SCREENID, SCREENNAME do not exist in the SCREENCONTROL table */
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
				join	SCREENCONTROL SC on (SC.CRITERIANO=I1.CRITERIANO)
				where 	SC.SCREENNAME = @pScreenName
				and	SC.SCREENID = @pScreenId
				and not exists
					(select * from #PARENTS P2
					 where P2.PARENT=I1.CRITERIANO)
			 end
			/* must find out if the above have caused any errors */
			select @ErrorCode = @@Error
		end
	
		if @ErrorCode = 0
		begin
	
			update	SCREENCONTROL
			set	DISPLAYSEQUENCE = 
		            case   SCREENNAME 
				/* When the Screen being updated is equal to the Given Screen 		*/
				/* set the DISPLAYSEQUENCE to the position after the Screen that exists	*/
				/* immediately before the Given Screen in the Parent criteria and	*/
				/* also exists in the Child criteria.					*/
	                        when  @pScreenName 
					/* Note that if no Screen exists in the Child criteria that also exists	*/
					/* before the inserted Screen in the Parent criteria then the given Screen*/
					/* will be positioned at the top of the list with DisplaySequence=0.	*/
					then case SCREENID
						when @pScreenId					
			         		then (	select isnull(max( CHILD.DISPLAYSEQUENCE )+1,0)
							from	SCREENCONTROL PARENT,
								SCREENCONTROL CHILD
							where	PARENT.CRITERIANO = @pCriteriaNo
							and	CHILD.CRITERIANO  = SC.CRITERIANO
							and	not ( PARENT.SCREENID = @pScreenId     and PARENT.SCREENNAME = @pScreenName)
							and	    ( PARENT.SCREENID = CHILD.SCREENID and PARENT.SCREENNAME = CHILD.SCREENNAME)
							and	PARENT.DISPLAYSEQUENCE = (
									/* Find the highest DisplaySequence of the	*/
									/* Screen that exists in both the Child and the	*/
									/* Parent criteria and falls before the Given 	*/
									/* Screen.					*/
									select max(PARENT2.DISPLAYSEQUENCE)
									from	SCREENCONTROL PARENT2,
										SCREENCONTROL CHILD2,
										SCREENCONTROL NEW
									where	PARENT2.CRITERIANO=PARENT.CRITERIANO
									and	CHILD2.CRITERIANO =CHILD.CRITERIANO
									and	NEW.CRITERIANO    =PARENT.CRITERIANO
									and	    ( NEW.SCREENID     = @pScreenId       and NEW.SCREENNAME = @pScreenName)
									and	not ( PARENT2.SCREENID = NEW.SCREENID    and PARENT2.SCREENNAME = NEW.SCREENNAME)
									and	    ( CHILD2.SCREENID  = PARENT2.SCREENID and CHILD2.SCREENNAME = PARENT2.SCREENNAME)
									and	PARENT2.DISPLAYSEQUENCE<=NEW.DISPLAYSEQUENCE)
			                                    )
					     else
						SC.DISPLAYSEQUENCE + 1
					     end
						/* When the Screen is not the same as the Given Screen then		*/
						/* increment the DisplaySequence by 1 to make room for the given screen.*/
					else SC.DISPLAYSEQUENCE + 1
			end
			from	SCREENCONTROL SC
			join	INHERITS I on I.CRITERIANO = SC.CRITERIANO
			join	#PARENTS P on P.PARENT 	   = I.FROMCRITERIA
				/* Return the Screen within a Criteria whose current position falls on or after the	*/
				/* next position down from the Screen that exists in both the Parent and Child criteria	*/
				/* and has the highest DisplaySequence before the Given Screen.				*/
			where	(SC.DISPLAYSEQUENCE >= (
					select	isnull(max( CHILD.DISPLAYSEQUENCE)+1, 0)
					from	SCREENCONTROL PARENT, 
						SCREENCONTROL CHILD
					where	PARENT.CRITERIANO = @pCriteriaNo
					and	CHILD.CRITERIANO  = SC.CRITERIANO
					and	not ( PARENT.SCREENID = @pScreenId       and PARENT.SCREENNAME = @pScreenName)
					and	    ( PARENT.SCREENID   = CHILD.SCREENID and PARENT.SCREENNAME = CHILD.SCREENNAME)
					and	PARENT.DISPLAYSEQUENCE = (
						select max(PARENT2.DISPLAYSEQUENCE)
						from	SCREENCONTROL PARENT2,
							SCREENCONTROL CHILD2,
							SCREENCONTROL NEW
						where	PARENT2.CRITERIANO=PARENT.CRITERIANO
						and	CHILD2.CRITERIANO =CHILD.CRITERIANO
						and	NEW.CRITERIANO    =PARENT.CRITERIANO
						and	    ( NEW.SCREENID     = @pScreenId       and NEW.SCREENNAME = @pScreenName )
						and	not ( PARENT2.SCREENID = NEW.SCREENID     and PARENT2.SCREENNAME = NEW.SCREENNAME)
						and	    ( CHILD2.SCREENID  = PARENT2.SCREENID and CHILD2.SCREENNAME = PARENT2.SCREENNAME)
						and	PARENT2.DISPLAYSEQUENCE<=NEW.DISPLAYSEQUENCE)
			            ) or
				/* The Given Screen exists before the designated location */
				( 	SC.SCREENNAME 	= @pScreenName and SC.SCREENID	= @pScreenId )	
				)
				/* The only Criteria that are to have their Screens shuffled are those	*/
				/* where the Given Screen has been inherited.				*/
			and	exists (select	* from SCREENCONTROL SC1
					where	SC1.CRITERIANO=SC.CRITERIANO
					and	SC1.SCREENNAME=@pScreenName
					and	SC1.SCREENID=@pScreenId
					and	SC1.INHERITED=1)
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

grant execute on dbo.ipr_ArrangeScreenCntrlSeq to public
go
