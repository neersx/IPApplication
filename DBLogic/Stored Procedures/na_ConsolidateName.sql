-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_ConsolidateName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_ConsolidateName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_ConsolidateName.'
	Drop procedure [dbo].[na_ConsolidateName]
End
Print '**** Creating Stored Procedure dbo.na_ConsolidateName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.na_ConsolidateName
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null, 
	@pnNameNoConsolidateFrom	int,		-- Mandatory
	@pnNameNoConsolidateTo		int,		-- Mandatory
	@pbKeepAddressHistory		bit		= 0,
	@pbKeepTelecomHistory		bit		= 0,
	@pbCalledFromCentura		bit		= 0
)
as
-- PROCEDURE:	na_ConsolidateName
-- VERSION:	20
-- SCOPE:	Inprotech
-- DESCRIPTION:	Used to consolidate the Name details identified where NameNo=@pnNameNoConsolidateFrom,
--		into an existing Name identified by @pnNameNoConsolidateTo.
--		References to the old Name will be moved to the new Name.
--		NOTE : 
--		The New Name will take precedence over information held in the old Name.
-- COPYRIGHT:	Copyright 1993 - 2009 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 28-Oct-2008  MF	16915	1	Procedure created
-- 21-Nov-2008	MF	16915	2	Corrections made after system testing
-- 20-Mar-2009	MF	17507	3	CreditorHistory not being consolidated
-- 23-Mar-2009	MF	17507	3	Correction after testing failure on CRENTITYDETAIL
-- 27-Aug-2009	CR	8819	4	Remove redundant SPECIALNAME columns and include new column
-- 03-Mar-2010	Dw	17755	5	Extended to cater for new column NARRATIVERULE.DEBTORNO
-- 04 Jun 2010	MF	18703	6	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE, ensure these match on a name consolidation.
-- 27 Aug 2010	MF	RFC9316	7	Include table DATAVALIDATION
-- 07-Oct-2011	MF	20058	9	Duplicate key error on EMPLOYEERMINDER
-- 15 Jun 2012	KR	R12005	10	added CASETYPE and WIPCODE to DISCOUNT table.
-- 06-May-2014	MF	34102	11	Provide a site control to indicate that Name(s) being consolidated into another Name are to be retained
--					with a Ceased Date instead of deleted.
-- 12-May-2014	MF	34102	12	Keep Creditor when new option in use.
-- 29-May-2014	MF	S22154	13	Feescalculation rows could result in duplicate key after consolidation. Delete rows for Name being consolidated.
-- 30-Apr-2015	MF	47155	14	After name consolidation a single Case may reference the same name for the same nametype and other identical attributes.
-- 01-Jun-2015	MS	R35907	15	Added COUNTRYCODE to the Discount calculation
-- 21-Jul-2015	MF	R50015	16	Balance on the ACCOUNT table set to NULL if any of the consolidated records have a balance value of NULL
-- 08-Jan-2018	MF	73260	17	WIPPAYMENT (for Cash Accounting) is not being considered in the name consolidation.  Also remove reference to SITEOPTIONS table.
-- 09-Jan-2018	MF	72945	18	The MAINCASEID column on OPENITEM is not being retained after consolidation.
-- 15-Aug-2015	MF	74770	19	Add an additional validation to ensure that the name being consolidated (@pnNameNoConsolidateFrom) is not an Accounting Entity.
-- 14 Nov 2018  AV  75198/DR-45358	20   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @TranCountStart		int

Declare @sSQLString		nvarchar(max)
declare	@bHexNumber		varbinary(128)
declare @nOfficeID		int
declare	@nLogMinutes		int 
declare	@nTransNo		int
declare	@nBatchNo		int		-- place holder only as not used here
declare	@bRetainName		bit		-- RFC34102

Set 	@nErrorCode = 0

--------------------------------------------------
-- D A T A   V A L I D A T I O N
-- Validate the input parameters before attempting
-- the consolidation
--------------------------------------------------

---------------------
-- Validate NewNameNo
---------------------
If @nErrorCode = 0
Begin
	If @pnNameNoConsolidateTo is null
	Begin
		RAISERROR('@pnNameNoConsolidateTo must not be NULL', 14, 1)
		Set @nErrorCode = @@ERROR
	End
	Else If not exists (select 1 from NAME where NAMENO=@pnNameNoConsolidateTo)
	Begin
		RAISERROR('@pnNameNoConsolidateTo must exist in NAME table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
	Else If exists (select 1 from NAME where NAMENO=@pnNameNoConsolidateTo and DATECEASED is not null)
	Begin
		RAISERROR('@pnNameNoConsolidateTo must not have a Ceased date', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

---------------------
-- Validate OldNameNo
---------------------
If @nErrorCode = 0
Begin
	If @pnNameNoConsolidateFrom is null
	Begin
		RAISERROR('@pnNameNoConsolidateFrom must not be NULL', 14, 1)
		Set @nErrorCode = @@ERROR
	End
	Else If not exists (select 1 from NAME where NAMENO=@pnNameNoConsolidateFrom)
	Begin
		RAISERROR('@pnNameNoConsolidateFrom must exist in NAME table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
	Else If exists (select 1 from SPECIALNAME where NAMENO=@pnNameNoConsolidateFrom and ENTITYFLAG=1)
	Begin
		RAISERROR('@pnNameNoConsolidateFrom must not be configured as an Accounting Entity', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

-----------------------------------
-- Validate OldNameNo and NewNameNo
-----------------------------------
If @nErrorCode = 0
Begin
	If @pnNameNoConsolidateFrom=@pnNameNoConsolidateTo
	Begin
		RAISERROR('@pnNameNoConsolidateFrom must not be same as @pnNameNoConsolidateTo', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

-------------------------------------
-- Validate the supplied UserIdentity
-------------------------------------
If @nErrorCode=0
Begin
	If (@pnUserIdentityId is null
	 or @pnUserIdentityId='')
	Begin
		Set @sSQLString="
		Select @pnUserIdentityId=min(IDENTITYID)
		from USERIDENTITY
		where LOGINID=substring(SYSTEM_USER,1,50)"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnUserIdentityId		int	OUTPUT',
				  @pnUserIdentityId=@pnUserIdentityId	OUTPUT
	End
	Else If not exists (select 1 from USERIDENTITY where IDENTITYID=@pnUserIdentityId)
	Begin
		RAISERROR('@pnUserIdentityId must exist in USERIDENTITY table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

--------------------------------------
-- Initialise variables that will be 
-- loaded into CONTEXT_INFO for access
-- by the audit triggers
--------------------------------------

If @nErrorCode=0
Begin
	Set @sSQLString="
	Select @nOfficeID=COLINTEGER
	from SITECONTROL
	where CONTROLID='Office For Replication'

	Select @nLogMinutes=COLINTEGER
	from SITECONTROL
	where CONTROLID='Log Time Offset'
	
	Select @bRetainName=COLBOOLEAN			-- RFC34102
	from SITECONTROL
	where CONTROLID='Keep Consolidated Name'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nOfficeID	int		OUTPUT,
				  @nLogMinutes	int		OUTPUT,
				  @bRetainName	bit		OUTPUT',
				  @nOfficeID  = @nOfficeID	OUTPUT,
				  @nLogMinutes=@nLogMinutes	OUTPUT,
				  @bRetainName=@bRetainName	OUTPUT

	If @bRetainName is null
		Set @bRetainName=0
End

---------------------------------------------------
-- Get Transaction Number for use in audit records.
---------------------------------------------------
If @nErrorCode=0
Begin
	-----------------------------------------------------------------------------
	-- A separate database transaction will be used to insert the TRANSACTIONINFO
	-- row to ensure the lock on the database is kept to a minimum as this table
	-- will be used extensively by other processes.
	-----------------------------------------------------------------------------

	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Allocate a transaction id that can be accessed by the audit logs
	-- for inclusion.

	Set @sSQLString="Insert into TRANSACTIONINFO(TRANSACTIONDATE) values(getdate())
			Set @nTransNo=SCOPE_IDENTITY()"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTransNo	int	OUTPUT',
					  @nTransNo=@nTransNo	OUTPUT

	--------------------------------------------------------------
	-- Load a common area accessible from the database server with
	-- the UserIdentityId and the TransactionNo just generated.
	-- This will be used by the audit logs.
	--------------------------------------------------------------
	If @nErrorCode=0
	Begin
		Set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4)+ 
				substring(cast(isnull(@nTransNo,'') as varbinary),1,4)+ 
				substring(cast(isnull(@nBatchNo,'') as varbinary),1,4) +
				substring(cast(isnull(@nOfficeID,'') as varbinary),1,4) +
				substring(cast(isnull(@nLogMinutes,'') as varbinary),1,4)
		SET CONTEXT_INFO @bHexNumber
	End

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

-----------------------------------------------------------------------------------------------
-- N A M E   C O N S O L I D A T I O N
-- Details of the Old Name that do not exist already against the New Name will be moved to the
-- new Name. 
-----------------------------------------------------------------------------------------------
If @nErrorCode=0
Begin
	Select @TranCountStart = @@TranCount

	Begin TRANSACTION
	
	------------------------------------------------
	-- N A M E R E P L A C E D
	-- Keep track of the names being consolidated by
	-- inserting a row into NAMEREPLACED
	------------------------------------------------
	If @nErrorCode=0
	and not exists(select 1 from NAMEREPLACED where OLDNAMENO=@pnNameNoConsolidateFrom and NEWNAMENO=@pnNameNoConsolidateTo)
	Begin
		insert into NAMEREPLACED(OLDNAMENO, NEWNAMENO) values(@pnNameNoConsolidateFrom, @pnNameNoConsolidateTo)
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		update NR
		set NEWNAMENO=@pnNameNoConsolidateTo
		from NAMEREPLACED NR
		where NR.NEWNAMENO=@pnNameNoConsolidateFrom
		and not exists
		(Select 1 from NAMEREPLACED NR1
		 where NR1.OLDNAMENO=NR.OLDNAMENO
		 and   NR1.NEWNAMENO=@pnNameNoConsolidateTo)
		
		set @nErrorCode=@@Error
	End
	
	--------------------------------------------------------
	-- I P N A M E
	-- If Old Name is a Client (IPNAME exists) and New Name
	-- is not a Client then the new Name will be  given the
	-- Client details currently associated with the Old Name
	--------------------------------------------------------
	If @nErrorCode=0
	and exists(select 1 from IPNAME where NAMENO=@pnNameNoConsolidateFrom)
	Begin
		If not exists(select 1 from IPNAME where NAMENO=@pnNameNoConsolidateTo)
		Begin
			update IPNAME
			set NAMENO=@pnNameNoConsolidateTo
			where NAMENO=@pnNameNoConsolidateFrom
			
			Set @nErrorCode=@@Error
		End
		Else If @bRetainName = 0
		Begin
			delete IPNAME
			where NAMENO=@pnNameNoConsolidateFrom
			
			Set @nErrorCode=@@Error
		End
			
		If @nErrorCode=0
		Begin
			----------------------------------
			-- Set the USEDASFLAG to allow the
			-- name to be used as a client
			----------------------------------
			update NAME
			set USEDASFLAG=USEDASFLAG|4
			where NAMENO=@pnNameNoConsolidateTo
			and isnull(USEDASFLAG,0)&4=0
			
			Set @nErrorCode=@@Error
		End
	End
	
	-----------------------------------------------------------
	-- C R E D I T O R
	-- If Old Name is a Supplier (CREDITOR exists) and New Name
	-- is not a Supplier then the new Name will be given the
	-- Client details currently associated with the Old Name
	-----------------------------------------------------------
	If @nErrorCode=0
	and not exists(select 1 from CREDITOR where NAMENO=@pnNameNoConsolidateTo)
	and     exists(select 1 from CREDITOR where NAMENO=@pnNameNoConsolidateFrom)
	Begin
		insert into CREDITOR 
		(	 NAMENO
			,SUPPLIERTYPE
			,DEFAULTTAXCODE
			,TAXTREATMENT
			,PURCHASECURRENCY
			,PAYMENTTERMNO
			,CHEQUEPAYEE
			,INSTRUCTIONS
			,EXPENSEACCOUNT
			,PROFITCENTRE
			,PAYMENTMETHOD
			,BANKNAME
			,BANKBRANCHNO
			,BANKACCOUNTNO
			,BANKACCOUNTNAME
			,BANKACCOUNTOWNER
			,BANKNAMENO
			,BANKSEQUENCENO
			,RESTRICTIONID
			,RESTNREASONCODE
			,PURCHASEDESC
			,DISBWIPCODE
			,BEIBANKCODE
			,BEICOUNTRYCODE
			,BEILOCATIONCODE
			,BEIBRANCHCODE
			,INSTRUCTIONS_TID
			,EXCHSCHEDULEID )
		select  @pnNameNoConsolidateTo
			,C.SUPPLIERTYPE
			,C.DEFAULTTAXCODE
			,C.TAXTREATMENT
			,C.PURCHASECURRENCY
			,C.PAYMENTTERMNO
			,C.CHEQUEPAYEE
			,C.INSTRUCTIONS
			,C.EXPENSEACCOUNT
			,C.PROFITCENTRE
			,C.PAYMENTMETHOD
			,C.BANKNAME
			,C.BANKBRANCHNO
			,C.BANKACCOUNTNO
			,C.BANKACCOUNTNAME
			,C.BANKACCOUNTOWNER
			,C.BANKNAMENO
			,C.BANKSEQUENCENO
			,C.RESTRICTIONID
			,C.RESTNREASONCODE
			,C.PURCHASEDESC
			,C.DISBWIPCODE
			,C.BEIBANKCODE
			,C.BEICOUNTRYCODE
			,C.BEILOCATIONCODE
			,C.BEIBRANCHCODE
			,C.INSTRUCTIONS_TID
			,C.EXCHSCHEDULEID
		  from CREDITOR C
		  left join CREDITOR C1 on (C1.NAMENO=@pnNameNoConsolidateTo)
		  where C.NAMENO=@pnNameNoConsolidateFrom
		  and C1.NAMENO is null
		
		Set @nErrorCode=@@Error
		
		if @nErrorCode=0
		Begin
			UPDATE NAME
			set SUPPLIERFLAG=1
			where NAMENO=@pnNameNoConsolidateTo
			and isnull(SUPPLIERFLAG,0)=0
			
			Set @nErrorCode=@@Error
		End
	End
	-- Change parent of CRENTITYDETAIL
	-- if a row does not already exist
	If @nErrorCode=0
	Begin
		update C1
		set NAMENO=@pnNameNoConsolidateTo
		from CRENTITYDETAIL C1
		left join (select * from CRENTITYDETAIL) C2
					on (C2.NAMENO=@pnNameNoConsolidateTo
					and C2.ENTITYNAMENO=C1.ENTITYNAMENO)
		where C1.NAMENO=@pnNameNoConsolidateFrom
		and C2.NAMENO is null
		
		Set @nErrorCode=@@Error
	End
	-- Delete CRENTITYDETAIL that is no longer required
	If @nErrorCode=0
	and @bRetainName=0
	Begin
		Delete C1
		from CRENTITYDETAIL C1
		where C1.NAMENO=@pnNameNoConsolidateFrom
		
		Set @nErrorCode=@@Error
	End
	
	----------------------------------------------------
	-- I N D I V I D U A L
	-- If Old Name is a Individual and New Name
	-- is not an Individual then copy the row across.
	-- This is so we do not break referential links from
	-- ASSOCIATENAME table. 
	----------------------------------------------------
	If @nErrorCode=0
	and not exists(select 1 from INDIVIDUAL where NAMENO=@pnNameNoConsolidateTo)
	and     exists(select 1 from INDIVIDUAL where NAMENO=@pnNameNoConsolidateFrom)
	Begin
		insert into INDIVIDUAL
		(	 NAMENO
			,SEX
			,FORMALSALUTATION
			,CASUALSALUTATION)
		select   @pnNameNoConsolidateTo
			,SEX
			,FORMALSALUTATION
			,CASUALSALUTATION
		from INDIVIDUAL
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- Change parent of ASSOCIATEDNAME
	-- where it points to INDIVIDUAL
	If @nErrorCode=0
	Begin
		update ASSOCIATEDNAME
		set CONTACT=@pnNameNoConsolidateTo
		where CONTACT=@pnNameNoConsolidateFrom
		
		Set @nErrorCode=@@Error
	End

	-- Delete INDIVIDUAL
	If @nErrorCode=0
	and @bRetainName=0
	Begin
		delete INDIVIDUAL
		where NAMENO=@pnNameNoConsolidateFrom
		
		Set @nErrorCode=@@Error
	End
	
	----------------------------------------------------
	-- N A M E A D D R E S S
	-- Only keep the NameAddress if explicitly indicated
	-- or it is referenced by NAMEADDRESSCPACLIENT
	-- or it is referenced by CASENAME.
	----------------------------------------------------
	If @nErrorCode=0
	and (@pbKeepAddressHistory=1
	 or exists (select 1 from CASENAME where NAMENO=@pnNameNoConsolidateFrom and ADDRESSCODE is not null)
	 or exists (select 1 from NAMEADDRESSCPACLIENT where NAMENO=@pnNameNoConsolidateFrom) )
	Begin
		insert into NAMEADDRESS
		(	 NAMENO
			,ADDRESSTYPE
			,ADDRESSCODE
			,ADDRESSSTATUS
			,DATECEASED
			,OWNEDBY)
		select	 @pnNameNoConsolidateTo
			,NA.ADDRESSTYPE
			,NA.ADDRESSCODE
			,NA.ADDRESSSTATUS
			,NA.DATECEASED
			,NA.OWNEDBY
		from NAMEADDRESS NA
		left join NAMEADDRESS NA1
					on (NA1.NAMENO=@pnNameNoConsolidateTo
					and NA1.ADDRESSTYPE=NA.ADDRESSTYPE
					and NA1.ADDRESSCODE=NA.ADDRESSCODE)	
		where NA.NAMENO=@pnNameNoConsolidateFrom
		and NA1.NAMENO is null
		
		set @nErrorCode=@@Error
		
		If @nErrorCode=0
		Begin
			update NAMEADDRESSCPACLIENT
			set NAMENO=@pnNameNoConsolidateTo
			where NAMENO=@pnNameNoConsolidateFrom
			
			set @nErrorCode=@@Error
		End
	End
	
	----------------------------------------------------
	-- N A M E T E L E C O M
	-- Only keep the NameTelecom if explicitly indicated	
	----------------------------------------------------
	If @nErrorCode=0
	and @pbKeepTelecomHistory=1
	Begin
		update NT
		set NAMENO=@pnNameNoConsolidateTo
		from NAMETELECOM NT
		left join (select * from NAMETELECOM) NT1
				on (NT1.NAMENO=@pnNameNoConsolidateTo
				and NT1.TELECODE=NT.TELECODE)
		where NT.NAMENO=@pnNameNoConsolidateFrom
		and NT1.NAMENO is null
		
		set @nErrorCode=@@Error
	End
	
	----------------------------------------------------
	-- F I L E S I N
	----------------------------------------------------
	If @nErrorCode=0
	Begin
		update F
		set NAMENO=@pnNameNoConsolidateTo
		from FILESIN F
		left join (select * from FILESIN) F1
				on (F1.NAMENO=@pnNameNoConsolidateTo
				and F1.COUNTRYCODE=F.COUNTRYCODE)
		where F.NAMENO=@pnNameNoConsolidateFrom
		and F1.NAMENO is null
		
		set @nErrorCode=@@Error
	End
	
	----------------------------------------------------
	-- N A M E
	----------------------------------------------------
	If @nErrorCode=0
	Begin
		update NAME
		set MAINCONTACT=@pnNameNoConsolidateTo
		where MAINCONTACT=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	----------------------------------------------------
	-- N A M E A L I A S	
	----------------------------------------------------
	If @nErrorCode=0
	Begin
		update NA
		set NAMENO=@pnNameNoConsolidateTo
		from NAMEALIAS NA
		left join (select * from NAMEALIAS) NA1
				on (NA1.NAMENO=@pnNameNoConsolidateTo
				and NA1.ALIAS=NA.ALIAS
				and NA1.ALIASTYPE=NA.ALIASTYPE
				and(NA1.COUNTRYCODE =NA.COUNTRYCODE  OR (NA1.COUNTRYCODE  is null and NA.COUNTRYCODE  is null))
				and(NA1.PROPERTYTYPE=NA.PROPERTYTYPE OR (NA1.PROPERTYTYPE is null and NA.PROPERTYTYPE is null)))
		where NA.NAMENO=@pnNameNoConsolidateFrom
		and NA1.NAMENO is null
		
		set @nErrorCode=@@Error
	End
	
	----------------------------------------------------
	-- N A M E I M A G E
	----------------------------------------------------
	If @nErrorCode=0
	Begin
		update NA
		set NAMENO=@pnNameNoConsolidateTo
		from NAMEIMAGE NA
		left join (select * from NAMEIMAGE) NA1
				on (NA1.NAMENO=@pnNameNoConsolidateTo
				and NA1.IMAGEID=NA.IMAGEID)
		where NA.NAMENO=@pnNameNoConsolidateFrom
		and NA1.NAMENO is null
		
		set @nErrorCode=@@Error
	End
	
	----------------------------------------------------
	-- N A M E T E X T
	----------------------------------------------------
	If @nErrorCode=0
	Begin
		update NA
		set NAMENO=@pnNameNoConsolidateTo
		from NAMETEXT NA
		left join (select * from NAMETEXT) NA1
				on (NA1.NAMENO=@pnNameNoConsolidateTo
				and NA1.TEXTTYPE=NA.TEXTTYPE)
		where NA.NAMENO=@pnNameNoConsolidateFrom
		and NA1.NAMENO is null
		
		set @nErrorCode=@@Error
	End
	
	----------------------------------------------------
	-- A S S O C I A T E D N A M E
	----------------------------------------------------
	If @nErrorCode=0
	Begin
		update NA
		set NAMENO=@pnNameNoConsolidateTo
		from ASSOCIATEDNAME NA
		left join (select * from ASSOCIATEDNAME) NA1
				on (NA1.NAMENO=@pnNameNoConsolidateTo
				and NA1.RELATIONSHIP=NA.RELATIONSHIP
				and NA1.RELATEDNAME=NA.RELATEDNAME)
		where NA.NAMENO=@pnNameNoConsolidateFrom
		and NA1.NAMENO is null
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		update NA
		set RELATEDNAME=@pnNameNoConsolidateTo
		from ASSOCIATEDNAME NA
		left join (select * from ASSOCIATEDNAME) NA1
				on (NA1.NAMENO=NA.NAMENO
				and NA1.RELATIONSHIP=NA.RELATIONSHIP
				and NA1.RELATEDNAME=@pnNameNoConsolidateTo)
		where NA.RELATEDNAME=@pnNameNoConsolidateFrom
		and NA1.NAMENO is null
		
		set @nErrorCode=@@Error
	End
	
	-- Remove refences back to this name
	-- even if the old name is being 
	-- retained.
	If @nErrorCode=0
	Begin
		Delete ASSOCIATEDNAME
		where RELATEDNAME=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	and @bRetainName=0
	Begin
		Delete ASSOCIATEDNAME
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	----------------------------------------------------
	-- D I S C O U N T
	-- Copy Discount rows to the new Name if a discount
	-- for the same characteristics does not exist.
	----------------------------------------------------
	If @nErrorCode=0
	Begin
		insert into DISCOUNT
		(	 NAMENO
			,SEQUENCE
			,PROPERTYTYPE
			,ACTION
			,DISCOUNTRATE
			,WIPCATEGORY
			,BASEDONAMOUNT
			,WIPTYPEID
			,EMPLOYEENO
			,PRODUCTCODE
			,CASEOWNER
			,MARGINPROFILENO
			,WIPCODE
			,CASETYPE
                        ,COUNTRYCODE)
		select	 @pnNameNoConsolidateTo
			,D.SEQUENCE+isnull(D1.SEQUENCE,0)+1
			,D.PROPERTYTYPE
			,D.ACTION
			,D.DISCOUNTRATE
			,D.WIPCATEGORY
			,D.BASEDONAMOUNT
			,D.WIPTYPEID
			,D.EMPLOYEENO
			,D.PRODUCTCODE
			,D.CASEOWNER
			,D.MARGINPROFILENO
			,D.WIPCODE
			,D.CASETYPE
                        ,D.COUNTRYCODE
		from	DISCOUNT D
		left join (select NAMENO, max(SEQUENCE) as SEQUENCE
			   from DISCOUNT
			   group by NAMENO) D1
					on (D1.NAMENO=@pnNameNoConsolidateTo)
		left join DISCOUNT D2	on (D2.NAMENO=@pnNameNoConsolidateTo
					and isnull(D2.PROPERTYTYPE,'')=isnull(D.PROPERTYTYPE,'')
					and isnull(D2.ACTION,'')      =isnull(D.ACTION,'')
					and isnull(D2.WIPCATEGORY,'') =isnull(D.WIPCATEGORY,'')
					and isnull(D2.WIPTYPEID,'')   =isnull(D.WIPTYPEID,'')
					and isnull(D2.EMPLOYEENO,'')  =isnull(D.EMPLOYEENO,'')
					and isnull(D2.PRODUCTCODE,'') =isnull(D.PRODUCTCODE,'')
					and isnull(D2.CASEOWNER,'')   =isnull(D.CASEOWNER,'')
					and isnull(D2.WIPCODE,'' )    =isnull(D.WIPCODE, '')
					and isnull(D2.CASETYPE, '')   =isnull(D.CASETYPE, '')
                                        and isnull(D2.COUNTRYCODE, '')=isnull(D.COUNTRYCODE, ''))
		where	D.NAMENO=@pnNameNoConsolidateFrom
		and D2.NAMENO is null
		
		set @nErrorCode=@@Error
	End
	
	-- DISCOUNT.CASEOWNER
	If @nErrorCode=0
	Begin
		update DISCOUNT
		set CASEOWNER=@pnNameNoConsolidateTo
		where CASEOWNER=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	-- DISCOUNT.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update DISCOUNT
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- Remove 
	If @nErrorCode=0
	and @bRetainName=0
	Begin
		Delete DISCOUNT
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	----------------------------------------------------------
	-- N A M E I N S T R U C T I O N S
	-- Copy NameInstruction rows to the new Name if
	-- instructions for the same characteristics do not exist.
	----------------------------------------------------------
	If @nErrorCode=0
	Begin
		insert into NAMEINSTRUCTIONS
		(	 NAMENO
			,INTERNALSEQUENCE
			,RESTRICTEDTONAME
			,INSTRUCTIONCODE
			,CASEID
			,COUNTRYCODE
			,PROPERTYTYPE
			,PERIOD1AMT
			,PERIOD1TYPE
			,PERIOD2AMT
			,PERIOD2TYPE
			,PERIOD3AMT
			,PERIOD3TYPE
			,ADJUSTMENT
			,ADJUSTDAY
			,ADJUSTSTARTMONTH
			,ADJUSTDAYOFWEEK
			,ADJUSTTODATE
			,STANDINGINSTRTEXT)
		select	 @pnNameNoConsolidateTo
			,N.INTERNALSEQUENCE+isnull(N1.INTERNALSEQUENCE,0)+1
			,N.RESTRICTEDTONAME
			,N.INSTRUCTIONCODE
			,N.CASEID
			,N.COUNTRYCODE
			,N.PROPERTYTYPE
			,N.PERIOD1AMT
			,N.PERIOD1TYPE
			,N.PERIOD2AMT
			,N.PERIOD2TYPE
			,N.PERIOD3AMT
			,N.PERIOD3TYPE
			,N.ADJUSTMENT
			,N.ADJUSTDAY
			,N.ADJUSTSTARTMONTH
			,N.ADJUSTDAYOFWEEK
			,N.ADJUSTTODATE
			,N.STANDINGINSTRTEXT
		from	NAMEINSTRUCTIONS N
		left join (select NAMENO, max(INTERNALSEQUENCE) as INTERNALSEQUENCE
			   from NAMEINSTRUCTIONS
			   group by NAMENO) N1
						on (N1.NAMENO=@pnNameNoConsolidateTo)
		left join NAMEINSTRUCTIONS N2	on (N2.NAMENO=@pnNameNoConsolidateTo
						and isnull(N2.RESTRICTEDTONAME,'')=isnull(N.RESTRICTEDTONAME,'')
						and isnull(N2.CASEID,'')          =isnull(N.CASEID,'')
						and isnull(N2.COUNTRYCODE,'')     =isnull(N.COUNTRYCODE,'')
						and isnull(N2.PROPERTYTYPE,'')    =isnull(N.PROPERTYTYPE,''))
		where	N.NAMENO=@pnNameNoConsolidateFrom
		and N2.NAMENO is null
		
		set @nErrorCode=@@Error
	End
	
	-- NAMEINSTRUCTIONS.RESTRICTEDTONAME
	If @nErrorCode=0
	Begin
		update NAMEINSTRUCTIONS
		set RESTRICTEDTONAME=@pnNameNoConsolidateTo
		where RESTRICTEDTONAME=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	If @nErrorCode=0
	and @bRetainName=0
	Begin
		Delete NAMEINSTRUCTIONS
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	----------------------------------------------------
	-- N A M E L A N G U A G E
	----------------------------------------------------
	If @nErrorCode=0
	and @bRetainName=0
	Begin
		delete NAMELANGUAGE
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	----------------------------------------------------
	-- O R G A N I S A T I O N
	----------------------------------------------------
	If @nErrorCode=0
	and @bRetainName=0
	Begin
		delete ORGANISATION
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	----------------------------------------------------
	-- N A M E I N S T R U C T I O N S
	----------------------------------------------------
	If @nErrorCode=0
	and @bRetainName=0
	Begin
		delete NAMEINSTRUCTIONS
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	and @bRetainName=0
	Begin
		delete NAMEINSTRUCTIONS
		where RESTRICTEDTONAME=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	----------------------------------------------------
	-- N A M E M A R G I N P R O F I L E
	----------------------------------------------------
	If @nErrorCode=0
	and @bRetainName=0
	Begin
		delete NAMEMARGINPROFILE
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	----------------------------------------------------
	-- N A M E T Y P E C L A S S I F I C A T I O N
	-- Move the NameTypeClassification rule that are 
	-- allowed, if no rule exists on the new name.
	----------------------------------------------------
	If @nErrorCode=0
	Begin
		Update NT
		set NAMENO=@pnNameNoConsolidateTo
		from NAMETYPECLASSIFICATION NT
		left join (select * from NAMETYPECLASSIFICATION) NT1
				on (NT1.NAMENO=@pnNameNoConsolidateTo
				and NT1.NAMETYPE=NT.NAMETYPE)
		where NT.NAMENO=@pnNameNoConsolidateFrom
		and NT.ALLOW=1
		and NT1.NAMENO is null
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	and @bRetainName=0
	Begin
		delete NAMETYPECLASSIFICATION
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	

	
	----------------------------------------------------
	-- S P E C I A L N A M E
	----------------------------------------------------
	If @nErrorCode=0
	Begin
		INSERT INTO SPECIALNAME
		(	 NAMENO
			,ENTITYFLAG
			,IPOFFICEFLAG
			,BANKFLAG
			,LASTOPENITEMNO
			,LASTDRAFTNO
			,LASTARNO
			,LASTINTERNALITEMNO
			,LASTAPNO
			,CURRENCY)		
		SELECT   @pnNameNoConsolidateTo
			,S.ENTITYFLAG
			,S.IPOFFICEFLAG
			,S.BANKFLAG
			,S.LASTOPENITEMNO
			,S.LASTDRAFTNO
			,S.LASTARNO
			,S.LASTINTERNALITEMNO
			,S.LASTAPNO
			,S.CURRENCY
		FROM SPECIALNAME S
		left join SPECIALNAME S1 on (S1.NAMENO=@pnNameNoConsolidateTo)
		where S.NAMENO=@pnNameNoConsolidateFrom
		and S1.NAMENO is null
		
		set @nErrorCode=@@Error
	End
	
	------------------------------------
	-- T R A N S A C T I O N H E A D E R
	------------------------------------

	-- TRANSACTIONHEADER.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update TRANSACTIONHEADER
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	----------------------------------------------------
	-- A C C O U N T
	-- Consolidate the Account balance values
	----------------------------------------------------
	If @nErrorCode=0
	Begin
		-- The ACCOUNT already exists for the Name 
		-- being consolidated into
		update	A
		set	BALANCE  =isnull(A.BALANCE,0)  +isnull(A1.BALANCE,0),
			CRBALANCE=isnull(A.CRBALANCE,0)+isnull(A1.CRBALANCE,0)
		from	ACCOUNT A
		join (	select * from ACCOUNT
			where NAMENO=@pnNameNoConsolidateFrom) A1
				on (A1.ENTITYNO=A.ENTITYNO)
		where A.NAMENO=@pnNameNoConsolidateTo
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		-- The ACCOUNT already exists for the EntityNo 
		-- being consolidated into
		update	A
		set	BALANCE  =isnull(A.BALANCE,0)  +isnull(A1.BALANCE,0),
			CRBALANCE=isnull(A.CRBALANCE,0)+isnull(A1.CRBALANCE,0)
		from	ACCOUNT A
		join (	select * from ACCOUNT
			where ENTITYNO=@pnNameNoConsolidateFrom) A1
				on (A1.NAMENO=A.NAMENO)
		where A.ENTITYNO=@pnNameNoConsolidateTo
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		-- The ACCOUNT does not exist for the EntityNo 
		-- being consolidated so copy the existing
		-- ACCOUNT rows
		insert into ACCOUNT
		(	 ENTITYNO
			,NAMENO
			,BALANCE
			,CRBALANCE)
		select	 @pnNameNoConsolidateTo
			,A.NAMENO
			,isnull(A.BALANCE,0)
			,isnull(A.CRBALANCE,0)
		from ACCOUNT A
		left join ACCOUNT A1	on (A1.ENTITYNO=@pnNameNoConsolidateTo
					and A1.NAMENO  =A.NAMENO)
		where A.ENTITYNO=@pnNameNoConsolidateFrom
		and A1.ENTITYNO is null
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		-- The ACCOUNT does not exist for the NameNo 
		-- being consolidated so copy the existing
		-- ACCOUNT rows
		insert into ACCOUNT
		(	 ENTITYNO
			,NAMENO
			,BALANCE
			,CRBALANCE)
		select	 A.ENTITYNO
			,@pnNameNoConsolidateTo
			,isnull(A.BALANCE,0)
			,isnull(A.CRBALANCE,0)
		from ACCOUNT A
		left join ACCOUNT A1	on (A1.ENTITYNO=A.ENTITYNO
					and A1.NAMENO  =@pnNameNoConsolidateTo)
		where A.NAMENO=@pnNameNoConsolidateFrom
		and A1.ENTITYNO is null
		
		set @nErrorCode=@@Error
	End
	
	-- Now update tables that are pointing to the
	-- ACCOUNT rows being updated.
	
	If @nErrorCode=0
	Begin
		update	BILLEDITEM
		set	ACCTDEBTORNO=@pnNameNoConsolidateTo
		where	ACCTDEBTORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
		
	If @nErrorCode=0
	Begin
		INSERT INTO CREDITORITEM
		(	 ITEMENTITYNO
			,ITEMTRANSNO
			,ACCTENTITYNO
			,ACCTCREDITORNO
			,DOCUMENTREF
			,ITEMDATE
			,ITEMDUEDATE
			,POSTDATE
			,POSTPERIOD
			,CLOSEPOSTDATE
			,CLOSEPOSTPERIOD
			,ITEMTYPE
			,CURRENCY
			,EXCHRATE
			,LOCALPRETAXVALUE
			,LOCALVALUE
			,LOCALTAXAMOUNT
			,FOREIGNVALUE
			,FOREIGNTAXAMT
			,LOCALBALANCE
			,FOREIGNBALANCE
			,EXCHVARIANCE
			,[STATUS]
			,[DESCRIPTION]
			,LONGDESCRIPTION
			,RESTRICTIONID
			,RESTNREASONCODE
			,PROTOCOLNO
			,PROTOCOLDATE)
		SELECT	 ITEMENTITYNO
			,ITEMTRANSNO
			,ACCTENTITYNO
			,@pnNameNoConsolidateTo
			,DOCUMENTREF
			,ITEMDATE
			,ITEMDUEDATE
			,POSTDATE
			,POSTPERIOD
			,CLOSEPOSTDATE
			,CLOSEPOSTPERIOD
			,ITEMTYPE
			,CURRENCY
			,EXCHRATE
			,LOCALPRETAXVALUE
			,LOCALVALUE
			,LOCALTAXAMOUNT
			,FOREIGNVALUE
			,FOREIGNTAXAMT
			,LOCALBALANCE
			,FOREIGNBALANCE
			,EXCHVARIANCE
			,[STATUS]
			,[DESCRIPTION]
			,LONGDESCRIPTION
			,RESTRICTIONID
			,RESTNREASONCODE
			,PROTOCOLNO
			,PROTOCOLDATE
		FROM CREDITORITEM
		where ACCTCREDITORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	If @nErrorCode=0
	Begin
		INSERT INTO CREDITORHISTORY
			(ITEMENTITYNO
			,ITEMTRANSNO
			,ACCTENTITYNO
			,ACCTCREDITORNO
			,HISTORYLINENO
			,DOCUMENTREF
			,TRANSDATE
			,POSTDATE
			,POSTPERIOD
			,TRANSTYPE
			,MOVEMENTCLASS
			,COMMANDID
			,ITEMPRETAXVALUE
			,LOCALTAXAMT
			,LOCALVALUE
			,EXCHVARIANCE
			,FOREIGNTAXAMT
			,FOREIGNTRANVALUE
			,REFENTITYNO
			,REFTRANSNO
			,LOCALBALANCE
			,FOREIGNBALANCE
			,FORCEDPAYOUT
			,CURRENCY
			,EXCHRATE
			,[STATUS]
			,ASSOCLINENO
			,ITEMIMPACT
			,[DESCRIPTION]
			,LONGDESCRIPTION
			,GLMOVEMENTNO
			,GLSTATUS
			,REMITTANCENAMENO)
		SELECT   ITEMENTITYNO
			,ITEMTRANSNO
			,ACCTENTITYNO
			,@pnNameNoConsolidateTo
			,HISTORYLINENO
			,DOCUMENTREF
			,TRANSDATE
			,POSTDATE
			,POSTPERIOD
			,TRANSTYPE
			,MOVEMENTCLASS
			,COMMANDID
			,ITEMPRETAXVALUE
			,LOCALTAXAMT
			,LOCALVALUE
			,EXCHVARIANCE
			,FOREIGNTAXAMT
			,FOREIGNTRANVALUE
			,REFENTITYNO
			,REFTRANSNO
			,LOCALBALANCE
			,FOREIGNBALANCE
			,FORCEDPAYOUT
			,CURRENCY
			,EXCHRATE
			,[STATUS]
			,ASSOCLINENO
			,ITEMIMPACT
			,[DESCRIPTION]
			,LONGDESCRIPTION
			,GLMOVEMENTNO
			,GLSTATUS
			,REMITTANCENAMENO
		FROM CREDITORHISTORY
		where ACCTCREDITORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		INSERT INTO TAXPAIDHISTORY
		(	 ITEMENTITYNO
			,ITEMTRANSNO
			,ACCTENTITYNO
			,ACCTCREDITORNO
			,HISTORYLINENO
			,TAXCODE
			,COUNTRYCODE
			,TAXRATE
			,TAXABLEAMOUNT
			,TAXAMOUNT
			,REFENTITYNO
			,REFTRANSNO)
		SELECT	 ITEMENTITYNO
			,ITEMTRANSNO
			,ACCTENTITYNO
			,@pnNameNoConsolidateTo
			,HISTORYLINENO
			,TAXCODE
			,COUNTRYCODE
			,TAXRATE
			,TAXABLEAMOUNT
			,TAXAMOUNT
			,REFENTITYNO
			,REFTRANSNO
		FROM TAXPAIDHISTORY
		WHERE ACCTCREDITORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		DELETE TAXPAIDHISTORY
		where ACCTCREDITORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		DELETE CREDITORHISTORY
		where ACCTCREDITORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		INSERT INTO PAYMENTPLANDETAIL
		(	 PLANID
			,ITEMENTITYNO
			,ITEMTRANSNO
			,ACCTENTITYNO
			,ACCTCREDITORNO
			,REFENTITYNO
			,REFTRANSNO
			,PAYMENTAMOUNT
			,FXDEALERREF
			,ACCOUNTID)
		SELECT	 PLANID
			,ITEMENTITYNO
			,ITEMTRANSNO
			,ACCTENTITYNO
			,@pnNameNoConsolidateTo
			,REFENTITYNO
			,REFTRANSNO
			,PAYMENTAMOUNT
			,FXDEALERREF
			,ACCOUNTID
		FROM PAYMENTPLANDETAIL
		WHERE ACCTCREDITORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		DELETE PAYMENTPLANDETAIL
		where ACCTCREDITORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		INSERT INTO TAXPAIDITEM
		(	 ITEMENTITYNO
			,ITEMTRANSNO
			,ACCTENTITYNO
			,ACCTCREDITORNO
			,TAXCODE
			,COUNTRYCODE
			,TAXRATE
			,TAXABLEAMOUNT
			,TAXAMOUNT)
		SELECT	 ITEMENTITYNO
			,ITEMTRANSNO
			,ACCTENTITYNO
			,@pnNameNoConsolidateTo
			,TAXCODE
			,COUNTRYCODE
			,TAXRATE
			,TAXABLEAMOUNT
			,TAXAMOUNT
		FROM TAXPAIDITEM
		WHERE ACCTCREDITORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		DELETE TAXPAIDITEM
		where ACCTCREDITORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
		
	If @nErrorCode=0
	Begin
		-- Now Delete the CREDITORITEM rows that were previously copied 
		-- to the new NameNO
		Delete	CREDITORITEM
		where	ACCTCREDITORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		Insert into OPENITEM
		(	 ITEMENTITYNO
			,ITEMTRANSNO
			,ACCTENTITYNO
			,ACCTDEBTORNO
			,ACTION
			,OPENITEMNO
			,ITEMDATE
			,POSTDATE
			,POSTPERIOD
			,CLOSEPOSTDATE
			,CLOSEPOSTPERIOD
			,[STATUS]
			,ITEMTYPE
			,BILLPERCENTAGE
			,EMPLOYEENO
			,EMPPROFITCENTRE
			,CURRENCY
			,EXCHRATE
			,ITEMPRETAXVALUE
			,LOCALTAXAMT
			,LOCALVALUE
			,FOREIGNTAXAMT
			,FOREIGNVALUE
			,LOCALBALANCE
			,FOREIGNBALANCE
			,EXCHVARIANCE
			,STATEMENTREF
			,REFERENCETEXT
			,NAMESNAPNO
			,BILLFORMATID
			,BILLPRINTEDFLAG
			,REGARDING
			,SCOPE
			,LANGUAGE
			,ASSOCOPENITEMNO
			,LONGREGARDING
			,LONGREFTEXT
			,IMAGEID
			,FOREIGNEQUIVCURRCY
			,FOREIGNEQUIVEXRATE
			,ITEMDUEDATE
			,PENALTYINTEREST
			,LOCALORIGTAKENUP
			,FOREIGNORIGTAKENUP
			,REFERENCETEXT_TID
			,REGARDING_TID
			,SCOPE_TID
			,INCLUDEONLYWIP
			,PAYFORWIP
			,PAYPROPERTYTYPE
			,RENEWALDEBTORFLAG
			,CASEPROFITCENTRE
			,MAINCASEID)
		SELECT	 ITEMENTITYNO
			,ITEMTRANSNO
			,ACCTENTITYNO
			,@pnNameNoConsolidateTo
			,ACTION
			,'~'+OPENITEMNO  -- temporarily required to maintain uniqueness
			,ITEMDATE
			,POSTDATE
			,POSTPERIOD
			,CLOSEPOSTDATE
			,CLOSEPOSTPERIOD
			,[STATUS]
			,ITEMTYPE
			,BILLPERCENTAGE
			,EMPLOYEENO
			,EMPPROFITCENTRE
			,CURRENCY
			,EXCHRATE
			,ITEMPRETAXVALUE
			,LOCALTAXAMT
			,LOCALVALUE
			,FOREIGNTAXAMT
			,FOREIGNVALUE
			,LOCALBALANCE
			,FOREIGNBALANCE
			,EXCHVARIANCE
			,STATEMENTREF
			,REFERENCETEXT
			,NAMESNAPNO
			,BILLFORMATID
			,BILLPRINTEDFLAG
			,REGARDING
			,SCOPE
			,LANGUAGE
			,ASSOCOPENITEMNO
			,LONGREGARDING
			,LONGREFTEXT
			,IMAGEID
			,FOREIGNEQUIVCURRCY
			,FOREIGNEQUIVEXRATE
			,ITEMDUEDATE
			,PENALTYINTEREST
			,LOCALORIGTAKENUP
			,FOREIGNORIGTAKENUP
			,REFERENCETEXT_TID
			,REGARDING_TID
			,SCOPE_TID
			,INCLUDEONLYWIP
			,PAYFORWIP
			,PAYPROPERTYTYPE
			,RENEWALDEBTORFLAG
			,CASEPROFITCENTRE
			,MAINCASEID
		  FROM OPENITEM
		  where ACCTDEBTORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		update	OPENITEM
		set	EMPLOYEENO=@pnNameNoConsolidateTo
		where	EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		update	BILLEDCREDIT
		set	DRACCTDEBTORNO=@pnNameNoConsolidateTo
		where	DRACCTDEBTORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		update	BILLEDCREDIT
		set	CRACCTDEBTORNO=@pnNameNoConsolidateTo
		where	CRACCTDEBTORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		update	OPENITEMBREAKDOWN
		set	ACCTDEBTORNO=@pnNameNoConsolidateTo
		where	ACCTDEBTORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		update	OPENITEMCASE
		set	ACCTDEBTORNO=@pnNameNoConsolidateTo
		where	ACCTDEBTORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		update	OPENITEMTAX
		set	ACCTDEBTORNO=@pnNameNoConsolidateTo
		where	ACCTDEBTORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		update	WIPPAYMENT
		set	ACCTDEBTORNO=@pnNameNoConsolidateTo
		where	ACCTDEBTORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		-- Now Delete the OPENITEM rows that were previously copied 
		-- to the new NameNO
		Delete	OPENITEM
		where	ACCTDEBTORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		-- Now reset the OPENITEMNO that was temporarily modified to 
		-- maintain uniqueness
		Update	OPENITEM
		Set	OPENITEMNO=substring(OPENITEMNO,2,20)
		where 	ACCTDEBTORNO=@pnNameNoConsolidateTo
		AND	OPENITEMNO like '~%'
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		INSERT INTO DEBTORHISTORY
		(	 ITEMENTITYNO
			,ITEMTRANSNO
			,ACCTENTITYNO
			,ACCTDEBTORNO
			,HISTORYLINENO
			,OPENITEMNO
			,TRANSDATE
			,POSTDATE
			,POSTPERIOD
			,TRANSTYPE
			,MOVEMENTCLASS
			,COMMANDID
			,ITEMPRETAXVALUE
			,LOCALTAXAMT
			,LOCALVALUE
			,EXCHVARIANCE
			,FOREIGNTAXAMT
			,FOREIGNTRANVALUE
			,REFERENCETEXT
			,REASONCODE
			,REFENTITYNO
			,REFTRANSNO
			,REFSEQNO
			,REFACCTENTITYNO
			,REFACCTDEBTORNO
			,LOCALBALANCE
			,FOREIGNBALANCE
			,TOTALEXCHVARIANCE
			,FORCEDPAYOUT
			,CURRENCY
			,EXCHRATE
			,[STATUS]
			,ASSOCLINENO
			,ITEMIMPACT
			,LONGREFTEXT
			,GLMOVEMENTNO)
		SELECT	 ITEMENTITYNO
			,ITEMTRANSNO
			,ACCTENTITYNO
			,@pnNameNoConsolidateTo
			,HISTORYLINENO
			,OPENITEMNO
			,TRANSDATE
			,POSTDATE
			,POSTPERIOD
			,TRANSTYPE
			,MOVEMENTCLASS
			,COMMANDID
			,ITEMPRETAXVALUE
			,LOCALTAXAMT
			,LOCALVALUE
			,EXCHVARIANCE
			,FOREIGNTAXAMT
			,FOREIGNTRANVALUE
			,REFERENCETEXT
			,REASONCODE
			,REFENTITYNO
			,REFTRANSNO
			,REFSEQNO
			,REFACCTENTITYNO
			,REFACCTDEBTORNO
			,LOCALBALANCE
			,FOREIGNBALANCE
			,TOTALEXCHVARIANCE
			,FORCEDPAYOUT
			,CURRENCY
			,EXCHRATE
			,[STATUS]
			,ASSOCLINENO
			,ITEMIMPACT
			,LONGREFTEXT
			,GLMOVEMENTNO
		FROM DEBTORHISTORY
		where ACCTDEBTORNO=@pnNameNoConsolidateFrom
	End
	
	If @nErrorCode=0
	Begin
		update	DEBTORHISTORYCASE
		set	ACCTDEBTORNO=@pnNameNoConsolidateTo
		where	ACCTDEBTORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		update	TAXHISTORY
		set	ACCTDEBTORNO=@pnNameNoConsolidateTo
		where	ACCTDEBTORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		-- Now Delete the OPENITEM rows that were previously copied 
		-- to the new NameNO
		Delete	DEBTORHISTORY
		where	ACCTDEBTORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		update	TRANSADJUSTMENT
		set	TOACCTNAMENO=@pnNameNoConsolidateTo
		where	TOACCTNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin	
		INSERT INTO TRUSTACCOUNT
		(	 ENTITYNO
			,NAMENO
			,BALANCE)
		SELECT	 ENTITYNO
			,@pnNameNoConsolidateTo
			,BALANCE
		FROM TRUSTACCOUNT
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		INSERT INTO TRUSTITEM
		(	 ITEMENTITYNO
			,ITEMTRANSNO
			,TACCTENTITYNO
			,TACCTNAMENO
			,ITEMNO
			,ITEMDATE
			,POSTDATE
			,POSTPERIOD
			,CLOSEPOSTDATE
			,CLOSEPOSTPERIOD
			,ITEMTYPE
			,EMPLOYEENO
			,CURRENCY
			,EXCHRATE
			,LOCALVALUE
			,FOREIGNVALUE
			,LOCALBALANCE
			,FOREIGNBALANCE
			,EXCHVARIANCE
			,[STATUS]
			,[DESCRIPTION]
			,LONGDESCRIPTION)
		SELECT   ITEMENTITYNO
			,ITEMTRANSNO
			,TACCTENTITYNO
			,@pnNameNoConsolidateTo
			,ITEMNO
			,ITEMDATE
			,POSTDATE
			,POSTPERIOD
			,CLOSEPOSTDATE
			,CLOSEPOSTPERIOD
			,ITEMTYPE
			,EMPLOYEENO
			,CURRENCY
			,EXCHRATE
			,LOCALVALUE
			,FOREIGNVALUE
			,LOCALBALANCE
			,FOREIGNBALANCE
			,EXCHVARIANCE
			,[STATUS]
			,[DESCRIPTION]
			,LONGDESCRIPTION
		FROM TRUSTITEM
		where TACCTNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- TRUSTITEM.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update TRUSTITEM
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	If @nErrorCode=0
	Begin
		INSERT INTO TRUSTHISTORY
		(	 ITEMENTITYNO
			,ITEMTRANSNO
			,TACCTENTITYNO
			,TACCTNAMENO
			,HISTORYLINENO
			,ITEMNO
			,TRANSDATE
			,POSTDATE
			,POSTPERIOD
			,TRANSTYPE
			,MOVEMENTCLASS
			,COMMANDID
			,LOCALVALUE
			,EXCHVARIANCE
			,FOREIGNTRANVALUE
			,REFENTITYNO
			,REFTRANSNO
			,LOCALBALANCE
			,FOREIGNBALANCE
			,FORCEDPAYOUT
			,CURRENCY
			,EXCHRATE
			,[STATUS]
			,ASSOCLINENO
			,ITEMIMPACT
			,[DESCRIPTION]
			,LONGDESCRIPTION)
		SELECT   ITEMENTITYNO
			,ITEMTRANSNO
			,TACCTENTITYNO
			,@pnNameNoConsolidateTo
			,HISTORYLINENO
			,ITEMNO
			,TRANSDATE
			,POSTDATE
			,POSTPERIOD
			,TRANSTYPE
			,MOVEMENTCLASS
			,COMMANDID
			,LOCALVALUE
			,EXCHVARIANCE
			,FOREIGNTRANVALUE
			,REFENTITYNO
			,REFTRANSNO
			,LOCALBALANCE
			,FOREIGNBALANCE
			,FORCEDPAYOUT
			,CURRENCY
			,EXCHRATE
			,[STATUS]
			,ASSOCLINENO
			,ITEMIMPACT
			,[DESCRIPTION]
			,LONGDESCRIPTION
		FROM TRUSTHISTORY
		where	TACCTNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End		
	
	If @nErrorCode=0
	Begin			
		DELETE	TRUSTHISTORY
		where	TACCTNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin			
		DELETE	TRUSTITEM
		where	TACCTNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin			
		DELETE	TRUSTACCOUNT
		where	NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		update	WORKHISTORY
		set	ACCTCLIENTNO=@pnNameNoConsolidateTo
		where	ACCTCLIENTNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	---------------------------------------
	-- B A N K A C C O U N T
	---------------------------------------
		
	If @nErrorCode=0
	Begin
		INSERT INTO BANKACCOUNT
		(	 ACCOUNTOWNER
			,BANKNAMENO
			,SEQUENCENO
			,ISOPERATIONAL
			,BANKBRANCHNO
			,BRANCHNAMENO
			,ACCOUNTNO
			,ACCOUNTNAME
			,CURRENCY
			,[DESCRIPTION]
			,ACCOUNTTYPE
			,DRAWCHEQUESFLAG
			,LASTMANUALCHEQUE
			,LASTAUTOCHEQUE
			,ACCOUNTBALANCE
			,LOCALBALANCE
			,DATECEASED
			,BICBANKCODE
			,BICCOUNTRYCODE
			,BICLOCATIONCODE
			,BICBRANCHCODE
			,IBAN
			,BANKOPERATIONCODE
			,DETAILSOFCHARGES
			,EFTFILEFORMATUSED
			,CABPROFITCENTRE
			,CABACCOUNTID
			,CABCPROFITCENTRE
			,CABCACCOUNTID
			,PROCAMOUNTTOWORDS
			,TRUSTACCTFLAG)
		SELECT   B.ACCOUNTOWNER
			,@pnNameNoConsolidateTo
			,B.SEQUENCENO
			,B.ISOPERATIONAL
			,B.BANKBRANCHNO
			,B.BRANCHNAMENO
			,B.ACCOUNTNO
			,B.ACCOUNTNAME
			,B.CURRENCY
			,B.[DESCRIPTION]
			,B.ACCOUNTTYPE
			,B.DRAWCHEQUESFLAG
			,B.LASTMANUALCHEQUE
			,B.LASTAUTOCHEQUE
			,B.ACCOUNTBALANCE
			,B.LOCALBALANCE
			,B.DATECEASED
			,B.BICBANKCODE
			,B.BICCOUNTRYCODE
			,B.BICLOCATIONCODE
			,B.BICBRANCHCODE
			,B.IBAN
			,B.BANKOPERATIONCODE
			,B.DETAILSOFCHARGES
			,B.EFTFILEFORMATUSED
			,B.CABPROFITCENTRE
			,B.CABACCOUNTID
			,B.CABCPROFITCENTRE
			,B.CABCACCOUNTID
			,B.PROCAMOUNTTOWORDS
			,B.TRUSTACCTFLAG
		FROM BANKACCOUNT B
		left join BANKACCOUNT B1	on (B1.ACCOUNTOWNER=B.ACCOUNTOWNER
						and B1.BANKNAMENO  =@pnNameNoConsolidateTo)
		where B.BANKNAMENO=@pnNameNoConsolidateFrom
		and  B1.BANKNAMENO is null
		
		set @nErrorCode=@@Error
	End
		
	If @nErrorCode=0
	Begin
		INSERT INTO BANKACCOUNT
		(	 ACCOUNTOWNER
			,BANKNAMENO
			,SEQUENCENO
			,ISOPERATIONAL
			,BANKBRANCHNO
			,BRANCHNAMENO
			,ACCOUNTNO
			,ACCOUNTNAME
			,CURRENCY
			,[DESCRIPTION]
			,ACCOUNTTYPE
			,DRAWCHEQUESFLAG
			,LASTMANUALCHEQUE
			,LASTAUTOCHEQUE
			,ACCOUNTBALANCE
			,LOCALBALANCE
			,DATECEASED
			,BICBANKCODE
			,BICCOUNTRYCODE
			,BICLOCATIONCODE
			,BICBRANCHCODE
			,IBAN
			,BANKOPERATIONCODE
			,DETAILSOFCHARGES
			,EFTFILEFORMATUSED
			,CABPROFITCENTRE
			,CABACCOUNTID
			,CABCPROFITCENTRE
			,CABCACCOUNTID
			,PROCAMOUNTTOWORDS
			,TRUSTACCTFLAG)
		SELECT   @pnNameNoConsolidateTo
			,B.BANKNAMENO
			,B.SEQUENCENO
			,B.ISOPERATIONAL
			,B.BANKBRANCHNO
			,B.BRANCHNAMENO
			,B.ACCOUNTNO
			,B.ACCOUNTNAME
			,B.CURRENCY
			,B.[DESCRIPTION]
			,B.ACCOUNTTYPE
			,B.DRAWCHEQUESFLAG
			,B.LASTMANUALCHEQUE
			,B.LASTAUTOCHEQUE
			,B.ACCOUNTBALANCE
			,B.LOCALBALANCE
			,B.DATECEASED
			,B.BICBANKCODE
			,B.BICCOUNTRYCODE
			,B.BICLOCATIONCODE
			,B.BICBRANCHCODE
			,B.IBAN
			,B.BANKOPERATIONCODE
			,B.DETAILSOFCHARGES
			,B.EFTFILEFORMATUSED
			,B.CABPROFITCENTRE
			,B.CABACCOUNTID
			,B.CABCPROFITCENTRE
			,B.CABCACCOUNTID
			,B.PROCAMOUNTTOWORDS
			,B.TRUSTACCTFLAG
		FROM BANKACCOUNT B
		left join BANKACCOUNT B1	on (B1.ACCOUNTOWNER=@pnNameNoConsolidateTo
						and B1.BANKNAMENO  =B.BANKNAMENO)
		where B.ACCOUNTOWNER=@pnNameNoConsolidateFrom
		and  B1.ACCOUNTOWNER is null
		
		set @nErrorCode=@@Error
	End

	-- BANKACCOUNT.BRANCHNAMENO
	If @nErrorCode=0
	Begin
		update BANKACCOUNT
		set BRANCHNAMENO=@pnNameNoConsolidateTo
		where BRANCHNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	------------------------
	-- B A N K H I S T O R Y
	------------------------
	If @nErrorCode=0
	Begin
		INSERT INTO BANKHISTORY
		(	 ENTITYNO
			,BANKNAMENO
			,SEQUENCENO
			,HISTORYLINENO
			,TRANSDATE
			,POSTDATE
			,POSTPERIOD
			,PAYMENTMETHOD
			,WITHDRAWALCHEQUENO
			,TRANSTYPE
			,MOVEMENTCLASS
			,COMMANDID
			,REFENTITYNO
			,REFTRANSNO
			,[STATUS]
			,[DESCRIPTION]
			,ASSOCLINENO
			,PAYMENTCURRENCY
			,PAYMENTAMOUNT
			,BANKEXCHANGERATE
			,BANKAMOUNT
			,BANKCHARGES
			,BANKNET
			,LOCALAMOUNT
			,LOCALCHARGES
			,LOCALEXCHANGERATE
			,LOCALNET
			,BANKCATEGORY
			,REFERENCE
			,ISRECONCILED
			,GLMOVEMENTNO)
		SELECT	 @pnNameNoConsolidateTo
			,B.BANKNAMENO
			,B.SEQUENCENO
			,B.HISTORYLINENO
			,B.TRANSDATE
			,B.POSTDATE
			,B.POSTPERIOD
			,B.PAYMENTMETHOD
			,B.WITHDRAWALCHEQUENO
			,B.TRANSTYPE
			,B.MOVEMENTCLASS
			,B.COMMANDID
			,B.REFENTITYNO
			,B.REFTRANSNO
			,B.[STATUS]
			,B.[DESCRIPTION]
			,B.ASSOCLINENO
			,B.PAYMENTCURRENCY
			,B.PAYMENTAMOUNT
			,B.BANKEXCHANGERATE
			,B.BANKAMOUNT
			,B.BANKCHARGES
			,B.BANKNET
			,B.LOCALAMOUNT
			,B.LOCALCHARGES
			,B.LOCALEXCHANGERATE
			,B.LOCALNET
			,B.BANKCATEGORY
			,B.REFERENCE
			,B.ISRECONCILED
			,B.GLMOVEMENTNO
		FROM BANKHISTORY B
		where ENTITYNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	If @nErrorCode=0
	Begin
		INSERT INTO BANKHISTORY
		(	 ENTITYNO
			,BANKNAMENO
			,SEQUENCENO
			,HISTORYLINENO
			,TRANSDATE
			,POSTDATE
			,POSTPERIOD
			,PAYMENTMETHOD
			,WITHDRAWALCHEQUENO
			,TRANSTYPE
			,MOVEMENTCLASS
			,COMMANDID
			,REFENTITYNO
			,REFTRANSNO
			,[STATUS]
			,[DESCRIPTION]
			,ASSOCLINENO
			,PAYMENTCURRENCY
			,PAYMENTAMOUNT
			,BANKEXCHANGERATE
			,BANKAMOUNT
			,BANKCHARGES
			,BANKNET
			,LOCALAMOUNT
			,LOCALCHARGES
			,LOCALEXCHANGERATE
			,LOCALNET
			,BANKCATEGORY
			,REFERENCE
			,ISRECONCILED
			,GLMOVEMENTNO)
		SELECT	 B.ENTITYNO
			,@pnNameNoConsolidateTo
			,B.SEQUENCENO
			,B.HISTORYLINENO
			,B.TRANSDATE
			,B.POSTDATE
			,B.POSTPERIOD
			,B.PAYMENTMETHOD
			,B.WITHDRAWALCHEQUENO
			,B.TRANSTYPE
			,B.MOVEMENTCLASS
			,B.COMMANDID
			,B.REFENTITYNO
			,B.REFTRANSNO
			,B.[STATUS]
			,B.[DESCRIPTION]
			,B.ASSOCLINENO
			,B.PAYMENTCURRENCY
			,B.PAYMENTAMOUNT
			,B.BANKEXCHANGERATE
			,B.BANKAMOUNT
			,B.BANKCHARGES
			,B.BANKNET
			,B.LOCALAMOUNT
			,B.LOCALCHARGES
			,B.LOCALEXCHANGERATE
			,B.LOCALNET
			,B.BANKCATEGORY
			,B.REFERENCE
			,B.ISRECONCILED
			,B.GLMOVEMENTNO
		FROM BANKHISTORY B
		where BANKNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	------------------------------
	-- S T A T E M E N T T R A N S
	------------------------------
	If @nErrorCode=0
	Begin
		INSERT INTO STATEMENTTRANS
		(	 STATEMENTNO
			,ACCOUNTOWNER
			,BANKNAMENO
			,ACCOUNTSEQUENCENO
			,HISTORYLINENO)
		SELECT	 STATEMENTNO
			,@pnNameNoConsolidateTo
			,BANKNAMENO
			,ACCOUNTSEQUENCENO
			,HISTORYLINENO
		FROM STATEMENTTRANS
		where ACCOUNTOWNER=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	If @nErrorCode=0
	Begin
		INSERT INTO STATEMENTTRANS
		(	 STATEMENTNO
			,ACCOUNTOWNER
			,BANKNAMENO
			,ACCOUNTSEQUENCENO
			,HISTORYLINENO)
		SELECT	 STATEMENTNO
			,ACCOUNTOWNER
			,@pnNameNoConsolidateTo
			,ACCOUNTSEQUENCENO
			,HISTORYLINENO
		FROM STATEMENTTRANS
		where BANKNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
 
	--------------------------------
	-- Now delete the STATEMENTTRANS
	--------------------------------
	If @nErrorCode=0
	Begin
		Delete STATEMENTTRANS
		where ACCOUNTOWNER=@pnNameNoConsolidateFrom
		OR BANKNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
 
	-----------------------------
	-- Now delete the BANKHISTORY
	-----------------------------
	If @nErrorCode=0
	Begin
		Delete BANKHISTORY
		where ENTITYNO=@pnNameNoConsolidateFrom
		OR BANKNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	-----------------------------	
	-- B A N K S T A T E M E N T
	----------------------------
	If @nErrorCode=0
	Begin
		INSERT INTO BANKSTATEMENT
		(	 STATEMENTNO
			,ACCOUNTOWNER
			,BANKNAMENO
			,ACCOUNTSEQUENCENO
			,STATEMENTENDDATE
			,CLOSINGBALANCE
			,ISRECONCILED
			,USERID
			,DATECREATED
			,OPENINGBALANCE
			,RECONCILEDDATE
			,IDENTITYID)
		SELECT	 STATEMENTNO
			,@pnNameNoConsolidateTo
			,BANKNAMENO
			,ACCOUNTSEQUENCENO
			,STATEMENTENDDATE
			,CLOSINGBALANCE
			,ISRECONCILED
			,USERID
			,DATECREATED
			,OPENINGBALANCE
			,RECONCILEDDATE
			,IDENTITYID
		FROM BANKSTATEMENT
		WHERE ACCOUNTOWNER=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		INSERT INTO BANKSTATEMENT
		(	 STATEMENTNO
			,ACCOUNTOWNER
			,BANKNAMENO
			,ACCOUNTSEQUENCENO
			,STATEMENTENDDATE
			,CLOSINGBALANCE
			,ISRECONCILED
			,USERID
			,DATECREATED
			,OPENINGBALANCE
			,RECONCILEDDATE
			,IDENTITYID)
		SELECT	 STATEMENTNO
			,ACCOUNTOWNER
			,@pnNameNoConsolidateTo
			,ACCOUNTSEQUENCENO
			,STATEMENTENDDATE
			,CLOSINGBALANCE
			,ISRECONCILED
			,USERID
			,DATECREATED
			,OPENINGBALANCE
			,RECONCILEDDATE
			,IDENTITYID
		FROM BANKSTATEMENT
		WHERE BANKNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
 
	--------------------------------
	-- Now delete the BANKSTATEMENT
	--------------------------------
	If @nErrorCode=0
	Begin
		Delete BANKSTATEMENT
		where ACCOUNTOWNER=@pnNameNoConsolidateFrom
		OR BANKNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	------------------
	-- C A S H I T E M
	------------------
	If @nErrorCode=0
	Begin
		INSERT INTO CASHITEM
		(	 ENTITYNO
			,BANKNAMENO
			,SEQUENCENO
			,TRANSENTITYNO
			,TRANSNO
			,ITEMDATE
			,[DESCRIPTION]
			,[STATUS]
			,ITEMTYPE
			,POSTDATE
			,POSTPERIOD
			,CLOSEPOSTDATE
			,CLOSEPOSTPERIOD
			,TRADER
			,ACCTENTITYNO
			,ACCTNAMENO
			,BANKEDBYENTITYNO
			,BANKEDBYTRANSNO
			,BANKCATEGORY
			,ITEMBANKBRANCHNO
			,ITEMREFNO
			,ITEMBANKNAME
			,ITEMBANKBRANCH
			,CREDITCARDTYPE
			,CARDEXPIRYDATE
			,PAYMENTCURRENCY
			,PAYMENTAMOUNT
			,BANKEXCHANGERATE
			,BANKAMOUNT
			,BANKCHARGES
			,BANKNET
			,DISSECTIONCURRENCY
			,DISSECTIONAMOUNT
			,DISSECTIONUNALLOC
			,DISSECTIONEXCHANGE
			,LOCALAMOUNT
			,LOCALCHARGES
			,LOCALEXCHANGERATE
			,LOCALNET
			,LOCALUNALLOCATED
			,BANKOPERATIONCODE
			,DETAILSOFCHARGES
			,EFTFILEFORMAT
			,EFTPAYMENTFILE
			,FXDEALERREF
			,TRANSFERENTITYNO
			,TRANSFERTRANSNO
			,INSTRUCTIONCODE)
		SELECT   @pnNameNoConsolidateTo
			,BANKNAMENO
			,SEQUENCENO
			,TRANSENTITYNO
			,TRANSNO
			,ITEMDATE
			,[DESCRIPTION]
			,[STATUS]
			,ITEMTYPE
			,POSTDATE
			,POSTPERIOD
			,CLOSEPOSTDATE
			,CLOSEPOSTPERIOD
			,TRADER
			,ACCTENTITYNO
			,ACCTNAMENO
			,BANKEDBYENTITYNO
			,BANKEDBYTRANSNO
			,BANKCATEGORY
			,ITEMBANKBRANCHNO
			,ITEMREFNO
			,ITEMBANKNAME
			,ITEMBANKBRANCH
			,CREDITCARDTYPE
			,CARDEXPIRYDATE
			,PAYMENTCURRENCY
			,PAYMENTAMOUNT
			,BANKEXCHANGERATE
			,BANKAMOUNT
			,BANKCHARGES
			,BANKNET
			,DISSECTIONCURRENCY
			,DISSECTIONAMOUNT
			,DISSECTIONUNALLOC
			,DISSECTIONEXCHANGE
			,LOCALAMOUNT
			,LOCALCHARGES
			,LOCALEXCHANGERATE
			,LOCALNET
			,LOCALUNALLOCATED
			,BANKOPERATIONCODE
			,DETAILSOFCHARGES
			,EFTFILEFORMAT
			,EFTPAYMENTFILE
			,FXDEALERREF
			,TRANSFERENTITYNO
			,TRANSFERTRANSNO
			,INSTRUCTIONCODE
		FROM CASHITEM
		WHERE ENTITYNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		INSERT INTO CASHITEM
		(	 ENTITYNO
			,BANKNAMENO
			,SEQUENCENO
			,TRANSENTITYNO
			,TRANSNO
			,ITEMDATE
			,[DESCRIPTION]
			,[STATUS]
			,ITEMTYPE
			,POSTDATE
			,POSTPERIOD
			,CLOSEPOSTDATE
			,CLOSEPOSTPERIOD
			,TRADER
			,ACCTENTITYNO
			,ACCTNAMENO
			,BANKEDBYENTITYNO
			,BANKEDBYTRANSNO
			,BANKCATEGORY
			,ITEMBANKBRANCHNO
			,ITEMREFNO
			,ITEMBANKNAME
			,ITEMBANKBRANCH
			,CREDITCARDTYPE
			,CARDEXPIRYDATE
			,PAYMENTCURRENCY
			,PAYMENTAMOUNT
			,BANKEXCHANGERATE
			,BANKAMOUNT
			,BANKCHARGES
			,BANKNET
			,DISSECTIONCURRENCY
			,DISSECTIONAMOUNT
			,DISSECTIONUNALLOC
			,DISSECTIONEXCHANGE
			,LOCALAMOUNT
			,LOCALCHARGES
			,LOCALEXCHANGERATE
			,LOCALNET
			,LOCALUNALLOCATED
			,BANKOPERATIONCODE
			,DETAILSOFCHARGES
			,EFTFILEFORMAT
			,EFTPAYMENTFILE
			,FXDEALERREF
			,TRANSFERENTITYNO
			,TRANSFERTRANSNO
			,INSTRUCTIONCODE)
		SELECT   ENTITYNO
			,@pnNameNoConsolidateTo
			,SEQUENCENO
			,TRANSENTITYNO
			,TRANSNO
			,ITEMDATE
			,[DESCRIPTION]
			,[STATUS]
			,ITEMTYPE
			,POSTDATE
			,POSTPERIOD
			,CLOSEPOSTDATE
			,CLOSEPOSTPERIOD
			,TRADER
			,ACCTENTITYNO
			,ACCTNAMENO
			,BANKEDBYENTITYNO
			,BANKEDBYTRANSNO
			,BANKCATEGORY
			,ITEMBANKBRANCHNO
			,ITEMREFNO
			,ITEMBANKNAME
			,ITEMBANKBRANCH
			,CREDITCARDTYPE
			,CARDEXPIRYDATE
			,PAYMENTCURRENCY
			,PAYMENTAMOUNT
			,BANKEXCHANGERATE
			,BANKAMOUNT
			,BANKCHARGES
			,BANKNET
			,DISSECTIONCURRENCY
			,DISSECTIONAMOUNT
			,DISSECTIONUNALLOC
			,DISSECTIONEXCHANGE
			,LOCALAMOUNT
			,LOCALCHARGES
			,LOCALEXCHANGERATE
			,LOCALNET
			,LOCALUNALLOCATED
			,BANKOPERATIONCODE
			,DETAILSOFCHARGES
			,EFTFILEFORMAT
			,EFTPAYMENTFILE
			,FXDEALERREF
			,TRANSFERENTITYNO
			,TRANSFERTRANSNO
			,INSTRUCTIONCODE
		FROM CASHITEM
		WHERE BANKNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- CASHITEM.ACCTNAMENO
	If @nErrorCode=0
	Begin
		update CASHITEM
		set ACCTNAMENO=@pnNameNoConsolidateTo
		where ACCTNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	------------------------
	-- C A S H H I S T O R Y
	------------------------
	If @nErrorCode=0
	Begin			
		INSERT INTO CASHHISTORY
		(	 ENTITYNO
			,BANKNAMENO
			,SEQUENCENO
			,TRANSENTITYNO
			,TRANSNO
			,HISTORYLINENO
			,TRANSDATE
			,POSTDATE
			,POSTPERIOD
			,TRANSTYPE
			,MOVEMENTCLASS
			,COMMANDID
			,REFENTITYNO
			,REFTRANSNO
			,[STATUS]
			,[DESCRIPTION]
			,ASSOCIATEDLINENO
			,ITEMREFNO
			,ACCTENTITYNO
			,ACCTNAMENO
			,GLACCOUNTCODE
			,DISSECTIONCURRENCY
			,FOREIGNAMOUNT
			,DISSECTIONEXCHANGE
			,LOCALAMOUNT
			,ITEMIMPACT
			,GLMOVEMENTNO)
		SELECT	 ENTITYNO
			,@pnNameNoConsolidateTo
			,SEQUENCENO
			,TRANSENTITYNO
			,TRANSNO
			,HISTORYLINENO
			,TRANSDATE
			,POSTDATE
			,POSTPERIOD
			,TRANSTYPE
			,MOVEMENTCLASS
			,COMMANDID
			,REFENTITYNO
			,REFTRANSNO
			,[STATUS]
			,[DESCRIPTION]
			,ASSOCIATEDLINENO
			,ITEMREFNO
			,ACCTENTITYNO
			,ACCTNAMENO
			,GLACCOUNTCODE
			,DISSECTIONCURRENCY
			,FOREIGNAMOUNT
			,DISSECTIONEXCHANGE
			,LOCALAMOUNT
			,ITEMIMPACT
			,GLMOVEMENTNO
		FROM CASHHISTORY
		WHERE BANKNAMENO=@pnNameNoConsolidateFrom
		
		Set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	Begin
		update	CASHHISTORY
		set	ACCTNAMENO=@pnNameNoConsolidateTo
		where	ACCTNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	---------------------
	-- Delete CASHHISTORY
	---------------------
	If @nErrorCode=0
	Begin
		DELETE CASHHISTORY
		where BANKNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	------------------
	-- Delete CASHITEM
	------------------
	If @nErrorCode=0
	Begin
		DELETE CASHITEM
		where ENTITYNO=@pnNameNoConsolidateFrom
		OR BANKNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	-----------------
	-- CHEQUEREGISTER
	-----------------
	If @nErrorCode=0
	Begin
		update	CHEQUEREGISTER
		set	BANKNAMENO=@pnNameNoConsolidateTo
		where	BANKNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	-----------------
	-- CREDITOR
	-----------------
	If @nErrorCode=0
	Begin
		update	CREDITOR
		set	BANKACCOUNTOWNER=@pnNameNoConsolidateTo
		where	BANKACCOUNTOWNER=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	If @nErrorCode=0
	Begin
		update	CREDITOR
		set	BANKNAMENO=@pnNameNoConsolidateTo
		where	BANKNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	-----------------
	-- CRENTITYDETAIL
	-----------------
	If @nErrorCode=0
	Begin
		update	CRENTITYDETAIL
		set	BANKNAMENO=@pnNameNoConsolidateTo
		where	BANKNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	-----------------
	-- DATAVALIDATION
	-----------------
	If @nErrorCode=0
	Begin
		update	DATAVALIDATION
		set	NAMENO=@pnNameNoConsolidateTo
		where	NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	-----------------
	-- EFTDETAIL
	-----------------
	If @nErrorCode=0
	Begin
		update	EFTDETAIL
		set	BANKNAMENO=@pnNameNoConsolidateTo
		where	BANKNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	If @nErrorCode=0
	Begin
		update	EFTDETAIL
		set	ACCOUNTOWNER=@pnNameNoConsolidateTo
		where	ACCOUNTOWNER=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	-------------------
	-- GLACCOUNTMAPPING
	-------------------
	If @nErrorCode=0
	Begin
		update	GLACCOUNTMAPPING
		set	BANKNAMENO=@pnNameNoConsolidateTo
		where	BANKNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	-------------------
	-- PAYMENTPLAN
	-------------------
	If @nErrorCode=0
	Begin
		update	PAYMENTPLAN
		set	BANKNAMENO=@pnNameNoConsolidateTo
		where	BANKNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	If @nErrorCode=0
	Begin
		Delete BANKACCOUNT
		where BANKNAMENO=@pnNameNoConsolidateFrom
		 OR ACCOUNTOWNER=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	

	-----------------------------
	-- Now delete the CREDITOR
	-----------------------------
	If  @nErrorCode  = 0
	and @bRetainName = 0
	Begin
		delete CREDITOR
		where NAMENO=@pnNameNoConsolidateFrom
		
		Set @nErrorCode=@@Error
	End
	---------------------------------------
	-- Now delete the ACCOUNT rows pointing
	-- to the Name being consolidated
	---------------------------------------
	
	If @nErrorCode=0
	Begin
		delete ACCOUNT
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	---------------------------------------
	-- Now delete the SPECIALNAMES rows 
	-- after all references to this table
	-- have been removed.
	---------------------------------------
	If @nErrorCode=0
	Begin
		DELETE SPECIALNAME
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	------------------------------------------------
	-- Now update all references to the NameNo being
	-- consolidated and point to the new NameNo
	------------------------------------------------
	
	
	-- ACCESSACCOUNTNAMES.NAMENO
	If @nErrorCode=0
	Begin
		INSERT INTO ACCESSACCOUNTNAMES
		(	 ACCOUNTID
			,NAMENO)
		SELECT	 A.ACCOUNTID
			,@pnNameNoConsolidateTo
		FROM ACCESSACCOUNTNAMES A
		left join ACCESSACCOUNTNAMES A1	on (A1.ACCOUNTID=A.ACCOUNTID
						and A1.NAMENO=@pnNameNoConsolidateTo)
		where A.NAMENO=@pnNameNoConsolidateFrom
		and A1.ACCOUNTID is null 
		
		set @nErrorCode=@@Error
	End
	
	If @nErrorCode=0
	and @bRetainName=0
	Begin
		DELETE  ACCESSACCOUNTNAMES
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- ACTIVITY.CALLER
	If @nErrorCode=0
	Begin
		update ACTIVITY
		set CALLER=@pnNameNoConsolidateTo
		where CALLER=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- ACTIVITY.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update ACTIVITY
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- ACTIVITY.NAMENO
	If @nErrorCode=0
	Begin
		update ACTIVITY
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- ACTIVITY.REFERREDTO
	If @nErrorCode=0
	Begin
		update ACTIVITY
		set REFERREDTO=@pnNameNoConsolidateTo
		where REFERREDTO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- ACTIVITYREQUEST.DEBTOR
	If @nErrorCode=0
	Begin
		update ACTIVITYREQUEST
		set DEBTOR=@pnNameNoConsolidateTo
		where DEBTOR=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- ACTIVITYREQUEST.DISBEMPLOYEENO
	If @nErrorCode=0
	Begin
		update ACTIVITYREQUEST
		set DISBEMPLOYEENO=@pnNameNoConsolidateTo
		where DISBEMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- ACTIVITYREQUEST.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update ACTIVITYREQUEST
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- ACTIVITYREQUEST.INSTRUCTOR
	If @nErrorCode=0
	Begin
		update ACTIVITYREQUEST
		set INSTRUCTOR=@pnNameNoConsolidateTo
		where INSTRUCTOR=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- ACTIVITYREQUEST.OWNER
	If @nErrorCode=0
	Begin
		update ACTIVITYREQUEST
		set OWNER=@pnNameNoConsolidateTo
		where OWNER=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- ACTIVITYREQUEST.SERVEMPLOYEENO
	If @nErrorCode=0
	Begin
		update ACTIVITYREQUEST
		set SERVEMPLOYEENO=@pnNameNoConsolidateTo
		where SERVEMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- ALERT.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update ALERT
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- BATCHTYPERULES.FROMNAMENO
	If @nErrorCode=0
	Begin
		update BATCHTYPERULES
		set FROMNAMENO=@pnNameNoConsolidateTo
		where FROMNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- BATCHTYPERULES.HEADERINSTRUCTOR
	If @nErrorCode=0
	Begin
		update BATCHTYPERULES
		set HEADERINSTRUCTOR=@pnNameNoConsolidateTo
		where HEADERINSTRUCTOR=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- BATCHTYPERULES.HEADERSTAFFNAME
	If @nErrorCode=0
	Begin
		update BATCHTYPERULES
		set HEADERSTAFFNAME=@pnNameNoConsolidateTo
		where HEADERSTAFFNAME=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- BATCHTYPERULES.IMPORTEDINSTRUCTOR
	If @nErrorCode=0
	Begin
		update BATCHTYPERULES
		set IMPORTEDINSTRUCTOR=@pnNameNoConsolidateTo
		where IMPORTEDINSTRUCTOR=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- BATCHTYPERULES.IMPORTEDSTAFFNAME
	If @nErrorCode=0
	Begin
		update BATCHTYPERULES
		set IMPORTEDSTAFFNAME=@pnNameNoConsolidateTo
		where IMPORTEDSTAFFNAME=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- BATCHTYPERULES.REJECTEDINSTRUCTOR
	If @nErrorCode=0
	Begin
		update BATCHTYPERULES
		set REJECTEDINSTRUCTOR=@pnNameNoConsolidateTo
		where REJECTEDINSTRUCTOR=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- BATCHTYPERULES.REJECTEDSTAFFNAME
	If @nErrorCode=0
	Begin
		update BATCHTYPERULES
		set REJECTEDSTAFFNAME=@pnNameNoConsolidateTo
		where REJECTEDSTAFFNAME=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- BILLFORMAT.NAMENO
	If @nErrorCode=0
	Begin
		update BILLFORMAT
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- BILLRULE.DEBTORNO
	If @nErrorCode=0
	Begin
		update BILLRULE
		set DEBTORNO=@pnNameNoConsolidateTo
		where DEBTORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- BUDGET.ENTITYNO
	If @nErrorCode=0
	Begin
		update BUDGET
		set ENTITYNO=@pnNameNoConsolidateTo
		where ENTITYNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- CASEBUDGET.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update CASEBUDGET
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- CASECHECKLIST.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update CASECHECKLIST
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- CASEEVENT.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update CASEEVENT
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- CASELOCATION.ISSUEDBY
	If @nErrorCode=0
	Begin
		update CASELOCATION
		set ISSUEDBY=@pnNameNoConsolidateTo
		where ISSUEDBY=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- CASENAME.CORRESPONDNAME
	If @nErrorCode=0
	Begin
		UPDATE CN 
		SET CORRESPONDNAME =   case	when ( CN.DERIVEDCORRNAME = 0 ) then @pnNameNoConsolidateTo                         
						when ( convert(bit,NT.COLUMNFLAGS&1)=0 and CN.NAMETYPE not in ('I','A') ) then NULL            
						when ( AN.CONTACT is not null ) then AN.CONTACT            
						else dbo.fn_GetDerivedAttnNameNo( CN.NAMENO, CN.CASEID, CN.NAMETYPE )   
					end  
		from CASENAME CN  
		join NAMETYPE NT on (NT.NAMETYPE = CN.NAMETYPE)  
		left join ASSOCIATEDNAME AN	on (AN.NAMENO = CN.INHERITEDNAMENO      
						and AN.RELATIONSHIP = CN.INHERITEDRELATIONS      
						and AN.RELATEDNAME = CN.NAMENO      
						and AN.SEQUENCE = CN.INHERITEDSEQUENCE) 
		WHERE CN.CORRESPONDNAME = @pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- CASENAME.INHERITEDNAMENO
	If @nErrorCode=0
	Begin
		update CASENAME
		set INHERITEDNAMENO=@pnNameNoConsolidateTo
		where INHERITEDNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- CASENAME.NAMENO
	If @nErrorCode=0
	Begin
		update CASENAME
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	-----------------------------------------------
	-- Deletion of CASENAME where the consolidation
	-- now results in duplicate rows.
	-----------------------------------------------
	If @nErrorCode=0
	Begin	
		delete CN1
		from CASENAME CN1
		where NAMENO=@pnNameNoConsolidateTo
		and exists
		(select 1
		 from CASENAME CN2
		 where CN2.CASEID  =CN1.CASEID
		 and   CN2.NAMETYPE=CN1.NAMETYPE
		 and   CN2.NAMENO  =CN1.NAMENO
		 and   CN2.SEQUENCE<CN1.SEQUENCE
		 and   CHECKSUM(CN1.CORRESPONDNAME, CN1.ADDRESSCODE, CN1.REFERENCENO, CN1.ASSIGNMENTDATE, CN1.COMMENCEDATE, CN1.EXPIRYDATE, CN1.BILLPERCENTAGE, CN1.NAMEVARIANTNO, CN1.REMARKS, CN1.CORRESPONDENCESENT, CN1.CORRESPONDENCERECEIVED, CN1.CORRESPSENT, CN1.CORRESPRECEIVED)
		     = CHECKSUM(CN2.CORRESPONDNAME, CN2.ADDRESSCODE, CN2.REFERENCENO, CN2.ASSIGNMENTDATE, CN2.COMMENCEDATE, CN2.EXPIRYDATE, CN2.BILLPERCENTAGE, CN2.NAMEVARIANTNO, CN2.REMARKS, CN2.CORRESPONDENCESENT, CN2.CORRESPONDENCERECEIVED, CN2.CORRESPSENT, CN2.CORRESPRECEIVED)
		 )
		 
		set @nErrorCode=@@ERROR
	End
	
	If @nErrorCode=0
	Begin	
		delete CN1
		from CASENAME CN1
		where CORRESPONDNAME=@pnNameNoConsolidateTo
		and exists
		(select 1
		 from CASENAME CN2
		 where CN2.CASEID        =CN1.CASEID
		 and   CN2.NAMETYPE      =CN1.NAMETYPE
		 and   CN2.NAMENO        =CN1.NAMENO
		 and   CN2.CORRESPONDNAME=CN1.CORRESPONDNAME
		 and   CN2.SEQUENCE      <CN1.SEQUENCE
		 and   CHECKSUM(CN1.ADDRESSCODE, CN1.REFERENCENO, CN1.ASSIGNMENTDATE, CN1.COMMENCEDATE, CN1.EXPIRYDATE, CN1.BILLPERCENTAGE, CN1.NAMEVARIANTNO, CN1.REMARKS, CN1.CORRESPONDENCESENT, CN1.CORRESPONDENCERECEIVED, CN1.CORRESPSENT, CN1.CORRESPRECEIVED)
		     = CHECKSUM(CN2.ADDRESSCODE, CN2.REFERENCENO, CN2.ASSIGNMENTDATE, CN2.COMMENCEDATE, CN2.EXPIRYDATE, CN2.BILLPERCENTAGE, CN2.NAMEVARIANTNO, CN2.REMARKS, CN2.CORRESPONDENCESENT, CN2.CORRESPONDENCERECEIVED, CN2.CORRESPSENT, CN2.CORRESPRECEIVED)
		 )
		 
		set @nErrorCode=@@ERROR
	End
	-----------------------------------------------
	-- Deletion of NAMEADDRESS rows must occur
	-- after CASENAME references have been updated.
	-----------------------------------------------
	If @nErrorCode=0
	and (@pbKeepAddressHistory=1
	 or exists (select 1 from CASENAME where NAMENO=@pnNameNoConsolidateFrom and ADDRESSCODE is not null)
	 or exists (select 1 from NAMEADDRESSCPACLIENT where NAMENO=@pnNameNoConsolidateFrom) )
	Begin
		If @bRetainName=0
		Begin
			delete NAMEADDRESS
			where NAMENO=@pnNameNoConsolidateFrom
			
			set @nErrorCode=@@Error
		End
	End

	-- CASENAMEREQUEST.CURRENTATTENTION
	If @nErrorCode=0
	Begin
		update CASENAMEREQUEST
		set CURRENTATTENTION=@pnNameNoConsolidateTo
		where CURRENTATTENTION=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- CASENAMEREQUEST.CURRENTNAMENO
	If @nErrorCode=0
	Begin
		update CASENAMEREQUEST
		set CURRENTNAMENO=@pnNameNoConsolidateTo
		where CURRENTNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- CASENAMEREQUEST.NEWATTENTION
	If @nErrorCode=0
	Begin
		update CASENAMEREQUEST
		set NEWATTENTION=@pnNameNoConsolidateTo
		where NEWATTENTION=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- CASENAMEREQUEST.NEWNAMENO
	If @nErrorCode=0
	Begin
		update CASENAMEREQUEST
		set NEWNAMENO=@pnNameNoConsolidateTo
		where NEWNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- CASEPROFITCENTRE.INSTRUCTOR
	If @nErrorCode=0
	Begin
		update CASEPROFITCENTRE
		set INSTRUCTOR=@pnNameNoConsolidateTo
		where INSTRUCTOR=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- COSTRATE.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update COSTRATE
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- COSTTRACK.AGENTNO
	If @nErrorCode=0
	Begin
		update COSTTRACK
		set AGENTNO=@pnNameNoConsolidateTo
		where AGENTNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- COSTTRACKALLOC.DEBTORNO
	If @nErrorCode=0
	Begin
		update COSTTRACKALLOC
		set DEBTORNO=@pnNameNoConsolidateTo
		where DEBTORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- COSTTRACKALLOC.DIVISIONNO
	If @nErrorCode=0
	Begin
		update COSTTRACKALLOC
		set DIVISIONNO=@pnNameNoConsolidateTo
		where DIVISIONNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- COSTTRACKLINE.DIVISIONNO
	If @nErrorCode=0
	Begin
		update COSTTRACKLINE
		set DIVISIONNO=@pnNameNoConsolidateTo
		where DIVISIONNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- COSTTRACKLINE.FOREIGNAGENTNO
	If @nErrorCode=0
	Begin
		update COSTTRACKLINE
		set FOREIGNAGENTNO=@pnNameNoConsolidateTo
		where FOREIGNAGENTNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- CPAUPDATE.NAMEID
	If @nErrorCode=0
	Begin
		update CPAUPDATE
		set NAMEID=@pnNameNoConsolidateTo
		where NAMEID=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- CREDITORHISTORY.REMITTANCENAMENO
	If @nErrorCode=0
	Begin
		update CREDITORHISTORY
		set REMITTANCENAMENO=@pnNameNoConsolidateTo
		where REMITTANCENAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- CRITERIA.DATASOURCENAMENO
	If @nErrorCode=0
	Begin
		update CRITERIA
		set DATASOURCENAMENO=@pnNameNoConsolidateTo
		where DATASOURCENAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- DATAMAP.SOURCENO
	If @nErrorCode=0
	Begin
		update DATAMAP
		set SOURCENO=@pnNameNoConsolidateTo
		where SOURCENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- DATASOURCE.SOURCENAMENO
	If @nErrorCode=0
	Begin
		update DATASOURCE
		set SOURCENAMENO=@pnNameNoConsolidateTo
		where SOURCENAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- DATAWIZARD.DEFAULTSOURCENO
	If @nErrorCode=0
	Begin
		update DATAWIZARD
		set DEFAULTSOURCENO=@pnNameNoConsolidateTo
		where DEFAULTSOURCENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- DEBITNOTEIMAGE.DEBTORNO
	If @nErrorCode=0
	Begin
		update DEBITNOTEIMAGE
		set DEBTORNO=@pnNameNoConsolidateTo
		where DEBTORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	------------
	-- D I A R Y
	------------
	If @nErrorCode=0
	Begin
		INSERT INTO DIARY
		(	 EMPLOYEENO
			,ENTRYNO
			,ACTIVITY
			,CASEID
			,NAMENO
			,STARTTIME
			,FINISHTIME
			,TOTALTIME
			,TOTALUNITS
			,TIMECARRIEDFORWARD
			,UNITSPERHOUR
			,TIMEVALUE
			,CHARGEOUTRATE
			,WIPENTITYNO
			,TRANSNO
			,WIPSEQNO
			,NOTES
			,NARRATIVENO
			,SHORTNARRATIVE
			,LONGNARRATIVE
			,DISCOUNTVALUE
			,FOREIGNCURRENCY
			,FOREIGNVALUE
			,EXCHRATE
			,FOREIGNDISCOUNT
			,QUOTATIONNO
			,PARENTENTRYNO
			,COSTCALCULATION1
			,COSTCALCULATION2
			,PRODUCTCODE
			,ISTIMER
			,CREATEDON)
		SELECT   @pnNameNoConsolidateTo
			,D.ENTRYNO+CASE WHEN(D1.ENTRYNO is null) THEN 0 ELSE D1.ENTRYNO+1 END
			,ACTIVITY
			,CASEID
			,NAMENO
			,STARTTIME
			,FINISHTIME
			,TOTALTIME
			,TOTALUNITS
			,TIMECARRIEDFORWARD
			,UNITSPERHOUR
			,TIMEVALUE
			,CHARGEOUTRATE
			,WIPENTITYNO
			,TRANSNO
			,WIPSEQNO
			,NOTES
			,NARRATIVENO
			,SHORTNARRATIVE
			,LONGNARRATIVE
			,DISCOUNTVALUE
			,FOREIGNCURRENCY
			,FOREIGNVALUE
			,EXCHRATE
			,FOREIGNDISCOUNT
			,QUOTATIONNO
			,PARENTENTRYNO
			,COSTCALCULATION1
			,COSTCALCULATION2
			,PRODUCTCODE
			,ISTIMER
			,CREATEDON
		FROM DIARY D
		left join (	select EMPLOYEENO, max(ENTRYNO) as ENTRYNO
				from DIARY
				where EMPLOYEENO=@pnNameNoConsolidateTo
				group by EMPLOYEENO) D1
					on (D1.EMPLOYEENO=@pnNameNoConsolidateTo)
		where D.EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	-------------------------
	-- DELETE the DIARY entry
	-------------------------
	If @nErrorCode=0
	Begin
		Delete DIARY
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- DIARY.NAMENO
	If @nErrorCode=0
	Begin
		update DIARY
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- DOCUMENTREQUEST.RECIPIENT
	If @nErrorCode=0
	Begin
		update DOCUMENTREQUEST
		set RECIPIENT=@pnNameNoConsolidateTo
		where RECIPIENT=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- EDEADDRESSBOOK.NAMENO
	If @nErrorCode=0
	Begin
		update EDEADDRESSBOOK
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- EDEFORMATTEDATTNOF.NAMENO
	If @nErrorCode=0
	Begin
		update EDEFORMATTEDATTNOF
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- EDEOUTSTANDINGISSUES.NAMENO
	If @nErrorCode=0
	Begin
		update EDEOUTSTANDINGISSUES
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- EDESENDERDETAILS.SENDERNAMENO
	If @nErrorCode=0
	Begin
		update EDESENDERDETAILS
		set SENDERNAMENO=@pnNameNoConsolidateTo
		where SENDERNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- EDETRANSACTIONCONTENTDETAILS.ALTSENDERNAMENO
	If @nErrorCode=0
	Begin
		update EDETRANSACTIONCONTENTDETAILS
		set ALTSENDERNAMENO=@pnNameNoConsolidateTo
		where ALTSENDERNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End
	
	----------------------------------
	-- E M P L O Y E E R E M I N D E R
	----------------------------------
	If @nErrorCode=0
	Begin
		INSERT INTO EMPLOYEEREMINDER
		(	 EMPLOYEENO
			,MESSAGESEQ
			,CASEID
			,REFERENCE
			,EVENTNO
			,CYCLENO
			,DUEDATE
			,REMINDERDATE
			,READFLAG
			,SOURCE
			,HOLDUNTILDATE
			,DATEUPDATED
			,SHORTMESSAGE
			,LONGMESSAGE
			,COMMENTS
			,SEQUENCENO
			,COMMENTS_TID
			,MESSAGE_TID
			,REFERENCE_TID
			,NAMENO
			,ALERTNAMENO)
		SELECT   @pnNameNoConsolidateTo
			,E1.MESSAGESEQ
			,E1.CASEID
			,E1.REFERENCE
			,E1.EVENTNO
			,E1.CYCLENO
			,E1.DUEDATE
			,E1.REMINDERDATE
			,E1.READFLAG
			,E1.SOURCE
			,E1.HOLDUNTILDATE
			,E1.DATEUPDATED
			,E1.SHORTMESSAGE
			,E1.LONGMESSAGE
			,E1.COMMENTS
			,E1.SEQUENCENO
			,E1.COMMENTS_TID
			,E1.MESSAGE_TID
			,E1.REFERENCE_TID
			,E1.NAMENO
			,E1.ALERTNAMENO
		FROM EMPLOYEEREMINDER E1
		left join EMPLOYEEREMINDER E2	on ( E2.EMPLOYEENO=@pnNameNoConsolidateTo
	 					and (E2.CASEID    =E1.CASEID    or (E2.CASEID    is null and E1.CASEID    is null))
	 					and (E2.EVENTNO   =E1.EVENTNO   or (E2.EVENTNO   is null and E1.EVENTNO   is null))
	 					and (E2.CYCLENO   =E1.CYCLENO   or (E2.CYCLENO   is null and E1.CYCLENO   is null))
	 					and (E2.REFERENCE =E1.REFERENCE or (E2.REFERENCE is null and E1.REFERENCE is null))
	 					and  E2.SEQUENCENO=E1.SEQUENCENO)
		where E1.EMPLOYEENO=@pnNameNoConsolidateFrom
		and E2.EMPLOYEENO is null
		
		set @nErrorCode=@@Error
	End

	-- EMPLOYEEREMINDER.NAMENO
	If @nErrorCode=0
	Begin
		update EMPLOYEEREMINDER
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- EMPLOYEEREMINDER.ALERTNAMENO
	If @nErrorCode=0
	Begin
		update EMPLOYEEREMINDER
		set ALERTNAMENO=@pnNameNoConsolidateTo
		where ALERTNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End


	-- Delete EMPLOYEEREMINDER
	If @nErrorCode=0
	Begin
		DELETE EMPLOYEEREMINDER
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- EVENTCONTROL.DUEDATERESPNAMENO
	If @nErrorCode=0
	Begin
		update EVENTCONTROL
		set DUEDATERESPNAMENO=@pnNameNoConsolidateTo
		where DUEDATERESPNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- EXPENSEIMPORT.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update EXPENSEIMPORT
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- EXPENSEIMPORT.NAMENO
	If @nErrorCode=0
	Begin
		update EXPENSEIMPORT
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- EXPENSEIMPORT.SUPPLIERNAMENO
	If @nErrorCode=0
	Begin
		update EXPENSEIMPORT
		set SUPPLIERNAMENO=@pnNameNoConsolidateTo
		where SUPPLIERNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- EXTERNALNAME.DATASOURCENAMENO
	If @nErrorCode=0
	Begin
		update EXTERNALNAME
		set DATASOURCENAMENO=@pnNameNoConsolidateTo
		where DATASOURCENAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- EXTERNALNAMEMAPPING.INPRONAMENO
	If @nErrorCode=0
	Begin
		update EXTERNALNAMEMAPPING
		set INPRONAMENO=@pnNameNoConsolidateTo
		where INPRONAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- EXTERNALNAMEMAPPING.INSTRUCTORNAMENO
	If @nErrorCode=0
	Begin
		update EXTERNALNAMEMAPPING
		set INSTRUCTORNAMENO=@pnNameNoConsolidateTo
		where INSTRUCTORNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- FEELIST.FEELISTNAME
	If @nErrorCode=0
	Begin
		update FEELIST
		set FEELISTNAME=@pnNameNoConsolidateTo
		where FEELISTNAME=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- FEELIST.IPOFFICE
	If @nErrorCode=0
	Begin
		update FEELIST
		set IPOFFICE=@pnNameNoConsolidateTo
		where IPOFFICE=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- FEESCALCULATION.AGENT
	If @nErrorCode=0
	Begin
		If exists(select 1 
			  from FEESCALCULATION F1
			  join FEESCALCULATION F2 on( F2.CRITERIANO   =F1.CRITERIANO
						  and(F2.DEBTORTYPE   =F1.DEBTORTYPE    or (F2.DEBTORTYPE    is null and F1.DEBTORTYPE    is null))
						  and F2.AGENT        =@pnNameNoConsolidateTo
						  and(F2.DEBTOR       =F1.DEBTOR        or (F2.DEBTOR        is null and F1.DEBTOR        is null))
						  and(F2.CYCLENUMBER  =F1.CYCLENUMBER   or (F2.CYCLENUMBER   is null and F1.CYCLENUMBER   is null))
 						  and(F2.VALIDFROMDATE=F1.VALIDFROMDATE or (F2.VALIDFROMDATE is null and F1.VALIDFROMDATE is null))
						  and(F2.OWNER        =F1.OWNER         or (F2.OWNER         is null and F1.OWNER         is null))
						  and(F2.INSTRUCTOR   =F1.INSTRUCTOR    or (F2.INSTRUCTOR    is null and F1.INSTRUCTOR    is null))
						  and(F2.FROMEVENTNO  =F1.FROMEVENTNO   or (F2.FROMEVENTNO   is null and F1.FROMEVENTNO   is null)) )
			  Where F1.AGENT=@pnNameNoConsolidateFrom)
		Begin
			DELETE F1
			from FEESCALCULATION F1
			join FEESCALCULATION F2	on( F2.CRITERIANO   =F1.CRITERIANO
						and(F2.DEBTORTYPE   =F1.DEBTORTYPE    or (F2.DEBTORTYPE    is null and F1.DEBTORTYPE    is null))
						and F2.AGENT        =@pnNameNoConsolidateTo
						and(F2.DEBTOR       =F1.DEBTOR        or (F2.DEBTOR        is null and F1.DEBTOR        is null))
						and(F2.CYCLENUMBER  =F1.CYCLENUMBER   or (F2.CYCLENUMBER   is null and F1.CYCLENUMBER   is null))
						and(F2.VALIDFROMDATE=F1.VALIDFROMDATE or (F2.VALIDFROMDATE is null and F1.VALIDFROMDATE is null))
						and(F2.OWNER        =F1.OWNER         or (F2.OWNER         is null and F1.OWNER         is null))
						and(F2.INSTRUCTOR   =F1.INSTRUCTOR    or (F2.INSTRUCTOR    is null and F1.INSTRUCTOR    is null))
						and(F2.FROMEVENTNO  =F1.FROMEVENTNO   or (F2.FROMEVENTNO   is null and F1.FROMEVENTNO   is null)) )
			Where F1.AGENT=@pnNameNoConsolidateFrom
			
			Set @nErrorCode=@@ERROR
		End
		Else Begin
			update FEESCALCULATION
			set AGENT=@pnNameNoConsolidateTo
			where AGENT=@pnNameNoConsolidateFrom
			
			set @nErrorCode=@@Error
		End
	End

	-- FEESCALCULATION.DEBTOR
	If @nErrorCode=0
	Begin
		If exists(select 1 
			  from FEESCALCULATION F1
			  join FEESCALCULATION F2 on( F2.CRITERIANO   =F1.CRITERIANO
						  and(F2.DEBTORTYPE   =F1.DEBTORTYPE    or (F2.DEBTORTYPE    is null and F1.DEBTORTYPE    is null))
						  and(F2.AGENT        =F1.AGENT         or (F2.AGENT         is null and F1.AGENT         is null))
						  and F2.DEBTOR       =@pnNameNoConsolidateTo
						  and(F2.CYCLENUMBER  =F1.CYCLENUMBER   or (F2.CYCLENUMBER   is null and F1.CYCLENUMBER   is null))
 						  and(F2.VALIDFROMDATE=F1.VALIDFROMDATE or (F2.VALIDFROMDATE is null and F1.VALIDFROMDATE is null))
						  and(F2.OWNER        =F1.OWNER         or (F2.OWNER         is null and F1.OWNER         is null))
						  and(F2.INSTRUCTOR   =F1.INSTRUCTOR    or (F2.INSTRUCTOR    is null and F1.INSTRUCTOR    is null))
						  and(F2.FROMEVENTNO  =F1.FROMEVENTNO   or (F2.FROMEVENTNO   is null and F1.FROMEVENTNO   is null)) )
			  Where F1.DEBTOR=@pnNameNoConsolidateFrom)
		Begin
			DELETE F1
			from FEESCALCULATION F1
			join FEESCALCULATION F2 on( F2.CRITERIANO   =F1.CRITERIANO
						  and(F2.DEBTORTYPE   =F1.DEBTORTYPE    or (F2.DEBTORTYPE    is null and F1.DEBTORTYPE    is null))
						  and(F2.AGENT        =F1.AGENT         or (F2.AGENT         is null and F1.AGENT         is null))
						  and F2.DEBTOR       =@pnNameNoConsolidateTo
						  and(F2.CYCLENUMBER  =F1.CYCLENUMBER   or (F2.CYCLENUMBER   is null and F1.CYCLENUMBER   is null))
 						  and(F2.VALIDFROMDATE=F1.VALIDFROMDATE or (F2.VALIDFROMDATE is null and F1.VALIDFROMDATE is null))
						  and(F2.OWNER        =F1.OWNER         or (F2.OWNER         is null and F1.OWNER         is null))
						  and(F2.INSTRUCTOR   =F1.INSTRUCTOR    or (F2.INSTRUCTOR    is null and F1.INSTRUCTOR    is null))
						  and(F2.FROMEVENTNO  =F1.FROMEVENTNO   or (F2.FROMEVENTNO   is null and F1.FROMEVENTNO   is null)) )
			Where F1.DEBTOR=@pnNameNoConsolidateFrom
			
			Set @nErrorCode=@@ERROR
		End
		Else Begin
			update FEESCALCULATION
			set DEBTOR=@pnNameNoConsolidateTo
			where DEBTOR=@pnNameNoConsolidateFrom
			
			set @nErrorCode=@@Error
		End
	End

	-- FEESCALCULATION.INSTRUCTOR
	If @nErrorCode=0
	Begin
		If exists(select 1 
			  from FEESCALCULATION F1
			  join FEESCALCULATION F2 on( F2.CRITERIANO   =F1.CRITERIANO
						  and(F2.DEBTORTYPE   =F1.DEBTORTYPE    or (F2.DEBTORTYPE    is null and F1.DEBTORTYPE    is null))
						  and(F2.AGENT        =F1.AGENT         or (F2.AGENT         is null and F1.AGENT         is null))
						  and(F2.DEBTOR       =F1.DEBTOR        or (F2.DEBTOR        is null and F1.DEBTOR        is null))
						  and(F2.CYCLENUMBER  =F1.CYCLENUMBER   or (F2.CYCLENUMBER   is null and F1.CYCLENUMBER   is null))
 						  and(F2.VALIDFROMDATE=F1.VALIDFROMDATE or (F2.VALIDFROMDATE is null and F1.VALIDFROMDATE is null))
						  and(F2.OWNER        =F1.OWNER         or (F2.OWNER         is null and F1.OWNER         is null))
						  and F2.INSTRUCTOR   =@pnNameNoConsolidateTo
						  and(F2.FROMEVENTNO  =F1.FROMEVENTNO   or (F2.FROMEVENTNO   is null and F1.FROMEVENTNO   is null)) )
			  Where F1.INSTRUCTOR=@pnNameNoConsolidateFrom)
		Begin
			DELETE F1
			from FEESCALCULATION F1
			join FEESCALCULATION F2 on( F2.CRITERIANO   =F1.CRITERIANO
						  and(F2.DEBTORTYPE   =F1.DEBTORTYPE    or (F2.DEBTORTYPE    is null and F1.DEBTORTYPE    is null))
						  and(F2.AGENT        =F1.AGENT         or (F2.AGENT         is null and F1.AGENT         is null))
						  and(F2.DEBTOR       =F1.DEBTOR        or (F2.DEBTOR        is null and F1.DEBTOR        is null))
						  and(F2.CYCLENUMBER  =F1.CYCLENUMBER   or (F2.CYCLENUMBER   is null and F1.CYCLENUMBER   is null))
 						  and(F2.VALIDFROMDATE=F1.VALIDFROMDATE or (F2.VALIDFROMDATE is null and F1.VALIDFROMDATE is null))
						  and(F2.OWNER        =F1.OWNER         or (F2.OWNER         is null and F1.OWNER         is null))
						  and F2.INSTRUCTOR   =@pnNameNoConsolidateTo
						  and(F2.FROMEVENTNO  =F1.FROMEVENTNO   or (F2.FROMEVENTNO   is null and F1.FROMEVENTNO   is null)) )
			Where F1.INSTRUCTOR=@pnNameNoConsolidateFrom
			
			Set @nErrorCode=@@ERROR
		End
		Else Begin
			update FEESCALCULATION
			set INSTRUCTOR=@pnNameNoConsolidateTo
			where INSTRUCTOR=@pnNameNoConsolidateFrom
			
			set @nErrorCode=@@Error
		End
	End

	-- FEESCALCULATION.OWNER
	If @nErrorCode=0
	Begin
		If exists(select 1 
			  from FEESCALCULATION F1
			  join FEESCALCULATION F2 on( F2.CRITERIANO   =F1.CRITERIANO
						  and(F2.DEBTORTYPE   =F1.DEBTORTYPE    or (F2.DEBTORTYPE    is null and F1.DEBTORTYPE    is null))
						  and(F2.AGENT        =F1.AGENT         or (F2.AGENT         is null and F1.AGENT         is null))
						  and(F2.DEBTOR       =F1.DEBTOR        or (F2.DEBTOR        is null and F1.DEBTOR        is null))
						  and(F2.CYCLENUMBER  =F1.CYCLENUMBER   or (F2.CYCLENUMBER   is null and F1.CYCLENUMBER   is null))
 						  and(F2.VALIDFROMDATE=F1.VALIDFROMDATE or (F2.VALIDFROMDATE is null and F1.VALIDFROMDATE is null))
						  and F2.OWNER        =@pnNameNoConsolidateTo
						  and(F2.INSTRUCTOR   =F1.INSTRUCTOR    or (F2.INSTRUCTOR    is null and F1.INSTRUCTOR    is null))
						  and(F2.FROMEVENTNO  =F1.FROMEVENTNO   or (F2.FROMEVENTNO   is null and F1.FROMEVENTNO   is null)) )
			  Where F1.OWNER=@pnNameNoConsolidateFrom)
		Begin
			DELETE F1
			from FEESCALCULATION F1
			join FEESCALCULATION F2 on( F2.CRITERIANO   =F1.CRITERIANO
						  and(F2.DEBTORTYPE   =F1.DEBTORTYPE    or (F2.DEBTORTYPE    is null and F1.DEBTORTYPE    is null))
						  and(F2.AGENT        =F1.AGENT         or (F2.AGENT         is null and F1.AGENT         is null))
						  and(F2.DEBTOR       =F1.DEBTOR        or (F2.DEBTOR        is null and F1.DEBTOR        is null))
						  and(F2.CYCLENUMBER  =F1.CYCLENUMBER   or (F2.CYCLENUMBER   is null and F1.CYCLENUMBER   is null))
 						  and(F2.VALIDFROMDATE=F1.VALIDFROMDATE or (F2.VALIDFROMDATE is null and F1.VALIDFROMDATE is null))
						  and F2.OWNER        =@pnNameNoConsolidateTo
						  and(F2.INSTRUCTOR   =F1.INSTRUCTOR    or (F2.INSTRUCTOR    is null and F1.INSTRUCTOR    is null))
						  and(F2.FROMEVENTNO  =F1.FROMEVENTNO   or (F2.FROMEVENTNO   is null and F1.FROMEVENTNO   is null)) )
			Where F1.OWNER=@pnNameNoConsolidateFrom
			
			Set @nErrorCode=@@ERROR
		End
		Else Begin
			update FEESCALCULATION
			set OWNER=@pnNameNoConsolidateTo
			where OWNER=@pnNameNoConsolidateFrom
		
			set @nErrorCode=@@Error
		End
	End

	-- FEESCALCULATION.DISBEMPLOYEENO
	If @nErrorCode=0
	Begin
		update FEESCALCULATION
		set DISBEMPLOYEENO=@pnNameNoConsolidateTo
		where DISBEMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- FEESCALCULATION.SERVEMPLOYEENO
	If @nErrorCode=0
	Begin
		update FEESCALCULATION
		set SERVEMPLOYEENO=@pnNameNoConsolidateTo
		where SERVEMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- FILEREQUEST.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update FILEREQUEST
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- FUNCTIONSECURITY.ACCESSSTAFFNO
	If @nErrorCode=0
	Begin
		update FUNCTIONSECURITY
		set ACCESSSTAFFNO=@pnNameNoConsolidateTo
		where ACCESSSTAFFNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- FUNCTIONSECURITY.OWNERNO
	If @nErrorCode=0
	Begin
		update FUNCTIONSECURITY
		set OWNERNO=@pnNameNoConsolidateTo
		where OWNERNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- GLACCOUNTMAPPING.WIPEMPLOYEENO
	If @nErrorCode=0
	Begin
		update GLACCOUNTMAPPING
		set WIPEMPLOYEENO=@pnNameNoConsolidateTo
		where WIPEMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- IDENTITYNAMES.NAMENO
	If @nErrorCode=0
	Begin
		update IDENTITYNAMES
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- IMPORTBATCH.FROMNAMENO
	If @nErrorCode=0
	Begin
		update IMPORTBATCH
		set FROMNAMENO=@pnNameNoConsolidateTo
		where FROMNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- IRALLOCATION.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update IRALLOCATION
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- LETTERSUBSTITUTE.NAMENO
	If @nErrorCode=0
	Begin
		update LETTERSUBSTITUTE
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- MARGIN.AGENT
	If @nErrorCode=0
	Begin
		update MARGIN
		set AGENT=@pnNameNoConsolidateTo
		where AGENT=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- MARGIN.INSTRUCTOR
	If @nErrorCode=0
	Begin
		update MARGIN
		set INSTRUCTOR=@pnNameNoConsolidateTo
		where INSTRUCTOR=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- NAMEADDRESSSNAP.ATTNNAMENO
	If @nErrorCode=0
	Begin
		update NAMEADDRESSSNAP
		set ATTNNAMENO=@pnNameNoConsolidateTo
		where ATTNNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- NAMEADDRESSSNAP.NAMENO
	If @nErrorCode=0
	Begin
		update NAMEADDRESSSNAP
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- NAMETYPE.DEFAULTNAMENO
	If @nErrorCode=0
	Begin
		update NAMETYPE
		set DEFAULTNAMENO=@pnNameNoConsolidateTo
		where DEFAULTNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- NAMEVARIANT.NAMENO
	If @nErrorCode=0
	Begin
		update NAMEVARIANT
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- NAMELOCATION.NAMENO
	If @nErrorCode=0
	Begin
		update NAMELOCATION
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- NARRATIVERULE.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update NARRATIVERULE
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- NARRATIVERULE.DEBTORNO -- SQA17755
	If @nErrorCode=0
	Begin
		update NARRATIVERULE
		set DEBTORNO=@pnNameNoConsolidateTo
		where DEBTORNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- NARRATIVESUBSTITUT.NAMENO
	If @nErrorCode=0
	Begin
		update NARRATIVESUBSTITUT
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- OFFICE.ORGNAMENO
	If @nErrorCode=0
	Begin
		update OFFICE
		set ORGNAMENO=@pnNameNoConsolidateTo
		where ORGNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- POLICING.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update POLICING
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- POLICING.NAMENO
	If @nErrorCode=0
	Begin
		update POLICING
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- QUOTATION.QUOTATIONNAMENO
	If @nErrorCode=0
	Begin
		update QUOTATION
		set QUOTATIONNAMENO=@pnNameNoConsolidateTo
		where QUOTATIONNAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- QUOTATION.RAISEDBYNO
	If @nErrorCode=0
	Begin
		update QUOTATION
		set RAISEDBYNO=@pnNameNoConsolidateTo
		where RAISEDBYNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- RECIPROCITY.NAMENO
	If @nErrorCode=0
	Begin
		update RECIPROCITY
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- RECORDALAFFECTEDCASE.AGENTNO
	If @nErrorCode=0
	Begin
		update RECORDALAFFECTEDCASE
		set AGENTNO=@pnNameNoConsolidateTo
		where AGENTNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- RELATEDCASE.AGENT
	If @nErrorCode=0
	Begin
		update RELATEDCASE
		set AGENT=@pnNameNoConsolidateTo
		where AGENT=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- RELATEDCASE.TRANSLATOR
	If @nErrorCode=0
	Begin
		update RELATEDCASE
		set TRANSLATOR=@pnNameNoConsolidateTo
		where TRANSLATOR=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- REMINDERS.REMINDEMPLOYEE
	If @nErrorCode=0
	Begin
		update REMINDERS
		set REMINDEMPLOYEE=@pnNameNoConsolidateTo
		where REMINDEMPLOYEE=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- RFIDFILEREQUEST.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update RFIDFILEREQUEST
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- ROWACCESSDETAIL.NAMENO
	If @nErrorCode=0
	Begin
		update ROWACCESSDETAIL
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- TIMECOSTING.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update TIMECOSTING
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- TIMECOSTING.INSTRUCTOR
	If @nErrorCode=0
	Begin
		update TIMECOSTING
		set INSTRUCTOR=@pnNameNoConsolidateTo
		where INSTRUCTOR=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- TIMECOSTING.NAMENO
	If @nErrorCode=0
	Begin
		update TIMECOSTING
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- TIMECOSTING.OWNER
	If @nErrorCode=0
	Begin
		update TIMECOSTING
		set OWNER=@pnNameNoConsolidateTo
		where OWNER=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- TRANSACTIONINFO.NAMENO
	If @nErrorCode=0
	Begin
		update TRANSACTIONINFO
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- TRANSADJUSTMENT.TOEMPLOYEENO
	If @nErrorCode=0
	Begin
		update TRANSADJUSTMENT
		set TOEMPLOYEENO=@pnNameNoConsolidateTo
		where TOEMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- USERIDENTITY.NAMENO
	If @nErrorCode=0
	Begin
		update USERIDENTITY
		set NAMENO=@pnNameNoConsolidateTo
		where NAMENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- WORKHISTORY.ASSOCIATENO
	If @nErrorCode=0
	Begin
		update WORKHISTORY
		set ASSOCIATENO=@pnNameNoConsolidateTo
		where ASSOCIATENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- WORKHISTORY.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update WORKHISTORY
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- WORKHISTORY.ACCTCLIENTNO
	If @nErrorCode=0
	Begin
		update WORKHISTORY
		set ACCTCLIENTNO=@pnNameNoConsolidateTo
		where ACCTCLIENTNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- WORKINPROGRESS.ASSOCIATENO
	If @nErrorCode=0
	Begin
		update WORKINPROGRESS
		set ASSOCIATENO=@pnNameNoConsolidateTo
		where ASSOCIATENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- WORKINPROGRESS.EMPLOYEENO
	If @nErrorCode=0
	Begin
		update WORKINPROGRESS
		set EMPLOYEENO=@pnNameNoConsolidateTo
		where EMPLOYEENO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	-- WORKINPROGRESS.ACCTCLIENTNO
	If @nErrorCode=0
	Begin
		update WORKINPROGRESS
		set ACCTCLIENTNO=@pnNameNoConsolidateTo
		where ACCTCLIENTNO=@pnNameNoConsolidateFrom
		
		set @nErrorCode=@@Error
	End

	
	-------------------------------------------------------------------------------
	-- N A M E   D E L E T I O N
	-- Now that all references to the Old NameNo have been moved to the New NameNo, 
	-- the Old Name may be removed from the database
	-------------------------------------------------------------------------------
	if @nErrorCode=0
	Begin
		If @bRetainName=1
		Begin
			Set @sSQLString="
			Update NAME
			set DATECEASED=convert(nvarchar(11),getdate(),112)
			where NAMENO=@pnNameNoConsolidateFrom"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnNameNoConsolidateFrom	int',
							  @pnNameNoConsolidateFrom
		End
		Else Begin
			Set @sSQLString="
			delete from NAME
			where NAMENO=@pnNameNoConsolidateFrom"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnNameNoConsolidateFrom	int',
							  @pnNameNoConsolidateFrom
		End
	End
	
	If @nErrorCode=0
	Begin
		------------------------------------------
		-- Recalculate the derived attention names
		-- stored against the Cases.
		------------------------------------------
		exec @nErrorCode=dbo.cs_RecalculateDerivedAttention
						@pnMainNameKey		=@pnNameNoConsolidateTo,
						@pbCalledFromCentura	=0	-- deliberately set to 0 so as not to get count back
	End

	-- Commit the transaction if it has successfully completed

	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
		Begin
			COMMIT TRANSACTION
		End
		Else Begin
			ROLLBACK TRANSACTION
		End
	End
End

If @pbCalledFromCentura=1
	select @nErrorCode
	
Return @nErrorCode
GO

Grant execute on dbo.na_ConsolidateName to public
GO
