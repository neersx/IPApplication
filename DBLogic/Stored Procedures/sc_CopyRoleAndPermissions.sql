-----------------------------------------------------------------------------------------------------------------------------
-- Creation of sc_CopyRoleAndPermissions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sc_CopyRoleAndPermissions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.sc_CopyRoleAndPermissions.'
	Drop procedure [dbo].[sc_CopyRoleAndPermissions]
End
Print '**** Creating Stored Procedure dbo.sc_CopyRoleAndPermissions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[sc_CopyRoleAndPermissions]
(
	@pnUserIdentityId	int		= NULL,
	@psCulture		nvarchar(10)	= NULL,	-- the language in which output is to be expressed
	@psRoleName		nvarchar(254),		-- mandatory Role Name to be copied
	@psIntoServer		nvarchar(50),		-- mandatory name of the database server into which Role and Permissions details will be copied
	@psIntoDatabase		nvarchar(50),		-- mandatory name of the database into which Role and Permissions details will be copied
	@pStatusMessages	bit            = 1,
	@pDebug			bit            = 0
)
AS
-- PROCEDURE :	sc_CopyRoleAndPermissions
-- VERSION :	2
-- DESCRIPTION:	Copies the details of a Web Role and its Permissions (tasks, web parts, subjects) from the current database into another database.
--
-- NOTES :	This procedure does not manage a change in the role name between the "from" and "into" database;
--		This procedure does not copy any translated text;
--		ROLE.DEFAULTPORTALID is no longer in use. Refer to RFC 1581 (https://jira.inprotech.cpaglobal.com/browse/SDR-1209).
--		Orphaned rows in PERMISSIONS can cause problems in this procedure. Refer to RFC 54965 (https://jira.inprotech.cpaglobal.com/browse/DR-16571).
--
--	 ****** WHEN USING DISTRIBUTED SERVERS ******
--		@psIntoServer parameter allows the copy of data to a database on a different server.
--		There is SQLServer configuration required to allow for transactions to span servers.
--		1. Ensure Distributed Transaction Coordinator service is running on both servers.
--		2. Disable all MSDTC security on both servers.
--		3. Turn on random options on the linked server.
--		Following post explained step  http://stackoverflow.com/questions/7473508/unable-to-begin-a-distributed-transaction
--
--	*********************************************************************************************************************
-- CALLED BY :	DataAccess directly
-- COPYRIGHT:	Copyright 1993 - 2015 CPA Software Solutions (UK) Limited
-- MODIFICTIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	------------------------------------------
-- 21-Dec-2015	AvB	56559	 1	Created
-- 23-Mar-2020	BS	DR-57435 2	DB public role missing execute permission on some stored procedures and functions
BEGIN

  SET CONCAT_NULL_YIELDS_NULL ON;
  SET XACT_ABORT ON;	-- This is critical to allow transactions to span different servers

  DECLARE
    @ErrorCode              int,
    @SQLStr                 nvarchar (max),
    @nRetry                 smallint,
    @TranCountStart         int,
    @sStatusMessage         nvarchar (254),
    @RowCount               int,
    @FromROLEID             int,
    @IntoROLEID             int,
    @NewIntoROLEID          int,
    @IntoROLEIDCurrentOrNew int;

  IF @pDebug = 1
  BEGIN
    PRINT N'Input parameters:';
    SELECT	@pnUserIdentityId AS [@pnUserIdentityId],
          	@psCulture        AS [@psCulture],
          	@psRoleName       AS [@psRoleName],
          	@psIntoServer     AS [@psIntoServer],
          	@psIntoDatabase   AS [@psIntoDatabase],
          	@pStatusMessages  AS [@pStatusMessages],
          	@pDebug           AS [@pDebug];
  END;

  SET @ErrorCode = 0;

  ------------------------------------------------------------------------------
  -- Enclose Server and Database name by brackets
  ------------------------------------------------------------------------------
  SET @psIntoServer   = N'[' + REPLACE (REPLACE (@psIntoServer,   N'[', N''), N']', N'') + N']';
  SET @psIntoDatabase = N'[' + REPLACE (REPLACE (@psIntoDatabase, N'[', N''), N']', N'') + N']';

  ------------------------------------------------------------------------------
  -- Get the "from" ROLEID if it exists
  ------------------------------------------------------------------------------
  IF @ErrorCode = 0
  BEGIN

    SET @SQLStr =     N'SELECT @onROLEID = [ROLEID]
			FROM [dbo].[ROLE]
			WHERE [ROLENAME] = @sRoleName;';

    IF @pDebug = 1
      SELECT @SQLStr AS [SQLStr];

    EXECUTE @ErrorCode = sp_executesql @SQLStr,
                                       N'@onROLEID int OUTPUT,
                                         @sRoleName nvarchar (254)',
                                         @onROLEID = @FromROLEID OUTPUT,
                                         @sRoleName = @psRoleName;

    IF @pDebug = 1
      SELECT @ErrorCode AS [ErrorCode];

    IF @pStatusMessages = 1
    BEGIN
      SET @sStatusMessage = N'Role "' + @psRoleName + N'" in the current database found with ROLEID = ' + CONVERT (nvarchar (254), @FromROLEID) + N'.';
      PRINT @sStatusMessage;
    END;

    IF ISNULL (@FromROLEID, 0) = 0
    BEGIN
     	RAISERROR ('No role with the given role name has been found in the current database.', 14, 1); --13:
      SET @ErrorCode = @@ERROR;
    END;

  END; -- if: @ErrorCode = 0

  ------------------------------------------------------------------------------
  -- Get the "into" ROLEID for the ROLENAME if it exists
  ------------------------------------------------------------------------------
  IF @ErrorCode = 0
  BEGIN

    SET @SQLStr =     N'SELECT @onROLEID = [ROLEID]
			FROM ' + @psIntoServer + N'.' + @psIntoDatabase + N'.[dbo].[ROLE]
			WHERE [ROLENAME] = @sRoleName;';

    IF @pDebug = 1
      SELECT @SQLStr AS [SQLStr];

    EXECUTE @ErrorCode = sp_executesql @SQLStr,
                                       N'@onROLEID int OUTPUT,
                                         @sRoleName nvarchar (254)',
                                         @onROLEID = @IntoROLEID OUTPUT,
                                         @sRoleName = @psRoleName;

    IF @pDebug = 1
      SELECT @ErrorCode AS [ErrorCode];

    IF @ErrorCode = 0 AND
       @pStatusMessages = 1
    BEGIN
      IF ISNULL (@IntoROLEID, 0) = 0
        SET @sStatusMessage = N'Role "' + @psRoleName + N'" in the into database could not be found.'
      ELSE
        SET @sStatusMessage = N'Role "' + @psRoleName + N'" in the into database found with ROLEID = ' + CONVERT (nvarchar (254), @IntoROLEID) + N'.';
        PRINT @sStatusMessage;
    END;

  END; -- if: @ErrorCode = 0

  SET @nRetry = 3;
  WHILE @nRetry > 0 AND
        @ErrorCode = 0
  BEGIN

    IF @pDebug = 1
      SELECT @nRetry AS [nRetry];

  --/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

  BEGIN TRY

  --/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

  SET @TranCountStart = @@TRANCOUNT;
  ------------------------------------------------------------------------------
  BEGIN TRANSACTION
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Update "into" role description if it exists
  --  Updates for ISEXTERNAL- and ISPROTECTED-flags are not supported in the UI,
  --  but will be updated here.
  ------------------------------------------------------------------------------

  IF @ErrorCode = 0 AND
     ISNULL (@IntoROLEID, 0) <> 0
  BEGIN

    SET @SQLStr =     N'UPDATE [Target]
			SET
			  [DESCRIPTION]     = [Source].[DESCRIPTION],
			  [ISEXTERNAL]      = [Source].[ISEXTERNAL],
			  [ISPROTECTED]     = [Source].[ISPROTECTED]
			FROM
			  [dbo].[ROLE] [Source]
			  INNER JOIN ' + @psIntoServer + N'.' + @psIntoDatabase + N'.[dbo].[ROLE] [Target]
			    ON ([Source].[ROLEID] = @nFromROLEID AND
				[Target].[ROLEID] = @nIntoROLEID);';

    IF @pDebug = 1
      SELECT @SQLStr AS [SQLStr];

    EXECUTE @ErrorCode = sp_executesql @SQLStr,
                                       N'@nFromROLEID int,
                                         @nIntoROLEID int',
                                         @nFromROLEID = @FromROLEID,
                                         @nIntoROLEID = @IntoROLEID;

    IF @pDebug = 1
      SELECT @ErrorCode AS [ErrorCode];

    IF @ErrorCode = 0 AND
       @pStatusMessages = 1
    BEGIN

      SET @sStatusMessage = N'ROLE details updated.';
      PRINT @sStatusMessage;

    END;

  END; -- if: @ErrorCode = 0

  ------------------------------------------------------------------------------
  -- Create "into" role if it does not exist
  --  A new ROLEID will be used in the "into" database
  --  Thus SCOPE_IDENTITY() is used to retrieve the new ID after the insert
  ------------------------------------------------------------------------------

  IF @ErrorCode = 0 AND
     ISNULL (@IntoROLEID, 0) = 0
  BEGIN

    SET @SQLStr = N'';
    SET @RowCount = NULL;

    SET @SQLStr = @SQLStr + N'INSERT INTO ' + @psIntoServer + N'.' + @psIntoDatabase + N'.[dbo].[ROLE]
				( [ROLENAME],
				  [DESCRIPTION],
				  [ISEXTERNAL],
				  [ISPROTECTED]
				)
				SELECT
				  [Source].[ROLENAME],
				  [Source].[DESCRIPTION],
				  [Source].[ISEXTERNAL],
				  [Source].[ISPROTECTED]
				FROM
				  [dbo].[ROLE] [Source]
				WHERE
				  [Source].[ROLEID] = @nFromROLEID;

				';

      SET @SQLStr = @SQLStr + N'SELECT @nNewIntoROLEID = SCOPE_IDENTITY (),
       @onRowCount = @@ROWCOUNT;';

    IF @pDebug = 1
      SELECT @SQLStr AS [SQLStr];

    EXECUTE @ErrorCode = sp_executesql @SQLStr,
                                       N'@nFromROLEID int,
                                         @nNewIntoROLEID int OUTPUT,
                                         @onRowCount int OUTPUT',
                                         @nFromROLEID = @FromROLEID,
                                         @nNewIntoROLEID = @NewIntoROLEID OUTPUT,
                                         @onRowCount = @RowCount OUTPUT;

    IF @pDebug = 1
      SELECT @ErrorCode AS [ErrorCode], @RowCount AS [RowCount];

    IF @ErrorCode = 0 AND
       ISNULL (@RowCount, 0) > 0 AND
       @pStatusMessages = 1
    BEGIN

      SET @sStatusMessage = N'New row inserted into ROLE with ROLEID = ' + CONVERT (nvarchar (254), @NewIntoROLEID) + N'.';
      PRINT @sStatusMessage;

    END;

  END; -- if: @ErrorCode = 0

  ------------------------------------------------------------------------------
  -- Delete "into" permissions if role exists
  ------------------------------------------------------------------------------

  IF @ErrorCode = 0 AND
     ISNULL (@IntoROLEID, 0) <> 0
  BEGIN

    -- All OBJECTTABLEs affected: DATATOPIC, MODULE, TASK
    SET @SQLStr = N'DELETE [PERMISSIONS]
			FROM
			  ' + @psIntoServer + N'.' + @psIntoDatabase + N'.[dbo].[PERMISSIONS] [PERMISSIONS]
			  INNER JOIN ' + @psIntoServer + N'.' + @psIntoDatabase + N'.[dbo].[ROLE] [ROLE]
			    ON ([PERMISSIONS].[LEVELKEY] = [ROLE].[ROLEID] AND
				[PERMISSIONS].[LEVELTABLE] = N''ROLE'' AND
				[ROLE].[ROLEID] = @nIntoROLEID);

			SET @onRowCount = @@ROWCOUNT;
			';

    IF @pDebug = 1
      SELECT @SQLStr AS [SQLStr];

    SET @RowCount = NULL;
    EXECUTE @ErrorCode = sp_executesql @SQLStr,
                                       N'@nIntoROLEID int,
                                         @onRowCount int OUTPUT',
                                         @nIntoROLEID = @IntoROLEID,
                                         @onRowCount = @RowCount OUTPUT;

    IF @pDebug = 1
      SELECT @ErrorCode AS [ErrorCode];

    IF @ErrorCode = 0 AND
       @pStatusMessages = 1
    BEGIN

      SET @sStatusMessage = CONVERT (nvarchar (254), @RowCount) + N' PERMISSIONS rows deleted for role "' + @psRoleName + N'" in the into database.';
      PRINT @sStatusMessage;

    END;

  END; -- if: @ErrorCode = 0

  ------------------------------------------------------------------------------
  -- Copy all permissions
  ------------------------------------------------------------------------------

  IF @ErrorCode = 0
  BEGIN

    -- All OBJECTTABLEs affected: DATATOPIC, MODULE, TASK
    SET @SQLStr = N'INSERT INTO ' + @psIntoServer + N'.' + @psIntoDatabase + N'.[dbo].[PERMISSIONS]
		( [OBJECTTABLE],
		  [OBJECTINTEGERKEY],
		  [OBJECTSTRINGKEY],
		  [LEVELTABLE],
		  [LEVELKEY],
		  [GRANTPERMISSION],
		  [DENYPERMISSION]
		)
		SELECT
		  [OBJECTTABLE],
		  [OBJECTINTEGERKEY],
		  [OBJECTSTRINGKEY],
		  [LEVELTABLE],
		  @nIntoROLEIDCurrentOrNew AS [LEVELKEY],
		  [GRANTPERMISSION],
		  [DENYPERMISSION]
		FROM
		  [dbo].[PERMISSIONS]
		  INNER JOIN [dbo].[ROLE]
		    ON ([dbo].[PERMISSIONS].[LEVELKEY] = [dbo].[ROLE].[ROLEID] AND
			[dbo].[PERMISSIONS].[LEVELTABLE] = N''ROLE'' AND
			[dbo].[ROLE].[ROLEID] = @nFromROLEID);

		SET @onRowCount = @@ROWCOUNT;
		';

    SET @IntoROLEIDCurrentOrNew = ISNULL (@IntoROLEID, @NewIntoROLEID);

    IF @pDebug = 1
    BEGIN
      SELECT @SQLStr AS [SQLStr];
      SELECT @FromROLEID AS [@FromROLEID], @IntoROLEIDCurrentOrNew AS [@IntoROLEIDCurrentOrNew];
    END;

    SET @RowCount = NULL;
    EXECUTE @ErrorCode = sp_executesql @SQLStr,
                                       N'@nFromROLEID int,
                                         @nIntoROLEIDCurrentOrNew int,
                                         @onRowCount int OUTPUT',
                                         @nFromROLEID = @FromROLEID,
                                         @nIntoROLEIDCurrentOrNew = @IntoROLEIDCurrentOrNew,
                                         @onRowCount = @RowCount OUTPUT;

    IF @pDebug = 1
      SELECT @ErrorCode AS [ErrorCode];

    IF @ErrorCode = 0 AND
       @pStatusMessages = 1
    BEGIN

      SET @sStatusMessage = CONVERT (nvarchar (254), @RowCount) + N' PERMISSIONS rows inserted for role "' + @psRoleName + N'" in the into database.';
      PRINT @sStatusMessage;

    END;

  END; -- if: @ErrorCode = 0

		IF @@TRANCOUNT > @TranCountStart
		BEGIN
			 IF @ErrorCode = 0
				COMMIT TRANSACTION
			 ELSE
  				ROLLBACK TRANSACTION;
		END;

  -- Terminate the WHILE
  SET @nRetry = -1;

  --/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

  END TRY

  --/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

	 ------------------------------------------------------------------------------
	 -- D E A D L O C K   V I C T I M   P R O C E S S I N G
	 ------------------------------------------------------------------------------

  --/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

  BEGIN CATCH

  --/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

	 ------------------------------------------------------------------------------
		-- If the process has been made the victim
		-- of a deadlock (error 1205), then allow 
		-- another attempt to apply the updates 
		-- to the database up to a retry limit.
	 ------------------------------------------------------------------------------

		SET @ErrorCode = ERROR_NUMBER ();

		IF @ErrorCode = 1205
		 	SET @nRetry = @nRetry - 1
		ELSE
  BEGIN
			 SET @nRetry = -1;
    PRINT N'An error has occurred.';
    IF @pDebug = 1
      SELECT @ErrorCode AS [ErrorCode];
  END;

		IF XACT_STATE () <> 0 -- 0 = There is no active user transaction for the current request
			 ROLLBACK TRANSACTION;

  --/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

  END CATCH

  --/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

  END; -- while: @nRetry > 0 AND @ErrorCode = 0

  RETURN @ErrorCode;

END; -- procedure sc_CopyRoleAndPermissions
GO

Grant execute on dbo.sc_CopyRoleAndPermissions to public
GO

