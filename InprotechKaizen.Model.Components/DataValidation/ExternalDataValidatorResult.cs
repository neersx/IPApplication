namespace InprotechKaizen.Model.Components.DataValidation
{
    public enum FunctionalAreaType
    {
        Case,
        Name
    }

    public class ExternalDataValidatorResult
    {
        public FunctionalAreaType FunctionalArea { get; set; }
        public int? CaseKey { get; set; }
        public int? NameKey { get; set; }
        public int ValidationKey { get; set; }
        public bool IsWarning { get; set; }
        public bool CanOverride { get; set; }
        public int? ProgramContext { get; set; }
        public string DisplayMessage { get; set; }
    }
}