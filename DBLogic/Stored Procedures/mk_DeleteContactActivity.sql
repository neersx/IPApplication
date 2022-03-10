-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mk_DeleteContactActivity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.mk_DeleteContactActivity.'
	Drop procedure [dbo].[mk_DeleteContactActivity]
End
Print '**** Creating Stored Procedure dbo.mk_DeleteContactActivity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.mk_DeleteContactActivity
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnActivityKey		int,		-- Mandatory		
	@pdtLogDateTimeStamp	datetime	= null
)
-- PROCEDURE:	mk_DeleteContactActivity
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete a Contact Activity if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 15 Feb 2005  TM	RFC1743	1	Procedure created.
-- 23 Feb 2005	TM 	RFC1743	2	If Activity.LongFlag is null use Activity.Notes column. 
-- 31 May 2006	SW	RFC2985	3	Implement new column ClientReference
-- 10 Oct 2014	DV	R26412	4	Use LogDateTimeStamp for concurency check
-- 27 May 2015  MS      R47576  5       Increased size of @psOldSummary from 100 to 254
AS

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON


Declare @nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

-- Update the Activity
If @nErrorCode = 0
Begin
	Set @sSQLString = "	
	Delete
	from    ACTIVITY 
	where   ACTIVITYNO		= @pnActivityKey
	and	(LOGDATETIMESTAMP	= @pdtLogDateTimeStamp or @pdtLogDateTimeStamp is null)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnActivityKey	int,
					  @pdtLogDateTimeStamp	datetime',					  
					  @pnActivityKey	= @pnActivityKey,
					  @pdtLogDateTimeStamp	= @pdtLogDateTimeStamp					 
End


Return @nErrorCode
GO

Grant execute on dbo.mk_DeleteContactActivity to public
GO

