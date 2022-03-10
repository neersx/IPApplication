-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_CheckKeepOnTopNotes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_CheckKeepOnTopNotes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_CheckKeepOnTopNotes.'
	Drop procedure [dbo].[ipw_CheckKeepOnTopNotes]
End
Print '**** Creating Stored Procedure dbo.ipw_CheckKeepOnTopNotes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_CheckKeepOnTopNotes
(
	@pbNotesExist			bit		= 0             output,	
	@pnUserIdentityId		int,			        -- Mandatory
	@psCulture			nvarchar(10)	= null,         -- the language in which output is to be expressed
	@ptXMLFilterCriteria		ntext		= null,	        -- The filtering to be performed on the result set.
	@pbCalledFromCentura	        bit		= 0			
)
as
-- PROCEDURE:	ipw_CheckKeepOnTopNotes
-- VERSION:	8
-- DESCRIPTION:	Returns the requested Keep on Top Notes

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Oct 2010	MS	RFC5885	1	Procedure created
-- 28 Sep 2011  MS      R11214  2       Fix error for Keep on top notes over 254 characters
-- 18 Oct 2011  MS      R10177  3       Added check for Program          
-- 15 Nov 2011	SF	R11559	4	Re-enable Keep On Top Notes for Timesheet 
-- 04 Sep 2013  MS      DR635   5       Display default instructions if Billing instructions not there
-- 18 Apr 2017  MS      R71142  6       Remove NameTypeClassification join and use exists for CaseName and NameTypeClassification for Names
-- 07 Sep 2018	AV	74738	7	Set isolation level to read uncommited.
-- 08 Apr 2019  MS      DR46788 8       Added multiple cases keep on top notes for billing

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(max)
Declare @sCaseTypeKey 		nchar(1)
Declare @sCRMProgramName	nvarchar(8)
Declare @nNotesCount            int
Declare @sLookupCulture		nvarchar(10)

-- Declare Filter Variables	
Declare @nCaseKey		int
Declare @sCaseKeys              nvarchar(max)
Declare @nProgram               int	
Declare @bIsTimesheet		bit
Declare @idoc 			int 	-- Declare a document handle of the XML document in memory 
                                        -- that is created by sp_xml_preparedocument.
-- Initialise variables
Set 	@nErrorCode = 0
Set     @nNotesCount = 0
set 	@sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)

CREATE TABLE dbo.#TEMPNAMETABLE
        (
                NameKey         int             null,
                NameType        nvarchar(3)     collate database_default        null
        )  
        
-- Extract the Data from the filter criteria:
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin

        exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
        
        If @nErrorCode = 0
        Begin
	        Set @sSQLString = 	
	        "Select @nCaseKey		= CaseKey,"+CHAR(10)+
                "       @sCaseKeys		= CaseKeys,"+CHAR(10)+
	        "       @bIsTimesheet           = IsTimesheet,"+CHAR(10)+
	        "       @nProgram               = Program"+CHAR(10)+
	        "from	OPENXML (@idoc, '/ipw_ListKeepOnTopNotes/FilterCriteria',2)"+CHAR(10)+
	        "	WITH ("+CHAR(10)+	
	        "	      CaseKey		int	        'CaseKey/text()',"+CHAR(10)+
                "             CaseKeys          nvarchar(max)	'CaseKeys/text()',"+CHAR(10)+
	        "             Program           int             'Program/text()',"+CHAR(10)+
	     	"             IsTimesheet       bit             'IsTimesheet/text()'"+CHAR(10)+   
     	        "     	     )"

	        exec @nErrorCode = sp_executesql @sSQLString,
				        N'@idoc			int,				 	  		
				          @nCaseKey		int		output,
                                          @sCaseKeys            nvarchar(max)	output,
				          @nProgram             int             output,
				          @bIsTimesheet		bit		output',
				          @idoc			= @idoc,				 	 		
				          @nCaseKey		= @nCaseKey	output,
				          @nProgram             = @nProgram     output,
				          @bIsTimesheet		= @bIsTimesheet	output,
                                          @sCaseKeys            = @sCaseKeys    output				                 
	End
	
	If @nErrorCode = 0
	and @bIsTimesheet = 1
	Begin
		/* set @nProgram to include Timesheet */
		If @nProgram = 0 or @nProgram is null
		Begin
			Set @nProgram = 8
		End
		Else
		Begin
			Set @nProgram = @nProgram & 8
		End
	End
	
	If @nErrorCode = 0
	Begin
	        Set @sSQLString ="Insert into #TEMPNAMETABLE (NameKey, NameType)
	        Select NameKey, NameType
	        From OPENXML (@idoc, '/ipw_ListKeepOnTopNotes/FilterCriteria/NameGroup/Name',2)
	        WITH (  NameKey         int             'NameKey/text()',
	                NameType        nvarchar(3)     'NameType/text()'
	             )"
	             
	        exec @nErrorCode = sp_executesql @sSQLString,
		        N'@idoc		int',
			@idoc		= @idoc	
	End	

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc	

	Set @nErrorCode=@@Error
End


If @nErrorCode = 0 and (@sCaseKeys is not null or @nCaseKey is not null)
Begin        
        Set	@sSQLString = 
        "Select @nNotesCount = @nNotesCount + count(*)
        From CASES C  
        join CASETYPE CTY on (C.CASETYPE = CTY.CASETYPE)
        join CASETEXT CT on (C.CASEID = CT.CASEID and CT.TEXTTYPE = CTY.KOTTEXTTYPE)
        where C.CASEID"+dbo.fn_ConstructOperator(0,'CS', ISNULL(@sCaseKeys, @nCaseKey), null, @pbCalledFromCentura)
        + char(10) + "and cast((ISNULL(CTY.PROGRAM,0) & @nProgram) as bit) = 1   
        and " + char(10) + "ISNULL(" + dbo.fn_SqlTranslatedColumn('CASETEXT','SHORTTEXT',null,'CT',@sLookupCulture,0) + "," + 
        dbo.fn_SqlTranslatedColumn('CASETEXT','TEXT',null,'CT',@sLookupCulture,0)+ ")"+ char(10) + 
        " is not null" 
        
        Exec	@nErrorCode = sp_executesql @sSQLString,
                N'@nNotesCount     int                  output,
                @nProgram          int,        
                @sCaseKeys         nvarchar(max)',
                @nNotesCount       = @nNotesCount      output,  
                @nProgram          = @nProgram,                
                @sCaseKeys         = @sCaseKeys
End

If @nErrorCode = 0 and @nNotesCount = 0
Begin
        If @nCaseKey is not null
        Begin
                If @nErrorCode = 0
                Begin
	                set @sSQLString = "select @sCaseTypeKey = CASETYPE
			                from CASES where CASEID = @nCaseKey"

	                exec @nErrorCode=sp_executesql @sSQLString,
					N'@nCaseKey	        int,
					@sCaseTypeKey	        nchar(1)        output',	
					@nCaseKey		= @nCaseKey,
					@sCaseTypeKey		= @sCaseTypeKey output
                End

                If @nErrorCode = 0
                Begin

	                set @sSQLString = "select @sCRMProgramName = COLCHARACTER
			                from SITECONTROL where UPPER(CONTROLID) = 'CRM SCREEN CONTROL PROGRAM'"

	                exec @nErrorCode=sp_executesql @sSQLString,
					N'@sCRMProgramName      nvarchar(8)             output',
					@sCRMProgramName        = @sCRMProgramName      output
                End
        
                If @nErrorCode = 0
                Begin
                        Set	@sSQLString = 
                        "Select @nNotesCount = @nNotesCount + count(1)                               
                        From CASENAME CN                        
                        join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,@psCulture,0,@pbCalledFromCentura) UNT 
					on (UNT.NAMETYPE = CN.NAMETYPE
					and (UNT.BULKENTRYFLAG = 0 or UNT.BULKENTRYFLAG IS NULL))"
					
			if (exists (select 1 from CASETYPE WHERE CASETYPE = @sCaseTypeKey AND CRMONLY = 1))
	                Begin
		                -- If CRM Case, filter names from screen control
		                Set @sSQLString = @sSQLString +CHAR(10)+ "
		                join dbo.fnw_GetScreenControlNameTypes(@pnUserIdentityId, @nCaseKey, @sCRMProgramName) SCNT
					                on (SCNT.NameTypeKey = CN.NAMETYPE)"
	                End

	                Set @sSQLString = @sSQLString +CHAR(10)+ "
	                join NAME N             on (CN.NAMENO = N.NAMENO)
                        join NAMETYPE NTY       on (NTY.NAMETYPE = CN.NAMETYPE)
                        left join NAMETEXT NT	on (NT.TEXTTYPE = NTY.KOTTEXTTYPE and NT.NAMENO = N.NAMENO)  
			left join IPNAME IPN	on (N.NAMENO = IPN.NAMENO and NTY.KOTTEXTTYPE in ('CB','CC','CP'))        
                        where CASEID = @nCaseKey
                        and cast((ISNULL(NTY.PROGRAM,0) & @nProgram) as bit) = 1
                        and (NT.TEXT is not null or IPN.CORRESPONDENCE is not null)"
                        
                        If @nProgram = 8
                        Begin
                                Set @sSQLString = @sSQLString +CHAR(10)+ "and CN.NAMETYPE in ('I','O','D','Z')"
                        End
                
                        print @sSQLString
                        Exec	@nErrorCode = sp_executesql @sSQLString,
                                N'@nNotesCount          int    output,
                                @nCaseKey               int,
                                @pnUserIdentityId 	int,
			        @psCulture		nvarchar(10),
				@pbCalledFromCentura	bit,
				@sCRMProgramName        nvarchar(8),
				@nProgram               int',
				@nNotesCount            = @nNotesCount    output,
                                @nCaseKey               = @nCaseKey,
                                @pnUserIdentityId 	= @pnUserIdentityId,	
				@psCulture		= @psCulture,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@sCRMProgramName	= @sCRMProgramName,
				@nProgram               = @nProgram
                End
        End
        Else If exists (Select 1 from #TEMPNAMETABLE)
        Begin
                Set	@sSQLString = 
                "Select @nNotesCount = @nNotesCount + count(1)
                From NAMETYPE NTY 
                join #TEMPNAMETABLE NTB on (NTY.NAMETYPE = NTB.NAMETYPE or NTB.NAMETYPE is null)        
                join NAME N on (N.NAMENO = NTB.NameKey)
                left join NAMETEXT NT on (NT.TEXTTYPE = NTY.KOTTEXTTYPE and NT.NAMENO = N.NAMENO)
	        left join IPNAME IPN on (N.NAMENO = IPN.NAMENO and NTY.KOTTEXTTYPE in ('CB','CC','CP'))   
                where NTY.KOTTEXTTYPE is not null
                and cast((ISNULL(NTY.PROGRAM,0) & @nProgram) as bit) = 1
                and (NT.TEXT is not null or IPN.CORRESPONDENCE is not null)
                and (exists (Select 1 from CASENAME where NAMENO = N.NAMENO and NAMETYPE = NTY.NAMETYPE)
                        or exists (Select 1 from NAMETYPECLASSIFICATION NTC where NTC.NAMENO = N.NAMENO and NTC.NAMETYPE = NTY.NAMETYPE and NTC.ALLOW = 1))"
                
                If @nProgram = 8
		Begin
		       Set	@sSQLString = @sSQLString + Char(10) + " and NTY.NAMETYPE in ('D','Z')" 
		End
        
                Exec	@nErrorCode = sp_executesql @sSQLString,
                        N'@nNotesCount        int    output,
                        @nProgram             int',
                        @nNotesCount          = @nNotesCount    output,
                        @nProgram             = @nProgram
        End
End

If @nErrorCode = 0 and @nNotesCount > 0
Begin
        Set @pbNotesExist = 1
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_CheckKeepOnTopNotes to public
GO
