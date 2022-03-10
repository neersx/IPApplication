SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_InsertAlert]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_InsertAlert.'
	Drop procedure [dbo].[ip_InsertAlert]
End
Print '**** Creating Stored Procedure dbo.ip_InsertAlert...'
Print ''
GO

CREATE PROCEDURE dbo.ip_InsertAlert
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnEmployeeKey		int		= null,
	@pnCaseKey		int		= null,
	@psAlertMessage		nvarchar(1000)	= null,
	@pdtDueDate		datetime	= null,
	@pdtDateOccurred	datetime	= null

)
-- PROCEDURE:	ip_InsertAlert
-- VERSION:	3
-- SCOPE:	CPA.net
-- DESCRIPTION:	Create a new Alert.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 27-MAR-2003  JEK	1	RFC03	Procedure created.
-- 14-May-2003	JEK	2	RFC154	Ensure that date/time in key is unique.
-- 11 Dec 2008	MF	3	17136	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 18 Jul 2011	LP	4	RFC10992 Increase @psAlertMessage parameter to 1000 characters.

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @nEmployeeKey int
Declare @nSequenceNo int
Declare @dtAlertSeq datetime

Set @nErrorCode = 0

If @nErrorCode = 0
and (@pdtDueDate is not null)
Begin
	If @pnEmployeeKey is null	-- Used as an ad hoc event rather than a reminder
	Begin
		Select 	@nEmployeeKey = COLINTEGER
		from	SITECONTROL
		where	CONTROLID = 'HOMENAMENO'

		Set @nErrorCode = @@ERROR
	End
	Else
	Begin
		Set @nEmployeeKey = @pnEmployeeKey
	End

	if @nErrorCode = 0
	begin
		select 	@nSequenceNo = isnull(SEQUENCENO+1, 0)
		from 	ALERT 
		where	EMPLOYEENO = @nEmployeeKey

		set @nErrorCode = @@error
	end

	-- Since DateTime is part of the key it is possible to
	-- get a duplicate key.  Keep trying until a unique DateTime
	-- is extracted.
	set @dtAlertSeq = getdate()

	While exists
		(Select 1 from ALERT
		where	EMPLOYEENO = @nEmployeeKey
		and	ALERTSEQ = @dtAlertSeq)
	Begin
		-- millisecond are held to equivalent to 3.33, so need to add 3
		Set @dtAlertSeq = DateAdd(millisecond,3,@dtAlertSeq)
		print convert(nvarchar(25), @dtAlertSeq, 121)
	End

	if @nErrorCode = 0
	begin
		insert into ALERT (
			EMPLOYEENO,
			ALERTSEQ,
			CASEID,
			ALERTMESSAGE,
			ALERTDATE,
			DUEDATE,			
			DATEOCCURRED,
			OCCURREDFLAG,
			DAILYFREQUENCY,
			DAYSLEAD,
			SEQUENCENO,
			SENDELECTRONICALLY
			)
		values (
			@nEmployeeKey,
			@dtAlertSeq,
			@pnCaseKey,
			@psAlertMessage,
			@pdtDueDate,
			@pdtDueDate,
			@pdtDateOccurred,
			case when @pdtDateOccurred is null then 0 else 3 end,
			0,
			0,
			isnull(@nSequenceNo,0),
			0
			)

		set @nErrorCode = @@error
	end
End

Return @nErrorCode
GO

Grant execute on dbo.ip_InsertAlert to public
GO

