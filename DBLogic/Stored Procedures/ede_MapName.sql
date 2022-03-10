-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_MapName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_MapName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_MapName.'
	Drop procedure [dbo].[ede_MapName]
End
Print '**** Creating Stored Procedure dbo.ede_MapName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ede_MapName
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10)	= null,
	@pnBatchNo		int
)
as
-- PROCEDURE:	ede_MapName
-- VERSION:	39
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This procedure uses predefined name mapping rules to update
--		and validate the the EDE holding tables for names it will also
--		create unresolved names where no mappings are found.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Sep 2006	vql	12995	1	Procedure created.
-- 02 Jan 2007	AT	13473	2	Renamed Transaction Producer to Alternative Sender.
-- 23 Jan 2007	vql	13452	3	Add mapping for Attention Names.
-- 31 Jan 2007	vql	14022	4	Transaction Processed Narratives Are Not Being Allocated to Name Import Transactions.
-- 31 Jan 2007	vql	13938	5	Name Mapping to Exclude Address Comparison for Address Not Provided.
-- 13 Feb 2007	vql	13452	6	Bug fix.
-- 25 May 2007	vql	14788	7	Display address lines in sequence order, ignoring missing sequence numbers.
-- 12 Dec 2007	DL	15686	8	Add isnull to aggregate functions to eliminate warning error.
-- 18 Jan 2008	vql	15846	9	Address not appearing in the Name Resolution window when the address is in the EDE Batch.
-- 16 Jun 2008	DL	16458	10	Fix bug duplicate attention name.
-- 09 Jul 2008	vql	16650	11	EDE Batch fails with Error Status but no Error Message.
-- 16 Jul 2008	vql	16700	12	Multiple address lines imported should be separated with carriage return.
-- 29 Jan 2009	MF	17330	13	Ensure @nErrorCode is tested after every statement
--					that causes it to be set.
-- 04 Mar 2009	MF	17453	14	Minimise locks by keeping length of transactions as short
--					as possible.
-- 16 Mar 2009	MF	17453	14	Also treat space filled data the same as an empty string to avoid excessive mismatches.
-- 25 Mar 2009	vql	17108	15	Name Resolution of Individual name not setting mapping Entity Type to Individual.
-- 02 Apr 2009	MF	17563	15	Need to handle the situation where multi entries exist in the EXTERNALNAME table 
--					for a given DATASOURCENAMENO with identical EXTERNALNAMECODE.
-- 02 Apr 2009	MF	17563	15	Need to handle the situation where multi entries exist in the EXTERNALNAME table 
--					for a given DATASOURCENAMENO with identical EXTERNALNAMECODE.
-- 30 Apr 2009	vql	17653	16	Processing EDE batch is getting stuck at name mapping (improve performance).
-- 07 May 2009	MF	17653	17	Further improvement to performance by using a derived table on update of EDEADDRESSBOOK.
-- 11 May 2009	MF	17666	18	Remove any existing unresolved names for this batch so that they are rechecked in case
--					another batch has resolved names that can be used by this batch.
-- 15 May 2009	MF	17687	19	Unresolved names not created when tran status is 'unresolved names'
-- 19 May 2009	MF	17678	20	EDE name transaction with issues end up with blank transaction status.
-- 04 Jun 2009	MF	13281	21	Check a sitecontrol to determine if created names are to have a name code generated.
-- 19 Jun 2009	MF	17751	22	Name matching for Owners is to also match on the Address if it has been supplied.
-- 19 Jun 2009	MF	17807	22	Ensure duplicate key error does not occur on insert into #TEMPEDEADDRESSBOOK by including DISTINCT.
-- 24 Jun 2009	MF	17751	22	Revisit after testing.
-- 03 Sep 2009	MF	17956	23	Attention name being incorrectly associated with wrong company Names
-- 08 Sep 2009	MF	18021	24	Name matching should leave as unresolved the imported name if more than one candidate name is found.
-- 14 Sep 2009	MF	18022	25	If Sender name identifier is provided, then external name code must match for Name Mapping 
-- 17 Nov 2009	MF	18235	26	Implement SQA17108 - Name Resolution of Individual name not setting mapping Entity Type to Individual.
-- 04 Jun 2010	MF	18703	27	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE, ensure these are set to null.
-- 05 Jan 2011	MF	17540	28	EDE Name Mapping cannot handle multiple names per name type.  Need to additionally match on the
--					NAMESEQUENCENUMBER column.
-- 20 Oct 2011	vql	18318	29	Missing Name Detail issue does not have enough information.
-- 10 Jan 2012  Dw	17662	30	Mapping needs to take into account Name Type Classification settings against Inprotech name.
-- 06 Aug 2012	MF	20821	31	Extention of SQA17540 to also set NAMESEQUENCENUMBER to zero if null for EDECASENAMEDETAILS.
-- 11 Sep 2012	MF	20898	32	If the address has changed against a external name that has been mapped to a specific Inprotech Name then
--					do not automatically update that Name if it is being used as an Owner.
-- 21 Sep 2012	DL	R12763	33	Fix collation error by adding 'collate database_default' to character based columns in temp table definition.
-- 15 Apr 2013	DV	R13270	34	Increase the length of nvarchar to 11 when casting or declaring integer
-- 26 Sep 2014	MF	R39831	35	If RECEIVERNAMEIDENTIFIER (Inprotech's NAMECODE) is supplied then check that it is numeric before padding 
--					with leading zeroes to match the user defined fixed length.
-- 26 Feb 2015	vql	R39831	36	Correct checksum same number of columns when linking unresolved name with the ede address book.

-- 20 May 2015	MF	46262	37	Mapped name with a different address is not being sent to operator for review. 
--					This is a revisit from SQA17751 which did not enforce the match on Address for Owners in one situation.
-- 19 Dec 2017	MF	73124	38	Duplicate names were being created when Attention name only had a Last Name and no First Name (e.g. Renewals Department).
-- 15 May 2018	MF	74148	39	When NameType was not correctly mapped an empty nametype (not null) was failing with a referential integrity error when
--					inserting EDEUNRESOLVEDNAME.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Create temporary table to store addresses.
Create table #TEMPADDRESSES   (
	BATCHNO			int,
	TRANSACTIONIDENTIFIER	nvarchar(254)	collate database_default NULL,
	NAMETYPECODE		nvarchar(50)	collate database_default NULL,
	NAMESEQUENCENUMBER	int		NULL,
	ADDRESSLINE		nvarchar(2000)	collate database_default NULL,
	ADDRESSCITY		nvarchar(254)	collate database_default NULL,
	ADDRESSSTATE		nvarchar(254)	collate database_default NULL,
	ADDRESSPOSTCODE		nvarchar(50)	collate database_default NULL,
	ADDRESSCOUNTRYCODE	nvarchar(50)	collate database_default NULL
 )
 
CREATE CLUSTERED INDEX XPKTEMPADDRESSES ON #TEMPADDRESSES
(
	BATCHNO,
	TRANSACTIONIDENTIFIER,
	NAMETYPECODE,
	NAMESEQUENCENUMBER
)
 
-- Create temp table to store mapped Name against
-- key of EDEADDRESSBOOK table.
-- SQA17662 added EDENAMETYPE
Create table #TEMPEDEADDRESSBOOK (
	ROWID			int		not null,
	NAMENO			int		null,
	MISSINGNAMEDETAILS	bit		default(0),
	EDENAMETYPE		nvarchar(3)	collate database_default  null
 )
 
CREATE CLUSTERED INDEX XPKTEMPADDRESSBOOK ON #TEMPEDEADDRESSBOOK
(
	ROWID,
	NAMENO
)

-- Create temp table to store EDE Associate Names.
Create table #TEMPASSOCIATEDNAMES   (
	ROWNUMBER		int identity(1,1),
	BATCHNO			int,
	USERID			nvarchar(50)	collate database_default NULL,
	TRANSACTIONIDENTIFIER	nvarchar(254)	collate database_default NULL,
	NAMETYPECODE		nvarchar(50)	collate database_default NULL,
	NAMEPREFIX		nvarchar(50)	collate database_default NULL,	
	FIRSTNAME		nvarchar(254)	collate database_default NULL,
	LASTNAME		nvarchar(254)	collate database_default NULL,
	MAINNAMENO		int,
	RELATEDNAMENO		int		
 )
 
Create table  #TEMPUNRESOLVEDNAME (
 	BATCHNO			int		NOT NULL ,
 	TRANSACTIONIDENTIFIER	nvarchar(254)	collate database_default NULL,
 	TRANSACTIONCODE		nvarchar(50)	collate database_default NULL,
 	TRANSACTIONSUBCODE	nvarchar(50)	collate database_default NULL,
 	NAMETYPE		nvarchar(3)	collate database_default NULL,
	NAMESEQUENCENUMBER	int		NULL,
 	SENDERNAMEIDENTIFIER	nvarchar(50)	collate database_default NULL,
 	ENTITYTYPEFLAG		int		NULL ,
 	TITLE			nvarchar(10)	collate database_default NULL,
 	FIRSTNAME		nvarchar(50)	collate database_default NULL,
 	NAME			nvarchar(254)	collate database_default NULL,
 	INITIALS		nvarchar(10)	collate database_default NULL,
 	GENDER			nchar(1)	collate database_default NULL,
 	ADDRESSLINE		nvarchar(1000)	collate database_default NULL,
 	CITY			nvarchar(254)	collate database_default NULL,
 	STATE			nvarchar(50)	collate database_default NULL,
 	POSTCODE		nvarchar(50)	collate database_default NULL,
 	COUNTRYCODE		nvarchar(3)	collate database_default NULL,
 	PHONE			nvarchar(100)	collate database_default NULL,
 	FAX			nvarchar(100)	collate database_default NULL,
 	EMAIL			nvarchar(254)	collate database_default NULL,
 	ATTNFIRSTNAME		nvarchar(254)	collate database_default NULL,
 	ATTNLASTNAME		nvarchar(254)	collate database_default NULL,
 	ATTNTITLE		nvarchar(10)	collate database_default NULL
 )

CREATE INDEX XIE1EDEUNRESOLVEDNAME ON #TEMPUNRESOLVEDNAME
(
	BATCHNO  ASC,
	TRANSACTIONIDENTIFIER  ASC
)

CREATE INDEX XIE2EDEUNRESOLVEDNAME ON #TEMPUNRESOLVEDNAME
(
	BATCHNO  ASC,
	NAMETYPE ASC
)

Declare	@nErrorCode		int
Declare @nRowCount		int
Declare @nRetry			smallint
Declare @sSQLString		nvarchar(max)
Declare @sTransProducerList	nvarchar(1000)
Declare @sMissingNamesList	nvarchar(1000)
Declare @TransactionCountStart	int

Declare @nRowNumber		int
Declare @nMaxRow		int
Declare	@sNameKey		varchar(11)
Declare @sNameCode		nvarchar(10)
Declare	@sName			nvarchar(254)
Declare @sNameTypeCode		nvarchar(50)
Declare	@sGivenNames		nvarchar(50) 
Declare	@sTitleKey		nvarchar(20) 
Declare @bIsMainContact		bit
Declare @nGenerateNameCode	int
Declare	@nNameCodeLength	int
Declare @nRelatedNameNo		int
Declare @nMainNameNo		int
Declare @nExist			int
Declare @nNameNo		int
Declare	@nTransId		int
Declare @nSequenceNo		int

------------------------------------
-- Variables for trapping any errors
-- raised.
------------------------------------
Declare	@sErrorMessage		nvarchar(max)
Declare	@nErrorSeverity		int
Declare	@nErrorState		int

-- Initialise variables.
Set @nErrorCode = 0

---------------------------------------------------------------------
-- SQA17666
-- Clear out any previous unresolved names for this batch so that we
-- can check if any other batches that have now been through the Name 
-- resolution stage (since this batch was loaded) can be used to help
-- automatically resolve the names.
---------------------------------------------------------------------
set @nRetry=3

While @nRetry>0
and @nErrorCode=0
Begin
	Begin TRY
		-- Start new transaction.
		Set @TransactionCountStart = @@TranCount
		BEGIN TRANSACTION

		-----------------------------------
		-- Update the EDEADDRESSBOOK table 
		-- to clear out references to the
		-- unresolved names and also ensure
		-- NAMESEQUENCENUMBER has a value.
		-----------------------------------
		Set @nTransId     =NULL
		Set @sNameTypeCode=NULL
		
		Set @sSQLString = "
		Update AB
		Set @nSequenceNo      =CASE WHEN(@nTransId=AB.TRANSACTIONIDENTIFIER and @sNameTypeCode=AB.NAMETYPECODE)
					 THEN CASE WHEN(AB.NAMESEQUENCENUMBER IS NOT NULL) THEN @nSequenceNo ELSE @nSequenceNo+1 END
					 ELSE AB1.NAMESEQUENCENUMBER+1
				       END,
		    UNRESOLVEDNAMENO  =NULL, 
		    NAMESEQUENCENUMBER=CASE WHEN(AB.NAMESEQUENCENUMBER IS NOT NULL) THEN AB.NAMESEQUENCENUMBER ELSE @nSequenceNo END,
		    @nTransId         =AB.TRANSACTIONIDENTIFIER,
		    @sNameTypeCode    =AB.NAMETYPECODE		    
		from EDEADDRESSBOOK AB    
		join (select TRANSACTIONIDENTIFIER, NAMETYPECODE, isnull(max(NAMESEQUENCENUMBER),-1) as NAMESEQUENCENUMBER
		      from EDEADDRESSBOOK
		      where BATCHNO=@pnBatchNo
		      group by TRANSACTIONIDENTIFIER, NAMETYPECODE) AB1 on (AB1.TRANSACTIONIDENTIFIER=AB.TRANSACTIONIDENTIFIER
		                                                        and AB1.NAMETYPECODE         =AB.NAMETYPECODE)
		Where AB.BATCHNO=@pnBatchNo
		and(AB.UNRESOLVEDNAMENO is not null
		 OR AB.NAMESEQUENCENUMBER is null)"
		
		Execute @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int,
						  @nTransId		int,
						  @nSequenceNo		int,
						  @sNameTypeCode	nvarchar(50)',
						  @pnBatchNo	=@pnBatchNo,
						  @nTransId	=@nTransId,
						  @nSequenceNo	=@nSequenceNo,
						  @sNameTypeCode=@sNameTypeCode

		If @nErrorCode=0
		Begin
			-----------------------------------
			-- Update the NAMESEQUENCENUMBER  
			-- column if no value exists.
			-----------------------------------
			Set @nTransId     =NULL
			Set @sNameTypeCode=NULL
			
			Set @sSQLString = "
			Update N
			Set @nSequenceNo      =CASE WHEN(@nTransId=N.TRANSACTIONIDENTIFIER and @sNameTypeCode=N.NAMETYPECODE)
						 THEN @nSequenceNo+1
						 ELSE N1.NAMESEQUENCENUMBER+1
					       END,
			    NAMESEQUENCENUMBER=@nSequenceNo,
			    @nTransId         =N.TRANSACTIONIDENTIFIER,
			    @sNameTypeCode    =N.NAMETYPECODE
			From EDENAME N	
			join (select TRANSACTIONIDENTIFIER, NAMETYPECODE, isnull(max(NAMESEQUENCENUMBER),-1) as NAMESEQUENCENUMBER
			      from EDENAME
			      where BATCHNO=@pnBatchNo
			      group by TRANSACTIONIDENTIFIER, NAMETYPECODE) N1 on (N1.TRANSACTIONIDENTIFIER=N.TRANSACTIONIDENTIFIER
									       and N1.NAMETYPECODE         =N.NAMETYPECODE)
			Where N.BATCHNO=@pnBatchNo
			and N.NAMESEQUENCENUMBER is null"
			
			Execute @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @nTransId		int,
							  @nSequenceNo		int,
							  @sNameTypeCode	nvarchar(50)',
							  @pnBatchNo	=@pnBatchNo,
							  @nTransId	=@nTransId,
							  @nSequenceNo	=@nSequenceNo,
							  @sNameTypeCode=@sNameTypeCode
		End

		If @nErrorCode=0
		Begin
			-----------------------------------
			-- Update the NAMESEQUENCENUMBER  
			-- column if no value exists.
			-----------------------------------
			Set @nTransId     =NULL
			Set @sNameTypeCode=NULL
			
			Set @sSQLString = "
			Update F
			Set @nSequenceNo      =CASE WHEN(@nTransId=F.TRANSACTIONIDENTIFIER and @sNameTypeCode=F.NAMETYPECODE)
						 THEN @nSequenceNo+1
						 ELSE F1.NAMESEQUENCENUMBER+1
					       END,
			    NAMESEQUENCENUMBER=@nSequenceNo,
			    @nTransId         =F.TRANSACTIONIDENTIFIER,
			    @sNameTypeCode    =F.NAMETYPECODE
			From EDEFORMATTEDADDRESS F
			join (select TRANSACTIONIDENTIFIER, NAMETYPECODE, isnull(max(NAMESEQUENCENUMBER),-1) as NAMESEQUENCENUMBER
			      from EDEFORMATTEDADDRESS
			      where BATCHNO=@pnBatchNo
			      group by TRANSACTIONIDENTIFIER, NAMETYPECODE) F1 on (F1.TRANSACTIONIDENTIFIER=F.TRANSACTIONIDENTIFIER
									       and F1.NAMETYPECODE         =F.NAMETYPECODE)
			Where F.BATCHNO=@pnBatchNo
			and F.NAMESEQUENCENUMBER is null"
			
			Execute @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @nTransId		int,
							  @nSequenceNo		int,
							  @sNameTypeCode	nvarchar(50)',
							  @pnBatchNo	=@pnBatchNo,
							  @nTransId	=@nTransId,
							  @nSequenceNo	=@nSequenceNo,
							  @sNameTypeCode=@sNameTypeCode
		End	

		If @nErrorCode=0
		Begin
			-----------------------------------
			-- Update the NAMESEQUENCENUMBER  
			-- column if no value exists.
			-----------------------------------
			Set @nTransId     =NULL
			Set @sNameTypeCode=NULL
			
			Set @sSQLString = "
			Update F
			Set @nSequenceNo      =CASE WHEN(@nTransId=F.TRANSACTIONIDENTIFIER and @sNameTypeCode=F.NAMETYPECODE)
						 THEN @nSequenceNo+1
						 ELSE F1.NAMESEQUENCENUMBER+1
					       END,
			    NAMESEQUENCENUMBER=@nSequenceNo,
			    @nTransId         =F.TRANSACTIONIDENTIFIER,
			    @sNameTypeCode    =F.NAMETYPECODE
			From EDEFORMATTEDNAME F
			join (select TRANSACTIONIDENTIFIER, NAMETYPECODE, isnull(max(NAMESEQUENCENUMBER),-1) as NAMESEQUENCENUMBER
			      from EDEFORMATTEDNAME
			      where BATCHNO=@pnBatchNo
			      group by TRANSACTIONIDENTIFIER, NAMETYPECODE) F1 on (F1.TRANSACTIONIDENTIFIER=F.TRANSACTIONIDENTIFIER
									       and F1.NAMETYPECODE         =F.NAMETYPECODE)
			Where F.BATCHNO=@pnBatchNo
			and F.NAMESEQUENCENUMBER is null"
			
			Execute @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @nTransId		int,
							  @nSequenceNo		int,
							  @sNameTypeCode	nvarchar(50)',
							  @pnBatchNo	=@pnBatchNo,
							  @nTransId	=@nTransId,
							  @nSequenceNo	=@nSequenceNo,
							  @sNameTypeCode=@sNameTypeCode
		End	

		If @nErrorCode=0
		Begin
			-----------------------------------
			-- Update the NAMESEQUENCENUMBER  
			-- column if no value exists.
			-----------------------------------
			Set @nTransId     =NULL
			Set @sNameTypeCode=NULL
			
			Set @sSQLString = "
			Update F
			Set @nSequenceNo      =CASE WHEN(@nTransId=F.TRANSACTIONIDENTIFIER and @sNameTypeCode=F.NAMETYPECODE)
						 THEN @nSequenceNo+1
						 ELSE F1.NAMESEQUENCENUMBER+1
					       END,
			    NAMESEQUENCENUMBER=@nSequenceNo,
			    @nTransId         =F.TRANSACTIONIDENTIFIER,
			    @sNameTypeCode    =F.NAMETYPECODE
			From EDECONTACTINFORMATIONDETAILS F
			join (select TRANSACTIONIDENTIFIER, NAMETYPECODE, isnull(max(NAMESEQUENCENUMBER),-1) as NAMESEQUENCENUMBER
			      from EDECONTACTINFORMATIONDETAILS
			      where BATCHNO=@pnBatchNo
			      group by TRANSACTIONIDENTIFIER, NAMETYPECODE) F1 on (F1.TRANSACTIONIDENTIFIER=F.TRANSACTIONIDENTIFIER
									       and F1.NAMETYPECODE         =F.NAMETYPECODE)
			Where F.BATCHNO=@pnBatchNo
			and F.NAMESEQUENCENUMBER is null"
			
			Execute @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @nTransId		int,
							  @nSequenceNo		int,
							  @sNameTypeCode	nvarchar(50)',
							  @pnBatchNo	=@pnBatchNo,
							  @nTransId	=@nTransId,
							  @nSequenceNo	=@nSequenceNo,
							  @sNameTypeCode=@sNameTypeCode
		End

		If @nErrorCode=0
		Begin
			-----------------------------------
			-- Update the NAMESEQUENCENUMBER  
			-- column if no value exists.
			-----------------------------------
			Set @nTransId     =NULL
			Set @sNameTypeCode=NULL
			
			Set @sSQLString = "
			Update F
			Set @nSequenceNo      =CASE WHEN(@nTransId=F.TRANSACTIONIDENTIFIER and @sNameTypeCode=F.NAMETYPECODE)
						 THEN @nSequenceNo+1
						 ELSE F1.NAMESEQUENCENUMBER+1
					       END,
			    NAMESEQUENCENUMBER=@nSequenceNo,
			    @nTransId         =F.TRANSACTIONIDENTIFIER,
			    @sNameTypeCode    =F.NAMETYPECODE
			From EDEFORMATTEDATTNOF F
			join (select TRANSACTIONIDENTIFIER, NAMETYPECODE, isnull(max(NAMESEQUENCENUMBER),-1) as NAMESEQUENCENUMBER
			      from EDEFORMATTEDATTNOF
			      where BATCHNO=@pnBatchNo
			      group by TRANSACTIONIDENTIFIER, NAMETYPECODE) F1 on (F1.TRANSACTIONIDENTIFIER=F.TRANSACTIONIDENTIFIER
									       and F1.NAMETYPECODE         =F.NAMETYPECODE)
			Where F.BATCHNO=@pnBatchNo
			and F.NAMESEQUENCENUMBER is null"
			
			Execute @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @nTransId		int,
							  @nSequenceNo		int,
							  @sNameTypeCode	nvarchar(50)',
							  @pnBatchNo	=@pnBatchNo,
							  @nTransId	=@nTransId,
							  @nSequenceNo	=@nSequenceNo,
							  @sNameTypeCode=@sNameTypeCode
		End

		If @nErrorCode=0
		Begin
			-----------------------------------
			-- Update the NAMESEQUENCENUMBER  
			-- column if no value exists.
			-----------------------------------
			Set @nTransId     =NULL
			Set @sNameTypeCode=NULL
			
			Set @sSQLString = "
			Update CN
			Set @nSequenceNo      =CASE WHEN(@nTransId=CN.TRANSACTIONIDENTIFIER and @sNameTypeCode=CN.NAMETYPECODE)
						 THEN @nSequenceNo+1
						 ELSE CN1.NAMESEQUENCENUMBER+1
					       END,
			    NAMESEQUENCENUMBER=@nSequenceNo,
			    @nTransId         =CN.TRANSACTIONIDENTIFIER,
			    @sNameTypeCode    =CN.NAMETYPECODE
			From EDECASENAMEDETAILS CN
			join (select TRANSACTIONIDENTIFIER, NAMETYPECODE, isnull(max(NAMESEQUENCENUMBER),-1) as NAMESEQUENCENUMBER
			      from EDECASENAMEDETAILS
			      where BATCHNO=@pnBatchNo
			      group by TRANSACTIONIDENTIFIER, NAMETYPECODE) CN1 on (CN1.TRANSACTIONIDENTIFIER=CN.TRANSACTIONIDENTIFIER
									        and CN1.NAMETYPECODE         =CN.NAMETYPECODE)
			Where CN.BATCHNO=@pnBatchNo
			and CN.NAMESEQUENCENUMBER is null"
			
			Execute @nErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @nTransId		int,
							  @nSequenceNo		int,
							  @sNameTypeCode	nvarchar(50)',
							  @pnBatchNo	=@pnBatchNo,
							  @nTransId	=@nTransId,
							  @nSequenceNo	=@nSequenceNo,
							  @sNameTypeCode=@sNameTypeCode
		End	

		If @nErrorCode=0
		Begin
			----------------------------------
			-- Now delete any unresolved names 
			-- existing for this batch
			----------------------------------
			Set @sSQLString="
			Delete EDEUNRESOLVEDNAME
			where BATCHNO=@pnBatchNo"
		
			Execute @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End	

		-- Commit transaction if successful.
		If @@TranCount > @TransactionCountStart
		Begin
			If @nErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
		
		Set @nRetry=-1
	End TRY

	Begin CATCH
		------------------------------------------
		-- If the process has been made the victim
		-- of a deadlock (error 1205), then allow 
		-- another attempt to apply the updates 
		-- to the database up to a retry limit.
		------------------------------------------
		set @nErrorCode=ERROR_NUMBER()
		
		If @nErrorCode=1205
			Set @nRetry=@nRetry-1
		Else 
			Set @nRetry=-1
		
		If @nRetry<0
		Begin
			-- Get error details to propagate to the caller
			Select 	@sErrorMessage = 'Error:' + cast(ERROR_NUMBER() as nvarchar) + ' - ' + ERROR_MESSAGE(),
				@nErrorSeverity = ERROR_SEVERITY(),
				@nErrorState    = ERROR_STATE(),
				@nErrorCode      = ERROR_NUMBER()

			-- Use RAISERROR inside the CATCH block to return error
			-- information about the original error that caused
			-- execution to jump to the CATCH block.
			RAISERROR ( @sErrorMessage,	-- Message text.
				    @nErrorSeverity,	-- Severity.
				    @nErrorState	-- State.
				  )
		End
		
		If XACT_STATE()<>0
			ROLLBACK TRANSACTION
			
	End CATCH
End -- While loop

-- Use the lowest level of locks on the database
set transaction isolation level read uncommitted

If @nErrorCode=0
Begin
	-- Site Control that specifies whether to make the EDE Associated Name the Main Contact.
	Select	@nGenerateNameCode=S1.COLINTEGER,
		@nNameCodeLength  =S2.COLINTEGER,
		@bIsMainContact   =S3.COLBOOLEAN 
	from SITECONTROL S1
	left join SITECONTROL S2 on (S2.CONTROLID = 'NAMECODELENGTH')
	left join SITECONTROL S3 on (S3.CONTROLID = 'EDE Attention as Main Contact')
	where S1.CONTROLID = 'GENERATENAMECODE'
	
	set @nErrorCode=@@error
End
-------------------------------------------------------------------------------------------
-- There may be multiple EDEFORMATTEDADDRESS rows for each transaction and NameType. 
-- Find the first row (with the lowest SEQUENCENUMBER) and then concatenate
-- the ADDRESSLINE columns for each of the subsequent rows for that transaction & nametype
-- and populate the #TEMPADDRESSES table with addresses from this batch.
-------------------------------------------------------------------------------------------
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Insert into #TEMPADDRESSES (BATCHNO, TRANSACTIONIDENTIFIER, NAMETYPECODE, NAMESEQUENCENUMBER, ADDRESSLINE, ADDRESSCITY, ADDRESSSTATE, ADDRESSPOSTCODE, ADDRESSCOUNTRYCODE)
	select	T1.BATCHNO, T1.TRANSACTIONIDENTIFIER, T1.NAMETYPECODE, T1.NAMESEQUENCENUMBER,
		cast(T1.ADDRESSLINE as nvarchar(2000)) + char(13)+char(10) + 
		cast(T2.ADDRESSLINE as nvarchar(2000)) + char(13)+char(10) + 
		cast(T3.ADDRESSLINE as nvarchar(2000)) + char(13)+char(10) + 
		cast(T4.ADDRESSLINE as nvarchar(2000)) + char(13)+char(10) + 
		cast(T5.ADDRESSLINE as nvarchar(2000)) + char(13)+char(10) + 
		cast(T6.ADDRESSLINE as nvarchar(2000)) as ADDRESSLINE, 
		T7.ADDRESSCITY, T7.ADDRESSSTATE, T7.ADDRESSPOSTCODE, T7.ADDRESSCOUNTRYCODE
	from (	select  BATCHNO, TRANSACTIONIDENTIFIER, NAMETYPECODE, NAMESEQUENCENUMBER, MIN(isnull(SEQUENCENUMBER,999)) as SEQ 
		from EDEFORMATTEDADDRESS EFA 
		group by BATCHNO, TRANSACTIONIDENTIFIER, NAMETYPECODE, NAMESEQUENCENUMBER) as MINSEQ 
	join EDEFORMATTEDADDRESS T1		on (MINSEQ.BATCHNO = T1.BATCHNO 
						and T1.TRANSACTIONIDENTIFIER = MINSEQ.TRANSACTIONIDENTIFIER
						and T1.NAMETYPECODE = MINSEQ.NAMETYPECODE
						and T1.NAMESEQUENCENUMBER=MINSEQ.NAMESEQUENCENUMBER
						and(T1.SEQUENCENUMBER = MINSEQ.SEQ or (T1.SEQUENCENUMBER is NULL and MINSEQ.SEQ = 999)))
	left join EDEFORMATTEDADDRESS T2	on (T2.BATCHNO = T1.BATCHNO 
						and T2.TRANSACTIONIDENTIFIER = T1.TRANSACTIONIDENTIFIER
						and T2.NAMETYPECODE = T1.NAMETYPECODE
						and T2.NAMESEQUENCENUMBER=T1.NAMESEQUENCENUMBER
						and T2.SEQUENCENUMBER = MINSEQ.SEQ + 1)
	left join EDEFORMATTEDADDRESS T3	on (T3.BATCHNO = T1.BATCHNO
						and T3.TRANSACTIONIDENTIFIER = T1.TRANSACTIONIDENTIFIER
						and T3.NAMETYPECODE = T1.NAMETYPECODE
						and T3.NAMESEQUENCENUMBER=T1.NAMESEQUENCENUMBER
						and T3.SEQUENCENUMBER = MINSEQ.SEQ + 2)
	left join EDEFORMATTEDADDRESS T4	on (T4.BATCHNO = T1.BATCHNO 
						and T4.TRANSACTIONIDENTIFIER = T1.TRANSACTIONIDENTIFIER
						and T4.NAMETYPECODE = T1.NAMETYPECODE
						and T4.NAMESEQUENCENUMBER=T1.NAMESEQUENCENUMBER
						and T4.SEQUENCENUMBER = MINSEQ.SEQ + 3)
	left join EDEFORMATTEDADDRESS T5	on (T5.BATCHNO = T1.BATCHNO 
						and T5.TRANSACTIONIDENTIFIER = T1.TRANSACTIONIDENTIFIER
						and T5.NAMETYPECODE = T1.NAMETYPECODE
						and T5.NAMESEQUENCENUMBER=T1.NAMESEQUENCENUMBER
						and T5.SEQUENCENUMBER = MINSEQ.SEQ + 4)
	left join EDEFORMATTEDADDRESS T6	on (T6.BATCHNO = T1.BATCHNO 
						and T6.TRANSACTIONIDENTIFIER = T1.TRANSACTIONIDENTIFIER
						and T6.NAMETYPECODE = T1.NAMETYPECODE
						and T6.NAMESEQUENCENUMBER=T1.NAMESEQUENCENUMBER
						and T6.SEQUENCENUMBER = MINSEQ.SEQ + 5)
	left join EDEFORMATTEDADDRESS T7	on (T7.BATCHNO = T1.BATCHNO 
						and T7.TRANSACTIONIDENTIFIER = T1.TRANSACTIONIDENTIFIER 
						and T7.NAMETYPECODE = T1.NAMETYPECODE
						and T7.NAMESEQUENCENUMBER=T1.NAMESEQUENCENUMBER
						and T7.SEQUENCENUMBER is null)
	where T1.BATCHNO = @pnBatchNo"

	Execute @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo 	int',
					  @pnBatchNo	= @pnBatchNo
End

-----------------------------------------
-- Map names and flag unresolved names --
-----------------------------------------
If @nErrorCode = 0
Begin
	-- If the EDEADDRESSBOOK.NAMENO is unknown then attempt to map by checking the
	-- EXTERNALNAME table for the SENDNAMENO and name code supplied (SENDERNAMEIDENTIFIER)
	-- Where no property type is involved then initially only map if no specific 
	-- property type mapping has been supplied in EXTERNALNAMEMAPPING.

	Set @sSQLString = "
	Insert into #TEMPEDEADDRESSBOOK (ROWID, NAMENO, EDENAMETYPE)
	Select distinct EAB.ROWID, EM.INPRONAMENO, EAB.NAMETYPECODE_T
	From EDETRANSACTIONBODY ETB
	join EDENAME EN			on (EN.BATCHNO=ETB.BATCHNO
					and EN.TRANSACTIONIDENTIFIER=ETB.TRANSACTIONIDENTIFIER)
	join EDEADDRESSBOOK EAB		on (EAB.BATCHNO = EN.BATCHNO 
					and EAB.TRANSACTIONIDENTIFIER = EN.TRANSACTIONIDENTIFIER 
					and EAB.NAMETYPECODE = EN.NAMETYPECODE
					and isnull(EAB.NAMESEQUENCENUMBER,99999)=isnull(EN.NAMESEQUENCENUMBER,99999))
	join EDESENDERDETAILS ESD	on (ESD.BATCHNO = EAB.BATCHNO)
	left join #TEMPADDRESSES A 	on (A.BATCHNO = EAB.BATCHNO 
					and A.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
					and A.NAMETYPECODE = EAB.NAMETYPECODE
					and A.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER)
	join EXTERNALNAMEMAPPING EM	on (EM.EXTERNALNAMEID=
						Substring(
						(select max(CASE WHEN(EXN .NAMETYPE     is not null) THEN '1' ELSE '0' END +
							    CASE WHEN(EA.EXTERNALNAMEID is not null) THEN '1' ELSE '0' END +
							    convert(varchar,EXN.EXTERNALNAMEID))
						from EXTERNALNAME EXN
						left join EXTERNALNAMEADDRESS EA
								on (EA.EXTERNALNAMEID = EXN.EXTERNALNAMEID
								and (rtrim(replace(replace(EA.ADDRESS+EA.CITY+EA.STATE+EA.POSTCODE+EA.COUNTRY, char(13), ''), char(10), '')) = rtrim(replace(replace(A.ADDRESSLINE, char(13), ''), char(10), ''))
								  or (  isnull(rtrim(EA.ADDRESS ),'')=isnull(rtrim(A.ADDRESSLINE       ),'')
								    and isnull(rtrim(EA.CITY    ),'')=isnull(rtrim(A.ADDRESSCITY       ),'')
								    and isnull(rtrim(EA.STATE   ),'')=isnull(rtrim(A.ADDRESSSTATE      ),'')
								    and isnull(rtrim(EA.POSTCODE),'')=isnull(rtrim(A.ADDRESSPOSTCODE   ),'')
								    and isnull(rtrim(EA.COUNTRY ),'')=isnull(rtrim(A.ADDRESSCOUNTRYCODE),'') )
									     )
									)
						where EXN.DATASOURCENAMENO=ESD.SENDERNAMENO
						and   EXN.EXTERNALNAMECODE=EN.SENDERNAMEIDENTIFIER
						and  (EXN.NAMETYPE=EAB.NAMETYPECODE_T OR EXN.NAMETYPE is null)
						------------------------------------------------
						-- If the NAMETYPE is Owner and Address has been
						-- supplied then must also match on the Address
						------------------------------------------------
						and (EAB.NAMETYPECODE_T<>'O'
						 or  A.ADDRESSLINE+A.ADDRESSCITY+A.ADDRESSSTATE+A.ADDRESSPOSTCODE+A.ADDRESSCOUNTRYCODE is null
						 or  EA.EXTERNALNAMEID is not null)
						),3,11))	
	left join EDECASEDETAILS ECD	on (ECD.BATCHNO = EN.BATCHNO
					and ECD.TRANSACTIONIDENTIFIER = EN.TRANSACTIONIDENTIFIER)
	where ETB.BATCHNO = @pnBatchNo
	and ETB.TRANSSTATUSCODE in (3420, 3430)
	and EAB.NAMENO is null
	and ECD.CASEPROPERTYTYPECODE_T is null
	------------------------------------------------
	-- Only map if there is just one possible name
	------------------------------------------------
	and 1 = (select count(*)
		 from EXTERNALNAMEMAPPING ENM
		 where ENM.EXTERNALNAMEID=EM.EXTERNALNAMEID)"

	Execute @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo 	int',
					  @pnBatchNo	= @pnBatchNo

	If @nErrorCode=0
	Begin
		---------------------------------------------------------------------------------
		-- INCOMPLETE NEED TO HANDLE INSTRUCTOR TOO !
		-- This will require a separate mapping of Instructor Names first so that the
		-- mapped instructor can then be used in a subsequent mapping to find other names
		-- that are mapped by Instructor.
		---------------------------------------------------------------------------------
		
		-- Use a best fit search to find the mapped name if there are also PropertyTypes involved
		-- as the mapping of names can also be at the Property Type level.
		
		Set @sSQLString = "
		Insert into #TEMPEDEADDRESSBOOK (ROWID, EDENAMETYPE, NAMENO)
		Select	distinct
			EAB.ROWID,
			EAB.NAMETYPECODE_T,
		 (	SELECT 
			convert(int,
			substring(
			max (
			CASE WHEN (EM.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +    			
			CASE WHEN (EM.INSTRUCTORNAMENO IS NULL)	THEN '0' ELSE '1' END +
			convert(varchar,EM.INPRONAMENO)), 3,20))
			FROM EXTERNALNAMEMAPPING EM
			WHERE	EM.EXTERNALNAMEID=EXN1.EXTERNALNAMEID 	
			AND (	EM.PROPERTYTYPE 	= ECD.CASEPROPERTYTYPECODE_T 	OR EM.PROPERTYTYPE 	IS NULL ) 
			-- !!!!!! Note the best fit by instructor has not been implemented at this time
			AND (	EM.INSTRUCTORNAMENO	<> EM.INSTRUCTORNAMENO		OR EM.INSTRUCTORNAMENO	IS NULL ) 
			)
		
		From EDETRANSACTIONBODY ETB
		join EDENAME EN			on (EN.BATCHNO=ETB.BATCHNO
						and EN.TRANSACTIONIDENTIFIER=ETB.TRANSACTIONIDENTIFIER)
		join EDEADDRESSBOOK EAB		on (EAB.BATCHNO = EN.BATCHNO 
						and EAB.TRANSACTIONIDENTIFIER = EN.TRANSACTIONIDENTIFIER 
						and EAB.NAMETYPECODE = EN.NAMETYPECODE
						and isnull(EAB.NAMESEQUENCENUMBER,99999)=isnull(EN.NAMESEQUENCENUMBER,99999))
		join EDESENDERDETAILS ESD	on (ESD.BATCHNO = EAB.BATCHNO)
		left join #TEMPADDRESSES A 	on (A.BATCHNO = EAB.BATCHNO 
						and A.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
						and A.NAMETYPECODE = EAB.NAMETYPECODE
						and A.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER)
		join EXTERNALNAME EXN1		on (EXN1.EXTERNALNAMEID=
						Substring(
						(select max(CASE WHEN(EXN .NAMETYPE     is not null) THEN '1' ELSE '0' END +
							    CASE WHEN(EA.EXTERNALNAMEID is not null) THEN '1' ELSE '0' END +
							    convert(varchar,EXN.EXTERNALNAMEID))
						from EXTERNALNAME EXN
						left join EXTERNALNAMEADDRESS EA
								on (EA.EXTERNALNAMEID = EXN.EXTERNALNAMEID
								and (rtrim(replace(replace(EA.ADDRESS+EA.CITY+EA.STATE+EA.POSTCODE+EA.COUNTRY, char(13), ''), char(10), '')) = rtrim(replace(replace(A.ADDRESSLINE, char(13), ''), char(10), ''))
								  or (  isnull(rtrim(EA.ADDRESS ),'')=isnull(rtrim(A.ADDRESSLINE       ),'')
								    and isnull(rtrim(EA.CITY    ),'')=isnull(rtrim(A.ADDRESSCITY       ),'')
								    and isnull(rtrim(EA.STATE   ),'')=isnull(rtrim(A.ADDRESSSTATE      ),'')
								    and isnull(rtrim(EA.POSTCODE),'')=isnull(rtrim(A.ADDRESSPOSTCODE   ),'')
								    and isnull(rtrim(EA.COUNTRY ),'')=isnull(rtrim(A.ADDRESSCOUNTRYCODE),'') )
									     )
									)
						where EXN.DATASOURCENAMENO=ESD.SENDERNAMENO
						and   EXN.EXTERNALNAMECODE=EN.SENDERNAMEIDENTIFIER
						and  (EXN.NAMETYPE=EAB.NAMETYPECODE_T OR EXN.NAMETYPE is null)
						------------------------------------------------
						-- If the NAMETYPE is Owner and Address has been
						-- supplied then must also match on the Address
						------------------------------------------------
						and (EAB.NAMETYPECODE_T<>'O'
						 or  A.ADDRESSLINE+A.ADDRESSCITY+A.ADDRESSSTATE+A.ADDRESSPOSTCODE+A.ADDRESSCOUNTRYCODE is null
						 or  EA.EXTERNALNAMEID is not null)
						),3,11))	
		join EDECASEDETAILS ECD		on (ECD.BATCHNO = EN.BATCHNO
						and ECD.TRANSACTIONIDENTIFIER = EN.TRANSACTIONIDENTIFIER)
		left join #TEMPEDEADDRESSBOOK T	on (T.ROWID=EAB.ROWID)
		where ETB.BATCHNO = @pnBatchNo
		and ETB.TRANSSTATUSCODE in (3420, 3430)
		and EAB.NAMENO is null
		and ECD.CASEPROPERTYTYPECODE_T is not null
		and T.ROWID is null -- ensure row has not already been inserted"
		
		Execute @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo 	int',
						  @pnBatchNo	= @pnBatchNo
	End
End

If @nErrorCode = 0
Begin
	-------------------------------------------------------------------------------------
	-- Attempt to map the name if the imported record has provided RECEIVERNAMEIDENTIFIER
	-- which is the Inprotech NAMECODE. May need to zero pad this to join on NameCode.
	-------------------------------------------------------------------------------------

	Set @sSQLString = "
	Insert into #TEMPEDEADDRESSBOOK (ROWID, NAMENO, EDENAMETYPE)
	Select Distinct EAB.ROWID, N.NAMENO, EAB.NAMETYPECODE_T 
	from EDETRANSACTIONBODY B	
	join EDEADDRESSBOOK EAB	on (EAB.BATCHNO = B.BATCHNO 
				and EAB.TRANSACTIONIDENTIFIER = B.TRANSACTIONIDENTIFIER)				
	join EDENAME EN		on (EN.BATCHNO = B.BATCHNO 
				and EN.TRANSACTIONIDENTIFIER = B.TRANSACTIONIDENTIFIER
				and EN.NAMETYPECODE = EAB.NAMETYPECODE
				and isnull(EN.NAMESEQUENCENUMBER,99999)=isnull(EAB.NAMESEQUENCENUMBER,99999))
	join [NAME] N		on (N.NAMECODE = CASE WHEN(@nGenerateNameCode=0 or isnumeric(EN.RECEIVERNAMEIDENTIFIER)=0)
							THEN EN.RECEIVERNAMEIDENTIFIER
							ELSE replicate('0', @nNameCodeLength - len(EN.RECEIVERNAMEIDENTIFIER)) + EN.RECEIVERNAMEIDENTIFIER
						 END)
	left join #TEMPEDEADDRESSBOOK T	on (T.ROWID=EAB.ROWID)
	where B.BATCHNO = @pnBatchNo
	and B.TRANSSTATUSCODE in (3420, 3430)
	and EAB.NAMENO is null
	and T.ROWID    is null"

	Execute @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo 		int,
					  @nGenerateNameCode	int,
					  @nNameCodeLength	int',
					  @pnBatchNo		=@pnBatchNo,
					  @nGenerateNameCode	=@nGenerateNameCode,
					  @nNameCodeLength	=@nNameCodeLength
End

If @nErrorCode = 0
Begin
	-------------------------------------------------------------------------------------
	-- At this point there are mappings based on name codes already done. 
	-- These are held in #TEMPEDEADDRESSBOOK.
	-- If any of the names with a SENDERNAMEIDENTIFIER or a RECEIVERNAMEIDENTIFIER value 
	-- has not been mapped yet and has no details at all we flag them as MISSINGDETAILS.
	-------------------------------------------------------------------------------------

	Set @sSQLString = "
	Insert into #TEMPEDEADDRESSBOOK (ROWID, MISSINGNAMEDETAILS, EDENAMETYPE)
	select Distinct EAB.ROWID, 1, EAB.NAMETYPECODE_T
	from EDETRANSACTIONBODY B	
	join EDEADDRESSBOOK EAB	on (EAB.BATCHNO = B.BATCHNO 
				and EAB.TRANSACTIONIDENTIFIER = B.TRANSACTIONIDENTIFIER)				
	join EDENAME EN		on (EN.BATCHNO = B.BATCHNO 
				and EN.TRANSACTIONIDENTIFIER = B.TRANSACTIONIDENTIFIER
				and EN.NAMETYPECODE = EAB.NAMETYPECODE
				and isnull(EN.NAMESEQUENCENUMBER,99999)=isnull(EAB.NAMESEQUENCENUMBER,99999))
	left join #TEMPEDEADDRESSBOOK T	on (T.ROWID=EAB.ROWID)
				    
	left join EDEFORMATTEDNAME EFN	on (EFN.BATCHNO = B.BATCHNO 
					and EFN.TRANSACTIONIDENTIFIER = B.TRANSACTIONIDENTIFIER 
					and EFN.NAMETYPECODE = EAB.NAMETYPECODE
					and isnull(EFN.NAMESEQUENCENUMBER,99999)=isnull(EAB.NAMESEQUENCENUMBER,99999))
	where B.BATCHNO = @pnBatchNo
	and B.TRANSSTATUSCODE in (3420, 3430)
	and EAB.NAMENO is null
	and T.ROWID    is null
	and (EN.SENDERNAMEIDENTIFIER is not null or EN.RECEIVERNAMEIDENTIFIER is not null)	
	and EFN.LASTNAME is null 
	and EFN.ORGANIZATIONNAME is null"

	Execute @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo 	int',
					  @pnBatchNo	= @pnBatchNo
End

If @nErrorCode = 0
Begin
	-- Map EDE Name using name details that has been previously stored in inprotech.
	-- This has to be an exact match on the Name, Phone, Fax, Address, City, State, Postcode and Country.

	Set @sSQLString = "
	Insert into #TEMPEDEADDRESSBOOK (ROWID, NAMENO, EDENAMETYPE)
	Select Distinct EAB.ROWID, ENM.INPRONAMENO, EAB.NAMETYPECODE_T
	from EDETRANSACTIONBODY B	
	join EDEADDRESSBOOK EAB	on (EAB.BATCHNO = B.BATCHNO 
				and EAB.TRANSACTIONIDENTIFIER = B.TRANSACTIONIDENTIFIER)				
	join EDENAME EN		on (EN.BATCHNO = B.BATCHNO 
				and EN.TRANSACTIONIDENTIFIER = B.TRANSACTIONIDENTIFIER
				and EN.NAMETYPECODE = EAB.NAMETYPECODE
				and isnull(EN.NAMESEQUENCENUMBER,99999)=isnull(EAB.NAMESEQUENCENUMBER,99999))
	left join #TEMPEDEADDRESSBOOK T	on (T.ROWID=EAB.ROWID)	
	join EDESENDERDETAILS ESD	
				on (ESD.BATCHNO = EAB.BATCHNO)
	join EDEFORMATTEDNAME EFN	
				on (EFN.BATCHNO = EAB.BATCHNO 
				and EFN.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER 
				and EFN.NAMETYPECODE = EAB.NAMETYPECODE
				and isnull(EFN.NAMESEQUENCENUMBER,99999)=isnull(EAB.NAMESEQUENCENUMBER,99999))
	left join EDECONTACTINFORMATIONDETAILS ECD 
				on (ECD.BATCHNO = EAB.BATCHNO 
				and ECD.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
				and ECD.NAMETYPECODE = EAB.NAMETYPECODE
				and isnull(ECD.NAMESEQUENCENUMBER,99999)=isnull(EAB.NAMESEQUENCENUMBER,99999))
	left join #TEMPADDRESSES A 
				on (A.BATCHNO = EAB.BATCHNO 
				and A.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
				and A.NAMETYPECODE = EAB.NAMETYPECODE
				and A.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER)
	join EXTERNALNAMEMAPPING ENM	on (ENM.EXTERNALNAMEID=
						Substring(
						(select max(CASE WHEN(EXN .NAMETYPE     is not null) THEN '1' ELSE '0' END +
							    CASE WHEN(EA.EXTERNALNAMEID is not null) THEN '1' ELSE '0' END +
							    convert(varchar,EXN.EXTERNALNAMEID))
						 from EXTERNALNAME EXN
						 left join EXTERNALNAMEADDRESS EA 
									on (EA.EXTERNALNAMEID = EXN.EXTERNALNAMEID
									and (rtrim(replace(replace(EA.ADDRESS+EA.CITY+EA.STATE+EA.POSTCODE+EA.COUNTRY, char(13), ''), char(10), '')) = rtrim(replace(replace(A.ADDRESSLINE, char(13), ''), char(10), ''))
									  or (  isnull(rtrim(EA.ADDRESS ),'')=isnull(rtrim(A.ADDRESSLINE       ),'')
									    and isnull(rtrim(EA.CITY    ),'')=isnull(rtrim(A.ADDRESSCITY       ),'')
									    and isnull(rtrim(EA.STATE   ),'')=isnull(rtrim(A.ADDRESSSTATE      ),'')
									    and isnull(rtrim(EA.POSTCODE),'')=isnull(rtrim(A.ADDRESSPOSTCODE   ),'')
									    and isnull(rtrim(EA.COUNTRY ),'')=isnull(rtrim(A.ADDRESSCOUNTRYCODE),'') )
										     )
										)
						where EXN.DATASOURCENAMENO=ESD.SENDERNAMENO
						and EXN.EXTERNALNAME = isnull(EFN.LASTNAME, EFN.ORGANIZATIONNAME)
						and(EXN.FIRSTNAME = EFN.FIRSTNAME OR (isnull(rtrim(EXN.FIRSTNAME),'')='' and isnull(rtrim(EFN.FIRSTNAME),'')=''))
						and(EXN.PHONE     = ECD.PHONE     OR (isnull(rtrim(EXN.PHONE),'')    ='' and isnull(rtrim(ECD.PHONE),'')    =''))
						and(EXN.FAX       = ECD.FAX       OR (isnull(rtrim(EXN.FAX),'')      ='' and isnull(rtrim(ECD.FAX),'')      =''))
						and(EXN.EMAIL     = ECD.EMAIL     OR (isnull(rtrim(EXN.EMAIL),'')    ='' and isnull(rtrim(ECD.EMAIL),'')    =''))
						and(EXN.NAMETYPE=EAB.NAMETYPECODE_T OR EXN.NAMETYPE is null)
						------------------------------------------------
						-- RFC46262
						-- If the NAMETYPE is Owner and Address has been
						-- supplied then must also match on the Address
						------------------------------------------------
						and (EAB.NAMETYPECODE_T<>'O'
						 or  A.ADDRESSLINE+A.ADDRESSCITY+A.ADDRESSSTATE+A.ADDRESSPOSTCODE+A.ADDRESSCOUNTRYCODE is null
						 or  EA.EXTERNALNAMEID is not null)
						),3,11))	      
	where B.BATCHNO = @pnBatchNo
	and B.TRANSSTATUSCODE in (3420, 3430)
	and EN.SENDERNAMEIDENTIFIER is null -- SQA18022 Names with SENDERNAMEIDENTIFIER should have already been mapped
	and EAB.NAMENO is null
	and T.ROWID    is null"

	Execute @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo 	int',
					  @pnBatchNo	= @pnBatchNo
End

If @nErrorCode = 0
Begin
	--------------------------------------------------------------------------------
	-- If it is a 'Name Import' transaction then ALWAYS create an Unresolved Name. 
	-- TRANSACTIONCODE and TRANSACTIONSUBCODE are not used.
	--------------------------------------------------------------------------------

	Set @sSQLString = "
	Insert into #TEMPUNRESOLVEDNAME(BATCHNO, TRANSACTIONIDENTIFIER, TRANSACTIONCODE, TRANSACTIONSUBCODE, NAMETYPE, NAMESEQUENCENUMBER,
					SENDERNAMEIDENTIFIER, ENTITYTYPEFLAG, TITLE, FIRSTNAME, [NAME], INITIALS, GENDER, 
					ADDRESSLINE, CITY, STATE, POSTCODE, COUNTRYCODE, PHONE, FAX, EMAIL, ATTNTITLE, ATTNFIRSTNAME, ATTNLASTNAME)
	select	EAB.BATCHNO, 
		EAB.TRANSACTIONIDENTIFIER, 
		null, 
		null, 
		EAB.NAMETYPECODE_T,
		EAB.NAMESEQUENCENUMBER,
		EN.SENDERNAMEIDENTIFIER,  
		case when EFN.LASTNAME is not null then 1 else 0 end,
		EFN.NAMEPREFIX, 
		EFN.FIRSTNAME, 
		isnull(EFN.LASTNAME, EFN.ORGANIZATIONNAME), 
		null, 
		EFN.GENDER_T, 
		ADDRESS.ADDRESSLINE, 
		ADDRESS.ADDRESSCITY, 
		ADDRESS.ADDRESSSTATE, 
		ADDRESS.ADDRESSPOSTCODE, 
		ADDRESS.ADDRESSCOUNTRYCODE, 
		ECD.PHONE, 
		ECD.FAX, 
		ECD.EMAIL, 
		EFO.NAMEPREFIX, 
		EFO.FIRSTNAME, 
		EFO.LASTNAME
	from EDETRANSACTIONBODY B
	join EDETRANSACTIONCONTENTDETAILS ETD
				on (ETD.BATCHNO = B.BATCHNO 
				and ETD.TRANSACTIONIDENTIFIER = B.TRANSACTIONIDENTIFIER)	
	join EDEADDRESSBOOK EAB	on (EAB.BATCHNO = B.BATCHNO 
				and EAB.TRANSACTIONIDENTIFIER = B.TRANSACTIONIDENTIFIER)				
	join EDENAME EN		on (EN.BATCHNO = B.BATCHNO 
				and EN.TRANSACTIONIDENTIFIER = B.TRANSACTIONIDENTIFIER
				and EN.NAMETYPECODE = EAB.NAMETYPECODE
				and isnull(EN.NAMESEQUENCENUMBER,99999)=isnull(EAB.NAMESEQUENCENUMBER,99999))
	left join EDEFORMATTEDNAME EFN 
				on (EFN.BATCHNO = EAB.BATCHNO 
				and EFN.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER 
				and EFN.NAMETYPECODE = EAB.NAMETYPECODE
				and EFN.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER)
	left join EDECONTACTINFORMATIONDETAILS ECD 
				on (ECD.BATCHNO = EAB.BATCHNO 
				and ECD.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
				and ECD.NAMETYPECODE = EAB.NAMETYPECODE
				and ECD.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER)
	left join #TEMPADDRESSES ADDRESS 
				on (ADDRESS.BATCHNO = EAB.BATCHNO 
				and ADDRESS.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
				and ADDRESS.NAMETYPECODE = EAB.NAMETYPECODE
				and ADDRESS.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER)
	left join EDEFORMATTEDATTNOF EFO 
				on (EFO.BATCHNO = EAB.BATCHNO 
				and EFO.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER 
				and EFO.NAMETYPECODE = EAB.NAMETYPECODE
				and EFO.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER)
	where B.BATCHNO = @pnBatchNo
	and B.TRANSSTATUSCODE in (3420, 3430)
	and EAB.UNRESOLVEDNAMENO is null
	and ETD.TRANSACTIONCODE = 'Name Import'"

	Execute @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo 	int',
					  @pnBatchNo	= @pnBatchNo
End	
 
If @nErrorCode=0
Begin
	-----------------------------------------------------------------------
	-- A SENDERNAMEIDENTIFIER name code match has been found, but there is 
	-- a change identified against what has been stored in the EXTERNALNAME 
	-- related tables. We must add a row to the UNRESOLVEDNAME table for
	-- these names.
	-- Disregard Name Imports as all have been accounted for above.
	-- TRANSACTIONIDENITFIER is not used as multiple transaction might 
	-- be referring to the Name.
	-----------------------------------------------------------------------
	Set @sSQLString = "
	Insert into #TEMPUNRESOLVEDNAME(BATCHNO, TRANSACTIONIDENTIFIER, TRANSACTIONCODE, TRANSACTIONSUBCODE, NAMETYPE, NAMESEQUENCENUMBER,
					SENDERNAMEIDENTIFIER, ENTITYTYPEFLAG, TITLE, FIRSTNAME, [NAME], INITIALS, GENDER, 
					ADDRESSLINE, CITY, STATE, POSTCODE, COUNTRYCODE, PHONE, FAX, EMAIL, ATTNTITLE, ATTNFIRSTNAME, ATTNLASTNAME)
	select	distinct 
		EAB.BATCHNO,null,null,null,EAB.NAMETYPECODE_T, EAB.NAMESEQUENCENUMBER, EN.SENDERNAMEIDENTIFIER, 
		case when EFN.LASTNAME is not null then 1 else 0 end,
		EFN.NAMEPREFIX,EFN.FIRSTNAME,isnull(EFN.LASTNAME, EFN.ORGANIZATIONNAME),null,EFN.GENDER_T,A.ADDRESSLINE, 
		A.ADDRESSCITY,A.ADDRESSSTATE,A.ADDRESSPOSTCODE,A.ADDRESSCOUNTRYCODE,ECD.PHONE,ECD.FAX,ECD.EMAIL,EFO.NAMEPREFIX,EFO.FIRSTNAME,EFO.LASTNAME
	from EDETRANSACTIONBODY B
	join EDETRANSACTIONCONTENTDETAILS ETD
				on (ETD.BATCHNO = B.BATCHNO 
				and ETD.TRANSACTIONIDENTIFIER = B.TRANSACTIONIDENTIFIER)	
	join EDEADDRESSBOOK EAB	on (EAB.BATCHNO = B.BATCHNO 
				and EAB.TRANSACTIONIDENTIFIER = B.TRANSACTIONIDENTIFIER)				
	join EDENAME EN		on (EN.BATCHNO = B.BATCHNO 
				and EN.TRANSACTIONIDENTIFIER = B.TRANSACTIONIDENTIFIER
				and EN.NAMETYPECODE = EAB.NAMETYPECODE
				and isnull(EN.NAMESEQUENCENUMBER,99999)=isnull(EAB.NAMESEQUENCENUMBER,99999))
	left join #TEMPEDEADDRESSBOOK TA
				on (TA.ROWID=EAB.ROWID)	
	left join EDEFORMATTEDNAME EFN 
				on (EFN.BATCHNO = EAB.BATCHNO 
				and EFN.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER 
				and EFN.NAMETYPECODE = EAB.NAMETYPECODE
				and EFN.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER)
	left join EDECONTACTINFORMATIONDETAILS ECD 
				on (ECD.BATCHNO = EAB.BATCHNO 
				and ECD.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
				and ECD.NAMETYPECODE = EAB.NAMETYPECODE
				and ECD.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER)
	left join #TEMPADDRESSES A 
				on (A.BATCHNO = EAB.BATCHNO 
				and A.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
				and A.NAMETYPECODE = EAB.NAMETYPECODE
				and A.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER)
	left join EDEFORMATTEDATTNOF EFO 
				on (EFO.BATCHNO = EAB.BATCHNO 
				and EFO.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER 
				and EFO.NAMETYPECODE = EAB.NAMETYPECODE
				and EFO.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER)
	join EDESENDERDETAILS ESD 
				on (ESD.BATCHNO = EAB.BATCHNO)
	join EXTERNALNAME EXN	on (EXN.DATASOURCENAMENO = ESD.SENDERNAMENO
				and EXN.EXTERNALNAMECODE = EN.SENDERNAMEIDENTIFIER
				and isnull(EXN.NAMETYPE,'')+convert(varchar,EXN.EXTERNALNAMEID)
							=(	select max(isnull(EXN1.NAMETYPE,'')+convert(varchar,EXN1.EXTERNALNAMEID))
								from EXTERNALNAME EXN1
								where EXN1.DATASOURCENAMENO=EXN.DATASOURCENAMENO
								and EXN1.EXTERNALNAMECODE=EXN.EXTERNALNAMECODE
								and (EXN1.NAMETYPE=EAB.NAMETYPECODE_T OR EXN1.NAMETYPE is null)))
	left join EXTERNALNAMEADDRESS EA 
				on (EA.EXTERNALNAMEID = EXN.EXTERNALNAMEID)
	where B.BATCHNO = @pnBatchNo
	and B.TRANSSTATUSCODE in (3420, 3430)
	and ETD.TRANSACTIONCODE <> 'Name Import'
	and isnull(EAB.NAMENO,TA.NAMENO) is not null
	and isnull(EAB.MISSINGNAMEDETAILS,0)<>1
	and isnull( TA.MISSINGNAMEDETAILS,0)<>1
	and EAB.UNRESOLVEDNAMENO is null

	and ( 	A.ADDRESSLINE+A.ADDRESSCITY+A.ADDRESSSTATE+A.ADDRESSPOSTCODE+A.ADDRESSCOUNTRYCODE is null
	 OR  ( NOT (isnull(rtrim(replace(replace(EA.ADDRESS,    char(13), ''), char(10), '')),'') =
		    isnull(rtrim(replace(replace(A.ADDRESSLINE, char(13), ''), char(10), '')),'') AND
		    isnull(rtrim(EA.CITY),'')	 = isnull(rtrim(A.ADDRESSCITY),'')		  AND
		    isnull(rtrim(EA.STATE),'')	 = isnull(rtrim(A.ADDRESSSTATE),'')		  AND
		    isnull(rtrim(EA.POSTCODE),'')= isnull(rtrim(A.ADDRESSPOSTCODE),'')		  AND
		    isnull(rtrim(EA.COUNTRY),'') = isnull(rtrim(A.ADDRESSCOUNTRYCODE),'')
		   )
	     ) 
	    )
		
	and NOT(EXN.EXTERNALNAME		= isnull(EFN.LASTNAME, EFN.ORGANIZATIONNAME)	AND
		isnull(rtrim(EXN.FIRSTNAME),'')	= isnull(rtrim(EFN.FIRSTNAME),'')		AND
		isnull(rtrim(EXN.PHONE),'')	= isnull(rtrim(ECD.PHONE),'')			AND
		isnull(rtrim(EXN.FAX),'')	= isnull(rtrim(ECD.FAX),'')			AND
		isnull(rtrim(EXN.EMAIL),'')	= isnull(rtrim(ECD.EMAIL),'')
		)"

	Execute @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo 	int',
					  @pnBatchNo	= @pnBatchNo
End 

If @nErrorCode = 0
Begin
	------------------------------------
	-- No name mappings have been found. 
	-- Look for a name in Inprotech that 
	-- matches exactly.
	------------------------------------

	Set @sSQLString = "
	Insert into #TEMPEDEADDRESSBOOK (ROWID, NAMENO, EDENAMETYPE)
	Select Distinct EAB.ROWID, N.NAMENO, EAB.NAMETYPECODE_T
	from EDETRANSACTIONBODY B	
	join EDENAME EN		on (EN.BATCHNO                = B.BATCHNO 
				and EN.TRANSACTIONIDENTIFIER  = B.TRANSACTIONIDENTIFIER)
	join EDEADDRESSBOOK EAB	on (EAB.BATCHNO               = B.BATCHNO 
				and EAB.TRANSACTIONIDENTIFIER = B.TRANSACTIONIDENTIFIER
				and EAB.NAMETYPECODE          =EN.NAMETYPECODE
				and isnull(EAB.NAMESEQUENCENUMBER,99999)=isnull(EN.NAMESEQUENCENUMBER,99999))
	left join #TEMPEDEADDRESSBOOK T	
				on (T.ROWID=EAB.ROWID)
	left join #TEMPADDRESSES TA	
				on (TA.BATCHNO               = EAB.BATCHNO 
				and TA.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
				and TA.NAMETYPECODE          = EAB.NAMETYPECODE
				and TA.NAMESEQUENCENUMBER    = EAB.NAMESEQUENCENUMBER)
	join EDEFORMATTEDNAME EFN 
				on (EFN.BATCHNO               = EAB.BATCHNO
				and EFN.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
				and EFN.NAMETYPECODE          = EAB.NAMETYPECODE
				and EFN.NAMESEQUENCENUMBER    = EAB.NAMESEQUENCENUMBER)
	-- Attempt exact match on Name				
	join [NAME] N		on (N.NAME=isnull(EFN.LASTNAME, EFN.ORGANIZATIONNAME)
				and(N.FIRSTNAME=EFN.FIRSTNAME OR (N.FIRSTNAME is null and EFN.FIRSTNAME is null))) 
	left join ADDRESS A	on (A.ADDRESSCODE = N.POSTALADDRESS)
	left join EDECONTACTINFORMATIONDETAILS ECD
				on (ECD.BATCHNO               = EAB.BATCHNO 
				and ECD.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
				and ECD.NAMETYPECODE          = EAB.NAMETYPECODE
				and ECD.NAMESEQUENCENUMBER    = EAB.NAMESEQUENCENUMBER)
	left join NAMETELECOM NT	on (NT.NAMENO = N.NAMENO)
	left join TELECOMMUNICATION T1	on (T1.TELECODE = NT.TELECODE 
					and T1.TELECOMTYPE = 1901
					and T1.TELECOMNUMBER=ECD.PHONE)
	left join TELECOMMUNICATION T2	on (T2.TELECODE = NT.TELECODE 
					and T2.TELECOMTYPE = 1902
					and T2.TELECOMNUMBER=ECD.FAX)
	left join TELECOMMUNICATION T3	on (T3.TELECODE = NT.TELECODE 
					and T3.TELECOMTYPE = 1903
					and T3.TELECOMNUMBER=ECD.EMAIL)
	where B.BATCHNO = @pnBatchNo
	and B.TRANSSTATUSCODE in (3420, 3430)
	and EN.SENDERNAMEIDENTIFIER is null -- SQA18022 ignore unmapped names that have a SENDERNAMEIDENTIFIER supplied
	and EAB.NAMENO is null
	-- has not been flagged as missing name details
	and isnull(EAB.MISSINGNAMEDETAILS,0)<>1
	-- no previous row inserted into #TEMPEDEADDRESSBOOK
	and T.ROWID is null
	-- Match on Address if supplied
	and (rtrim(replace(replace(TA.ADDRESSLINE,char(13),''),char(10),'')) = rtrim(replace(replace(A.STREET1+A.STREET2+A.CITY+A.STATE,char(13),''),char(10),''))
	  OR TA.ADDRESSLINE is null) -- SQA18021 only match on Address if EDE has provided one
	-- Only match on PHONE, FAX & EMAIL if they have been supplied
	and (T1.TELECODE is not null OR ECD.PHONE is null)
	and (T2.TELECODE is not null OR ECD.FAX   is null)
	and (T2.TELECODE is not null OR ECD.EMAIL is null)"

	Execute @nErrorCode = sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo		= @pnBatchNo
End

If @nErrorCode = 0
Begin
	------------------------------------
	-- SQA18021
	-- If multiple Names have been found 
	-- to match the imported name then
	-- remove these matches so that an
	-- unresolved name is created. This
	-- will force the operator to make 
	-- a decision as to how to map the
	-- Name.
	------------------------------------

	Set @sSQLString = "
	Delete T
	from #TEMPEDEADDRESSBOOK T
	join (select ROWID
	      from #TEMPEDEADDRESSBOOK
	      where NAMENO is not null
	      group by ROWID
	      having count(*)>1) T1 on (T1.ROWID=T.ROWID)"

	exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	------------------------------------
	-- SQA17662
	-- If any of the proposed mappings 
	-- involve Inprotech Names that have  
	-- NAMETYPECLASSIFICATION settings that
	-- prevent them from being used as the
	-- Name Type associated with the imported name 
	-- then remove these matches so that an
	-- unresolved name is created. This
	-- will force the operator to make 
	-- a decision as to how to map the
	-- Name.
	------------------------------------

	Set @sSQLString = "
		      
	Delete TA		
	from #TEMPEDEADDRESSBOOK TA
	join NAMETYPE NT on (NT.NAMETYPE=TA.EDENAMETYPE)
	join NAMETYPECLASSIFICATION NTC	on (NTC.NAMENO = TA.NAMENO
					and NTC.NAMETYPE=TA.EDENAMETYPE
					and NTC.ALLOW=0)
	where (NT.PICKLISTFLAGS&16=16)"

	exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode=0
Begin
	-----------------------------------------------------------------------
	-- At this point if the EDEADDRESSBOOK has not been mapped to a NAMENO
	-- or marked as an UNRESOLVEDNAMENO then we have exhausted our ability
	-- to find a matching name. These names should then me marked as being
	-- unresolved.
	-- Ignore Name Import transactions as these have already been handled.
	-----------------------------------------------------------------------

	Set @sSQLString = "
	Insert into #TEMPUNRESOLVEDNAME(BATCHNO, TRANSACTIONIDENTIFIER, TRANSACTIONCODE, TRANSACTIONSUBCODE, NAMETYPE, NAMESEQUENCENUMBER,
					SENDERNAMEIDENTIFIER, ENTITYTYPEFLAG, TITLE, FIRSTNAME, [NAME], INITIALS, GENDER, 
					ADDRESSLINE, CITY, STATE, POSTCODE, COUNTRYCODE, PHONE, FAX, EMAIL, ATTNTITLE, ATTNFIRSTNAME, ATTNLASTNAME)
	select	distinct 
		EAB.BATCHNO, 
		null,null,null, 
		EAB.NAMETYPECODE_T,EAB.NAMESEQUENCENUMBER, EN.SENDERNAMEIDENTIFIER, 
		case when EFN.LASTNAME is not null then 1 else 0 end,
		EFN.NAMEPREFIX,EFN.FIRSTNAME,isnull(EFN.LASTNAME, EFN.ORGANIZATIONNAME),
		null, 
		EFN.GENDER_T,A.ADDRESSLINE,A.ADDRESSCITY,A.ADDRESSSTATE,A.ADDRESSPOSTCODE,A.ADDRESSCOUNTRYCODE,
		ECD.PHONE,ECD.FAX,ECD.EMAIL,EFO.NAMEPREFIX,EFO.FIRSTNAME,EFO.LASTNAME
	from EDETRANSACTIONBODY B
	join EDETRANSACTIONCONTENTDETAILS ETD
				on (ETD.BATCHNO               = B.BATCHNO 
				and ETD.TRANSACTIONIDENTIFIER = B.TRANSACTIONIDENTIFIER)	
	join EDEADDRESSBOOK EAB	on (EAB.BATCHNO               = B.BATCHNO 
				and EAB.TRANSACTIONIDENTIFIER = B.TRANSACTIONIDENTIFIER)				
	join EDENAME EN		on (EN.BATCHNO                = B.BATCHNO 
				and EN.TRANSACTIONIDENTIFIER  = B.TRANSACTIONIDENTIFIER
				and EN.NAMETYPECODE           = EAB.NAMETYPECODE
				and EN.NAMESEQUENCENUMBER     = EAB.NAMESEQUENCENUMBER)
	left join #TEMPEDEADDRESSBOOK TA
				on (TA.ROWID=EAB.ROWID)
	left join EDEFORMATTEDNAME EFN
				on (EFN.BATCHNO               = EAB.BATCHNO 
				and EFN.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER 
				and EFN.NAMETYPECODE          = EAB.NAMETYPECODE
				and EFN.NAMESEQUENCENUMBER    = EAB.NAMESEQUENCENUMBER)
	left join EDECONTACTINFORMATIONDETAILS ECD 
				on (ECD.BATCHNO               = EAB.BATCHNO 
				and ECD.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
				and ECD.NAMETYPECODE          = EAB.NAMETYPECODE
				and ECD.NAMESEQUENCENUMBER    = EAB.NAMESEQUENCENUMBER)
	left join #TEMPADDRESSES A 
				on (A.BATCHNO               = EAB.BATCHNO 
				and A.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
				and A.NAMETYPECODE          = EAB.NAMETYPECODE
				and A.NAMESEQUENCENUMBER    = EAB.NAMESEQUENCENUMBER)
	left join EDEFORMATTEDATTNOF EFO 
				on (EFO.BATCHNO               = EAB.BATCHNO 
				and EFO.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER 
				and EFO.NAMETYPECODE          = EAB.NAMETYPECODE
				and EFO.NAMESEQUENCENUMBER    = EAB.NAMESEQUENCENUMBER)
	-- check for an existing unresolved name
	left join #TEMPUNRESOLVEDNAME TU			
				on (TU.BATCHNO=EAB.BATCHNO
				and TU.TRANSACTIONIDENTIFIER is null
				and TU.NAMETYPE=EAB.NAMETYPECODE_T
				and TU.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER
				and TU.SENDERNAMEIDENTIFIER= EN.SENDERNAMEIDENTIFIER
				and TU.[NAME]              = isnull(EFN.LASTNAME, EFN.ORGANIZATIONNAME)
				and isnull(rtrim(TU.TITLE),'')	       = isnull(rtrim(EFN.NAMEPREFIX),'')
				and isnull(rtrim(TU.FIRSTNAME),'')     = isnull(rtrim(EFN.FIRSTNAME),'')
				and isnull(rtrim(TU.GENDER),'')        = isnull(rtrim(EFN.GENDER_T),'')
				and isnull(rtrim(TU.ADDRESSLINE),'')   = isnull(rtrim(A.ADDRESSLINE),'')
				and isnull(rtrim(TU.CITY),'')          = isnull(rtrim(A.ADDRESSCITY),'')
				and isnull(rtrim(TU.STATE),'')         = isnull(rtrim(A.ADDRESSSTATE),'')
				and isnull(rtrim(TU.POSTCODE),'')      = isnull(rtrim(A.ADDRESSPOSTCODE),'')
				and isnull(rtrim(TU.COUNTRYCODE),'')   = isnull(rtrim(A.ADDRESSCOUNTRYCODE),'')
				and isnull(rtrim(TU.PHONE),'')         = isnull(rtrim(ECD.PHONE),'')
				and isnull(rtrim(TU.FAX),'')           = isnull(rtrim(ECD.FAX),'')
				and isnull(rtrim(TU.EMAIL),'')         = isnull(rtrim(ECD.EMAIL),'')
				and isnull(rtrim(TU.ATTNTITLE),'')     = isnull(rtrim(EFO.NAMEPREFIX),'')
				and isnull(rtrim(TU.ATTNFIRSTNAME),'') = isnull(rtrim(EFO.FIRSTNAME),'')
				and isnull(rtrim(TU.ATTNLASTNAME),'')  = isnull(rtrim(EFO.LASTNAME),'')
				  )
	where B.BATCHNO = @pnBatchNo
	and B.TRANSSTATUSCODE in (3420, 3430)
	and TU.BATCHNO is null				-- Unresolved name not already inserted
	and EAB.UNRESOLVEDNAMENO is null
	and isnull(EAB.NAMENO,TA.NAMENO) is null	-- The name has NOT already been mapped
	and isnull(EAB.MISSINGNAMEDETAILS,0)<>1		-- Not flagged as having missing name details
	and isnull( TA.MISSINGNAMEDETAILS,0)<>1
	and ETD.TRANSACTIONCODE <> 'Name Import'"

	Execute @nErrorCode = sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo		= @pnBatchNo
End

--==========================================================================
--
-- A P P L Y   C H A N G E S   T O   L I V E   D A T A B A S E   T A B L E S
--
--==========================================================================	
Set @nRetry=3

While @nRetry>0
and @nErrorCode=0
Begin
	BEGIN TRY
		-- Start new transaction.
		Set @TransactionCountStart = @@TranCount
		BEGIN TRANSACTION

		-----------------------------------
		-- Update the EDEADDRESSBOOK table 
		-- with results of mapping
		-----------------------------------	
		Set @sSQLString = "
		Update EAB
		Set	NAMENO=T.NAMENO,
			MISSINGNAMEDETAILS=T.MISSINGNAMEDETAILS
		from EDEADDRESSBOOK EAB
		join #TEMPEDEADDRESSBOOK T on (T.ROWID=EAB.ROWID)"
		
		Execute @nErrorCode=sp_executesql @sSQLString
		

		-- Commit transaction if successful.
		If @@TranCount > @TransactionCountStart
		Begin
			If @nErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	
		If @nErrorCode=0
		Begin
			-- Start new transaction.
			Set @TransactionCountStart = @@TranCount
			BEGIN TRANSACTION
			
			-----------------------------------
			-- Load the EDEUNRESOLVEDNAME table 
			-- from the temporary table
			-----------------------------------
			Set @sSQLString = "
			Insert into EDEUNRESOLVEDNAME
				(BATCHNO, TRANSACTIONIDENTIFIER, TRANSACTIONCODE, TRANSACTIONSUBCODE, NAMETYPE, 
				 SENDERNAMEIDENTIFIER, ENTITYTYPEFLAG, TITLE, FIRSTNAME, [NAME], INITIALS, GENDER, 
				 ADDRESSLINE, CITY, STATE, POSTCODE, COUNTRYCODE, PHONE, FAX, EMAIL, ATTNTITLE, 
				 ATTNFIRSTNAME, ATTNLASTNAME)
			Select   Distinct
				 T.BATCHNO, T.TRANSACTIONIDENTIFIER, T.TRANSACTIONCODE, T.TRANSACTIONSUBCODE, T.NAMETYPE, 
				 T.SENDERNAMEIDENTIFIER, T.ENTITYTYPEFLAG, T.TITLE, T.FIRSTNAME, T.[NAME], T.INITIALS, T.GENDER, 
				 T.ADDRESSLINE, T.CITY, T.STATE, T.POSTCODE, T.COUNTRYCODE, T.PHONE, T.FAX, T.EMAIL, T.ATTNTITLE, 
				 T.ATTNFIRSTNAME, T.ATTNLASTNAME
			from #TEMPUNRESOLVEDNAME T
			left join EDETRANSACTIONCONTENTDETAILS C
						   on (C.BATCHNO=T.BATCHNO
						   and C.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			left join EDEADDRESSBOOK A on (A.BATCHNO=T.BATCHNO
						   and A.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
			left join NAMETYPE NT	   on (NT.NAMETYPE=T.NAMETYPE)
			-- do not create an unresolved name if the transaction
			-- is a Name Import transaciton and there are missing name details
			where (isnull(C.TRANSACTIONCODE,'')<>'Name Import'	
			OR isnull(A.MISSINGNAMEDETAILS,0)=0)
			and (T.NAMETYPE is null OR NT.NAMETYPE is not null)"	-- If NameType provided, then it must be valid.
			
			Execute @nErrorCode=sp_executesql @sSQLString
							  
			Set @nRowCount=@@rowcount

			If  @nErrorCode=0
			and @nRowCount>0
			Begin
				-----------------------------------------------------------
				-- Link the unresolved name inserted into EDEUNRESOLVEDNAME 
				-- to the name in EDEADDRESSBOOK. 
				-- This update is for unresolved names linked to a specific 
				-- TRANSACTIONIDENTIFIER.
				-----------------------------------------------------------

				Set @sSQLString = "
				Update EAB
				set UNRESOLVEDNAMENO = EUN.UNRESOLVEDNAMENO
				from #TEMPUNRESOLVEDNAME T
				join EDEADDRESSBOOK EAB		on (EAB.BATCHNO = T.BATCHNO 
								and EAB.TRANSACTIONIDENTIFIER = T.TRANSACTIONIDENTIFIER 
								and EAB.NAMETYPECODE_T = T.NAMETYPE
								and EAB.NAMESEQUENCENUMBER=T.NAMESEQUENCENUMBER)
				join EDEUNRESOLVEDNAME EUN	on (EUN.BATCHNO = EAB.BATCHNO
								and EUN.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
								and EUN.NAMETYPE = EAB.NAMETYPECODE_T)
				-----------------------------------
				-- Additional matching to cater for
				-- multiple names with the same 
				-- Name Type.
				-----------------------------------
				where 	checksum (EUN.SENDERNAMEIDENTIFIER, EUN.ENTITYTYPEFLAG, EUN.TITLE, EUN.FIRSTNAME, EUN.[NAME], EUN.INITIALS, EUN.GENDER, 
						  EUN.ADDRESSLINE, EUN.CITY, EUN.STATE, EUN.POSTCODE, EUN.COUNTRYCODE, EUN.PHONE, EUN.FAX, EUN.EMAIL, EUN.ATTNTITLE, 
						  EUN.ATTNFIRSTNAME, EUN.ATTNLASTNAME)
				     =	checksum(T.SENDERNAMEIDENTIFIER, T.ENTITYTYPEFLAG, T.TITLE, T.FIRSTNAME, T.[NAME], T.INITIALS, T.GENDER, 
						  T.ADDRESSLINE, T.CITY, T.STATE, T.POSTCODE, T.COUNTRYCODE, T.PHONE, T.FAX, T.EMAIL, T.ATTNTITLE, 
						  T.ATTNFIRSTNAME, T.ATTNLASTNAME)"

				Execute @nErrorCode=sp_executesql @sSQLString

				If  @nErrorCode=0
				Begin
					-----------------------------------------------------------
					-- Link the unresolved name inserted into EDEUNRESOLVEDNAME
					-- that are not for an explicit TRANSACTIONIDENTIFIER,
					-- to the name in EDEADDRESSBOOK.
					-----------------------------------------------------------
					Set @sSQLString = "
					Update EAB
					set UNRESOLVEDNAMENO = EUN.UNRESOLVEDNAMENO
					from (	select distinct A.*				--SQA17653 Use derived table for performance improvement
						from #TEMPUNRESOLVEDNAME U
						join EDEADDRESSBOOK A	on (A.BATCHNO = U.BATCHNO 
									and A.NAMETYPECODE_T = U.NAMETYPE) 
						where U.TRANSACTIONIDENTIFIER is null) UA
					join EDEADDRESSBOOK EAB		on (EAB.ROWID=UA.ROWID)
					join EDEUNRESOLVEDNAME EUN	on (EUN.BATCHNO = EAB.BATCHNO
									and EUN.NAMETYPE = EAB.NAMETYPECODE_T)			
					join EDENAME EN			on (EN.BATCHNO = EAB.BATCHNO 
									and EN.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
									and EN.NAMETYPECODE = EAB.NAMETYPECODE
									and EN.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER)
					left join EDEFORMATTEDNAME EFN	on (EFN.BATCHNO = EAB.BATCHNO 
									and EFN.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER 
									and EFN.NAMETYPECODE = EAB.NAMETYPECODE
									and EFN.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER)
					left join EDEFORMATTEDATTNOF EFO 
									on (EFO.BATCHNO = EAB.BATCHNO 
									and EFO.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER 
									and EFO.NAMETYPECODE = EAB.NAMETYPECODE
									and EFO.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER)
					left join EDECONTACTINFORMATIONDETAILS ECD 
									on (ECD.BATCHNO = EAB.BATCHNO 
									and ECD.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
									and ECD.NAMETYPECODE = EAB.NAMETYPECODE
									and ECD.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER)
					left join #TEMPADDRESSES A	on (A.BATCHNO = EAB.BATCHNO 
									and A.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER
									and A.NAMETYPECODE = EAB.NAMETYPECODE
									and A.NAMESEQUENCENUMBER=EAB.NAMESEQUENCENUMBER)
					Where EUN.TRANSACTIONIDENTIFIER is null
					and EAB.UNRESOLVEDNAMENO is null
					-- Where name details match with unresolved name details
					and EUN.NAME                 = isnull(EFN.LASTNAME, EFN.ORGANIZATIONNAME)
					and isnull(EUN.SENDERNAMEIDENTIFIER,'')=isnull(EN.SENDERNAMEIDENTIFIER,'')

					-- Only match on Address if one has been supplied
					and (A.ADDRESSLINE+A.ADDRESSCITY+A.ADDRESSSTATE+A.ADDRESSPOSTCODE+A.ADDRESSCOUNTRYCODE = NULL
					 or (isnull(rtrim(EUN.ADDRESSLINE),'') = isnull(rtrim(A.ADDRESSLINE),'')     AND 
					     isnull(rtrim(EUN.CITY),'')        = isnull(rtrim(A.ADDRESSCITY),'')     AND
					     isnull(rtrim(EUN.STATE),'')       = isnull(rtrim(A.ADDRESSSTATE),'')    AND
					     isnull(rtrim(EUN.POSTCODE),'')    = isnull(rtrim(A.ADDRESSPOSTCODE),'') AND
					     isnull(rtrim(EUN.COUNTRYCODE),'') = isnull(rtrim(A.ADDRESSCOUNTRYCODE),'') )
					     )
					     
					and isnull(rtrim(EUN.FIRSTNAME),'')    = isnull(rtrim(EFN.FIRSTNAME),'')
					and isnull(rtrim(EUN.GENDER),'')       = isnull(rtrim(EFN.GENDER_T),'')
					and isnull(rtrim(EUN.ATTNTITLE),'')    = isnull(rtrim(EFO.NAMEPREFIX),'')
					and isnull(rtrim(EUN.ATTNFIRSTNAME),'')= isnull(rtrim(EFO.FIRSTNAME),'')
					and isnull(rtrim(EUN.ATTNLASTNAME),'') = isnull(rtrim(EFO.LASTNAME),'')
					and isnull(rtrim(EUN.PHONE),'')        = isnull(rtrim(ECD.PHONE),'')
					and isnull(rtrim(EUN.FAX),'')          = isnull(rtrim(ECD.FAX),'')
					and isnull(rtrim(EUN.EMAIL),'')        = isnull(rtrim(ECD.EMAIL),'')"
					
					Execute @nErrorCode=sp_executesql @sSQLString
				End

				If @nErrorCode = 0
				Begin
					----------------------------------------------
					-- Update EXTERNALNAME and EXTERNALNAMEADDRESS 
					-- tables to reflect details in batch file.
					----------------------------------------------

					Set @sSQLString = "
					Update EXN
					Set	EXTERNALNAME = ERN.[NAME],
						FIRSTNAME    = ERN.FIRSTNAME,
						EMAIL        = ERN.EMAIL,
						PHONE        = ERN.PHONE,
						FAX          = ERN.FAX
					from EDEUNRESOLVEDNAME ERN
					join EDESENDERDETAILS ESD on (ESD.BATCHNO = ERN.BATCHNO)
					join EXTERNALNAME EXN     on (EXN.DATASOURCENAMENO = ESD.SENDERNAMENO
								  and EXN.EXTERNALNAMECODE = ERN.SENDERNAMEIDENTIFIER
								  and isnull(EXN.NAMETYPE,'')+convert(varchar,EXN.EXTERNALNAMEID)
											=(	select max(isnull(EXN1.NAMETYPE,'')+convert(varchar,EXN1.EXTERNALNAMEID))
												from EXTERNALNAME EXN1
												where EXN1.DATASOURCENAMENO=EXN.DATASOURCENAMENO
												and EXN1.EXTERNALNAMECODE=EXN.EXTERNALNAMECODE
												and (EXN1.NAMETYPE=ERN.NAMETYPE OR EXN1.NAMETYPE is null)))
					where ERN.BATCHNO = @pnBatchNo
					and checksum(EXN.EXTERNALNAME, EXN.FIRSTNAME, EXN.EMAIL, EXN.PHONE, EXN.FAX)
					 <> checksum(ERN.[NAME],       ERN.FIRSTNAME, ERN.EMAIL, ERN.PHONE, ERN.FAX)"

					Execute @nErrorCode=sp_executesql @sSQLString,
									N'@pnBatchNo 	int',
									  @pnBatchNo	= @pnBatchNo


					If @nErrorCode=0
					Begin
						Set @sSQLString = "
						Update ENA
						Set	ADDRESS  = ERN.ADDRESSLINE,
							CITY     = ERN.CITY,
							STATE    = ERN.STATE,
							POSTCODE = ERN.POSTCODE,
							COUNTRY  = ERN.COUNTRYCODE
						from EDEUNRESOLVEDNAME ERN
						join EDESENDERDETAILS ESD on (ESD.BATCHNO = ERN.BATCHNO)
						join (	select	EXN1.DATASOURCENAMENO,
								EXN1.EXTERNALNAMECODE,
								ERN1.NAMETYPE,
								max(isnull(EXN1.NAMETYPE,'')+convert(varchar,EXN1.EXTERNALNAMEID)) as COMPLEXKEY
							from EDEUNRESOLVEDNAME ERN1
							join EXTERNALNAME EXN1 on (EXN1.EXTERNALNAMECODE=ERN1.SENDERNAMEIDENTIFIER)
							where ERN1.BATCHNO=@pnBatchNo
							and (EXN1.NAMETYPE=ERN1.NAMETYPE OR EXN1.NAMETYPE is null)
							group by EXN1.DATASOURCENAMENO,EXN1.EXTERNALNAMECODE,ERN1.NAMETYPE) X	
									on (X.DATASOURCENAMENO=ESD.SENDERNAMENO
									and X.EXTERNALNAMECODE=ERN.SENDERNAMEIDENTIFIER
									and X.NAMETYPE=ERN.NAMETYPE)
						join EXTERNALNAME EXN   on (EXN.DATASOURCENAMENO = ESD.SENDERNAMENO
									and EXN.EXTERNALNAMECODE = ERN.SENDERNAMEIDENTIFIER
									and isnull(EXN.NAMETYPE,'')+convert(varchar,EXN.EXTERNALNAMEID)=X.COMPLEXKEY)
						join EXTERNALNAMEADDRESS ENA on (ENA.EXTERNALNAMEID   = EXN.EXTERNALNAMEID)
						where ERN.BATCHNO = @pnBatchNo
						-- Do not automatically update the Address if the 
						-- name is being used as the Owner.
						and (ERN.NAMETYPE<>'O' or ERN.NAMETYPE is null)
						-- only apply the update if an Address has been imported
						-- and the address does not match the existing address.
						and ERN.ADDRESSLINE+ERN.CITY+ERN.STATE+ERN.POSTCODE+ERN.COUNTRYCODE is not null
						and checksum(ENA.ADDRESS,    ENA.CITY, ENA.STATE, ENA.POSTCODE, ENA.COUNTRY)
						 <> checksum(ERN.ADDRESSLINE,ERN.CITY, ERN.STATE, ERN.POSTCODE, ERN.COUNTRYCODE)"

						Execute @nErrorCode=sp_executesql @sSQLString,
										N'@pnBatchNo 	int',
										  @pnBatchNo	= @pnBatchNo
					End
				End
			End -- @nRowCount>0

			-- Commit transaction if successful.
			If @@TranCount > @TransactionCountStart
			Begin
				If @nErrorCode = 0
					COMMIT TRANSACTION
				Else
					ROLLBACK TRANSACTION
			End
			
			Set @nRetry=-1
		End
	End TRY

	Begin CATCH
		------------------------------------------
		-- If the process has been made the victim
		-- of a deadlock (error 1205), then allow 
		-- another attempt to apply the updates 
		-- to the database up to a retry limit.
		------------------------------------------
		set @nErrorCode=ERROR_NUMBER()
		
		If @nErrorCode=1205
			Set @nRetry=@nRetry-1
		Else
			Set @nRetry=-1
		
		If @nRetry<0
		Begin
			-- Get error details to propagate to the caller
			Select 	@sErrorMessage = 'Error:' + cast(ERROR_NUMBER() as nvarchar) + ' - ' + ERROR_MESSAGE(),
				@nErrorSeverity = ERROR_SEVERITY(),
				@nErrorState    = ERROR_STATE(),
				@nErrorCode      = ERROR_NUMBER()

			-- Use RAISERROR inside the CATCH block to return error
			-- information about the original error that caused
			-- execution to jump to the CATCH block.
			RAISERROR ( @sErrorMessage,	-- Message text.
				    @nErrorSeverity,	-- Severity.
				    @nErrorState	-- State.
				  )
		End
			
		If XACT_STATE()<>0
			ROLLBACK TRANSACTION
	End CATCH
End -- While loop

If @nErrorCode = 0
Begin
	Set @nRetry=3
	While @nRetry>0
	and @nErrorCode=0
	Begin
		BEGIN TRY
			-- Handle EDE Attention Names on the EDEFORMATTEDATTNOF table. If EDE Attention Name is same as the one on our database
			-- then map the EDEFORMATTEDATTNOF.NAMENO column.
			-- If Attention Name is different then create a new name and insert an associated name.
			-- Do not map. Mapping can be done at Name Resolution stage.

			-- Start new transaction.
			Set @TransactionCountStart = @@TranCount
			BEGIN TRANSACTION

			-- Find matching EDE Associate Names and map it into the EDEFORMATTEDATTNOF.NAMENO column.
			-- This is a fairly weak match, but the user can fix it in Name Resolution.
			Set @sSQLString = "
			Update EFO
			Set  NAMENO = AN.RELATEDNAME
			from EDEADDRESSBOOK EAB
			join EDEFORMATTEDATTNOF EFO 
						on (EFO.BATCHNO               = EAB.BATCHNO 
						and EFO.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER 
						and EFO.NAMETYPECODE          = EAB.NAMETYPECODE
						and isnull(EFO.NAMESEQUENCENUMBER,99999)=isnull(EAB.NAMESEQUENCENUMBER,99999))
			join ASSOCIATEDNAME AN	on (AN.NAMENO = EAB.NAMENO 
						and AN.RELATIONSHIP = 'EMP'
						and AN.SEQUENCE = (	select max(AN1.SEQUENCE) 
									from ASSOCIATEDNAME AN1
									where AN1.NAMENO=AN.NAMENO
									and AN1.RELATIONSHIP=AN.RELATIONSHIP
									and AN1.RELATEDNAME=AN.RELATEDNAME))
			join NAME N		on (N.NAMENO = AN.RELATEDNAME)
			where EAB.BATCHNO = @pnBatchNo
			and EAB.NAMENO is not null
			and EFO.NAMENO is null
			and N.NAME	= EFO.LASTNAME
			and(N.FIRSTNAME = EFO.FIRSTNAME OR (N.FIRSTNAME is null and EFO.FIRSTNAME is null))"

			Execute @nErrorCode = sp_executesql @sSQLString,
							N'@pnBatchNo		int',
							  @pnBatchNo		= @pnBatchNo

			-- Commit transaction if successful.
			If @@TranCount > @TransactionCountStart
			Begin
				If @nErrorCode = 0
					COMMIT TRANSACTION
				Else
					ROLLBACK TRANSACTION
			End
			Set @nRetry=-1
		End TRY

		Begin CATCH
			------------------------------------------
			-- If the process has been made the victim
			-- of a deadlock (error 1205), then allow 
			-- another attempt to apply the updates 
			-- to the database up to a retry limit.
			------------------------------------------
			set @nErrorCode=ERROR_NUMBER()
			
			If @nErrorCode=1205
				Set @nRetry=@nRetry-1
			Else
				Set @nRetry=-1
		
			If @nRetry<0
			Begin
				-- Get error details to propagate to the caller
				Select 	@sErrorMessage = 'Error:' + cast(ERROR_NUMBER() as nvarchar) + ' - ' + ERROR_MESSAGE(),
					@nErrorSeverity = ERROR_SEVERITY(),
					@nErrorState    = ERROR_STATE(),
					@nErrorCode      = ERROR_NUMBER()

				-- Use RAISERROR inside the CATCH block to return error
				-- information about the original error that caused
				-- execution to jump to the CATCH block.
				RAISERROR ( @sErrorMessage,	-- Message text.
					    @nErrorSeverity,	-- Severity.
					    @nErrorState	-- State.
					  )
			End
				
			If XACT_STATE()<>0
				ROLLBACK TRANSACTION
		End CATCH
	End -- While loop


	-- sqa16458 make the attention name the main contact if it is not currently the main contact
	if  @nErrorCode = 0 
	and @bIsMainContact = 1
	begin
		Set @sSQLString = "	
		Insert into #TEMPASSOCIATEDNAMES (BATCHNO, TRANSACTIONIDENTIFIER, MAINNAMENO, RELATEDNAMENO)
		select EFO.BATCHNO, EFO.TRANSACTIONIDENTIFIER,  EAB.NAMENO, EFO.NAMENO
		from EDEADDRESSBOOK EAB
		join EDEFORMATTEDATTNOF EFO	on (EFO.BATCHNO               = EAB.BATCHNO 
						and EFO.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER 
						and EFO.NAMETYPECODE          = EAB.NAMETYPECODE
						and isnull(EFO.NAMESEQUENCENUMBER,99999)=isnull(EAB.NAMESEQUENCENUMBER,99999))
		join NAME N2	on (N2.NAMENO = EAB.NAMENO)
		where EAB.BATCHNO = @pnBatchNo 
		and EFO.NAMENO is not null
		and ISNULL(N2.MAINCONTACT,'') <> EFO.NAMENO "  -- attention is not the main contact

		Execute @nErrorCode = sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo		= @pnBatchNo

		Set @nMaxRow = @@Rowcount
		Set @nRowNumber = 1

		While @nRowNumber <= @nMaxRow
		and @nErrorCode=0
		Begin
			Set @nRetry=3
			While @nRetry>0
			and @nErrorCode=0
			Begin
				Begin TRY
					-- Start new transaction.
					Set @TransactionCountStart = @@TranCount
					BEGIN TRANSACTION
					
					Set @sSQLString="
					Select	@nMainNameNo	= MAINNAMENO,
						@nRelatedNameNo	= RELATEDNAMENO
					from #TEMPASSOCIATEDNAMES
					where ROWNUMBER = @nRowNumber"
					
					Execute @nErrorCode = sp_executesql @sSQLString,
								N'@nMainNameNo		int	OUTPUT,
								  @nRelatedNameNo	int	OUTPUT,
								  @nRowNumber		int',
								  @nMainNameNo	 = @nMainNameNo		OUTPUT,
								  @nRelatedNameNo= @nRelatedNameNo	OUTPUT,
								  @nRowNumber    = @nRowNumber

					if @nErrorCode = 0
					Begin
						Update 	NAME
						Set	MAINCONTACT = @nRelatedNameNo
						Where	NAMENO = @nMainNameNo
						and    (MAINCONTACT<>@nRelatedNameNo 
						    OR (MAINCONTACT is null and @nRelatedNameNo is not null))
						
						Select @nErrorCode = @@Error,
							@nRowCount = @@Rowcount
					End
					
					-- Reset the derived attention if the 
					-- main contact on the name has changed.
					if @nErrorCode = 0
					and @nRowCount > 0
					Begin
						Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
									@pnMainNameKey 		= @nMainNameNo,
									@pnOldAttentionKey 	= null,
									@pnNewAttentionKey 	= @nRelatedNameNo 
					End

					-------------------------------------------------
					-- For each amended NAME, insert a TRANSACTIONINFO row 
					-------------------------------------------------
					If @nErrorCode=0
					Begin
						Set @sSQLString="
						Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONIDENTIFIER, NAMENO, TRANSACTIONMESSAGENO, TRANSACTIONREASONNO) 
						select getdate(), T.BATCHNO, T.TRANSACTIONIDENTIFIER, @nMainNameNo, 8, RT.TRANSACTIONREASONNO 
						from #TEMPASSOCIATEDNAMES T
						join EDESENDERDETAILS SD ON SD.BATCHNO = T.BATCHNO 
						join EDEREQUESTTYPE RT on RT.REQUESTTYPECODE = SD.SENDERREQUESTTYPE
						where T.ROWNUMBER = @nRowNumber "

						exec @nErrorCode=sp_executesql @sSQLString,
									N'@nMainNameNo		int,
									  @nRowNumber		int',
									  @nMainNameNo	= @nMainNameNo,
									  @nRowNumber	= @nRowNumber
					End

					-- Commit transaction if successful.
					If @@TranCount > @TransactionCountStart
					Begin
						If @nErrorCode = 0
						Begin
							Set @nRowNumber = @nRowNumber + 1
							COMMIT TRANSACTION
						End
						Else
							ROLLBACK TRANSACTION
					End
					Set @nRetry=-1
				End TRY

				Begin CATCH
					------------------------------------------
					-- If the process has been made the victim
					-- of a deadlock (error 1205), then allow 
					-- another attempt to apply the updates 
					-- to the database up to a retry limit.
					------------------------------------------
					set @nErrorCode=ERROR_NUMBER()
					
					If @nErrorCode=1205
						Set @nRetry=@nRetry-1
					Else
						Set @nRetry=-1
		
					If @nRetry<0
					Begin
						-- Get error details to propagate to the caller
						Select 	@sErrorMessage = 'Error:' + cast(ERROR_NUMBER() as nvarchar) + ' - ' + ERROR_MESSAGE(),
							@nErrorSeverity = ERROR_SEVERITY(),
							@nErrorState    = ERROR_STATE(),
							@nErrorCode      = ERROR_NUMBER()

						-- Use RAISERROR inside the CATCH block to return error
						-- information about the original error that caused
						-- execution to jump to the CATCH block.
						RAISERROR ( @sErrorMessage,	-- Message text.
							    @nErrorSeverity,	-- Severity.
							    @nErrorState	-- State.
							  )
					End
						
					If XACT_STATE()<>0
						ROLLBACK TRANSACTION
				End CATCH
			End -- Retry loop
		End  -- End of loop
	End

	If @nErrorCode=0
	Begin
		-- Now handle EDE Associate Names that have not been matched.
		-- We need to add a new Name for each EDE Associated Name. Note that this could potentially give alot of names.
		-- Then associate that newly created Name with the Main Name.
		
		Delete from #TEMPASSOCIATEDNAMES
		
		Set @nErrorCode=@@Error

		If @nErrorCode=0
		Begin
			Set @sSQLString = "	
			Insert into #TEMPASSOCIATEDNAMES (BATCHNO, USERID, TRANSACTIONIDENTIFIER, NAMETYPECODE, NAMEPREFIX, FIRSTNAME, LASTNAME, MAINNAMENO)
			select EFO.BATCHNO, EFO.USERID, EFO.TRANSACTIONIDENTIFIER, EFO.NAMETYPECODE, EFO.NAMEPREFIX, EFO.FIRSTNAME, EFO.LASTNAME, EAB.NAMENO
			from EDEADDRESSBOOK EAB
			join EDEFORMATTEDATTNOF EFO on (EFO.BATCHNO = EAB.BATCHNO 
						    and EFO.TRANSACTIONIDENTIFIER = EAB.TRANSACTIONIDENTIFIER 
						    and EFO.NAMETYPECODE = EAB.NAMETYPECODE
						   and isnull(EFO.NAMESEQUENCENUMBER,99999)=isnull(EAB.NAMESEQUENCENUMBER,99999))
			where EAB.BATCHNO = @pnBatchNo 
			and EAB.NAMENO is not null
			and EFO.NAMENO is null"

			Execute @nErrorCode = sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo		= @pnBatchNo
		End
		
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Select	@nRowNumber=min(isnull(ROWNUMBER,0)),
				@nMaxRow   =max(isnull(ROWNUMBER, 0)) 
			from #TEMPASSOCIATEDNAMES"

			Execute @nErrorCode = sp_executesql @sSQLString,
							N'@nRowNumber		int	OUTPUT,
							  @nMaxRow		int	OUTPUT',
							  @nRowNumber	= @nRowNumber	OUTPUT,
							  @nMaxRow	= @nMaxRow	OUTPUT
		End
	End
	
	-- For each EDE Associated Name we need to run the na_InsertName procedure
	-- and na_InsertAssociatedName to insert a name and then associate the name.
	While @nErrorCode = 0 
	and @nRowNumber <= @nMaxRow
	Begin
		Set @sSQLString="
		Select	@sName		= LASTNAME,
			@sGivenNames	= FIRSTNAME,
			@sTitleKey	= NAMEPREFIX,
			@nMainNameNo	= MAINNAMENO
		from #TEMPASSOCIATEDNAMES
		where ROWNUMBER = @nRowNumber"
		
		Execute @nErrorCode = sp_executesql @sSQLString,
						N'@sName		nvarchar(254)	OUTPUT,
						  @sGivenNames		nvarchar(254)	OUTPUT,
						  @sTitleKey		nvarchar(10)	OUTPUT,
						  @nMainNameNo		int		OUTPUT,
						  @nRowNumber		int',
						  @sName		= @sName	OUTPUT,
						  @sGivenNames		= @sGivenNames	OUTPUT,
						  @sTitleKey		= @sTitleKey	OUTPUT,
						  @nMainNameNo		= @nMainNameNo	OUTPUT,
						  @nRowNumber		= @nRowNumber
					  

		If @nErrorCode=0
		Begin
			set @nRelatedNameNo=null
			-- 16458 Check that name does not exist in NAME table before inserting
			Set @sSQLString = "
			Select TOP 1 @nRelatedNameNo = NAMENO
			from NAME 
			where NAME = @sName
			and FIRSTNAME = @sGivenNames"

			Execute @nErrorCode = sp_executesql @sSQLString,
						N'@nRelatedNameNo	int output,
						  @sName		nvarchar(254),
						  @sGivenNames		nvarchar(254)',
						  @nRelatedNameNo	= @nRelatedNameNo output,
						  @sName		= @sName,
						  @sGivenNames		= @sGivenNames
		End	

		-- create the attention name if it does not exist 
		If  @nErrorCode = 0 and @nRelatedNameNo is null and @nMainNameNo is not null
		Begin
			-- If the site control option indicates 
			-- that Name Codes are mandatory to be generated
			-- and then protected then call the procedure
			-- to generate the Name Code.
			if @nGenerateNameCode=2
			Begin
				exec @nErrorCode=dbo.na_GenerateNameCode
							@psNameCode		=@sNameCode 	output,
							@pnUserIdentityId	=@pnUserIdentityId
			End
			
			If @nErrorCode=0
			Begin
				-- Note that this procedure contains its own explicit
				-- transaction so names will be committed within the procedure
				Execute @nErrorCode = dbo.na_InsertName
							@pnUserIdentityId	= @pnUserIdentityId,
							@psNameKey		= @sNameKey output,
							@psNameCode		= @sNameCode,
							@psName			= @sName,
							@psGivenNames		= @sGivenNames,
							@psTitleKey		= @sTitleKey
			End

			If @nErrorCode=0
			Begin
				-- Note that this procedure contains its own explicit
				-- transaction so associated names will be committed within the procedure
				Execute @nErrorCode = dbo.na_InsertAssociatedName
							@pnUserIdentityId	= @pnUserIdentityId,
							@psNameKey		= @nMainNameNo,
							@pnRelationshipTypeId	= 1, -- 'EMP' relationship.
							@psRelatedNameKey	= @sNameKey,
							@pbIsMainContact	= @bIsMainContact
			End
			-------------------------------------------------
			-- For NEW NAME ADDED, insert a TRANSACTIONINFO row 
			-------------------------------------------------
			If @nErrorCode=0
			Begin
				Set @nNameNo = cast(@sNameKey as int)
				
				-- Keep the database transaction as short as 
				-- possible to reduce locks.
				Set @TransactionCountStart = @@TranCount
				BEGIN TRANSACTION

				Set @sSQLString="
				Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONIDENTIFIER, NAMENO, TRANSACTIONMESSAGENO, TRANSACTIONREASONNO) 
				select getdate(), T.BATCHNO, T.TRANSACTIONIDENTIFIER, @nNameNo, 7, RT.TRANSACTIONREASONNO 
				from #TEMPASSOCIATEDNAMES T
				join EDESENDERDETAILS SD ON SD.BATCHNO = T.BATCHNO 
				join EDEREQUESTTYPE RT on RT.REQUESTTYPECODE = SD.SENDERREQUESTTYPE
				where T.ROWNUMBER = @nRowNumber "

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nNameNo	int,
							  @nRowNumber	int',
							  @nNameNo = @nNameNo,
							  @nRowNumber=@nRowNumber

				-- Commit transaction if successful.
				If @@TranCount > @TransactionCountStart
				Begin
					If @nErrorCode = 0
						COMMIT TRANSACTION
					Else
						ROLLBACK TRANSACTION
				End
			End
		End

		-- if attention name does exist in NAME we need to check whether it exists in ASSOCIATEDNAME table. 
		If  @nErrorCode = 0 and @nRelatedNameNo is not null 
		Begin
			Set @nExist = 0

			Set @sSQLString = "
			select @nExist = 1
			from ASSOCIATEDNAME AN 
			where AN.NAMENO = @nMainNameNo
			and AN.RELATEDNAME = @nRelatedNameNo
			and AN.RELATIONSHIP = 'EMP'"

			Execute @nErrorCode = sp_executesql @sSQLString,
						N'@nExist		int output,
						  @nMainNameNo		int,
						  @nRelatedNameNo	int',
						  @nExist		= @nExist output,
						  @nMainNameNo		= @nMainNameNo,
						  @nRelatedNameNo	= @nRelatedNameNo

			-- add the associated name if it does not exist
			If  @nErrorCode = 0 and @nExist = 0
			Begin
				-- Note that this procedure contains its own explicit
				-- transaction so associated names will be committed within the procedure
				Execute @nErrorCode = dbo.na_InsertAssociatedName
							@pnUserIdentityId	= @pnUserIdentityId,
							@psNameKey		= @nMainNameNo,
							@pnRelationshipTypeId	= 1, -- 'EMP' relationship.
							@psRelatedNameKey	= @nRelatedNameNo,
							@pbIsMainContact	= @bIsMainContact

				-------------------------------------------------
				-- For each amended NAME, insert a TRANSACTIONINFO row 
				-------------------------------------------------
				If @nErrorCode=0
				Begin
				
					-- Keep the database transaction as short as 
					-- possible to reduce locks.
					Set @TransactionCountStart = @@TranCount
					BEGIN TRANSACTION

					Set @sSQLString="
					Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONIDENTIFIER, NAMENO, TRANSACTIONMESSAGENO, TRANSACTIONREASONNO) 
					select getdate(), T.BATCHNO, T.TRANSACTIONIDENTIFIER, @nMainNameNo, 8, RT.TRANSACTIONREASONNO 
					from #TEMPASSOCIATEDNAMES T
					join EDESENDERDETAILS SD ON SD.BATCHNO = T.BATCHNO 
					join EDEREQUESTTYPE RT on RT.REQUESTTYPECODE = SD.SENDERREQUESTTYPE
					where T.ROWNUMBER = @nRowNumber "

					exec @nErrorCode=sp_executesql @sSQLString,
								N'@nMainNameNo		int,
								  @nRowNumber		int',
								  @nMainNameNo = @nMainNameNo,
								  @nRowNumber  = @nRowNumber

					-- Commit transaction if successful.
					If @@TranCount > @TransactionCountStart
					Begin
						If @nErrorCode = 0
							COMMIT TRANSACTION
						Else
							ROLLBACK TRANSACTION
					End
				End
			End
		End

		Set @nRowNumber = @nRowNumber + 1
	End	-- End Loop
End

If @nErrorCode = 0
Begin
	--------------------------------------------------
	-- The transaction status needs to be updated now. 
	-- For a transaction not mapped to a NAMENO or has
	-- unresolved name issues set the TRANSSTATUSCODE
	-- to 3430 Unresolved names.
	-- Ignore names with missing name details.
	--------------------------------------------------

	-- Start new transaction.
	Set @TransactionCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Flag transaction that still have unresolved names.
	Set @sSQLString = "
	Update B
	set TRANSSTATUSCODE = 3430
	From EDETRANSACTIONBODY B
	join EDEADDRESSBOOK EAB	on (EAB.BATCHNO=B.BATCHNO
				and EAB.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER
				and(EAB.NAMENO is null or EAB.UNRESOLVEDNAMENO is not null)
				and isnull(EAB.MISSINGNAMEDETAILS,0)=0)
	where B.BATCHNO = @pnBatchNo
	and   B.TRANSSTATUSCODE=3420"

	Execute @nErrorCode = sp_executesql @sSQLString,
				N'@pnBatchNo		int',
				  @pnBatchNo=@pnBatchNo

	If @nErrorCode=0
	Begin
		------------------------------------
		-- Update the TRANSNARRATIVECODE for 
		-- Name Import Unresolved Names.
		------------------------------------
		Set @sSQLString = "
		Update B
		set TRANSNARRATIVECODE = 4027
		from EDETRANSACTIONBODY B
		join EDETRANSACTIONCONTENTDETAILS ECD	on (ECD.BATCHNO=B.BATCHNO
							and ECD.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
		where B.BATCHNO = @pnBatchNo
		and B.TRANSSTATUSCODE = 3430
		and ECD.TRANSACTIONCODE='Name Import'"

		Execute @nErrorCode = sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo		= @pnBatchNo
	End


	If @nErrorCode=0
	Begin
		---------------------------------
		-- Now flag transactions that are 
		-- ready for case load.
		---------------------------------
		Set @sSQLString = "
		Update B
		set TRANSSTATUSCODE = 3440
		from EDETRANSACTIONBODY B
		left join EDEADDRESSBOOK EAB	on (EAB.BATCHNO=B.BATCHNO
						and EAB.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER
						and(EAB.NAMENO is null or EAB.UNRESOLVEDNAMENO is not null)
						and isnull(EAB.MISSINGNAMEDETAILS,0)=0)
		where B.BATCHNO = @pnBatchNo
		and B.TRANSSTATUSCODE in (3420, 3430)
		and EAB.BATCHNO is null"

		Execute @nErrorCode = sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo		= @pnBatchNo
	End

	-- Commit transaction if successful.
	If @@TranCount > @TransactionCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

If @nErrorCode = 0
Begin
	-- Validate Alternative Sender.

	-- Start new transaction.
	Set @TransactionCountStart = @@TranCount
	BEGIN TRANSACTION

	Set @sSQLString ="
	Update ETC
	set ALTSENDERNAMENO = NA.NAMENO
	from NAMEALIAS NA 
	join EDETRANSACTIONCONTENTDETAILS ETC ON (ETC.ALTERNATIVESENDER = NA.ALIAS)	-- Assume case insensitive
	where ETC.BATCHNO = @pnBatchNo
	and NA.ALIASTYPE = '_E'
	and NA.COUNTRYCODE  is null
	and NA.PROPERTYTYPE is null"

	Exec @nErrorCode = sp_executesql @sSQLString,
				      N'@pnBatchNo	int',
					@pnBatchNo	=@pnBatchNo


	If @nErrorCode=0
	Begin
		----------------------------------------
		-- Remove previous issues generated for:
		--	(-24) invalid Alternative Sender
		--	(-15) missing name details
		----------------------------------------
		Set @sSQLString = "
		Delete 
		from EDEOUTSTANDINGISSUES
		where BATCHNO = @pnBatchNo
		and ISSUEID in (-24, -15)"

		Execute @nErrorCode = sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo		= @pnBatchNo
	End

	If @nErrorCode=0
	Begin
		-- Insert Outstanding Issue for unvalidated Alternative Sender.
		Set @sSQLString = "
		Insert into EDEOUTSTANDINGISSUES(BATCHNO, TRANSACTIONIDENTIFIER, ISSUEID, ISSUETEXT, DATECREATED)
		select @pnBatchNo, TRANSACTIONIDENTIFIER, -24, ALTERNATIVESENDER, getdate( )
		from EDETRANSACTIONCONTENTDETAILS
		where ALTSENDERNAMENO is null
		and ALTERNATIVESENDER is not null
		and BATCHNO = @pnBatchNo"

		Execute @nErrorCode = sp_executesql @sSQLString,
				N'@pnBatchNo		int',
				  @pnBatchNo		= @pnBatchNo
	End

	If @nErrorCode=0
	Begin
		-- Insert Outstanding Issue for names with missing details.
		Set @sSQLString = "
		Insert into EDEOUTSTANDINGISSUES(BATCHNO, TRANSACTIONIDENTIFIER, ISSUEID, DATECREATED, ISSUETEXT, REPORTEDVALUE)
		select @pnBatchNo, EB.TRANSACTIONIDENTIFIER, -15, getdate( ), 'Name Type: '+EB.NAMETYPECODE, isnull(EN.SENDERNAMEIDENTIFIER,EN.RECEIVERNAMEIDENTIFIER)
		from EDEADDRESSBOOK EB
		left join EDENAME EN on (EN.BATCHNO=EB.BATCHNO and EN.TRANSACTIONIDENTIFIER=EB.TRANSACTIONIDENTIFIER and EN.NAMETYPECODE=EB.NAMETYPECODE and isnull(EN.NAMESEQUENCENUMBER,99999)=isnull(EB.NAMESEQUENCENUMBER,99999))		
		where EB.MISSINGNAMEDETAILS = 1
		and EB.BATCHNO = @pnBatchNo"

		Execute @nErrorCode = sp_executesql @sSQLString,
				N'@pnBatchNo		int',
				  @pnBatchNo		= @pnBatchNo
	End
	
	-------------------------------------------------
	-- For each Name Import transaction that about to 
	-- be rejected, insert a TRANSACTIONINFO row.
	-------------------------------------------------
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO,TRANSACTIONIDENTIFIER, TRANSACTIONMESSAGENO, TRANSACTIONREASONNO) 
		select I.DATECREATED,I.BATCHNO,I.TRANSACTIONIDENTIFIER,4,R.TRANSACTIONREASONNO
		from EDEOUTSTANDINGISSUES I
		join EDESENDERDETAILS S on (S.BATCHNO=I.BATCHNO)
		join EDEREQUESTTYPE R	on (R.REQUESTTYPECODE=S.SENDERREQUESTTYPE)
		join EDETRANSACTIONCONTENTDETAILS C
					on (C.BATCHNO=I.BATCHNO
					and C.TRANSACTIONIDENTIFIER=I.TRANSACTIONIDENTIFIER)
		left join TRANSACTIONINFO T
					on (T.BATCHNO=I.BATCHNO
					and T.TRANSACTIONIDENTIFIER=I.TRANSACTIONIDENTIFIER)
		where I.BATCHNO=@pnBatchNo
		and I.ISSUEID=-15
		and C.TRANSACTIONCODE = 'Name Import'
		and T.TRANSACTIONIDENTIFIER is null"
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo=@pnBatchNo
	End

	If @nErrorCode=0
	Begin
		------------------------------------
		-- Mark the rejected transactions as
		-- Processed if an issue has been
		-- raised with a reject severity
		------------------------------------
		Set @sSQLString="
		Update T
		Set TRANSSTATUSCODE=3480,	--Processed
		    TRANSACTIONRETURNCODE='Rejected',
		    TRANSNARRATIVECODE=CASE WHEN(T.TRANSNARRATIVECODE is not null) THEN T.TRANSNARRATIVECODE
										   ELSE S.DEFAULTNARRATIVE
					END
		From EDETRANSACTIONBODY T
		join EDEOUTSTANDINGISSUES O	on (O.BATCHNO=T.BATCHNO
						and O.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
		join EDETRANSACTIONCONTENTDETAILS C
						on (C.BATCHNO=T.BATCHNO
						and C.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
		join EDESTANDARDISSUE S		on (S.ISSUEID=O.ISSUEID)
		Where T.BATCHNO=@pnBatchNo
		and O.ISSUEID=-15
		and C.TRANSACTIONCODE = 'Name Import'"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo=@pnBatchNo
	End

	-- Commit transaction if successful.
	If @@TranCount > @TransactionCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ede_MapName to public
GO