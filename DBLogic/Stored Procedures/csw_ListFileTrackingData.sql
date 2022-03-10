-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListFileTrackingData									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListFileTrackingData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListFileTrackingData.'
	Drop procedure [dbo].[csw_ListFileTrackingData]
End
Print '**** Creating Stored Procedure dbo.csw_ListFileTrackingData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListFileTrackingData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int, 		-- Mandatory
	@pnFilePartId		smallint	= null
)
as
-- PROCEDURE:	csw_ListFileTrackingData
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the FileTracking tabs.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Jan 2011	MS	RFC8363	1	Procedure created
-- 15 Mar 2011  MS      R100485	2	Mofified File Details query            
-- 24 Oct 2011	ASH	R11460	3	Cast integer columns as nvarchar(11) data type.
-- 05 Jun 2012  MS      R100634	4	Remove code for File Location and Request. These data will be 
--					fetched in seperate stored procedures
-- 10 Dec 2015	MF	R56171	5	If no FilePart is provided and there is an explicit location for the Case
--					without a FilePart then return the detail of the Case.  If however the Case
--					does not have a location then return the last location and date of the last part.	
-- 07 Sep 2018	AV	74738	6	Set isolation level to read uncommited.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)
Declare @bIsRFIDSystem  bit
Declare @dtLastAuditDate datetime

-- Initialise variables
Set @nErrorCode = 0
If @psCulture is not null
Begin
        Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)
End 

-- Site control RFID System
If @nErrorCode = 0
Begin
        Set @sSQLString = "SELECT @bIsRFIDSystem = COLBOOLEAN                        
                        FROM SITECONTROL
                        WHERE CONTROLID = 'RFID System'"

        exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@bIsRFIDSystem		bit                     output',
			@bIsRFIDSystem		= @bIsRFIDSystem        output  
End

If @nErrorCode = 0
Begin
        Set @sSQLString = "SELECT @dtLastAuditDate = MAX(AUDITDATE)                        
                        FROM AUDITLOCATION
                        WHERE CASEID = @pnCaseKey
                        and (FILEPARTID=@pnFilePartId OR (FILEPARTID is null and @pnFilePartId is null))"

        exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@dtLastAuditDate	datetime                output,
			@pnCaseKey              int,
			@pnFilePartId		smallint',
			@dtLastAuditDate	= @dtLastAuditDate      output,
			@pnCaseKey              = @pnCaseKey,
			@pnFilePartId		= @pnFilePartId
End

-- File Details
If  @nErrorCode = 0
Begin
	If @pnFilePartId is not null
	Begin
		Set @sSQLString = "SELECT TOP(1)
				C.CASEID as CaseKey,
				C.IRN as CaseReference,
				C.TITLE as CaseTitle,
				CL.WHENMOVED as LastDateMoved,
				CL.BAYNO as LastBayNo, 
				CL.FILELOCATION as LastLocationKey,
				dbo.fn_GetTranslation(FLD.[DESCRIPTION],null,FLD.DESCRIPTION_TID,@sLookupCulture)
						as LastLocationDescription,
				@dtLastAuditDate as LastAuditDate,
				SC.COLBOOLEAN   as HasRFIDSystem
				FROM CASES C 
				left join CASELOCATION CL on (CL.CASEID = C.CASEID
							  and CL.FILEPARTID=@pnFilePartId)
				left join TABLECODES FLD on (FLD.TABLECODE = CL.FILELOCATION)
				left join SITECONTROL SC on (SC.CONTROLID = 'RFID System')
				WHERE C.CASEID = @pnCaseKey 
				ORDER BY LastDateMoved DESC"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnCaseKey		int,
				@pnFilePartId		smallint,
				@dtLastAuditDate        datetime,
				@sLookupCulture		nvarchar(10)',
				@pnCaseKey		= @pnCaseKey,
				@pnFilePartId		= @pnFilePartId,
				@dtLastAuditDate        = @dtLastAuditDate,
				@sLookupCulture		= @sLookupCulture
	End
	Else Begin
		--------------------------------------------------
		-- The last location of the master file is to be
		-- returned if it has a location, otherwise return
		-- the last location of the last File Part moved.
		--------------------------------------------------
		Set @sSQLString = "SELECT
				C.CASEID as CaseKey,
				C.IRN as CaseReference,
				C.TITLE as CaseTitle,
				CL.WHENMOVED as LastDateMoved,
				CL.BAYNO as LastBayNo, 
				CL.FILELOCATION as LastLocationKey,
				dbo.fn_GetTranslation(FLD.[DESCRIPTION],null,FLD.DESCRIPTION_TID,@sLookupCulture)
						as LastLocationDescription,
				@dtLastAuditDate as LastAuditDate,
				SC.COLBOOLEAN   as HasRFIDSystem
				FROM CASES C 
				join CASELOCATION CL	 on (CL.CASEID = C.CASEID
							 and CL.FILEPARTID is null
							 and CL.WHENMOVED=(select MAX(CL1.WHENMOVED)
									   from CASELOCATION CL1
									   where CL1.CASEID=CL.CASEID
									   and   CL1.FILEPARTID is null))
				left join TABLECODES FLD on (FLD.TABLECODE = CL.FILELOCATION)
				left join SITECONTROL SC on (SC.CONTROLID = 'RFID System')
				WHERE C.CASEID = @pnCaseKey
				UNION ALL
				-----------------------------------------
				-- Get the last location of the File Part
				-- last moved if the master case has no
				-- file location
				-----------------------------------------
				SELECT TOP(1)
				C.CASEID,
				C.IRN,
				C.TITLE,
				CL.WHENMOVED,
				CL.BAYNO, 
				CL.FILELOCATION,
				dbo.fn_GetTranslation(FLD.[DESCRIPTION],null,FLD.DESCRIPTION_TID,@sLookupCulture),
				@dtLastAuditDate,
				SC.COLBOOLEAN
				FROM CASES C 
				left join CASELOCATION CL on (CL.CASEID = C.CASEID
							  and CL.WHENMOVED=(select MAX(CL1.WHENMOVED)
									   from CASELOCATION CL1
									   where CL1.CASEID=CL.CASEID))
				left join CASELOCATION CX on (CX.CASEID = C.CASEID
							  and CX.FILEPARTID is null)
				left join TABLECODES FLD on (FLD.TABLECODE = CL.FILELOCATION)
				left join SITECONTROL SC on (SC.CONTROLID = 'RFID System')
				WHERE C.CASEID = @pnCaseKey
				and CX.CASEID is null	-- no location for master file"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnCaseKey		int,
				@dtLastAuditDate        datetime,
				@sLookupCulture		nvarchar(10)',
				@pnCaseKey		= @pnCaseKey,
				@dtLastAuditDate        = @dtLastAuditDate,
				@sLookupCulture		= @sLookupCulture
	End
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListFileTrackingData to public
GO