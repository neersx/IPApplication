-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListCaseAttachments
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListCaseAttachments]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListCaseAttachments'
	drop procedure [dbo].[wa_ListCaseAttachments]
	print '**** Creating procedure dbo.wa_ListCaseAttachments...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListCaseAttachments]
	@pnCaseId	int
AS
-- PROCEDURE :	wa_ListCaseAttachments
-- VERSION :	2.2.0
-- DESCRIPTION:	Returns a list of Attachments for a given Case passed as a parameter.
--				No rows are returned if the user is external (client)
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 01/07/2001	MF	Procedure created
-- 21/07/2001	AF  	Dont return rows if an external user

begin
	-- disable row counts
	set nocount on
	
	declare @ErrorCode	int

	-- Check that external users have access to see the details of the case.

	Execute @ErrorCode=wa_CheckSecurityForCase @pnCaseId

	If @ErrorCode=0
	Begin
	
		select	AA.ATTACHMENTNAME,
				AA.FILENAME,
			    A.ACTIVITYDATE,  
				TC.DESCRIPTION as  ACTIVITYTYPENAME,    
				TN.DESCRIPTION as ACTIVITYCATEGORYNAME
		FROM    ACTIVITY A
		JOIN	ACTIVITYATTACHMENT AA	ON (AA.ACTIVITYNO=A.ACTIVITYNO)
		LEFT JOIN TABLECODES TC		ON (TC.TABLECODE=A.ACTIVITYTYPE)
		LEFT JOIN TABLECODES TN		ON (TN.TABLECODE=A.ACTIVITYCATEGORY)
		WHERE A.CASEID = @pnCaseId
		and  exists	(select * from USERS
				 	where USERID = user
				 	and   (EXTERNALUSERFLAG<2 or EXTERNALUSERFLAG is NULL))
		ORDER BY A.ACTIVITYDATE DESC
	
		Set @ErrorCode=@@Error
	End

	return @ErrorCode
end
go 

grant execute on [dbo].[wa_ListCaseAttachments] to public
go
