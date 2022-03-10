namespace InprotechKaizen.Model.Components.Cases.Rules.Visualisation
{
    public class ReminderDetails
    {
        public short? LeadTime { get; set; }
        public string PeriodType { get; set; }
        public short? Frequency { get; set; }
        public string FreqPeriodType { get; set; }
        public short? StopTime { get; set; }
        public string StopTimePeriodType { get; set; }
        public string EmployeeNameType { get; set; }
        public string SignatoryNameType { get; set; }
        public string InstructorNameType { get; set; }
        public bool? CriticalFlag { get; set; }
        public string ReminderName { get; set; }
        public string NameType { get; set; }
        public string Relationship { get; set; }
        public bool? SendElectronically { get; set; }
        public string EmailSubject { get; set; }
        public bool? UseBeforeDueDate { get; set; }
        public string Message1 { get; set; }
        public string Message2 { get; set; }
    }
}
