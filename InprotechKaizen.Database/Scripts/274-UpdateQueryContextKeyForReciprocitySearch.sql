/**********************************************************************************************************/
    /*** Configuration item for 'Reciprocity Search'                                                   ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 171 AND URL = '/apps/#/search/columns?queryContextKey=19')
        BEGIN
            UPDATE CONFIGURATIONITEM
                SET URL = '/apps/#/search/columns?queryContextKey=18'
                WHERE TASKID = 171
             PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 171.'
             PRINT ''
         END
    GO