-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListNameTypes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListNameTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListNameTypes'
	drop procedure [dbo].[wa_ListNameTypes]
	print '**** Creating procedure dbo.wa_ListNameTypes...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListNameTypes]
AS
-- PROCEDURE :	wa_ListNameTypes
-- VERSION :	2
-- DESCRIPTION:	Returns a list of NameTypes that the currently connected user is allowed to see.
--				If the currently connected user is external then the list is filtered by
--				a list of types set as a Site Control
--				
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01/07/2001	A		1	Procedure created
-- 15 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	

	-- set server options
	set NOCOUNT on

	-- declare variables
	declare	@ErrorCode	int

	-- initialise variables
	set @ErrorCode=0

	SELECT	T.NAMETYPE, T.DESCRIPTION
	FROM	NAMETYPE T
	left 	join SITECONTROL S	on (S.CONTROLID='Client Name Types')
	     	join USERS U	on (U.USERID=user)
	where 	(U.EXTERNALUSERFLAG>1
	and  	patindex('%' + T.NAMETYPE + '%', S.COLCHARACTER)>0)
	or    	(U.EXTERNALUSERFLAG<2 or U.EXTERNALUSERFLAG is NULL)
	ORDER BY T.DESCRIPTION

	Select @ErrorCode=@@Error

	return @ErrorCode
go

grant execute on [dbo].[wa_ListNameTypes] to public
go
