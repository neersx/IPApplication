-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListSearchColumns
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListSearchColumns]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListSearchColumns.'
	Drop procedure [dbo].[ipw_ListSearchColumns]
End
Print '**** Creating Stored Procedure dbo.ipw_ListSearchColumns...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListSearchColumns
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListSearchColumns
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the list of functions.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Oct 2010	DV		RFC9437		1	Procedure created
-- 18 Feb 2013	vql		RFC11971	2	Not all columns available in Display/Sort columns are maintainable in Maintain Columns

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture				nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = 
		"WITH QUERYIMPLIEDCOLUMN (PROCEDUREITEMID,CONTEXTID) 
			AS
			(
				SELECT QII.PROCEDUREITEMID as [PROCEDUREITEMID], QID.CONTEXTID as [CONTEXTID]
				FROM QUERYIMPLIEDITEM QII
				join QUERYIMPLIEDDATA QID on (QII.IMPLIEDDATAID = QID.IMPLIEDDATAID)
				WHERE QID.DATAITEMID is null and USAGE is not null
			)
			SELECT QD.DATAITEMID as 'Key', 
			QD.PROCEDUREITEMID as Description, 
			QC.CONTEXTID as QueryContext,
			CASE WHEN QD.QUALIFIERTYPE is null THEN 0 ELSE 1 END as IsQualifierAvailable,
			CASE WHEN QD.PROCEDUREITEMID like 'UserColumn%' THEN 1 ELSE 0 END as IsUserDefined,"+char(10)+
			dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+char(10)+" as DataFormat,
			CASE WHEN QIC.PROCEDUREITEMID is null THEN 0 ELSE 1 END as IsUsedBySystem
			FROM QUERYDATAITEM QD 
			join QUERYCONTEXT QC on (QD.PROCEDURENAME = QC.PROCEDURENAME)	  
			join TABLECODES TC on (QD.DATAFORMATID = TC.TABLECODE)  	 
			left join [QUERYIMPLIEDCOLUMN] QIC on (QIC.CONTEXTID = QC.CONTEXTID and QD.PROCEDUREITEMID = QIC.PROCEDUREITEMID)
			UNION
			SELECT QD.DATAITEMID as 'Key', 
			QD.PROCEDUREITEMID as Description, 
			QCC.CONTEXTID as QueryContext,
			CASE WHEN QD.QUALIFIERTYPE is null THEN 0 ELSE 1 END as IsQualifierAvailable,
			CASE WHEN QD.PROCEDUREITEMID like 'UserColumn%' THEN 1 ELSE 0 END as IsUserDefined,"+char(10)+
			dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+char(10)+" as DataFormat,
			CASE WHEN QIC.PROCEDUREITEMID is null THEN 0 ELSE 1 END as IsUsedBySystem
			FROM QUERYCONTEXTCOLUMN QCC
			join QUERYCOLUMN QC on (QC.COLUMNID = QCC.COLUMNID)
			join QUERYDATAITEM QD on (QD.DATAITEMID = QC.DATAITEMID)
			join TABLECODES TC on (QD.DATAFORMATID = TC.TABLECODE)  	 
			left join [QUERYIMPLIEDCOLUMN] QIC on (QIC.CONTEXTID = QCC.CONTEXTID and QD.PROCEDUREITEMID = QIC.PROCEDUREITEMID)	
			ORDER BY 2"

	exec @nErrorCode = sp_executesql @sSQLString  
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListSearchColumns to public
GO
