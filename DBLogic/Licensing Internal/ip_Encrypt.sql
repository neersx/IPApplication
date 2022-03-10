-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_Encrypt
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_Encrypt]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	 Print '**** Drop Stored Procedure dbo.ip_Encrypt.'
	 Drop procedure [dbo].[ip_Encrypt]
End
Print '**** Creating Stored Procedure dbo.ip_Encrypt...'
Print ''
go

CREATE PROCEDURE dbo.ip_Encrypt
(
	-- Standard parameters
	@pnUserIdentityId		int,
	@psCulture			nvarchar(10) 	= null,

	@psClearText 			varchar(268),	-- note that this is a varchar(268) instead of a nvarchar(286)
							-- this is because when a string greater than 254 character comes in
							-- from Centura the text is sometimes corrupted if the defined param
							-- is nvarchar.
	@pnReturnTextLength 		smallint	= 268
)
With encryption
AS
-- PROCEDURE :	ip_Encrypt
-- VERSION :	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns an Encrypted string
-- NOTES:	SP to call the fn_Encrypt function as the return value was getting corrupted
--		in Centura when returned from a function.

--
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 24/05/2006	vql	11588	1	Procedure created
-- 05/02/2010	DL	18430	2	Grant stored procedure to public


Set concat_null_yields_null off

Declare @nErrorCode		int

Set @nErrorCode			= 0

If @nErrorCode = 0 
Begin
	Select dbo.fn_Encrypt(@psClearText,@pnReturnTextLength)
End
GO

Grant execute on dbo.ip_Encrypt to public
GO
