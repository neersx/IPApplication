-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GenerateActivityRequest
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GenerateActivityRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	Print '**** Drop Stored Procedure dbo.cs_GenerateActivityRequest.'
	Drop procedure [dbo].[cs_GenerateActivityRequest]
end
Print '**** Creating Stored Procedure dbo.cs_GenerateActivityRequest...'
Print ''
GO


SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE PROCEDURE dbo.cs_GenerateActivityRequest
(
	@pnUserIdentityId	int = null,	--Mandatory if @pnDocumentRequestKey is provided
	@pnDocumentRequestKey	int = null
)
AS
-- PROCEDURE :	cs_GenerateActivityRequest
-- VERSION :	11
-- DESCRIPTION:	Generate ACTIVITYREQUEST rows based on user defined document requests
-- COPYRIGHT: 	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
--
-- MODIFICATIONS :
-- Date		Who	SQA#		Version	Change
-- ------------	-------	-----		-------	----------------------------------------------- 
-- 03/12/2006	DL	12331		1	Procedure created
-- 04/04/2007	PG	RFC3646		2	Added support for creating ad hoc requests
-- 30/04/2007  	DL			3	Fixed syntax error.
-- 17/05/2007  	PG	RFC3646		4	Fixed syntax error.
-- 22/05/2007	DL	12331		5	Update the last generated date after requests are generated.
-- 11/08/2009	DL	SQA17939	6	Monthly frequency for document requests not working correctly.
-- 17/08/2009	vql	SQA17939	7	Monthly frequency for document requests not working correctly (fix).
-- 04/02/2010	DL	SQA18430	8	Grant stored procedure to public
-- 30/06/2010	DL	SQA17957	9	Fixed bug - Monthly frequency for document requests not working correctly if DAYOFMONTH is empty
-- 19/08/2011   DV      RFC11069        10      Insert IDENTITYID value in ACTIVITYREQUEST table
-- 28 Mar 2017	MF	71038		11	Parameter @pnUserIdentityId not being passed to sp_executesql.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF


Declare	@nErrorCode 		int,
	@sSQLString		nvarchar(1000),
	@TranCountStart		int,
	@dtCurrentDate		datetime

set @nErrorCode = 0


Select @TranCountStart = @@TranCount
BEGIN TRANSACTION


If @pnDocumentRequestKey is null
	Begin
		-- Get the current date ignoring time
		Select @dtCurrentDate = cast(convert(nvarchar(8), getdate(), 112) as datetime) 

		-- Generate ACTIVITYREQUEST rows
		Set @sSQLString = "
		Insert into ACTIVITYREQUEST (WHENREQUESTED, SQLUSER, PROGRAMID, LETTERNO, HOLDFLAG,
		LETTERDATE, DELIVERYID, ACTIVITYTYPE, ACTIVITYCODE, REQUESTID, IDENTITYID)
		Select getdate(), 'SYSADM', 'DocReq', 
		DD.LETTERNO, 0, getdate(), L.DELIVERYID, 32, 3204, DR.REQUESTID, @pnUserIdentityId  
		from DOCUMENTREQUEST DR
		join DOCUMENTDEFINITION DD on (DD.DOCUMENTDEFID = DR.DOCUMENTDEFID)
		join LETTER L on (L.LETTERNO = DD.LETTERNO)
		where (DR.NEXTGENERATE <= @dtCurrentDate or DR.NEXTGENERATE is null)
		and (DR.STOPON > @dtCurrentDate OR DR.STOPON IS NULL)
		and (DR.LASTGENERATED < @dtCurrentDate or DR.LASTGENERATED is null)
		"
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@dtCurrentDate	datetime,
			@pnUserIdentityId       int',
			@dtCurrentDate		= @dtCurrentDate,
			@pnUserIdentityId	= @pnUserIdentityId
	

		-- Update next/last/stop generate date
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			Update 	 DOCUMENTREQUEST 
			set NEXTGENERATE =
				(CASE when PERIODTYPE = 'D' then dateadd( day, isnull(FREQUENCY, 1), NEXTGENERATE)
				      when PERIODTYPE = 'W' then dateadd( week, isnull(FREQUENCY, 1), NEXTGENERATE) 
				      when PERIODTYPE = 'M' then dbo.fn_GetNextGenerateDate(NEXTGENERATE, DAYOFMONTH, FREQUENCY)
				      when PERIODTYPE = 'Y' then dateadd( year, isnull(FREQUENCY, 1), NEXTGENERATE)
				      else NEXTGENERATE
				END),
				STOPON = case when (FREQUENCY is null and PERIODTYPE is null ) then @dtCurrentDate else STOPON end
			where ( NEXTGENERATE <= @dtCurrentDate or NEXTGENERATE is null)
			and (STOPON > @dtCurrentDate OR STOPON IS NULL)
			and (LASTGENERATED < @dtCurrentDate or LASTGENERATED is null)
			"
			exec @nErrorCode=sp_executesql @sSQLString,
				N'@dtCurrentDate	datetime,
				@pnUserIdentityId       int',
				@dtCurrentDate		= @dtCurrentDate,
				@pnUserIdentityId	= @pnUserIdentityId
		End


End
Else
Begin
	Set @sSQLString = "
		Insert into ACTIVITYREQUEST (WHENREQUESTED, SQLUSER, PROGRAMID, LETTERNO, HOLDFLAG,
		LETTERDATE, DELIVERYID, ACTIVITYTYPE, ACTIVITYCODE, REQUESTID,IDENTITYID)
		Select getdate(), USER, 'DocReq', 
		DD.LETTERNO, 0, getdate(), L.DELIVERYID, 32, 3204, REQUESTID, @pnUserIdentityId 
		from DOCUMENTREQUEST DR
		join DOCUMENTDEFINITION DD on (DD.DOCUMENTDEFID = DR.DOCUMENTDEFID)
		join LETTER L on (L.LETTERNO = DD.LETTERNO)
		where DR.REQUESTID = @pnDocumentRequestKey"
	
		exec @nErrorCode=sp_executesql @sSQLString, 					      
						N'@pnUserIdentityId	int,
						@pnDocumentRequestKey	int',
						@pnDocumentRequestKey 	= @pnDocumentRequestKey,
						@pnUserIdentityId	= @pnUserIdentityId

End


-- Commit the transaction if it has successfully completed
If @@TranCount > @TranCountStart
Begin
	If @nErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End


RETURN @nErrorCode

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

Grant execute on dbo.cs_GenerateActivityRequest to public
GO
