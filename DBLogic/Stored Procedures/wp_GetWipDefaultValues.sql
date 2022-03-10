-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_GetWipDefaultValues
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_GetWipDefaultValues]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_GetWipDefaultValues.'
	Drop procedure [dbo].[wp_GetWipDefaultValues]
End
Print '**** Creating Stored Procedure dbo.wp_GetWipDefaultValues...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.wp_GetWipDefaultValues
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	-- The language in which output is to be expressed.
	@pnCaseKey		int		= null, -- The key of the case selected.
	@psWIPCode      	nvarchar(6)	= null  -- The code of the activity selected.
)
as
-- PROCEDURE:	wp_GetWipDefaultValues
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This procedure defaults the fundamental WIP Information such as Agent and Currency Code.  
--              It can be used to extract information when the activity is entered or modified.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 Apr 2012	MS	R100686	1	Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		        int
Declare @sSQLString		        nvarchar(4000)
Declare @nLanguageKey		        int
Declare @sLookupCulture		        nvarchar(10)

Declare @sLocalCurrencyCode	        nvarchar(3)
Declare @nLocalDecimalPlaces 	        tinyint

Declare @nAgentNameKey		        int
Declare @sAgentNameCode		        nvarchar(10)
Declare @sAgentName		        nvarchar(254)

Declare @bDefaultCurrencyFromAgent      bit
Declare @bIsRenewalWIP                  bit
Declare @sCurrencyCode                  nvarchar(3)
Declare @sCurrency                      nvarchar(40)
Declare @bIsCurrencyDefaultFromAgent    bit

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)
Set @bIsRenewalWIP = 0

-- Extract IsRenewalWIP
If @nErrorCode = 0 and @psWIPCode is not null
Begin
        Set @sSQLString = "Select @bIsRenewalWIP = RENEWALFLAG
                        from WIPTEMPLATE
                        where WIPCODE = @psWIPCode"
                        
        exec @nErrorCode = sp_executesql @sSQLString,
                        N'@bIsRenewalWIP        bit              output,
                        @psWIPCode              nvarchar(6)',
                        @bIsRenewalWIP          = @bIsRenewalWIP output,
                        @psWIPCode              = @psWIPCode
End

-- Extract Site control 'Currency Default from Agent'
If @nErrorCode = 0
Begin
        Set @sSQLString = "Select @bIsCurrencyDefaultFromAgent = COLBOOLEAN
                        from SITECONTROL
                        where CONTROLID = 'Currency Default from Agent'"
                        
        exec @nErrorCode = sp_executesql @sSQLString,
                        N'@bIsCurrencyDefaultFromAgent        bit       output',
                        @bIsCurrencyDefaultFromAgent          = @bIsCurrencyDefaultFromAgent output
End

-- Extract name, staff and case details:
If @nErrorCode = 0 and @pnCaseKey is not null and @psWIPCode is not null
Begin
	Set @sSQLString = "	
	WITH SelectedAgent(NAMENO) as 
	(Select CASE WHEN @bIsRenewalWIP = 1 THEN ISNULL(RENAGENT.NAMENO, AGENT.NAMENO) ELSE AGENT.NAMENO END as NameNo
	        from CASES C		
	        left join CASENAME AGENT on (AGENT.CASEID = C.CASEID
					and AGENT.NAMETYPE = 'A'
					and (AGENT.EXPIRYDATE is null or AGENT.EXPIRYDATE>getdate()))							
	        left join CASENAME RENAGENT on (RENAGENT.CASEID = C.CASEID
					and RENAGENT.NAMETYPE = '&'
					and (RENAGENT.EXPIRYDATE is null or RENAGENT.EXPIRYDATE>getdate()))
                where C.CASEID = @pnCaseKey)
                
	Select  @nAgentNameKey = N.NAMENO,
		@sAgentNameCode = N.NAMECODE,
		@sAgentName = dbo.fn_FormatNameUsingNameNo(N.NAMENO, null),
		@sCurrencyCode = CU.CURRENCY,
		@sCurrency = CU.DESCRIPTION
	from SelectedAgent AG 
	join NAME N on (N.NAMENO = AG.NAMENO)
	left join CREDITOR CD on (CD.NAMENO = AG.NAMENO)
	left join CURRENCY CU on (CU.CURRENCY = CD.PURCHASECURRENCY and @bIsCurrencyDefaultFromAgent = 1)"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@nAgentNameKey	        int			output,
			  @sAgentNameCode	        nvarchar(10)		output,
			  @sAgentName		        nvarchar(254)		output,
			  @sCurrencyCode                nvarchar(3)             output,
			  @sCurrency                    nvarchar(40)            output,
			  @bIsRenewalWIP	        bit,
			  @bIsCurrencyDefaultFromAgent  bit,
			  @pnCaseKey		        int',
			  @nAgentNameKey	        = @nAgentNameKey	output,
			  @sAgentNameCode	        = @sAgentNameCode	output,
			  @sAgentName		        = @sAgentName		output,
			  @sCurrencyCode                = @sCurrencyCode        output,
			  @sCurrency                    = @sCurrency            output,
			  @bIsRenewalWIP	        = @bIsRenewalWIP,
			  @bIsCurrencyDefaultFromAgent  = @bIsCurrencyDefaultFromAgent,
			  @pnCaseKey		        = @pnCaseKey
End

-- Return the result set:
If  @nErrorCode = 0	
Begin
	Select 
	@nAgentNameKey   	as 'AssociateKey',
	@sAgentName             as 'AssociateName',
	@sAgentNameCode		as 'AssociateCode',	
	@sCurrencyCode	        as 'CurrencyCode',
	@sCurrency      	as 'Currency'
						  
End

Return @nErrorCode
GO

Grant execute on dbo.wp_GetWipDefaultValues to public
GO
