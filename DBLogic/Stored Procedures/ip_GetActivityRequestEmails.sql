-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_GetActivityRequestEmails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_GetActivityRequestEmails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_GetActivityRequestEmails.'
	Drop procedure [dbo].[ip_GetActivityRequestEmails]
	Print '**** Creating Stored Procedure dbo.ip_GetActivityRequestEmails...'
	Print ''
End
go

SET QUOTED_IDENTIFIER off
go

create procedure dbo.ip_GetActivityRequestEmails
(
	@pnUserIdentityId	int,
	@psCulture		nvarchar(10)	= null,
	@pnCaseId		int,				-- Mandatory
	@pdtWhenRequested	datetime	= null,
	@psSqlUser		nvarchar(40)	= null,	
	@pbCalledFromCTD	tinyint		= 1,
	@pnActivityId		int		= null,		-- Alternative key for ACTIVITYREQUEST row
	@psRecipients		nvarchar(1000)	= null output,
	@psCCRecipients		nvarchar(1000)	= null output
)
as
-- PROCEDURE :	ip_GetActivityRequestEmails
-- VERSION :	6
-- DESCRIPTION:	Collect all email address re this Activity Request row.  
-- CALLED BY :	Document Generator
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20/08/2002	SF			Procedure created
-- 21/08/2002	SF 			Add a few more parameters to be called by CTD.
-- 21/08/2002	SF			use min instead of top 1 and order by for performance reasons.
-- 13 Jan 2009	MF	17291	4	@psSqlUser parameter to the ip_GetActivityRequestEmails stored procedure too short
-- 10 Jul 2009	MF	17861	5	AcitivityRequest table now has a unique key on ACTIVITYID. Allow procedure to accept
--					a new paramter of @pnActivityId to identify the explicit ACTIVITYREQUEST row. Also 
--					restructure the code to make it run faster.
-- 18 Nov 2009	DL	18179	6	Reorder input parameters to be in synch with client server module.
--					NOTE: new input param must be inserted before the output params.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @nErrorCode		int
declare @nLetterNo		int
declare @sEmailAddress		nvarchar(1000)
declare @sCurrEmailAddress	nvarchar(1000)

set @nErrorCode	    = 0
set @psRecipients   = null
set @psCCRecipients = null


--------------------------------------------------
-- D A T A   V A L I D A T I O N
-- Validate the input parameters proceeding
--------------------------------------------------

--------------------
-- Validate CaseType
--------------------
If @nErrorCode = 0
Begin
	If  @pnActivityId     is null
	and @psSqlUser        is null
	and @pdtWhenRequested is null
	Begin
		RAISERROR('@pnActivityId or @psSqlUser and @pdtWhenRequested must be provided to identify ACTIVITYREQUEST row', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

if @nErrorCode =0
begin	
	-- if there is an overriding email address recorded against the Activity Request row,
	-- return this and stop processing.
	
	If @pnActivityId is not null
		select 	@psRecipients = EMAILOVERRIDE,
			@nLetterNo = isnull(ALTERNATELETTER, LETTERNO)
		from 	ACTIVITYREQUEST
		where	ACTIVITYID = @pnActivityId
	Else
		select 	@psRecipients = EMAILOVERRIDE,
			@nLetterNo = isnull(ALTERNATELETTER, LETTERNO)
		from 	ACTIVITYREQUEST
		where	CASEID = @pnCaseId
		and	SQLUSER = @psSqlUser
		and	WHENREQUESTED = @pdtWhenRequested		
	
	set @nErrorCode = @@error
end

if @psRecipients is null
and @nLetterNo   is not null
and @nErrorCode  = 0
begin
	-- overriding email address is not present
	-- using the default method, get email from nametypes specified 
	-- by the correspondent type of this letter

	select 	@psRecipients = isnull(@psRecipients,'')+CASE WHEN(@psRecipients is NOT NULL) THEN ";" ELSE '' END+EMAIL.TELECOMNUMBER
	from (  select distinct T.TELECOMNUMBER
		from	LETTER L
		join	CORRESPONDTO C 		on (C.CORRESPONDTYPE = L.CORRESPONDTYPE)
		join	CASENAME CN 		on (CN.NAMETYPE = C.NAMETYPE
						and CN.CASEID = @pnCaseId)
		join	NAMETELECOM NT 		on (CN.NAMENO = NT.NAMENO)
		join	TELECOMMUNICATION T 	on (T.TELECODE = NT.TELECODE
						and T.TELECOMTYPE = 1903)
		where	L.LETTERNO = @nLetterNo) EMAIL
		
	set @nErrorCode=@@Error
	
	If @nErrorCode=0
	Begin
		----------------------------------
		-- Now get the a concatenated list
		-- of Copy To email address
		----------------------------------
		select 	@psCCRecipients = isnull(@psCCRecipients,'')+CASE WHEN(@psCCRecipients is NOT NULL) THEN ";" ELSE '' END+EMAIL.TELECOMNUMBER
		from (  select distinct T.TELECOMNUMBER
			from	LETTER L
			join	CORRESPONDTO C 		on (C.CORRESPONDTYPE = L.CORRESPONDTYPE)
			join	CASENAME CN 		on (CN.NAMETYPE = C.COPIESTO
							and CN.CASEID = @pnCaseId)
			join	NAMETELECOM NT 		on (CN.NAMENO = NT.NAMENO)
			join	TELECOMMUNICATION T 	on (T.TELECODE = NT.TELECODE
							and T.TELECOMTYPE = 1903)
			where	L.LETTERNO = @nLetterNo) EMAIL
		
		set @nErrorCode=@@Error
	End
end

-------------------------------------------
--  Centura expects outputs in result sets.
-------------------------------------------
if @pbCalledFromCTD = 1
Begin
	select 	@psRecipients, 
		@psCCRecipients,
		@nErrorCode
End

return @nErrorCode
go

grant execute on dbo.ip_GetActivityRequestEmails to public
go
