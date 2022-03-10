-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListTelecomNameAssociated									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListTelecomNameAssociated]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListTelecomNameAssociated.'
	Drop procedure [dbo].[naw_ListTelecomNameAssociated]
End
Print '**** Creating Stored Procedure dbo.naw_ListTelecomNameAssociated...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListTelecomNameAssociated
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnTelecomkey		int			-- Mandatory
)
as
-- PROCEDURE:	naw_ListTelecomNameAssociated
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Provide the list of all names which are associated with the telecom.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 05 Oct 2010	ASH	RFC9510	1	Procedure created
-- 11 Apr 2013	DV	R13270	2	Increase the length of nvarchar to 11 when casting or declaring integer 
-- 02 Nov 2015	vql	R53910	3	Adjust formatted names logic (DR-15543).

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

--Get Telecom
--
If @nErrorCode = 0
Begin
	Set @sSQLString = "Select Distinct T.TELECODE as TelecomKey, TT.DESCRIPTION			as TelecomType	,	
		dbo.fn_FormatTelecom   (T.TELECOMTYPE,
					T.ISD,
					T.AREACODE,
					T.TELECOMNUMBER,
					T.EXTENSION) 	As TelecomNumber
		from [NAME] N
		join NAMETELECOM NT 		on (NT.NAMENO = N.NAMENO)
		join TELECOMMUNICATION T 	on (T.TELECODE = NT.TELECODE)
		join TABLECODES TT on (TT.TABLECODE = T.TELECOMTYPE)
		where  NT.TELECODE= @pnTelecomkey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnTelecomkey	int',
			@pnTelecomkey	 = @pnTelecomkey

End

--Telecom Referenced by Names
If @nErrorCode = 0
Begin
       Set @sSQLString ="SELECT distinct @pnTelecomkey as TelecomKey,
		N.NAMENO AS NameKey,
		N.NAMECODE AS NameCode,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) AS NAME,
		 NT.TELECOMDESC as Description,
		ISNULL(NT.OWNEDBY,0) as IsOwner,
		cast(N.NAMENO as nvarchar(11)) +'^'+ cast(ISNULL(NT.OWNEDBY,0) as nvarchar(10)) as RowKey
		FROM NAME N
		JOIN NAMETELECOM NT ON (NT.NAMENO=N.NAMENO)
		WHERE NT.TELECODE= @pnTelecomkey
		ORDER BY NAME"

        exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnTelecomkey	int',
			@pnTelecomkey	 = @pnTelecomkey
								
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListTelecomNameAssociated to public
GO
