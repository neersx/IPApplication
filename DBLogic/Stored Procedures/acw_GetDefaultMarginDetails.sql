-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [acw_GetDefaultMarginDetails] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[acw_GetDefaultMarginDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[acw_GetDefaultMarginDetails].'
	drop procedure dbo.[acw_GetDefaultMarginDetails]
end
print '**** Creating procedure dbo.[acw_GetDefaultMarginDetails]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[acw_GetDefaultMarginDetails]
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture				nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnCaseKey				int		= null, 
				@pbRenewalFlag			bit		= 0,
				@pnNameKey              int,
				@pnStaffKey             int		= null,
				@pnEntityKey			int		= null
as
-- PROCEDURE :	acw_GetDefaultMarginDetails
-- VERSION :	6
-- DESCRIPTION:	A procedure to return the default Margin narrative.
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions Pty Limited
-- MODIFICATION
-- Date			Who		RFC			Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 24-Jun-2010	MS		RFC7269		1		Procedure created.
-- 29-Jul-2010  MS		RFC100332	2		Return Associated Margin Narratives for WIP Codes
-- 21-Sep-2010  MS      RFC5885     3       Define BestFit narrative rule for getting Narratives for the margin.
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

declare @nNarrativeNo int
declare @sNarrativeCode nvarchar(6)
declare @sNarrativeTitle nvarchar(50)
declare @sNarrativeText nvarchar(max)
Declare	@nDebtorKey int

declare @sControlId nvarchar(50)

Set @nErrorCode = 0

If @pbRenewalFlag = 0
Begin
	SET @sControlId = 'Margin WIP Code'
END
Else
Begin
	SET @sControlId = 'Margin Renewal WIP Code'
End

-- Fetch WIP code & description
If @nErrorCode = 0
Begin
    Set @sSQLString = "
		select @sWIPCode = WT.WIPCODE,
		@sWIPDescription = WT.DESCRIPTION,
		@sWIPTypeId = WT.WIPTYPEID,
		@sWIPCategory = WC.CATEGORYCODE,
		@sWIPCategorySort = WC.CATEGORYSORT,
		@sWIPTaxCode = dbo.fn_GetDefaultTaxCodeForWIP(@pnCaseKey,WT.WIPCODE,@pnNameKey, @pnStaffKey, @pnEntityKey)
		FROM WIPTEMPLATE WT
		Join WIPTYPE WTP on (WT.WIPTYPEID = WTP.WIPTYPEID)
		Join WIPCATEGORY WC on (WC.CATEGORYCODE = WTP.CATEGORYCODE)
		WHERE WT.WIPCODE = (select COLCHARACTER FROM SITECONTROL WHERE CONTROLID = @sControlId)"

    exec @nErrorCode = sp_executesql @sSQLString, 
			N'@sWIPCode		nvarchar(6) output,
			@sWIPDescription	nvarchar(30) output,
			@sWIPTypeId		nvarchar(6) output,
			@sWIPCategory		nvarchar(3) output,
			@sWIPCategorySort	int output,
			@sWIPTaxCode		nvarchar(3) output,
			@sControlId		nvarchar(50),
			@pnCaseKey		int,
			@pnStaffKey		int,
			@pnEntityKey	int,
			@pnNameKey		int',
			@sWIPCode		= @sWIPCode output,
			@sWIPDescription	= @sWIPDescription output,
			@sWIPTypeId		= @sWIPTypeId output,
			@sWIPCategory		= @sWIPCategory output,
			@sWIPCategorySort	= @sWIPCategorySort output,
			@sWIPTaxCode		= @sWIPTaxCode output,
			@sControlId		= @sControlId,
			@pnCaseKey		= @pnCaseKey,
			@pnEntityKey	= @pnEntityKey,
			@pnStaffKey		= @pnStaffKey,
			@pnNameKey		= @pnNameKey
END

-- Fetch Narrative
If (@nErrorCode = 0)  
Begin
        If @sWIPCode is not null
	Begin
	        -- Deriving DebtorKey. The main debtor for the CaseKey is used. This is the 
		-- CaseName for the Name Type = 'D' with the minimum sequence number.
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
			FROM NARRATIVE 
			WHERE NARRATIVECODE = (select COLCHARACTER FROM SITECONTROL WHERE CONTROLID = 'Margin Narrative')"
		
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

If (@nErrorCode = 0)
Begin
	select @sWIPCode as 'WIPCode', 
		@sWIPDescription as 'WIPDescription',
		@sWIPTypeId as 'WIPTypeId',
		@sWIPCategory as 'WIPCategory',
		@sWIPCategorySort as 'WIPCategorySort',
		@sWIPTaxCode as 'WIPTaxCode',		
		@nNarrativeNo as 'NarrativeNo',
		@sNarrativeCode as 'NarrativeCode',
		@sNarrativeTitle as 'NarrativeTitle',
		@sNarrativeText as 'NarrativeText'
End

return @nErrorCode
go

grant execute on dbo.[acw_GetDefaultMarginDetails]  to public
go
