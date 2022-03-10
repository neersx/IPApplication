
-----------------------------------------------------------------------------------------------------------------------------
-- Obsoletion of apps_FilterDataExtractCases
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[apps_FilterDataExtractCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.apps_FilterDataExtractCases.'
	Drop procedure [dbo].[apps_FilterDataExtractCases]
End
Print '**** Creating Stored Procedure dbo.apps_FilterDataExtractCases...'
Print ''
GO
