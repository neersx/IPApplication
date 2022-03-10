-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ConstructFileRequestWhere
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ConstructFileRequestWhere]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ConstructFileRequestWhere.'
	Drop procedure [dbo].[csw_ConstructFileRequestWhere]
End
Print '**** Creating Stored Procedure dbo.csw_ConstructFileRequestWhere...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ConstructFileRequestWhere
(
	@psWhere			nvarchar(4000)	= null	OUTPUT,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	csw_ConstructFileRequestWhere
-- VERSION:	3
-- DESCRIPTION:	This stored procedure accepts the variables that may be used to filter File Request information 
--		and constructs a Where clause.  

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Nov 2011	MS	R11208	1	Procedure created
-- 05 Jul 2013	vql	R13629	2	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	3   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode			int
Declare @sSQLString			nvarchar(max)
Declare @sLookupCulture			nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Declare Filter Variables
		
Declare @dtDateRangeFrom		datetime	
Declare @dtDateRangeTo			datetime		

Declare @nRequestedByNameKey 		int		
Declare @nCaseKey			int
Declare @nOwnerKey			int
Declare @nNameOperator			tinyint
Declare @nDeviceKey			int
Declare @nAssignedToNameKey             int
Declare @nPriorityKey                   int
Declare @nStatusKey                     int

Declare @sFrom				nvarchar(4000)
Declare @sWhere				nvarchar(4000)

Declare @idoc 				int  -- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
-- Declare some constants
Declare @Date				nchar(2)
Declare @Numeric			nchar(1)
Declare @Col                            nchar(3)

Set	@Date   			='DT'
Set	@Numeric			='N'
Set     @Col                            ='COL'

-- Initialise variables
Set 	@nErrorCode = 0
set 	@sFrom				= char(10)+"    FROM RFIDFILEREQUEST FR"
set 	@sWhere 			= char(10)+"	WHERE 1=1"


-- If filter criteria was passed, extract details from the XML
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	-- 1) Retrieve the AnySearch element using element-centric mapping (implement 
	--    Case Insensitive searching)   
	Set @sSQLString = 	
	"Select @nRequestedByNameKey		= RequestedByNameKey,"+CHAR(10)+
	"	@dtDateRangeFrom		= DateRangeFrom,"+CHAR(10)+
	"	@dtDateRangeTo			= DateRangeTo,"+CHAR(10)+
	"	@nCaseKey			= CaseKey,"+CHAR(10)+
	"	@nOwnerKey			= OwnerKey,"+CHAR(10)+
	"	@nDeviceKey			= DeviceKey,"+CHAR(10)+
	"       @nAssignedToNameKey             = AssignedToNameKey,"+CHAR(10)+
	"	@nPriorityKey			= PriorityKey,"+CHAR(10)+
	"	@nStatusKey			= StatusKey"+CHAR(10)+
	"from	OPENXML (@idoc, '//csw_ListFileRequestSearches/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      RequestedByNameKey		int		'RequestedByNameKey/text()',"+CHAR(10)+
	"	      DateRangeFrom		        datetime	'RequestedDate/DateRange/From/text()',"+CHAR(10)+	
	"	      DateRangeTo		        datetime	'RequestedDate/DateRange/To/text()',"+CHAR(10)+	
	"	      CaseKey			        int		'CaseKey/text()',"+CHAR(10)+
	"	      OwnerKey			        int		'OwnerKey/text()',"+CHAR(10)+
	"	      DeviceKey		                int		'DeviceKey/text()',"+CHAR(10)+
	"             AssignedToNameKey                 int             'AssignedToNameKey/text()',"+CHAR(10)+
	"	      PriorityKey			int		'PriorityKey/text()',"+CHAR(10)+
	"	      StatusKey         		int		'StatusKey/text()'"+CHAR(10)+
     	"     	)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nRequestedByNameKey 		int			output,
				  @dtDateRangeFrom		datetime		output,		
				  @dtDateRangeTo		datetime		output,	
				  @nCaseKey			int			output,
				  @nOwnerKey		        int			output,
				  @nDeviceKey			int			output,
				  @nAssignedToNameKey           int                     output,
				  @nPriorityKey		        int			output,
				  @nStatusKey			int		        output',
				  @idoc				= @idoc,
				  @nRequestedByNameKey 		= @nRequestedByNameKey	output,
				  @dtDateRangeFrom 		= @dtDateRangeFrom	output,
				  @dtDateRangeTo		= @dtDateRangeTo	output,
				  @nCaseKey			= @nCaseKey		output,
				  @nOwnerKey		        = @nOwnerKey	        output,
				  @nDeviceKey		        = @nDeviceKey	        output,
				  @nAssignedToNameKey           = @nAssignedToNameKey   output, 
				  @nPriorityKey		        = @nPriorityKey	        output,
				  @nStatusKey			= @nStatusKey		output				
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error	

	If @nErrorCode = 0
	Begin	
	        If @nRequestedByNameKey is not NULL
	        Begin
		        Set @sWhere = @sWhere+char(10)+"and FR.EMPLOYEENO " + dbo.fn_ConstructOperator(0,@Col,@nRequestedByNameKey, null,0)
	        End
	
		If @dtDateRangeFrom is not null
		or @dtDateRangeTo   is not null
		Begin
			Set @sWhere =  @sWhere+char(10)+"and FR.DATEREQUIRED "+dbo.fn_ConstructOperator(7,@Date,convert(nvarchar,@dtDateRangeFrom,112), convert(nvarchar,@dtDateRangeTo,112),@pbCalledFromCentura)
		End
		
		If @nCaseKey is not null
		Begin
			Set @sWhere = @sWhere+char(10)+"and (FR.CASEID " + dbo.fn_ConstructOperator(0,@Col,@nCaseKey, null,0)
			Set @sWhere = @sWhere+char(10)+"or FRC.CASEID " + dbo.fn_ConstructOperator(0,@Col,@nCaseKey, null,0)+")"
			Set @sFrom = @sFrom+char(10)+"LEFT JOIN RFIDFILEREQUESTCASES FRC on (FRC.REQUESTID = FR.REQUESTID)"
		End
		
		
		If @nOwnerKey is not null
		Begin
			Set @sWhere = @sWhere+char(10)+"and CN.NAMENO " + dbo.fn_ConstructOperator(0,@Col,@nOwnerKey, null,0)
			Set @sFrom = @sFrom+char(10)+"LEFT JOIN CASES C on (C.CASEID = FR.CASEID or C.CASEID in (Select RFC.CASEID from RFIDFILEREQUESTCASES RFC where RFC.REQUESTID = FR.REQUESTID))"+ CHAR(10) + 
			        "LEFT JOIN CASENAME CN on (CN.CASEID = C.CASEID)"
		End
		
		
		If @nDeviceKey is not null
		Begin
			Set @sWhere = @sWhere+char(10)+"and FAD.RESOURCENO " + dbo.fn_ConstructOperator(0,@Col,@nDeviceKey, null,0)
			Set @sFrom = @sFrom+char(10)+"LEFT JOIN FILEREQASSIGNEDDEVICE FAD on (FAD.REQUESTID = FR.REQUESTID)"
		End
		
		If @nAssignedToNameKey is not null
		Begin
			Set @sWhere = @sWhere+char(10)+"and FAE.NAMENO " + dbo.fn_ConstructOperator(0,@Col,@nAssignedToNameKey, null,0)			
			Set @sFrom = @sFrom+char(10)+"LEFT JOIN FILEREQASSIGNEDEMP FAE on (FAE.REQUESTID = FR.REQUESTID)"
		End

		If @nPriorityKey is not null
		Begin
			Set @sWhere = @sWhere+char(10)+"and FR.PRIORITY " + dbo.fn_ConstructOperator(0,@Col,@nPriorityKey, null,0)
		End

		If @nStatusKey is not null
		Begin
			Set @sWhere = @sWhere+char(10)+"and FR.STATUS " + dbo.fn_ConstructOperator(0,@Col,@nStatusKey, null,0)
		End
		Else 
		Begin
		        Set @sWhere = @sWhere+char(10)+"and FR.STATUS in (0,1)"
		End
	End

	Set @psWhere = ltrim(rtrim(@sFrom+char(10)+@sWhere))	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ConstructFileRequestWhere to public
GO
