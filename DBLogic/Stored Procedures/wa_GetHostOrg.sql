-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_GetHostOrg
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_GetHostOrg]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_GetHostOrg'
	drop procedure [dbo].[wa_GetHostOrg]
	print '**** Creating procedure dbo.wa_GetHostOrg...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_GetHostOrg] 
	@psName varchar(254) OUTPUT

-- PROCEDURE :	wa_GetHostOrg
-- VERSION :	2.2.0
-- DESCRIPTION:	Gets the name of the host organisation
--				returning the result in an output parameter
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 01/07/2001	AF	Procedure created
-- 03/08/2001	MF	Correct the variable name

as
set nocount on
Select @psName= NAME 
	 	FROM	NAME
	 	WHERE	NAMENO	= (SELECT COLINTEGER FROM SITECONTROL WHERE CONTROLID = 'HOMENAMENO')
return 0
go

grant execute on [dbo].[wa_GetHostOrg] to public
go
