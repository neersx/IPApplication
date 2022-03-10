-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_GetUserType
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_GetUserType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_GetUserType'
	drop procedure [dbo].[wa_GetUserType]
	print '**** Creating procedure dbo.wa_GetUserType...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_GetUserType] 
	@pnType int OUTPUT
AS
-- PROCEDURE :	wa_GetUserType
-- VERSION :	2.2.0
-- DESCRIPTION:	Gets the type of user for the current connection
--				i.e. internal (staff) or external (client).
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 01/07/2001	AF	Procedure created	

set nocount on
	select @pnType = isnull(EXTERNALUSERFLAG, 0) from USERS
							where USERID = user
return 0
go

grant execute on [dbo].[wa_GetUserType] to public
go
