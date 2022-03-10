-----------------------------------------------------------------------------------------------------------------------------
-- Creation of bi_GetBillingLanguage
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[bi_GetBillingLanguage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.bi_GetBillingLanguage.'
	Drop procedure [dbo].[bi_GetBillingLanguage]
End
Print '**** Creating Stored Procedure dbo.bi_GetBillingLanguage...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.bi_GetBillingLanguage
(
	@pnLanguageKey		int		= null output,	-- The language in which a bill is to be prepared.
	@pnUserIdentityId	int,		-- Mandatory
	@pnDebtorKey		int		= null,		-- Either DebtorKey or CaseKey must be provided. The DebtorKey will be derived from the CaseKey if it is not supplied.	
	@pnCaseKey		int		= null,		-- The key of the main case being billed. 	
	@psActionKey		nvarchar(2)	= null,		-- The action under which the billing is being performed.
	@pbDeriveAction		bit		= null		-- Indicates that the ActionKey should be derived form the CaseKey. This is necessary to differentiate from the situation where the bill has no action.
)
as
-- PROCEDURE:	bi_GetBillingLanguage
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the language in which the debit note for a case/name will be prepared.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Jun 2005	TM	RFC2575	1	Procedure created
-- 15 Jun 2005	TM	RFC2575	2	Correct the extraction of the @psActionKey.
-- 29 Jun 2005	TM	RFC2766	3	Choose action in a similar manner to client/server.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

-- Deriving DebtorKey. If the DebtorKey has not been provided, 
-- the main debtor for the CaseKey is used. This is the CaseName 
-- for the Name Type = 'D' with the minimum sequence number.
If @nErrorCode = 0
and @pnDebtorKey is null
Begin
	Set @sSQLString = 
	"Select @pnDebtorKey = CN.NAMENO
	 from CASENAME CN
	 where CN.CASEID = @pnCaseKey
	 and   CN.NAMETYPE = 'D'
	 and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
	 and   CN.SEQUENCE = (select min(SEQUENCE) from CASENAME CN
                              where CN.CASEID = @pnCaseKey
                              and CN.NAMETYPE = 'D'
                              and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"				

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnDebtorKey	int		OUTPUT,
					  @pnCaseKey	int',
					  @pnDebtorKey	= @pnDebtorKey	OUTPUT,
					  @pnCaseKey	= @pnCaseKey 
End

-- Deriving ActionKey. If requested, the ActionKey is extracted from the CaseKey.  
-- This is the open action for the CaseKey with the most recent DateUpdated.
If @nErrorCode = 0
and @psActionKey is null
and @pbDeriveAction = 1
Begin
	Set @sSQLString = 
	"Select TOP 1 @psActionKey = ACTION 
	from OPENACTION
	where CASEID=@pnCaseKey
	order by POLICEEVENTS DESC, DATEUPDATED DESC"			

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psActionKey	nvarchar(2)	OUTPUT,
					  @pnCaseKey	int',
					  @psActionKey	= @psActionKey	OUTPUT,
					  @pnCaseKey	= @pnCaseKey 
End

-- Determine the appropriate language using the best fit algorithm:
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select 
	@pnLanguageKey   =
	convert(int,
	substring(
	max (
	CASE WHEN (NL.NAMENO IS NULL)		THEN '0' ELSE '1' END +
	CASE WHEN (NL.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +  
	CASE WHEN (NL.ACTION IS NULL)		THEN '0' ELSE '1' END +    			
	convert(varchar,NL.LANGUAGE)), 4,10))
	FROM NAMELANGUAGE NL 
	left join CASES C   on (C.CASEID = @pnCaseKey)		
	WHERE	
	    (	NL.NAMENO 	= @pnDebtorKey 		OR NL.NAMENO 		IS NULL )
	AND (	NL.PROPERTYTYPE	= C.PROPERTYTYPE	OR NL.PROPERTYTYPE	IS NULL )
	AND (	NL.ACTION 	= @psActionKey 		OR NL.ACTION 		IS NULL )"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnLanguageKey	int		 OUTPUT,
					  @pnCaseKey		int,
					  @pnDebtorKey		int,
					  @psActionKey		nvarchar(2)',
					  @pnLanguageKey	= @pnLanguageKey OUTPUT,
					  @pnCaseKey		= @pnCaseKey,
					  @pnDebtorKey		= @pnDebtorKey,
					  @psActionKey		= @psActionKey					   
End

Return @nErrorCode
GO

Grant execute on dbo.bi_GetBillingLanguage to public
GO
