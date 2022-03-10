-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipr_MailingLabel
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipr_MailingLabel]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipr_MailingLabel.'
	drop procedure dbo.ipr_MailingLabel
	print '**** Creating procedure dbo.ipr_MailingLabel...'
	print ''
end
go

create procedure dbo.ipr_MailingLabel
	@pnNameNo int,
	@psOverridingRelationship varchar(3) = NULL

as
-- PROCEDURE :	ipr_MailingLabel
-- VERSION :	2.1.0
-- DESCRIPTION:	Format the Name, Attention and Postal Address into  a single string separated by Carriage Returns for the supplied NameNo.
-- 		Will use the base name attributes unless an overriding relationship is provided.  This is an AssociatedName relationship 
-- 		such as Billing address or Statement address.  If provided, the routine will use any attention or postal address on the 
-- 		associated name in preference to the base name information.
-- CALLED BY :	
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17/03/2004	abell			Modify syntax on grant statement

DECLARE @sMailingLabel varchar(254)

EXEC ipo_MailingLabel 	@pnNameNo = @pnNameNo, 
			@psOverridingRelationship = @psOverridingRelationship,
			@prsLabel = @sMailingLabel OUTPUT

-- publish the result so that it is accessible to FCDB classes
select @sMailingLabel

Return 0
go

grant execute on dbo.ipr_MailingLabel to public
go
