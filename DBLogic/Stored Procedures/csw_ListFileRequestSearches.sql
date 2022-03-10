-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListFileRequestSearches
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListFileRequestSearches]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListFileRequestSearches.'
	Drop procedure [dbo].[csw_ListFileRequestSearches]
End
Print '**** Creating Stored Procedure dbo.csw_ListFileRequestSearches...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListFileRequestSearches
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit 		= 0,
	@pbPrintSQL			bit		= 0
)
as
-- PROCEDURE:	csw_ListFileRequestSearches
-- VERSION:	2
-- DESCRIPTION:	Returns the File Requests that matches the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Nov 2011	MS	R11208	1	Procedure created
-- 10 Nov 2015	KR	R53910	2		Adjust formatted names logic (DR-15543)     


-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables

--	C
--	CN
--	F
--	FR
--	TC1
--	TC2
--	FAD
--	FAE
--	N
--	FLD

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int
Declare @sLookupCulture				nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Declare @sFRWhere				nvarchar(4000)
Declare @sSQLString                             nvarchar(4000)
Declare @sSelect				nvarchar(max)
Declare @sFrom					nvarchar(4000)
Declare @sOrder                                 nvarchar(4000)
Declare @bHasRFID                               bit

Declare @idoc 					int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.
		
-- Initialise variables
Set	@nErrorCode                             = 0
Set     @bHasRFID                               = 0
set 	@sSelect				='SET ANSI_NULLS OFF' + char(10)+ 'Select '
set 	@sFrom					= char(10)+"From RFIDFILEREQUEST F"

If   @nErrorCode=0
Begin
        Set @sSelect = "Select distinct
        F.REQUESTID                     as RequestKey,
	F.CASEID		        as CaseKey,
	CASE WHEN F.CASEID is null then 'CASES' else C.IRN end as CaseReference,
	"+ dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'P',@sLookupCulture,@pbCalledFromCentura)+" as PropertyType, "+CHAR(10)+
        "F.DATEOFREQUEST		as DateRequested,
        F.DATEREQUIRED                  as DateRequired,        
	F.FILELOCATION		        as FileLocationKey,
	"+ dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'FLD',@sLookupCulture,@pbCalledFromCentura)+" as FileLocationDescription, "+CHAR(10)+
        "F.EMPLOYEENO                   as RequestedByKey,
        N.NAMECODE                      as RequestedByCode,
	dbo.fn_FormatNameUsingNameNo(N.NAMENO, N.NAMESTYLE)
				        as RequestedByName,
        F.REMARKS                       as Remarks,
        F.PRIORITY                      as PriorityKey,
        "+ dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC1',@sLookupCulture,@pbCalledFromCentura)+" as Priority, "+CHAR(10)+
	"F.STATUS                       as StatusKey,
	"+ dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC2',@sLookupCulture,@pbCalledFromCentura)+" as Status, "+CHAR(10)+
        "F.LOGDATETIMESTAMP             as LastModifiedDate,
        ISNULL(F.ISSELFSEARCH,0)        as IsSelfSearch,
        dbo.fn_GetConcatenatedDataForFileRequest(F.REQUESTID, 'CASE') as CaseKeys,
        dbo.fn_GetConcatenatedDataForFileRequest(F.REQUESTID, 'DEVICE') as AssignedDevices,
        dbo.fn_GetConcatenatedDataForFileRequest(F.REQUESTID, 'STAFF') as AssignedStaff,
        dbo.fn_GetFileRequestItems(F.REQUESTID, 0) as HasRFIDItems,
        dbo.fn_GetFileRequestItems(F.REQUESTID, 1) as AllItemsDelivered"+CHAR(10)
         
        Select @sFrom = " FROM RFIDFILEREQUEST F
        left join RFIDFILEREQUESTCASES FC on (F.REQUESTID = FC.REQUESTID)
        left join CASES C on (F.CASEID = C.CASEID)
        left join PROPERTYTYPE P on (P.PROPERTYTYPE = C.PROPERTYTYPE)
	left join TABLECODES FLD on (FLD.TABLECODE = F.FILELOCATION)	
	left join [NAME] N on (N.NAMENO = F.EMPLOYEENO)        
        left join TABLECODES TC1 on (TC1.TABLECODE = F.PRIORITY)
        left join TABLECODES TC2 on (TC2.USERCODE = F.STATUS 
                                     and TC2.TABLETYPE = (Select TABLETYPE from TABLETYPE where TABLENAME = 'File Request Status'))
        left join FILEREQASSIGNEDDEVICE FAD on (FAD.REQUESTID = F.REQUESTID)
        left join FILEREQASSIGNEDEMP FAE on (FAE.REQUESTID = F.REQUESTID)"+CHAR(10)
End

If   @nErrorCode=0
and (datalength(@ptXMLFilterCriteria) <> 0
or   datalength(@ptXMLFilterCriteria) is not null)
Begin
	exec @nErrorCode=dbo.csw_ConstructFileRequestWhere
				@psWhere		= @sFRWhere	  	OUTPUT,
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,	
				@ptXMLFilterCriteria	= @ptXMLFilterCriteria,	
				@pbCalledFromCentura	= @pbCalledFromCentura	
End

If @nErrorCode=0
Begin 	
	Set @sFRWhere		= char(10) 	+ ' WHERE F.REQUESTID in (Select FR.REQUESTID ' 
				  + char(10) 	+ @sFRWhere
				  + char(10)	+ ')'
				  
        Set @sOrder             = char(10) 	+ ' ORDER BY DateRequired desc, CaseReference asc, RequestedByName asc'     
 	  	  
	If @pbPrintSQL = 1
	Begin
		Print @sSelect + @sFrom + @sFRWhere + @sOrder
	End

	-- Now execute the constructed SQL to return the result set
	Exec (@sSelect + @sFrom + @sFRWhere + @sOrder)
	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListFileRequestSearches to public
GO
