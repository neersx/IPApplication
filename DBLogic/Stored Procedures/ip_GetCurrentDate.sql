-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_GetCurrentDate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_GetCurrentDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_GetCurrentDate.'
	Drop procedure [dbo].[ip_GetCurrentDate]
End
Print '**** Creating Stored Procedure dbo.ip_GetCurrentDate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_GetCurrentDate
(
	@pdtCurrentDate		datetime	output, 	-- The date requested.
	@pnUserIdentityId	int,            -- Mandatory
	@psDateType		char(1), 	-- Mandatory. 	'A'- Application Date; 'U' - User Date
	@pbIncludeTime		bit		= 0 		-- When set to 1, Application/User Date will include time portion. When set to 0, only date portion of the Application/User Date will be returned.

)
as
-- PROCEDURE:	ip_GetCurrentDate
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	The current date depends on the context of use.  There are possibly 
--		three different perspectives:
-- 		1) User - the current date of the end user
-- 		2) Application - the current date from the perspective of the firm operating the application
-- 		3) Server - the current date on the server on which the application is being run (getdate()).

--		This procedure returns either Application or User date based on the parameters supplied.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10 Oct 2005	TM	RFC3205	1	Procedure created
-- 31 Oct 2018	DL	DR-45102	2	Replace control character (word hyphen) with normal sql editor hyphen

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int

-- Initialise variables
Set @nErrorCode = 0

-- Please note that the current implementation of this stored procedure is a placeholder for future use. 
-- The server date is used for both the Application and User dates.
If @nErrorCode = 0
Begin
	If @pbIncludeTime = 1
	Begin
		Set @pdtCurrentDate = getdate()
	End
	Else Begin
		Set @pdtCurrentDate = convert(datetime,convert(char(10),getdate(),120), 121)
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ip_GetCurrentDate to public
GO
