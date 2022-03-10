DECLARE @RC int
DECLARE @pnUserIdentityId int
DECLARE @psCulture nvarchar(10)
DECLARE @pbCalledFromCentura bit
SELECT @pnUserIdentityId = 27
SELECT @psCulture = NULL
EXEC @RC = [dbo].[csw_ProcessInstructions] @pnUserIdentityId, @psCulture, DEFAULT, 
'<Instructions>
  <InstructionDate></InstructionDate>
  <Instruction>
    <CaseKey>-487</CaseKey>
    <InstructionDefinitionKey>1</InstructionDefinitionKey>
    <InstructionCycle>1</InstructionCycle>
    <ResponseNo>1</ResponseNo>
    <Notes>User notes</Notes>
  </Instruction>
</Instructions>',
@pnDebugFlag=2
DECLARE @PrnLine nvarchar(4000)
PRINT 'Stored Procedure: dbo.csw_ProcessInstructions'
SELECT @PrnLine = '	Return Code = ' + CONVERT(nvarchar, @RC)
PRINT @PrnLine