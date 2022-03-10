-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseName.'
	Drop procedure [dbo].[csw_ListCaseName]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListCaseName
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int, 		-- Mandatory
	@psProgramKey           nvarchar(8)     = null,
	@pnScreenCriteriaKey    int             = null
)
as
-- PROCEDURE:	csw_ListCaseName
-- VERSION:	19
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List Case Names for a case.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 17 Jul 2008	AT	RFC5749	1	Procedure created - Moved SQL from csw_ListCaseDetail.
--					Filter out name types by Screen Control NameType group 
--					for CRM Only case types.
-- 18 Sep 2008	AT	RFC5712 2	Filter out Bulk Name Types.
-- 23 Mar 2009	JC	RFC7756 3	Change fn_GetScreenControlNameTypes to fnw_GetScreenControlNameTypes
-- 30 Nov 2009	ASH	RFC8608 4	Implement two new columns 'AddressKey' and 'DefaultAddressKey'.
-- 24 Jun 2011	LP	RFC10896 5	DefaultAddressKey should be the Postal Address.
--					Always return the ADDRESSCODE against the CASENAME.
--					If CASENAME.ADDRESSCODE is null, then return the POSTALADDRESS for the NAME.
-- 21 Oct 2011  MS      R11438  6       Pass Namestyle in fn_FormatName call
-- 24 Oct 2011	ASH	R11460  7	Cast integer columns as nvarchar(11) data type.
-- 17 Jan 2012  MS      R11637  8      	Name Type Show Data fields checkboxes values will be checked before displaying
--					Attention, Name Variant, Address and Reference
-- 13 Aug 2012  DV	R12600	9	Return LOGDATETIMESTAMP column
-- 15 Apr 2013	DV	R13270	10	Increase the length of nvarchar to 11 when casting or declaring integer
-- 08 Nov 2013  SW      R27304  11      Apply Name Code style on the formatted name.
-- 20 Jan 2014  MS      R100844 12      Added parameter @psProgramKey
-- 10 Jul 2014	MF	R36972	13	Ensure that Names being used for Billing purposes consider any explicit Attention and Address
--					details defined for the Name.
-- 06 Aug 2014  SW      R34645  14      Return Remarks field in CaseName result set.
-- 16 Sep 2014  SW      R27882  15      Applied Union with fnw_FilteredTopicNameTypes to include Name Types which are set as hidden
--                                      and added @pnScreenCriteriaKey non mandatory parameter to pass into fnw_FilteredTopicNameTypes
-- 05 Jun 2015	MS	R47867	16	Get N1.NAMENO rather than CN.CORREPSONDNAME when fetching default attention
-- 02 Nov 2015	vql	R53910	17	Adjust formatted names logic (DR-15543).
-- 29 Aug 2016	MF	62643	18	If the NAMETYPE being returned is to consider any Name Restrictions, then return any Debtor Status
--					associated with the Name along with the ActionFlag for that Debtor Status.
-- 11 Apr 2017  MS      R56196  19      Use NAMETYPE.PRIORITYORDER column for sort order

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(max)
Declare @sSQLString1 		nvarchar(max)

Declare @sCaseTypeKey 		nchar(1)
Declare @sCRMProgramName	nvarchar(8)

-- Initialise variables
Set @nErrorCode = 0


If @nErrorCode = 0
Begin
	set @sSQLString = "select @sCaseTypeKey = CASETYPE
			from CASES where CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'	@pnCaseKey	int,
						@sCaseTypeKey	nchar(1) output',	
						@pnCaseKey		= @pnCaseKey,
						@sCaseTypeKey		= @sCaseTypeKey output
End

If @nErrorCode = 0
Begin

	set @sSQLString = "select @sCRMProgramName = COLCHARACTER
			from SITECONTROL where UPPER(CONTROLID) = 'CRM SCREEN CONTROL PROGRAM'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'	@sCRMProgramName  nvarchar(8) output',
						@sCRMProgramName = @sCRMProgramName output
End

If @nErrorCode=0
Begin
	if (exists (select 1 from CASETYPE WHERE CASETYPE = @sCaseTypeKey AND CRMONLY = 1))
	Begin
		-- If CRM Case, filter names from screen control
		Set @sSQLString1 = '
		join dbo.fnw_GetScreenControlNameTypes(@pnUserIdentityId, @pnCaseKey, @sCRMProgramName) SCNT
					on (SCNT.NameTypeKey = CN.NAMETYPE)'
	End
	Else
	Begin
	        Set @sSQLString1 = "join("+char(10)
		Set @sSQLString1 = @sSQLString1 + "Select NAMETYPEKEY from dbo.fnw_GetScreenControlNameTypes(@pnUserIdentityId, @pnCaseKey, @psProgramKey)"+char(10)
		Set @sSQLString1 = @sSQLString1 + " UNION Select NAMETYPE AS NAMETYPEKEY from dbo.fnw_FilteredTopicNameTypes(@pnScreenCriteriaKey,0)"+char(10) 
		Set @sSQLString1 = @sSQLString1 + ") SCNT on (SCNT.NameTypeKey = CN.NAMETYPE)"	
	End
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	with NameRestrictions (NAMENO, DEBTORSTATUS, ACTIONFLAG)
	as (Select IP.NAMENO, dbo.fn_GetTranslation(DS.DEBTORSTATUS,null,DS.DEBTORSTATUS_TID,@psCulture), cast(DS.ACTIONFLAG as tinyint)
	    from IPNAME IP
	    join DEBTORSTATUS DS on (DS.BADDEBTOR=IP.BADDEBTOR)
	    )
	Select	CN.CASEID		as CaseKey,
		CN.NAMETYPE		as NameTypeKey,
		CN.NAMENO		as NameKey,
		CN.SEQUENCE 		as NameSequence,
		NT.DESCRIPTION		as NameTypeDescription,
		dbo.fn_ApplyNameCodeStyle(dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101)),
		                        NT.SHOWNAMECODE, N.NAMECODE)as Name,
		N.NAMECODE		as NameCode,
		CASE WHEN NT.COLUMNFLAGS&4=4 
		        THEN CN.REFERENCENO 
		        ELSE NULL END   as ReferenceNo,		
		CASE WHEN NT.COLUMNFLAGS&1=1 
		        THEN dbo.fn_FormatNameUsingNameNo(N1.NAMENO, COALESCE(N1.NAMESTYLE, NN1.NAMESTYLE, 7101)) 
		        ELSE NULL END   as Attention,
		CASE WHEN NT.COLUMNFLAGS&1=1 
		        THEN CN.CORRESPONDNAME
		 	ELSE NULL END   as AttentionKey,
		CASE WHEN NT.COLUMNFLAGS&2=2  
		        THEN dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, CT.POSTALNAME, CT.POSTCODEFIRST, CT.STATEABBREVIATED, CT.POSTCODELITERAL, CT.ADDRESSSTYLE)					
			ELSE NULL END   as Address,
		N.POSTALADDRESS		as DefaultAddressKey,
		A.ADDRESSCODE		as AddressKey,
		CASE WHEN NT.COLUMNFLAGS&64=64 THEN CN.BILLPERCENTAGE ELSE NULL END
					as BillPercent,
		CASE WHEN NT.COLUMNFLAGS&128=128 THEN CAST(CN.INHERITED as bit) ELSE NULL END
					as IsInherited,
		CASE WHEN NT.COLUMNFLAGS&16=16 THEN CN.COMMENCEDATE ELSE NULL END
					as CommenceDate,
		CASE WHEN NT.COLUMNFLAGS&32=32 THEN CN.EXPIRYDATE ELSE NULL END
					as ExpiryDate,
		CASE WHEN NT.COLUMNFLAGS&8=8 THEN CN.ASSIGNMENTDATE ELSE NULL END
					as AssignmentDate,
		CASE WHEN NT.COLUMNFLAGS&1024=1024 THEN CN.REMARKS ELSE NULL END
		                        as Remarks,			
		CASE WHEN NT.COLUMNFLAGS&512=512 
		        THEN dbo.fn_FormatName(NV.NAMEVARIANT, NV.FIRSTNAMEVARIANT, null, null)
		 	ELSE NULL END   as NameVariant,
		cast(CN.CASEID as varchar(11)) 	+ '^' + 
		CN.NAMETYPE 			+ '^' +
		cast(CN.NAMENO as varchar(11)) 	+ '^' + 
		cast(CN.SEQUENCE as varchar(5))
					as RowKey,
		CN.LOGDATETIMESTAMP	as LastModifiedDate,
		NT.PRIORITYORDER	as SORTORDER,
		 NR.DEBTORSTATUS	as DebtorStatus,
		 NR.ACTIONFLAG		as ActionFlag
	from CASENAME CN
	join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,@psCulture,0,@pbCalledFromCentura) NT 
					on (NT.NAMETYPE = CN.NAMETYPE
					and (NT.BULKENTRYFLAG = 0 or NT.BULKENTRYFLAG IS NULL))"
	+@sSQLString1 + "
	join NAME N 			on (N.NAMENO = CN.NAMENO)
	left join NameRestrictions NR	on (NR.NAMENO= CN.NAMENO
					and NT.NAMERESTRICTFLAG=1)
	left join COUNTRY NN		on (NN.COUNTRYCODE = N.NATIONALITY)
	left join ADDRESS A		on (A.ADDRESSCODE = ISNULL(CN.ADDRESSCODE, N.POSTALADDRESS))
	left join COUNTRY CT		on (CT.COUNTRYCODE=A.COUNTRYCODE)
	left join STATE S		on (S.COUNTRYCODE=A.COUNTRYCODE
					and S.STATE=A.STATE)
	left join NAME N1		on (N1.NAMENO=CN.CORRESPONDNAME)	
	left join COUNTRY NN1		on (NN1.COUNTRYCODE = N1.NATIONALITY)
	left join NAMEVARIANT NV	on (NV.NAMEVARIANTNO=CN.NAMEVARIANTNO)
	where CN.CASEID = @pnCaseKey
	and   CN.NAMETYPE not in ('D','Z')
	UNION ALL
	Select	CN.CASEID,
		CN.NAMETYPE,
		CN.NAMENO,
		CN.SEQUENCE,
		NT.DESCRIPTION,
		dbo.fn_ApplyNameCodeStyle(dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101)),
		                        NT.SHOWNAMECODE, N.NAMECODE),
		N.NAMECODE,
		CASE WHEN NT.COLUMNFLAGS&4=4 
		        THEN CN.REFERENCENO 
		        ELSE NULL END,		
		CASE WHEN NT.COLUMNFLAGS&1=1 
		        THEN dbo.fn_FormatNameUsingNameNo(N1.NAMENO, COALESCE(N1.NAMESTYLE, NN1.NAMESTYLE, 7101)) 
		        ELSE NULL END,
		CASE WHEN NT.COLUMNFLAGS&1=1 
		        THEN N1.NAMENO
		 	ELSE NULL END,
		CASE WHEN NT.COLUMNFLAGS&2=2  
		        THEN dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, CT.POSTALNAME, CT.POSTCODEFIRST, CT.STATEABBREVIATED, CT.POSTCODELITERAL, CT.ADDRESSSTYLE)					
			ELSE NULL END,
		N.POSTALADDRESS,
		A.ADDRESSCODE,
		CASE WHEN NT.COLUMNFLAGS&64=64   THEN CN.BILLPERCENTAGE         ELSE NULL END,
		CASE WHEN NT.COLUMNFLAGS&128=128 THEN CAST(CN.INHERITED as bit) ELSE NULL END,
		CASE WHEN NT.COLUMNFLAGS&16=16   THEN CN.COMMENCEDATE           ELSE NULL END,
		CASE WHEN NT.COLUMNFLAGS&32=32   THEN CN.EXPIRYDATE             ELSE NULL END,
		CASE WHEN NT.COLUMNFLAGS&8=8     THEN CN.ASSIGNMENTDATE         ELSE NULL END,
		CASE WHEN NT.COLUMNFLAGS&1024=1024 THEN CN.REMARKS              ELSE NULL END,
		CASE WHEN NT.COLUMNFLAGS&512=512 
		        THEN dbo.fn_FormatName(NV.NAMEVARIANT, NV.FIRSTNAMEVARIANT, null, null)
		 	ELSE NULL END,
		cast(CN.CASEID as varchar(11)) 	+ '^' + 
		CN.NAMETYPE 			+ '^' +
		cast(CN.NAMENO as varchar(11)) 	+ '^' + 
		cast(CN.SEQUENCE as varchar(5)),
		CN.LOGDATETIMESTAMP,
		NT.PRIORITYORDER,
		NR.DEBTORSTATUS,
		NR.ACTIONFLAG
	from CASENAME CN
	join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,@psCulture,0,@pbCalledFromCentura) NT 
					on (NT.NAMETYPE = CN.NAMETYPE
					and (NT.BULKENTRYFLAG = 0 or NT.BULKENTRYFLAG IS NULL))"
	+@sSQLString1 + "
	join NAME N 			on (N.NAMENO = CN.NAMENO)
	left join NameRestrictions NR	on (NR.NAMENO= CN.NAMENO
					and NT.NAMERESTRICTFLAG=1)
	left join COUNTRY NN		on (NN.COUNTRYCODE = N.NATIONALITY)
	left join NAMEVARIANT NV	on (NV.NAMEVARIANTNO=CN.NAMEVARIANTNO)
	-- Debtor/Renewal Debtor Attention
	left join ASSOCIATEDNAME AN2	on (AN2.NAMENO = CN.INHERITEDNAMENO
					and AN2.RELATIONSHIP = CN.INHERITEDRELATIONS
					and AN2.RELATEDNAME = CN.NAMENO
					and AN2.SEQUENCE = CN.INHERITEDSEQUENCE)
	left join ASSOCIATEDNAME AN3	on (AN3.NAMENO = CN.NAMENO
					and AN3.RELATIONSHIP = N'BIL'
					and AN3.NAMENO = AN3.RELATEDNAME
					and AN2.NAMENO is null)
	-- For Debtor and Renewal Debtor (name types 'D' and 'Z') Attention and Address should be 
	-- extracted in the same manner as billing (SQA7355):
	-- 1)	Details recorded on the CaseName table; if no information is found then step 2 will be performed;
	-- 2)	If the debtor was inherited from the associated name then the details recorded against this 
	--      associated name will be returned; if the debtor was not inherited then go to the step 3;
	-- 3)	Check if the Address/Attention has been overridden on the AssociatedName table with 
	--	Relationship = 'BIL' and NameNo = RelatedName; if no information was found then go to the step 4; 
	-- 4)	Extract the Attention and Address details stored against the Name as the PostalAddress 
	--	and MainContact. 
	left join NAME N1		on (N1.NAMENO = COALESCE(CN.CORRESPONDNAME, AN2.CONTACT, AN3.CONTACT, N.MAINCONTACT))
	left join COUNTRY NN1		on (NN1.COUNTRYCODE=N1.NATIONALITY)
	-- Debtor/Renewal Debtor Address
	left join ADDRESS A 		on (A.ADDRESSCODE  = COALESCE(CN.ADDRESSCODE, AN2.POSTALADDRESS,AN3.POSTALADDRESS, N.POSTALADDRESS))
	left join COUNTRY CT		on (CT.COUNTRYCODE = A.COUNTRYCODE)
	left join STATE   S		on (S.COUNTRYCODE  = A.COUNTRYCODE
		 	           	and S.STATE        = A.STATE)
	where CN.CASEID = @pnCaseKey
	and   CN.NAMETYPE in ('D','Z')
	order by SORTORDER,
		 NT.DESCRIPTION,
		 CN.SEQUENCE"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey   		int,
					  @pnUserIdentityId 	int,
					  @psCulture		nvarchar(10),
					  @pbCalledFromCentura	bit,
					  @sCRMProgramName      nvarchar(8),
					  @psProgramKey         nvarchar(8),
					  @pnScreenCriteriaKey  int',
					  @pnCaseKey		= @pnCaseKey, 
					  @pnUserIdentityId 	= @pnUserIdentityId,	
					  @psCulture		= @psCulture,
					  @pbCalledFromCentura	= @pbCalledFromCentura,
					  @sCRMProgramName	= @sCRMProgramName,
					  @psProgramKey         = @psProgramKey,
					  @pnScreenCriteriaKey  = @pnScreenCriteriaKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseName to public
GO