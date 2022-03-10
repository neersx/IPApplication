-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetIssueDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetIssueDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetIssueDetails.'
	Drop procedure [dbo].[csw_GetIssueDetails]
End
Print '**** Creating Stored Procedure dbo.csw_GetIssueDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetIssueDetails
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseId			int,		-- Mandatory
	@pnImportBatchNo	int,		-- Mandatory
	@pnTransactionNo	int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	csw_GetIssueDetails
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the issue details for a rejected transaction.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26 Nov 2009	NG	RFC8098	1	Procedure created
-- 02 MAR 2015	MS	R43203	2	Get case event text for EVENTTEXT table

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int

declare @sSQLString	nvarchar(4000)
declare	@sSelectString	nvarchar(254)
declare	@sFromString	nvarchar(1000)
declare @sExistingData	nvarchar(1000)
declare @sHeader		nvarchar(254)
declare @psTransactionType	nvarchar(20)
declare @psRejectReason		nvarchar(254)

-- Initialise variables
Set @nErrorCode = 0
Set @sSelectString = "Select IJ.TRANSACTIONTYPE as TransactionType, IJ.CHARACTERDATA as ImportedData, "
Set @sFromString = " "

If @nErrorCode = 0
Begin
	Select @psTransactionType = IJ.TRANSACTIONTYPE,
			@psRejectReason = IJ.REJECTREASON
	from IMPORTJOURNAL IJ
	where IJ.IMPORTBATCHNO = @pnImportBatchNo and IJ.CASEID = @pnCaseId and IJ.TRANSACTIONNO = @pnTransactionNo
End


If @nErrorCode = 0
Begin
	If @psTransactionType = 'CLASS TYPE'
		Begin
			Set @sExistingData = 
						"(CASE WHEN (IJ.CHARACTERDATA <> 'S' and IJ.CHARACTERDATA <> 'G')"+char(10)+ 
								"THEN 'Class Type should be S or G'"+char(10)+
								"ELSE (CASE WHEN CT.CLASS is null"+char(10)+ 
										"THEN 'Class Type not found for this Case' ELSE TM.GOODSSERVICES"+char(10)+ 
									  "END) "+char(10)+
						" END) "
			Set @sHeader = "'Class Type'"
			Set @sFromString = @sFromString +
						"left join CASETEXT CT on (CT.CASEID = @pnCaseId and CT.TEXTTYPE = IJ.CHARACTERKEY)"+char(10)+
						"left join TMCLASS TM on (TM.COUNTRYCODE = C.COUNTRYCODE and TM.CLASS = CT.CLASS)"
		End
	
	Else If @psTransactionType = 'DUE DATE'
		Begin
			Begin
				If @psRejectReason = 'Next Cycle of Event exceeds maximum allowed'
					Set @sExistingData = "'the highest cycle found for the particular event'"
				Else if @psRejectReason = 'Data is not in a Valid Date type'
					Set @sExistingData = "'Due Date not found for this Case Event'"
				Else 
					Set @sExistingData = "cast(CE.EVENTDUEDATE as nvarchar(20))"
			End
			Set @sFromString = @sFromString + 
					"left join CASEEVENT CE on (CE.EVENTNO = IJ.NUMBERKEY and CE.CASEID = IJ.CASEID)"			
			Set @sHeader =	"'Event: ' + E.EVENTDESCRIPTION"
		End
	
	Else If @psTransactionType = 'EVENT DATE'
		Begin
			Begin
				If @psRejectReason = 'Next Cycle of Event exceeds maximum allowed'
					Set @sExistingData = "'the highest cycle found for the particular event'"
				Else if @psRejectReason = 'Data is not in a Valid Date type'
					Set @sExistingData = "'Event Date not found for this Case Event'"
				Else 
					Set @sExistingData = "CE.EVENTDATE"
			End
			Set @sFromString = @sFromString +
						"left join CASEEVENT CE on (CE.EVENTNO = IJ.NUMBERKEY and CE.CASEID = IJ.CASEID)"			
			Set @sHeader =	"'Event: ' + E.EVENTDESCRIPTION"
		End
	
	Else If @psTransactionType = 'EVENT TEXT'
		Begin
			Set @sExistingData = "isnull(ETF.EVENTLONGTEXT, 'Event Text not found for this Case Event')"
			Set @sFromString = @sFromString +
						" left join CASEEVENT CE on (CE.EVENTNO = IJ.NUMBERKEY and CE.CASEID = IJ.CASEID)
						left join (Select ET.EVENTTEXT, CET.CASEID, CET.EVENTNO, CET.CYCLE
						from EVENTTEXT ET
						Join CASEEVENTTEXT CET	on (CET.EVENTTEXTID = ET.EVENTTEXTID)
						where ET.EVENTTEXTTYPEID is null)
					as ETF on (ETF.CASEID = CE.CASEID and ETF.EVENTNO = CE.EVENTNO and ETF.CYCLE = CE.CYCLE)"
			Set @sHeader = "'Event: ' + E.EVENTDESCRIPTION"
		End
	
	Else If @psTransactionType = 'JOURNAL'
		Begin
			Set @sExistingData = 
						"(cast(J.JOURNALNO as nvarchar(20)) +';'+ "+char(10)+
						"cast(J.JOURNALPAGE as nvarchar(20)) +';'+ "+char(10)+
						"cast(J.JOURNALDATE as nvarchar(20)))"
			Set @sHeader =	"'Journal'"
			Set @sFromString = @sFromString + "left join JOURNAL J on (J.CASEID = IJ.CASEID)"
		End
	
	Else If @psTransactionType = 'LOCAL CLASSES'
		Begin
			Set @sExistingData = "isnull(C.LOCALCLASSES,'No Local Classes found for this Case')"
			Set @sHeader =  "'Local Class'"
		End
	
	Else If @psTransactionType = 'NAME'
		Begin
			Set @sExistingData = "dbo.fn_GetConcatenatedNames(@pnCaseId, NT.NAMETYPE, ';', getdate(), null)" 
			Set @sHeader =	"'Name Type: ' + NT.DESCRIPTION"			
			Set @sFromString = @sFromString + "left join NAMETYPE NT on (NT.NAMETYPE = IJ.CHARACTERKEY)"
		End
	
	Else If @psTransactionType = 'NAME ALIAS'
		Begin
			Set @sExistingData = "dbo.fn_GetConcatenatedPropertyList(@pnCaseId, 'NAMEALIAS', AT.ALIASTYPE, ';', getdate())"			
			Set @sHeader = "'Alias Type: ' + AT.ALIASDESCRIPTION"
			Set @sFromString = @sFromString + "left join ALIASTYPE AT on (AT.ALIASTYPE = IJ.CHARACTERKEY)"
		End
	
	Else If @psTransactionType = 'NAME COUNTRY'
		Begin
			Set @sExistingData = "dbo.fn_GetConcatenatedPropertyList(@pnCaseId, 'NAMECOUNTRY', null, ';', getdate())"
			Set @sHeader = "'Transaction Type : NAME COUNTRY'"
		End
	
	Else If @psTransactionType = 'NAME STATE'
		Begin
			Set @sExistingData = "dbo.fn_GetConcatenatedPropertyList(@pnCaseId, 'NAMESTATE', null, ';', getdate())"
			Set @sHeader = "'Transaction Type : NAME STATE'"
		End
	
	Else If @psTransactionType = 'NAME VAT NO'
		Begin
			Set @sExistingData = "dbo.fn_GetConcatenatedPropertyList(@pnCaseId, 'NAMEVATNO', null, ';', getdate())"
			Set @sHeader = "'Transaction Type : NAME VAT NO'"
		End
	
	Else If @psTransactionType = 'NUMBER TYPE'
		Begin
			Begin
				If @psRejectReason = 'Official Number Date does not match with Case Official Number Date' 
					Set @sExistingData = "isnull(cast(O.DATEENTERED as nvarchar(20)), 'DateEntered not found for the Official Number')"
				Else 
					Set @sExistingData = "isnull(cast(O.OFFICIALNUMBER as nvarchar(50)), 'No Current Official Number found for this Case')"
			End			
			Set @sHeader = "'Number Type: ' + NUT.DESCRIPTION"
			Set @sFromString = @sFromString +
						"left join NUMBERTYPES NUT on (NUT.NUMBERTYPE = IJ.CHARACTERKEY)"+char(10)+
						"left join OFFICIALNUMBERS O on (O.CASEID = IJ.CASEID)"
		End
	
	Else If @psTransactionType = 'RELATED COUNTRY'
		Begin
			Set @sExistingData = "dbo.fn_GetConcatenatedPropertyList(@pnCaseId, 'RELATEDCOUNTRY', CR.RELATIONSHIP, ';', getdate())"
			Set @sHeader = "'Relationship: ' + CR.RELATIONSHIPDESC"
			Set @sFromString = @sFromString + "left join CASERELATION CR on (CR.RELATIONSHIP = IJ.CHARACTERKEY)"
		End
	
	Else If @psTransactionType = 'RELATED DATE'
		Begin
			Set @sExistingData = "dbo.fn_GetConcatenatedPropertyList(@pnCaseId, 'RELATEDDATE', CR.RELATIONSHIP, ';', getdate())"
			Set @sHeader = "'Relationship: ' + CR.RELATIONSHIPDESC"
			Set @sFromString = @sFromString + "left join CASERELATION CR on (CR.RELATIONSHIP = IJ.CHARACTERKEY)"
		End
	
	Else If @psTransactionType = 'RELATED NUMBER'
		Begin
			Set @sExistingData = "dbo.fn_GetConcatenatedPropertyList(@pnCaseId, 'RELATEDNUMBER', CR.RELATIONSHIP, ';', getdate())"
			Set @sHeader = "'Relationship: ' + CR.RELATIONSHIPDESC"
			Set @sFromString = @sFromString + "left join CASERELATION CR on (CR.RELATIONSHIP = IJ.CHARACTERKEY)"
		End
	
	Else If @psTransactionType = 'TEXT'
		Begin
			Set @sExistingData = "dbo.fn_GetConcatenatedPropertyList(@pnCaseId, 'TEXT', TT.TEXTTYPE, '~', getdate())"
			Set @sHeader = "'Text Type: ' + TT.TEXTDESCRIPTION"
			Set @sFromString = @sFromString + "left join TEXTTYPE TT on (TT.TEXTTYPE = IJ.CHARACTERKEY)"
		End
	
	Else If @psTransactionType = 'TITLE'
		Begin
			Set @sExistingData = "isnull(C.TITLE, 'No Title found for this Case')"
			Set @sHeader = "'Title'"
		End
	
	Else If @psTransactionType = 'TYPE OF MARK'
		Begin
			Set @sExistingData = "isnull(TC.DESCRIPTION, 'TypeOfMark not found for this Case')"
			Set @sFromString = @sFromString +
								"left join TABLECODES TC on (TC.TABLECODE = C.TYPEOFMARK and TC.TABLETYPE = 51)"					
			Set @sHeader = "'Type of Mark'"
		End
	
End

Set @sSQLString = @sSelectString + @sExistingData + " as ExistingData," + @sHeader + " as Header, " + char(10)+
				"IJ.ERROREVENTNO as EventKey, " + char(10) +
				"E.EVENTDESCRIPTION as ErrorEventDescription, " + char(10) +
				"(select I.EventNo from"+char(10)+ 
					"	(select top 1 (CASE WHEN IC.COUNTRYCODE IS NULL THEN 0 ELSE 1 END * 100 +"+char(10)+
					"				CASE WHEN IC.PROPERTYTYPE IS NULL THEN 0 ELSE 1 END * 10 +"+char(10)+
					"				CASE WHEN IC.TRANSACTIONTYPE IS NULL THEN 0 ELSE 1 END * 1) as BestFit,"+char(10)+ 
					"			IC.EVENTNO as EventNo"+char(10)+
					"	from IMPORTCONTROL IC"+char(10)+
					"	where ((IC.COUNTRYCODE = C.COUNTRYCODE OR IC.COUNTRYCODE IS NULL)"+char(10)+ 
					"			and (IC.PROPERTYTYPE = C.PROPERTYTYPE OR IC.PROPERTYTYPE IS NULL)"+char(10)+
					"			and (IC.TRANSACTIONTYPE = IJ.TRANSACTIONTYPE OR IC.TRANSACTIONTYPE IS NULL))"+char(10)+
					"	ORDER BY BestFit DESC) I) as BestFitEvent,"+char(10)+
				"(select I.EventDescription from"+char(10)+ 
					"	(select top 1 (CASE WHEN IC.COUNTRYCODE IS NULL THEN 0 ELSE 1 END * 100 +"+char(10)+
					"				CASE WHEN IC.PROPERTYTYPE IS NULL THEN 0 ELSE 1 END * 10 +"+char(10)+
					"				CASE WHEN IC.TRANSACTIONTYPE IS NULL THEN 0 ELSE 1 END * 1) as BestFit,"+char(10)+ 
					"			E1.EVENTDESCRIPTION as EventDescription"+char(10)+
					"	from IMPORTCONTROL IC"+char(10)+
					"	join EVENTS E1 on (E1.EVENTNO = IC.EVENTNO)"+char(10)+
					"	where ((IC.COUNTRYCODE = C.COUNTRYCODE OR IC.COUNTRYCODE IS NULL)"+char(10)+ 
					"			and (IC.PROPERTYTYPE = C.PROPERTYTYPE OR IC.PROPERTYTYPE IS NULL)"+char(10)+
					"			and (IC.TRANSACTIONTYPE = IJ.TRANSACTIONTYPE OR IC.TRANSACTIONTYPE IS NULL))"+char(10)+
					"	ORDER BY BestFit DESC) I) as BestFitEventDescription"+char(10)+
				"from IMPORTJOURNAL IJ " + char(10)+
				"left join CASES C on (C.CASEID = @pnCaseId)"+char(10)+
				"left join EVENTS E on (E.EVENTNO = IJ.ERROREVENTNO) "+char(10)+
				@sFromString + char(10) +
				"where IJ.IMPORTBATCHNO = @pnImportBatchNo and IJ.CASEID = @pnCaseId and IJ.TRANSACTIONTYPE = @psTransactionType"

exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnImportBatchNo		int,
				  @pnCaseId				int,
				  @psTransactionType	nvarchar(20)',
				  @pnImportBatchNo =	@pnImportBatchNo,
				  @pnCaseId =			@pnCaseId,
				  @psTransactionType =	@psTransactionType



Return @nErrorCode
GO

Grant execute on dbo.csw_GetIssueDetails to public
GO
