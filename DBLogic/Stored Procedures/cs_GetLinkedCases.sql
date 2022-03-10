-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetLinkedCases
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_GetLinkedCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_GetLinkedCases.'
	drop procedure dbo.cs_GetLinkedCases
end
print '**** Creating procedure dbo.cs_GetLinkedCases...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_GetLinkedCases 
		@psXMLActivityRequestRow	ntext,
		@psLinkedCasesTable		nvarchar(50)
AS
-- PROCEDURE :	cs_GetLinkedCases
-- VERSION :	5
-- DESCRIPTION:	Get cases with similar criteria to the input case.  
--		These cases will be merged in a single generated letter.
-- COPYRIGHT: 	Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited
--
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 29/05/2006	DL	12388	1	Procedure created
-- 17/08/2006	IB	13201	2	Don't bunch already generated letters together, 
--					i.e. WHENOCCURRED column contains a non-null value.
-- 27-Nov-2006	MF	13919	3	Ensure sp_xml_removedocument is called after sp_xml_preparedocument
--					by ignoring the value or ErrorCode
-- 12 Jun 2007	MF	14908	4	Allow for the ACTIVITYREQUEST.HOLDFLAG to be null
-- 17 Jun 2008	DL	16531	5	Change @sSQLUser to nvarchar(40)

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF


Declare	@nErrorCode 		int,
	@sSQLString 		nvarchar(4000),
	@hDocument 		int,			-- handle to the XML parameter
	@nCaseId		int,
	@dtWhenRequested	datetime,
	@sSQLUser		nvarchar(40),
	@nLetterNo		smallint,
	@dtWhenOccurred		datetime



-- First collect the key for the Activity Request row that has been passed as an XML parameter using OPENXML functionality.
Set @nErrorCode = 0
Begin	
	Exec 	sp_xml_preparedocument  @hDocument OUTPUT, @psXMLActivityRequestRow
	Set 	@nErrorCode = @@Error
End

-- Now select the key from the xml, at the same time joining it to the ACTIVITYREQUEST table.
If @nErrorCode = 0
Begin
	Set @sSQLString="
	select 	@nCaseId 		= CASEID,
		@dtWhenRequested 	= WHENREQUESTED,
		@sSQLUser 		= SQLUSER,
		@nLetterNo 		= LETTERNO,
		@dtWhenOccurred 	= WHENOCCURRED
		from openxml(@hDocument,'ACTIVITYREQUEST',2)
		with ACTIVITYREQUEST "
	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nCaseId		int     	OUTPUT,
		  @dtWhenRequested	datetime	OUTPUT,
		  @sSQLUser		nvarchar(40)	OUTPUT,
		  @nLetterNo		smallint	OUTPUT, 	
		  @dtWhenOccurred	datetime	OUTPUT, 	
		  @hDocument		int',
		  @nCaseId		= @nCaseId		OUTPUT,
		  @dtWhenRequested	= @dtWhenRequested	OUTPUT,
		  @sSQLUser		= @sSQLUser		OUTPUT,
		  @nLetterNo		= @nLetterNo		OUTPUT,	
		  @dtWhenOccurred	= @dtWhenOccurred	OUTPUT,	
		  @hDocument 		= @hDocument
End

-- Remove the xml document
Exec sp_xml_removedocument @hDocument 

-- Get cases that can be merged into the same XML.  
-- i.e. cases that are currently in the document queue (ACTIVITYREQUEST) and 
-- have the same agent and letter as the current case.
If @nErrorCode = 0
Begin
	If @dtWhenOccurred is null
	Begin
		Set @sSQLString = "
		Insert into "+ @psLinkedCasesTable + " (CASEID, WHENREQUESTED, SQLUSER)
	
		select C.CASEID, AR.WHENREQUESTED, AR.SQLUSER
		from CASES C
		join CASENAME CN ON (CN.CASEID =C.CASEID)
		join ACTIVITYREQUEST AR ON (AR.CASEID = C.CASEID)
		where  CN.NAMETYPE = 'A'	
		and AR.LETTERNO =  @nLetterNo
		and (C.CASEID = @nCaseId OR (isnull(AR.HOLDFLAG,0) != 1 and C.CASEID != @nCaseId))	-- SQA14908
		and AR.WHENOCCURRED is null
		and CN.NAMENO IN (SELECT NAMENO FROM CASENAME WHERE CASEID = @nCaseId AND NAMETYPE = 'A')
	
		"
		Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nLetterNo			smallint,
		  @nCaseId			int',
		  @nLetterNo		=  	@nLetterNo,
		  @nCaseId		=	@nCaseId
	End
	Else
	Begin
		Set @sSQLString = "
		Insert into "+ @psLinkedCasesTable + " (CASEID, WHENREQUESTED, SQLUSER)	
		select @pnCaseId, @pdtWhenRequested, @psSQLUser"

		Exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCaseId		int,
		  @pdtWhenRequested	datetime,
		  @psSQLUser		nvarchar(40)',
		  @pnCaseId		= @nCaseId,
		  @pdtWhenRequested	= @dtWhenRequested,
		  @psSQLUser		= @sSQLUser
	End

End
RETURN @nErrorCode
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_GetLinkedCases to public
go
