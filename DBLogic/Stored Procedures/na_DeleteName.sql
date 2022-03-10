-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.na_DeleteName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_DeleteName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_DeleteName.'
	drop procedure [dbo].[na_DeleteName]
	print '**** Creating Stored Procedure dbo.na_DeleteName...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create procedure dbo.na_DeleteName
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psNameKey		varchar(11)	
)
-- PROCEDURE:	na_DeleteName
-- VERSION:	5
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Delete a name

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 11 Nov 2002	JEK	4	Delete Organisation before deleting the name.
-- 15 Apr 2013	DV	5	R13270  Increase the length of nvarchar to 11 when casting or declaring integer
as
begin
		
	-- requires that NameKey exists and maps to NAME.NAMENO.
	declare @nErrorCode int
	declare @nNameNo int

	set @nErrorCode = 0
	if @nErrorCode = 0
	begin
		select @nNameNo = Cast(@psNameKey as int)
		select @nErrorCode = @@Error
	end

	if @nErrorCode = 0
	begin
		-- There are cascade deletes for Individual, Employee and IPName
		-- but not for Organisation.  Delete the organisation, if any, first.

		delete from ORGANISATION where NAMENO = @nNameNo

		select @nErrorCode = @@Error	
	end	
	
	if @nErrorCode = 0
	begin
		delete from TABLEATTRIBUTES 
		where 	PARENTTABLE = 'NAME'
		and	GENERICKEY = @psNameKey

		select @nErrorCode = @@Error
	end
	
	
	if @nErrorCode = 0
	begin
		delete from ASSOCIATEDNAME
		where 	RELATEDNAME = @nNameNo
		or	NAMENO	= @nNameNo
		or 	CONTACT	= @nNameNo

		select @nErrorCode = @@Error
	end

	if @nErrorCode = 0
	begin
		delete from NAME
		where NAMENO = @nNameNo

		select @nErrorCode = @@Error
	end

end
go

grant exec on dbo.na_DeleteName to public
go
