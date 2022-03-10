-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [acw_GetDefaultDiscountDetails] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[acw_GetDefaultDiscountDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[acw_GetDefaultDiscountDetails].'
	drop procedure dbo.[acw_GetDefaultDiscountDetails]
end
print '**** Creating procedure dbo.[acw_GetDefaultDiscountDetails]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go      

create procedure dbo.[acw_GetDefaultDiscountDetails]
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture				nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnCaseKey              int     = null, -- used to get default tax code.
				@pnNameKey				int,	-- Mandatory
				@pnStaffKey				int		= null,
				@pnEntityKey			int		= null
as
-- PROCEDURE :	acw_GetDefaultDiscountDetails
-- VERSION :	6
-- DESCRIPTION:	A procedure to return the default Discount narrative.
--
-- COPYRIGHT:	Copyright 1993 - 2013 CPA Global Software Solutions Pty Limited
-- MODIFICATION
-- Date			Who		RFC		Version Description
-- -----------	-------	------	------- ----------------------------------------------- 
-- 24-Mar-2009	AT		RFC3605		1		Procedure created.
-- 20-Aug-2010	MS		RFC9685		2		Added Best Fit Criteria for Narrative and return Discount WIP Codes
-- 21 Sep 2010  MS      RFC5885		3       Swap DebtorKey with NameKey in Best Fit rule for Narrative for debtor value based on RenewalFlag
-- 27-Mar-2013	AT		RFC13318	4		Return correct tax code taking into account from name key (debtor).
-- 15-Feb-2018	Ak		RFC72937	5		passed @pnStaffKey in fn_GetDefaultTaxCodeForWIP.
-- 04 Oct 2018  AK		R74005		6		passed @pnEntityKey in fn_GetDefaultTaxCodeForWIP
set nocount on

Declare	@nErrorCode	int
Declare @sSQLString nvarchar(max)

declare @sWIPCode nvarchar(6)
declare @sWIPDescription nvarchar(30)
declare @sWIPTypeId nvarchar(6)
declare @sWIPCategory nvarchar(3)
declare @sWIPCategorySort int
declare @sWIPTaxCode nvarchar(3)

declare @sRenewalWIPCode nvarchar(6)
declare @sRenewalWIPDescription nvarchar(30)
declare @sRenewalWIPTypeId nvarchar(6)
declare @sRenewalWIPCategory nvarchar(3)
declare @sRenewalWIPCategorySort int
declare @sRenewalWIPTaxCode nvarchar(3)

declare @nNarrativeNo	int
declare @sNarrativeCode nvarchar(6)
declare @sNarrativeTitle nvarchar(50)
declare @sNarrativeText nvarchar(max)
Declare	@nDebtorKey		int	

if exists (select COLCHARACTER FROM SITECONTROL WHERE CONTROLID = 'Discounts' and COLBOOLEAN = 1)
Begin

-- Deriving DebtorKey. The main debtor for the CaseKey is used. This is the 
-- CaseName for the Name Type = 'D' with the minimum sequence number.
    			
	declare @sSiteControl nvarchar(30)
	Set @sSiteControl = 'Discount WIP Code'
	
	Set @sSQLString = "
		select @sWIPCode = WT.WIPCODE,
		@sWIPDescription = WT.DESCRIPTION,
		@sWIPTypeId = WT.WIPTYPEID,
		@sWIPCategory = WC.CATEGORYCODE,
		@sWIPCategorySort = WC.CATEGORYSORT,
		@sWIPTaxCode = dbo.fn_GetDefaultTaxCodeForWIP(@pnCaseKey,WT.WIPCODE,@pnNameKey,@pnStaffKey,@pnEntityKey)
		FROM WIPTEMPLATE WT
		Join WIPTYPE WTP on (WT.WIPTYPEID = WTP.WIPTYPEID)
		Join WIPCATEGORY WC on (WC.CATEGORYCODE = WTP.CATEGORYCODE)
		WHERE WT.WIPCODE = (select COLCHARACTER FROM SITECONTROL WHERE CONTROLID = @sSiteControl)"

	exec @nErrorCode = sp_executesql @sSQLString, 
			  N'@sWIPCode		nvarchar(6) output,
				@sWIPDescription nvarchar(30) output,
				@sWIPTypeId nvarchar(6) output,
				@sWIPCategory nvarchar(3) output,
				@sWIPCategorySort int output,
				@sWIPTaxCode nvarchar(3) output,
				@pnCaseKey		int,
				@pnNameKey		int,
				@pnStaffKey		int,
				@pnEntityKey	int,
				@sSiteControl	nvarchar(30)',
				@sWIPCode=@sWIPCode output,
				@sWIPDescription=@sWIPDescription output,
				@sWIPTypeId=@sWIPTypeId output,
				@sWIPCategory=@sWIPCategory output,
				@sWIPCategorySort=@sWIPCategorySort output,
				@sWIPTaxCode=@sWIPTaxCode output,
				@pnCaseKey		= @pnCaseKey,
				@pnNameKey		= @pnNameKey,
				@pnEntityKey	= @pnEntityKey,
				@pnStaffKey		= @pnStaffKey,
				@sSiteControl = 'Discount WIP Code'
	
	If (@nErrorCode = 0)
	Begin
		exec @nErrorCode = sp_executesql @sSQLString, 
			  N'@sWIPCode		nvarchar(6) output,
				@sWIPDescription nvarchar(30) output,
				@sWIPTypeId nvarchar(6) output,
				@sWIPCategory nvarchar(3) output,
				@sWIPCategorySort int output,
				@sWIPTaxCode nvarchar(3) output,
				@pnCaseKey		int,
				@pnNameKey		int,
				@pnStaffKey		int,
				@pnEntityKey	int,
				@sSiteControl	nvarchar(30)',
				@sWIPCode=@sRenewalWIPCode output,
				@sWIPDescription=@sRenewalWIPDescription output,
				@sWIPTypeId=@sRenewalWIPTypeId output,
				@sWIPCategory=@sRenewalWIPCategory output,
				@sWIPCategorySort=@sRenewalWIPCategorySort output,
				@sWIPTaxCode=@sRenewalWIPTaxCode output,
				@pnCaseKey		= @pnCaseKey,
				@pnNameKey		= @pnNameKey,
				@pnStaffKey		= @pnStaffKey,
				@pnEntityKey	= @pnEntityKey,
				@sSiteControl	= 'Discount Renewal WIP Code'
	End

    If (@nErrorCode = 0)  
	Begin
	
	    If @sWIPCode is not null
	    Begin
		    If @nErrorCode =0 and @pnCaseKey is not null
		    Begin
			    Set @sSQLString = 
			    "Select @nDebtorKey = CN.NAMENO
			     from CASENAME CN
			     where CN.CASEID = @pnCaseKey
			     and   CN.NAMETYPE = 'D'
			     and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
			     and   CN.SEQUENCE = (select min(SEQUENCE) from CASENAME CN
						      where CN.CASEID = @pnCaseKey
						      and CN.NAMETYPE = 'D'
						      and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"
			    exec @nErrorCode = sp_executesql @sSQLString,
						    N'@nDebtorKey			int			output,
						      @pnCaseKey			int',
						      @nDebtorKey			= @nDebtorKey		output,
						      @pnCaseKey			= @pnCaseKey
						    
		    End
		    Set @sSQLString = "
			    select @nNarrativeNo = N.NARRATIVENO,
			    @sNarrativeCode = N.NARRATIVECODE,
			    @sNarrativeTitle = N.NARRATIVETITLE,
			    @sNarrativeText = N.NARRATIVETEXT
			    FROM NARRATIVE N"
    			
		    Set @sSQLString = @sSQLString + char(10)+
		        " join ( Select "+char(10)+
                                "convert(int,"+char(10)+
                                "substring("+char(10)+
				"max ("+char(10)+								
				"CASE WHEN (NRL.DEBTORNO IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    
				"CASE WHEN (NRL.EMPLOYEENO IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    
				"CASE WHEN (NRL.CASETYPE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    			
				"CASE WHEN (NRL.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
				"CASE WHEN (NRL.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
				"CASE WHEN (NRL.SUBTYPE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
				"CASE WHEN (NRL.TYPEOFMARK is NULL)	THEN '0' ELSE '1' END +"+char(10)+
				"cast(NRL.NARRATIVENO as varchar(5)) ),8,5)) as NarrativeNo"+char(10)+
				"from NARRATIVERULE NRL"+char(10)+
				"left join CASES C on " + char(10)+ 
				CASE WHEN @pnCaseKey is null THEN "(C.CASEID is null)" ELSE "(C.CASEID = "+CAST(@pnCaseKey as varchar(11))+")" END +char(10)+							
				"where NRL.WIPCODE		= '"+ CAST(@sWIPCode as varchar(11)) + "'" + char(10)+	
				CASE WHEN @pnNameKey is null and @nDebtorKey is null THEN "AND NRL.DEBTORNO IS NULL "
				ELSE "AND ( NRL.DEBTORNO = "+ISNULL(CAST(@nDebtorKey as varchar(11)), CAST(@pnNameKey as varchar(11)))+ " OR NRL.DEBTORNO IS NULL )" END +char(10)+
				CASE WHEN @pnStaffKey is null THEN "AND NRL.EMPLOYEENO IS NULL "
				ELSE "AND ( NRL.EMPLOYEENO = "+CAST(@pnStaffKey as varchar(11))+" OR NRL.EMPLOYEENO IS NULL )" END +char(10)+
				"AND (	NRL.CASETYPE		= C.CASETYPE		OR NRL.CASETYPE		is NULL )"+char(10)+
				"AND (	NRL.PROPERTYTYPE 	= C.PROPERTYTYPE 	OR NRL.PROPERTYTYPE 	IS NULL )"+char(10)+
				"AND (	NRL.CASECATEGORY 	= C.CASECATEGORY 	OR NRL.CASECATEGORY 	IS NULL )"+char(10)+
				"AND (	NRL.SUBTYPE 		= C.SUBTYPE 		OR NRL.SUBTYPE	 	IS NULL )"+char(10)+
				"AND (	NRL.TYPEOFMARK		= C.TYPEOFMARK		OR NRL.TYPEOFMARK	IS NULL )"+char(10)+
				-- As there could be multiple Narrative rules for a WIP Code with the same best fit score, 
			        -- a NarrativeKey and other Narrative columns should only be defaulted if there is only 
				-- a single row with the maximum best fit score.
				"and not exists (Select 1"+char(10)+
				"		from NARRATIVERULE NRL2"+char(10)+
				"		where   NRL2.WIPCODE = NRL.WIPCODE"+char(10)+ 
				"		AND (	NRL2.DEBTORNO 		= NRL.DEBTORNO		OR (NRL2.DEBTORNO 	IS NULL AND NRL.DEBTORNO 	IS NULL) )"+char(10)+
				"		AND (	NRL2.EMPLOYEENO 	= NRL.EMPLOYEENO	OR (NRL2.EMPLOYEENO 	IS NULL AND NRL.EMPLOYEENO 	IS NULL) )"+char(10)+
				"		AND (	NRL2.CASETYPE		= NRL.CASETYPE		OR (NRL2.CASETYPE 	IS NULL AND NRL.CASETYPE	IS NULL) )"+char(10)+
				"		AND (	NRL2.PROPERTYTYPE 	= NRL.PROPERTYTYPE 	OR (NRL2.PROPERTYTYPE 	IS NULL AND NRL.PROPERTYTYPE 	IS NULL) )"+char(10)+
				"		AND (	NRL2.CASECATEGORY 	= NRL.CASECATEGORY 	OR (NRL2.CASECATEGORY 	IS NULL AND NRL.CASECATEGORY 	IS NULL) )"+char(10)+
				"		AND (	NRL2.SUBTYPE 		= NRL.SUBTYPE 		OR (NRL2.SUBTYPE 	IS NULL AND NRL.SUBTYPE	 	IS NULL) )"+char(10)+
				"		AND (	NRL2.TYPEOFMARK		= NRL.TYPEOFMARK	OR (NRL2.TYPEOFMARK	IS NULL AND NRL.TYPEOFMARK	IS NULL) )"+char(10)+
				"		AND NRL2.NARRATIVERULENO <> NRL.NARRATIVERULENO)"+char(10)+
				"group by NRL.WIPCODE) BestFit  on (BestFit.NarrativeNo = N.NARRATIVENO)"							    
		
	    End
	    Else 
	    Begin
		    Set @sSQLString = "
			    select @nNarrativeNo = NARRATIVENO,
			    @sNarrativeCode = NARRATIVECODE,
			    @sNarrativeTitle = NARRATIVETITLE,
			    @sNarrativeText = NARRATIVETEXT
			    FROM NARRATIVE WHERE NARRATIVECODE = (select COLCHARACTER FROM SITECONTROL WHERE CONTROLID = 'Discount Narrative')"					    
			
	    End 
	    
	    exec @nErrorCode = sp_executesql @sSQLString, 
			N'@nNarrativeNo	        int                     output,
			@sNarrativeCode         nvarchar(6)             output,
			@sNarrativeTitle        nvarchar(50)            output,
			@sNarrativeText         nvarchar(max)           output',
			@nNarrativeNo           =@nNarrativeNo          output,
			@sNarrativeCode         =@sNarrativeCode        output,
			@sNarrativeTitle        =@sNarrativeTitle       output,
			@sNarrativeText         =@sNarrativeText        output	 
	End	

	select @sWIPCode as 'WIPCode', 
		@sWIPDescription as 'WIPDescription',
		@sWIPTypeId as 'WIPTypeId',
		@sWIPCategory as 'WIPCategory',
		@sWIPCategorySort as 'WIPCategorySort',
		@sWIPTaxCode as 'WIPTaxCode',
		@sRenewalWIPCode as 'RenewalWIPCode', 
		@sRenewalWIPDescription as 'RenewalWIPDescription',
		@sRenewalWIPTypeId as 'RenewalWIPTypeId',
		@sRenewalWIPCategory as 'RenewalWIPCategory',
		@sRenewalWIPCategorySort as 'RenewalWIPCategorySort',
		@sRenewalWIPTaxCode as 'RenewalWIPTaxCode',
		@nNarrativeNo as 'NarrativeNo',
		@sNarrativeCode as 'NarrativeCode',
		@sNarrativeTitle as 'NarrativeTitle',
		@sNarrativeText as 'NarrativeText'
End


return @nErrorCode
go

grant execute on dbo.[acw_GetDefaultDiscountDetails]  to public
go
