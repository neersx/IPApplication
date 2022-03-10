-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fnw_FilteredTopicNameTypes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fnw_FilteredTopicNameTypes') and xtype='IF')
Begin
	Print '**** Drop Function dbo.fnw_FilteredTopicNameTypes.'
	Drop function [dbo].[fnw_FilteredTopicNameTypes]
End
Print '**** Creating Function dbo.fnw_FilteredTopicNameTypes...'
Print ''
GO

Set QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fnw_FilteredTopicNameTypes
(
	@pnScreenCriteriaKey int,
	@pbIsEditMode        bit
)
RETURNS TABLE

AS
-- FUNCTION:	fnw_FilteredTopicNameTypes
-- VERSION :	2
-- SCOPE:	CPAStart
-- DESCRIPTION:	A table of distinct Name Type keys that are added as 
--		separate topics with Filter as NameType 
--		in screen control rules matching the supplied parameters.
--
-- MODIFICATIONS :
-- Date		Who	No.		Version	Change
-- ------------	-------	-----------	-------	----------------------------------------------- 
-- 16 SEP 2014	DV	R27884		1	Function created
-- 16 SEP 2014  SW      R27882          2       Check IsEditMode parameter to include Left Join to check Edit button behaviour

-- populate the table with distinct name types 
RETURN	
	SELECT DISTINCT TF.FILTERVALUE AS NAMETYPE
	FROM TOPICCONTROLFILTER TF
	JOIN TOPICCONTROL TC on (TC.TOPICCONTROLNO = TF.TOPICCONTROLNO 
					AND TF.FILTERNAME='NameTypeKey')
	JOIN WINDOWCONTROL WC on (WC.WINDOWCONTROLNO = TC.WINDOWCONTROLNO)
	LEFT JOIN ELEMENTCONTROL EC on (EC.TOPICCONTROLNO = TC.TOPICCONTROLNO 
					AND EC.ELEMENTNAME like  'Names_Component_%_btnGridEdit'
					AND EC.ISHIDDEN = 1)
	WHERE WC.WINDOWNAME = 'CaseDetails'
	AND WC.CRITERIANO = @pnScreenCriteriaKey AND (EC.ELEMENTNAME is null or @pbIsEditMode = 0)
go

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fnw_FilteredTopicNameTypes to public
go