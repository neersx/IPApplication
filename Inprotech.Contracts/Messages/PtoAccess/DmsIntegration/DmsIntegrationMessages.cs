namespace Inprotech.Contracts.Messages.PtoAccess.DmsIntegration
{
    public class DmsIntegrationMessages
    {
        public const string PrepareToSendToDms = "Prepare to send item to DMS";

        public const string SendingToDms = "Transition to 'SendingToDms' state is not allowed, current state: {0}";

        public const string ItemSentToDms = "Item sent to DMS";

        public class Warning
        {
            public const string CaseHasNoCorrelationId = "Case has no correlationId";

            public const string CaseCorrelationIdIsChanged = "CorrelationId of the case is modified.";

            public const string UpdateConcurrencyViolationDetected = "Attempt to update document to status failed: {0}";
        }
    }
}