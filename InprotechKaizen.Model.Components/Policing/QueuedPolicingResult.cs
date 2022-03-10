namespace InprotechKaizen.Model.Components.Policing
{
    public interface IQueuedPolicingResult : IPolicingResult
    {
        int? PolicingBatchNumber { get; }
    }

    public sealed class QueuedPolicingResult : IQueuedPolicingResult
    {
        public QueuedPolicingResult(int? policingBatchNumber)
        {
            PolicingBatchNumber = policingBatchNumber;
        }

        public QueuedPolicingResult(string errorMessage)
        {
            ErrorReason = errorMessage;
            HasError = true;
        }

        public bool HasError { get; private set; }

        public string ErrorReason { get; private set; }

        public int? PolicingBatchNumber { get; private set; }
    }
}