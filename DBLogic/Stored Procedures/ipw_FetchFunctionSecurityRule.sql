-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_FetchFunctionSecurityRule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_FetchFunctionSecurityRule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_FetchFunctionSecurityRule.'
	Drop procedure [dbo].[ipw_FetchFunctionSecurityRule]
End
Print '**** Creating Stored Procedure dbo.ipw_FetchFunctionSecurityRule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_FetchFunctionSecurityRule
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnFunctionType		smallint,		-- Mandatory
	@pnSequenceNo		smallint,		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_FetchFunctionSecurityRule
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Gets the function security rule depending upon Function type and Sequence No.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Dec 2009	NG	RFC8631	1	Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString =
		"Select"+char(10)+
			"CAST(FS.SEQUENCENO as nvarchar(10))+'^'+ CAST(FS.FUNCTIONTYPE as varchar(10)) as RowKey,"+char(10)+
			"FS.SEQUENCENO as SeqNo,"+char(10)+
			"FS.FUNCTIONTYPE as FunctionType,"+char(10)+
			"BF.DESCRIPTION as FunctionTypeDescription,"+char(10)+
			"FS.ACCESSGROUP as AccessGroupKey,"+char(10)+
			"dbo.fn_FormatNameUsingNameNo(NG.NAMENO,null) as AccessGroup,"+char(10)+
			"cast((isnull(FS.ACCESSPRIVILEGES, 0) & 1) as bit) as CanRead,"+char(10)+
			"cast((isnull(FS.ACCESSPRIVILEGES, 0) & 2) as bit) as CanInsert,"+char(10)+
			"cast((isnull(FS.ACCESSPRIVILEGES, 0) & 4) as bit) as CanUpdate,"+char(10)+
			"cast((isnull(FS.ACCESSPRIVILEGES, 0) & 8) as bit) as CanDelete,"+char(10)+
			"cast((isnull(FS.ACCESSPRIVILEGES, 0) & 16) as bit) as CanPost,"+char(10)+
			"cast((isnull(FS.ACCESSPRIVILEGES, 0) & 32) as bit)	as CanFinalise,"+char(10)+
			"cast((isnull(FS.ACCESSPRIVILEGES, 0) & 64) as bit) as CanReverse,"+char(10)+
			"cast((isnull(FS.ACCESSPRIVILEGES, 0) & 128) as bit) as CanCredit,"+char(10)+
			"cast((isnull(FS.ACCESSPRIVILEGES, 0) & 256) as bit) as CanAdjustValue,"+char(10)+
			"cast((isnull(FS.ACCESSPRIVILEGES, 0) & 512) as bit) as CanConvert,"+char(10)+
			"FS.ACCESSSTAFFNO as AccessStaffKey,"+char(10)+
			"dbo.fn_FormatNameUsingNameNo(NS.NAMENO,null) as AccessStaff,"+char(10)+
			"FS.OWNERNO as OwnerNo,"+char(10)+
			"dbo.fn_FormatNameUsingNameNo(NO.NAMENO,null) as OwnerName,"+char(10)+
			"case when (FS.ACCESSSTAFFNO is not null) then 0"+char(10)+
			"	 when (FS.ACCESSGROUP is not null) then 1"+char(10)+
			"	 when (FS.ACCESSSTAFFNO is null and FS.ACCESSGROUP is null) then 2 end as Staff"+char(10)+
		"from FUNCTIONSECURITY FS"+char(10)+
		"left join BUSINESSFUNCTION BF on (BF.FUNCTIONTYPE = FS.FUNCTIONTYPE)"+char(10)+
		"left join NAME NG on (NG.NAMENO = FS.ACCESSGROUP)"+char(10)+
		"left join NAME NS on (NS.NAMENO = FS.ACCESSSTAFFNO)"+char(10)+
		"left join NAME NO on (NO.NAMENO = FS.OWNERNO)"+char(10)+
		"where FS.FUNCTIONTYPE = @pnFunctionType and FS.SEQUENCENO = @pnSequenceNo"

		exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnFunctionType		smallint,
			@pnSequenceNo			smallint',
			@pnFunctionType		= @pnFunctionType,
			@pnSequenceNo  = @pnSequenceNo
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_FetchFunctionSecurityRule to public
GO
