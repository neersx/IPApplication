-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.na_DeleteTelecommunication
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_DeleteTelecommunication]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_DeleteTelecommunication.'
	drop procedure [dbo].[na_DeleteTelecommunication]
	print '**** Creating Stored Procedure dbo.na_DeleteTelecommunication...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create   procedure dbo.na_DeleteTelecommunication
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psNameKey		varchar(11) = null,	
	@pnTelecomTypeId	int = null, 		
	@psTelecomKey		varchar(11) = null	
)
-- VERSION:	6
-- DESCRIPTION:	Delete a Telecommunication row of a Name
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 15 Nov 2002 	SF		4	Update Version Number
-- 25 Feb 2004	TM	RFC867	5	Implement logic similar to one that deletes MainPhone and Fax to handle 
--					the deletion of the MainEmail (@pnTelecomTypeId = 3).
-- 15 Apr 2013	DV	R13270	6	Increase the length of nvarchar to 11 when casting or declaring integer
as
begin
			
	/* Update Name Row  
		      Phone = 1 (Phone	Device Type 	= 1901)
		      Fax   = 2	(Fax Device Type	= 1902)
		      Email = 3 (Email Device Type	= 1903)

	*/

	-- requires that NameKey exists and maps to NAME.NAMENO.
	declare @nErrorCode int
	declare @nNameNo int
	declare @nTelecode int

	set @nErrorCode = 0

	if @pnTelecomTypeId is null
	begin
		/* do not know which type to delete */
		set @nErrorCode = -1
	end

	if @nErrorCode = 0
	begin
		select @nNameNo = Cast(@psNameKey as int)
		select @nErrorCode = @@Error
	end
	if @nErrorCode = 0
	begin
		select @nTelecode = Cast(@psTelecomKey as int)
		select @nErrorCode = @@Error
	end

	/* assumes the telecomtypeid is valid */
	if @pnTelecomTypeId = 1 and @nErrorCode = 0
	begin
		/* remove telecom reference from NAME.MAINPHONE */
		update	NAME		
		   set	MAINPHONE = null
		 where	NAMENO = @nNameNo
		   and	MAINPHONE = @nTelecode
			
		select @nErrorCode = @@Error			
	end
			
	if @pnTelecomTypeId = 2 and @nErrorCode = 0
	begin		
		/* remove telecom reference from NAME.FAX */
		update	NAME		
		   set	FAX = null
		 where	NAMENO = @nNameNo
		   and	FAX = @nTelecode
			
		select @nErrorCode = @@Error				
	end

	if @pnTelecomTypeId = 3 and @nErrorCode = 0
	begin		
		/* remove telecom reference from NAME.MAINEMAIL */
		update	NAME		
		   set	MAINEMAIL = null
		 where	NAMENO = @nNameNo
		   and	MAINEMAIL = @nTelecode
			
		select @nErrorCode = @@Error				
	end
		
	if exists (select 	*  
			from 	NAME  
			where 	NAMENO = @nNameNo
			and 	(MAINPHONE = @nTelecode  
			or	FAX = @nTelecode
			or	MAINEMAIL = @nTelecode))
	begin
		select @nErrorCode = -1
	end

	if @nErrorCode = 0
	begin
		/* remove telecom reference from NAME.MAINPHONE */
		delete  
		from 	NAMETELECOM
		where 	NAMENO = @nNameNo
		and	TELECODE = @nTelecode
		/* owned by ? */
			
		select @nErrorCode = @@Error		
	end
		
	if @nErrorCode = 0 and  
		not exists (Select	*
				from	NAMETELECOM
				where	TELECODE = @nTelecode)
	begin
		delete  
		from 	TELECOMMUNICATION
		where	TELECODE = @nTelecode
			
		select @nErrorCode = @@Error					
	end

	return @nErrorCode
end
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.na_DeleteTelecommunication to public
go
