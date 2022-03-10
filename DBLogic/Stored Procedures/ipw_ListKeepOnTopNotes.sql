-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListKeepOnTopNotes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListKeepOnTopNotes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListKeepOnTopNotes.'
	Drop procedure [dbo].[ipw_ListKeepOnTopNotes]
End
Print '**** Creating Stored Procedure dbo.ipw_ListKeepOnTopNotes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListKeepOnTopNotes
(
	@pnRowCount			int		= null          output,	
	@pnUserIdentityId		int,			        -- Mandatory
	@psCulture			nvarchar(10)	= null,         -- the language in which output is to be expressed	
	@ptXMLFilterCriteria		ntext		= null,	        -- The filtering to be performed on the result set.
	@psType                         nvarchar(5)     = 'CASE',       -- Case or Name depending upon the data required for case or name                                          
	@pbCalledFromCentura	        bit		= 0			
)
as
-- PROCEDURE:	ipw_ListKeepOnTopNotes
-- VERSION:	9
-- DESCRIPTION:	Returns the requested Keep on Top Notes

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Oct 2010	MS	RFC5885	1	Procedure created
-- 07 Mar 2011	MF	R10217  2	Correction to extraction of CASETEXT
-- 19 Oct 2011  MS      R10177  3       
-- 15 Nov 2011	SF	R11559	4	Re-enable Keep On Top Notes for Timesheet 
-- 04 Sep 2013  MS      DR635   5       Display default instructions if Billing instructions not there
-- 02 Nov 2015	vql	R53910	6	Adjust formatted names logic (DR-15543).
-- 18 Apr 2017  MS  R71142  7   Remove NameTypeClassification join and use exists for CaseName and NameTypeClassification for Names
-- 07 Sep 2018	AV	74738	8	Set isolation level to read uncommited.
-- 08 Apr 2019  MS      DR46788 9       Added multiple cases keep on top notes for billing

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(max)
Declare @sLookupCulture		nvarchar(10)

-- Declare Filter Variables		
Declare @nCaseKey		int
Declare @sCaseKeys              nvarchar(max)
Declare @nProgram               int		
Declare @bIsTimesheet		bit
Declare @idoc 			int 	-- Declare a document handle of the XML document in memory 
                                        -- that is created by sp_xml_preparedocument.		
		
Declare @sCaseTypeKey 		nchar(1)
Declare @sCRMProgramName	nvarchar(8)
		
-- Initialise variables
Set 	@nErrorCode = 0
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

-- Report Table matrix for Case
If @nErrorCode = 0 and (@sCaseKeys is not null or @nCaseKey is not null) and @psType = 'CASE'
Begin        
        Set	@sSQLString = 
        "Select 
                C.IRN   as CaseReference,
                C.CURRENTOFFICIALNO  as OfficialNo,
                CASE WHEN CT.LONGFLAG = 1 then " + char(10) +
                        dbo.fn_SqlTranslatedColumn('CASETEXT','TEXT',null,'CT',@sLookupCulture,0) + char(10) +
                " ELSE " + char(10) + 
                        dbo.fn_SqlTranslatedColumn('CASETEXT','SHORTTEXT',null,'CT',@sLookupCulture,0)+ char(10) +                
                " END as Instructions
        From CASES C  
        join CASETYPE CTY	on (CTY.CASETYPE= C.CASETYPE)
        join CASETEXT CT	on (CT.CASEID   = C.CASEID 
				and CT.TEXTTYPE = CTY.KOTTEXTTYPE 
				and CT.TEXTNO=(	SELECT MAX(CT1.TEXTNO) 
						FROM CASETEXT CT1
						where CT1.CASEID = CT.CASEID
						and CT1.TEXTTYPE = CT.TEXTTYPE))
        where C.CASEID"+dbo.fn_ConstructOperator(0,'CS', ISNULL(@sCaseKeys, @nCaseKey), null, @pbCalledFromCentura) 
        + CHAR(10) + "and cast((ISNULL(CTY.PROGRAM,0) & @nProgram) as bit) = 1"
        
        Exec	@nErrorCode = sp_executesql @sSQLString,
                N'@nCaseKey     int,
                @nProgram       int,
                @sCaseKeys      nvarchar(max)',
                @nCaseKey       = @nCaseKey,
                @nProgram       = @nProgram,                
                @sCaseKeys         = @sCaseKeys
End

-- Report Table matrix for Name
If @nErrorCode = 0 and @psType = 'NAME'
Begin
        -- Fetch data for Case Names
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
                        "Select 
                                dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as Name,
                                dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, CT.POSTALNAME, CT.POSTCODEFIRST, CT.STATEABBREVIATED, CT.POSTCODELITERAL, CT.ADDRESSSTYLE)					
					as Address,
                                NTY.DESCRIPTION as NameType, 
                                CASE WHEN NT.TEXT is not null
					THEN " +char(10)+dbo.fn_SqlTranslatedColumn('NAMETEXT','TEXT',null,'NT',@sLookupCulture,0) + CHAR(10) +
					"ELSE " +char(10)+ dbo.fn_SqlTranslatedColumn('IPNAME','CORRESPONDENCE',null,'IPN',@sLookupCulture,0) + char(10)+
                                "END as Instructions
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
                        left join ADDRESS A	on (A.ADDRESSCODE=ISNULL(CN.ADDRESSCODE, ISNULL(N.POSTALADDRESS,N.STREETADDRESS)))
	                left join COUNTRY CT	on (CT.COUNTRYCODE=A.COUNTRYCODE)
	                left join STATE S	on (S.COUNTRYCODE=A.COUNTRYCODE
					            and S.STATE=A.STATE)
                        where CASEID = @nCaseKey and cast((ISNULL(NTY.PROGRAM,0) & @nProgram) as bit) = 1 
                                and (NT.TEXT is not null or IPN.CORRESPONDENCE is not null)"
                        
                        If @nProgram = 8
                        Begin
                                Set @sSQLString = @sSQLString +CHAR(10)+ "and CN.NAMETYPE in ('I','O','D','Z')"
                        End
                        
                        Set	@sSQLString = @sSQLString +CHAR(10)+
                        "order by CASE	CN.NAMETYPE 	/* strictly only for orderby */
		  	WHEN	'I'	THEN 0		/* Instructor */
		  	WHEN 	'A'	THEN 1		/* Agent */
		  	WHEN 	'O'	THEN 2		/* Owner */
			WHEN	'EMP'	THEN 3		/* Responsible Staff */
			WHEN	'SIG'	THEN 4		/* Signotory */
			ELSE 5				/* others, order by description and sequence */
		        END, NTY.DESCRIPTION, CN.SEQUENCE"
                
                        Exec	@nErrorCode = sp_executesql @sSQLString,
                                N'@nCaseKey             int,
                                @pnUserIdentityId 	int,
			        @psCulture		nvarchar(10),
				@pbCalledFromCentura	bit,
				@sCRMProgramName        nvarchar(8),
				@nProgram               int',
                                @nCaseKey               = @nCaseKey,
                                @pnUserIdentityId 	= @pnUserIdentityId,	
				@psCulture		= @psCulture,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@sCRMProgramName	= @sCRMProgramName,
				@nProgram               = @nProgram
                End
        End
        Else If exists (Select 1 from #TEMPNAMETABLE) -- Fetch data for Names
        Begin
                Set	@sSQLString = 
                "Select 
                        dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as Name,
                        dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, 
                        CT.POSTALNAME, CT.POSTCODEFIRST, CT.STATEABBREVIATED, CT.POSTCODELITERAL, CT.ADDRESSSTYLE)					
					as Address,
                         NTY.DESCRIPTION as NameType,
                        CASE WHEN NT.TEXT is not null
					THEN " +char(10)+dbo.fn_SqlTranslatedColumn('NAMETEXT','TEXT',null,'NT',@sLookupCulture,0) + CHAR(10) +
					"ELSE " +char(10)+ dbo.fn_SqlTranslatedColumn('IPNAME','CORRESPONDENCE',null,'IPN',@sLookupCulture,0) + char(10)+
                        "END as Instructions
                From NAMETYPE NTY 
                join #TEMPNAMETABLE NTB on (NTY.NAMETYPE = NTB.NAMETYPE or NTB.NAMETYPE is null)        
                join NAME N on (N.NAMENO = NTB.NameKey)
                left join NAMETEXT NT on (NT.TEXTTYPE = NTY.KOTTEXTTYPE and NT.NAMENO = N.NAMENO)
	        left join IPNAME IPN on (N.NAMENO = IPN.NAMENO and NTY.KOTTEXTTYPE in ('CB','CC','CP'))  
                left join ADDRESS A	        on (A.ADDRESSCODE= ISNULL(N.POSTALADDRESS,N.STREETADDRESS))
	        left join COUNTRY CT	        on (CT.COUNTRYCODE=A.COUNTRYCODE)
	        left join STATE S	        on (S.COUNTRYCODE=A.COUNTRYCODE and S.STATE=A.STATE)
	        where  NTY.KOTTEXTTYPE is not null 
                and cast((ISNULL(NTY.PROGRAM,0) & @nProgram) as bit) = 1 
	        and (NT.TEXT is not null or IPN.CORRESPONDENCE is not null)
                and (exists (Select 1 from CASENAME where NAMENO = N.NAMENO and NAMETYPE = NTY.NAMETYPE)
                        or exists (Select 1 from NAMETYPECLASSIFICATION NTC where NTC.NAMENO = N.NAMENO and NTC.NAMETYPE = NTY.NAMETYPE and NTC.ALLOW = 1))"
					          
		If @nProgram = 8
		Begin
		       Set	@sSQLString = @sSQLString +CHAR(10)+ " and NTY.NAMETYPE in ('D','Z')" 
		End
					                
                Set	@sSQLString = @sSQLString +CHAR(10)+ " order by 1"   
        
                Exec	@nErrorCode = sp_executesql @sSQLString,
                        N'@nProgram           int',
                        @nProgram             = @nProgram
        End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListKeepOnTopNotes to public
GO
