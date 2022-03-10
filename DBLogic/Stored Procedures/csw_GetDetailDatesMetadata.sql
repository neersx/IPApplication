-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetDetailDatesMetadata
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetDetailDatesMetadata]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetDetailDatesMetadata.'
	Drop procedure [dbo].[csw_GetDetailDatesMetadata]
End
Print '**** Creating Stored Procedure dbo.csw_GetDetailDatesMetadata...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetDetailDatesMetadata
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCriteriaKey			int,		-- Mandatory
	@pnEntryNumber			int		-- Mandatory
)
as
-- PROCEDURE:	csw_GetDetailDatesMetadata
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Get applicable metadata for the current criteria entry session.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 MAR 2012	SF	R11318	1	Procedure created (Moved logic from ipw_ListWorkflowData


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @sSQLFromWhere nvarchar(4000)
declare @sLookupCulture	nvarchar(10)
declare @nMaxCycle int
declare @bIsActionCyclic bit

-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
If @nErrorCode = 0
Begin
	/* Populate the primary keys for this entry session */

	Set @sSQLString = "
		Select		DC.ENTRYNUMBER					as EntryNumber, 
				"+dbo.fn_SqlTranslatedColumn('DETAILCONTROL','ENTRYDESC',null,'DC',@sLookupCulture,@pbCalledFromCentura)			
								+"		as EntryDescription, 
				@pnCriteriaKey					as CriteriaKey,
				cast(case when ATLEAST1FLAG = 1 then 1 else 0 end as bit) 
										as IsRequireAtleast1Entry,
				"+dbo.fn_SqlTranslatedColumn('DETAILCONTROL','USERINSTRUCTION',null,'DC',@sLookupCulture,@pbCalledFromCentura)			
								+"		as UserInstructions, 
				cast(DC.STATUSCODE as int)			as CaseStatusKey,
				cast(DC.RENEWALSTATUS as int)			as RenewalStatusKey,
				Cast(isnull(S.CONFIRMATIONREQ,0) as bit)
										as IsStatusConfirmationRequired,
				DC.FILELOCATION					as FileLocationKey,
				"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'FLD',@sLookupCulture,@pbCalledFromCentura)			
								+"		as FileLocationDescription,
				DC.NUMBERTYPE					as NumberTypeKey,
				"+dbo.fn_SqlTranslatedColumn('NUMBERTYPES','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)			
								+"		as NumberTypeDescription,
				cast(case when DC.POLICINGIMMEDIATE=1 then 1 else 0 end as bit) as IsPoliceImmediately
		from	DETAILCONTROL DC  
		left join NUMBERTYPES NT on (NT.NUMBERTYPE = DC.NUMBERTYPE)	
		left join TABLECODES FLD on (FLD.TABLECODE = DC.FILELOCATION)		
		left join STATUS S on (S.STATUSCODE = DC.STATUSCODE)
		where 	DC.CRITERIANO = @pnCriteriaKey  
		and	DC.ENTRYNUMBER = @pnEntryNumber"	

	exec @nErrorCode = sp_executesql @sSQLString,
				      N'@pnCriteriaKey			int,
					@pnEntryNumber			int',
					@pnCriteriaKey		= @pnCriteriaKey,
					@pnEntryNumber		= @pnEntryNumber
End


Return @nErrorCode
GO

Grant execute on dbo.csw_GetDetailDatesMetadata to public
GO
