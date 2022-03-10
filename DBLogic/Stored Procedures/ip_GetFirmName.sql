---------------------------------------------------------------------------------------------
-- Creation of dbo.ip_GetFirmName
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_GetFirmName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_GetFirmName.'
	drop procedure [dbo].[ip_GetFirmName]
	Print '**** Creating Stored Procedure dbo.ip_GetFirmName...'
	Print ''
End
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ip_GetFirmName
(
    @pnUserIdentityId		int 		= null,
    @psCulture			nvarchar(10) 	= null,   
    @pbCalledFromCentura	bit		= 0
)    
AS
-- PROCEDURE :	ip_GetFirmName
-- VERSION :	3
-- DESCRIPTION:	A procedure to return the name of the firm that is operating the product 
-- MODIFICATIONS :
-- Date  	Who 	RFC 	Version Change
-- ------------ ------- ---- 	------- ----------------------------------------------- 
-- 29 Apr 2005  TM  	RFC2554	1	Procedure created
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 02 Nov 2015	vql	R53910	3	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare		@nErrorCode		int
Declare 	@sSQLString		nvarchar(4000)

-- Initialise the variables
Set @nErrorCode   = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "	
	Select dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
	from SITECONTROL SC
	join NAME N	on (N.NAMENO = SC.COLINTEGER)
	where CONTROLID = 'HOMENAMENO'"

	exec @nErrorCode = sp_executesql @sSQLString
End	

Return @nErrorCode
GO

Grant execute on dbo.ip_GetFirmName to public
GO

