namespace InprotechKaizen.Model.Components.Policing
{
    public sealed class PolicingResult : IPolicingResult
    {
        public PolicingResult()
        {
        }

        public PolicingResult(string errorMessage)
        {
            ErrorReason = errorMessage;
            HasError = true;
        }

        public bool HasError { get; private set; }

        public string ErrorReason { get; private set; }
    }
}