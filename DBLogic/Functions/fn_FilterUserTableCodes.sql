-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FilterUserTableCodes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_FilterUserTableCodes') and xtype='IF')
begin
	print '**** Drop function dbo.fn_FilterUserTableCodes.'
	drop function dbo.fn_FilterUserTableCodes
	print '**** Creating function dbo.fn_FilterUserTableCodes...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_FilterUserTableCodes
(
	@pnUserIdentityId		int,
	@pnTableTypeKey 		int,
	@psSiteControlKey 		nvarchar(30),
	@pbCalledFromCentura		bit
)
RETURNS TABLE
AS

-- FUNCTION :	fn_FilterUserTableCodes
-- VERSION :	1
-- DESCRIPTION:	This is a new function to filter a table list for use by external users.  

-- MODIFICATION
-- Date		Who	No.	Version	Description
-- ====         ===	=== 	=======	===========
-- 11 May 2006	SW	RFC2985	1	Function created

RETURN

	Select	T.TABLECODE		as TABLECODE
	from	TABLECODES T
	join	SITECONTROL S on upper(S.CONTROLID)=upper(@psSiteControlKey)
	where	TABLETYPE = @pnTableTypeKey
	and	patindex('%'+','+cast(T.TABLECODE as nvarchar(50))+','+'%',',' + replace(S.COLCHARACTER, ' ', '') + ',')>0
GO

grant REFERENCES, SELECT on dbo.fn_FilterUserTableCodes to public
GO
