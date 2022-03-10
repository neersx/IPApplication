namespace InprotechKaizen.Model.Components.Cases.Validation
{
    public class ExternalOfficialNumberValidatorResult
    {
        public int ErrorCode { get; set; }

        public int PatternError { get; set; }

        public string ErrorMessage { get; set; }

        public byte WarningFlag { get; set; }
    }
}