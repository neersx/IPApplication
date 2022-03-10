-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_SystemUser
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_SystemUser') and xtype='FN')
Begin
	print '**** Drop function dbo.fn_SystemUser.'
	drop function dbo.fn_SystemUser
	print '**** Creating function dbo.fn_SystemUser...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_SystemUser()
RETURNS nvarchar(255)
   
-- FUNCTION :	fn_SystemUser
-- VERSION :	1
-- DESCRIPTION:	This function returns the current System User.  If Windows Authentication is in use
--		then the DOMAIN\ will be stripped out so as to just return the SQLServer login 
--		identification name.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 15 Nov 2004	MF	SQA10659 1	Function created
AS
Begin

declare @sUser	nvarchar(255)

set @sUser = SYSTEM_USER 

if charindex ('\',@sUser)>0
   set @sUser = substring (@sUser, charindex ('\',@sUser)+1, 255)

	
Return @sUser
End
GO

Grant execute on dbo.fn_SystemUser to public
GO
