/**********************************************************************************************************/
/*** 6776 Create sp ipr_AddNumberTypeSequence	 	                        			***/
/**********************************************************************************************************/     
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipr_AddNumberTypeSequence]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipr_AddNumberTypeSequence'
		drop procedure dbo.ipr_AddNumberTypeSequence
end
print '**** Creating procedure dbo.ipr_AddNumberTypeSequence...'
print ''
go

Create proc dbo.ipr_AddNumberTypeSequence
as
-- PROCEDURE :	ipr_AddNumberTypeSequence
-- VERSION :	1
-- DESCRIPTION:	  
-- Date			Who		Number		Version	Change
-- ------------	-------	------		-------	----------------------------------------------- 
-- 19 May 2020	DL		DR-58943	1		Ability to enter up to 3 characters for Number type code via client server	

declare @row 		int
declare	@NumberType 	nvarchar(3)
declare	@Description	nvarchar(30)
declare @MsgOutput 	nvarchar(150)

-- Set all NUMBERTYPES which are more important than others.
update 	NUMBERTYPES set DISPLAYPRIORITY = 0, ISSUEDBYIPOFFICE = 1, RELATEDEVENTNO = -8 where NUMBERTYPE = 'R'
update 	NUMBERTYPES set DISPLAYPRIORITY = 1, ISSUEDBYIPOFFICE = 1 where NUMBERTYPE = 'P'
update 	NUMBERTYPES set DISPLAYPRIORITY = 2, ISSUEDBYIPOFFICE = 1, RELATEDEVENTNO = -7 where NUMBERTYPE = 'C'
update 	NUMBERTYPES set DISPLAYPRIORITY = 3, ISSUEDBYIPOFFICE = 1, RELATEDEVENTNO = -4  where NUMBERTYPE = 'A'
update 	NUMBERTYPES set DISPLAYPRIORITY = 4, ISSUEDBYIPOFFICE = 1, RELATEDEVENTNO = -3   where NUMBERTYPE = '0'

-- now set all other NUMBERTYPES, ordered by alpabetical order.
select 	@row = 5
	
declare AddSequenceCursor cursor for
	select	NUMBERTYPE, DESCRIPTION
	from		NUMBERTYPES 
	where	NUMBERTYPE not in ('R', 'P', 'C', 'A', '0')
	order by 	NUMBERTYPE
	open AddSequenceCursor
	fetch AddSequenceCursor into @NumberType, @Description
	while (@@fetch_status = 0)

begin
	update 	NUMBERTYPES 
	set 		DISPLAYPRIORITY = @row
	where	NUMBERTYPE = @NumberType
		set 	@row = @row + 1		

	select  	@MsgOutput = 'NUMBERTYPE for ' + @Description + ' has display priority of ' 
	select 	@MsgOutput = @MsgOutput + convert(nvarchar(2), @row)
	print		@MsgOutput
	
	fetch next from AddSequenceCursor into @NumberType, @Description
end

deallocate AddSequenceCursor 
go

grant execute on dbo.ipr_AddNumberTypeSequence to public
go
