namespace Inprotech.Web.Configuration.Core
{
    public class SaveStatusModel
    {
        public short Id { get; set; }
        public string Name { get; set; }
        public string ExternalName { get; set; }
        public StatusSummary StatusSummary { get; set; }
        public StatusType StatusType { get; set; }
        public bool IsDead { get; set; }
        public bool IsLive { get; set; }
        public bool IsPending { get; set; }
        public bool IsRegistered { get; set; }
        public bool IsRenewal { get; set; }
        public bool PoliceRenewals { get; set; }
        public bool PoliceExam { get; set; }
        public bool PoliceOtherActions { get; set; }
        public bool LettersAllowed { get; set; }
        public bool ChargesAllowed { get; set; }
        public bool RemindersAllowed { get; set; }
        public bool ConfirmationRequired { get; set; }
        public StopPayReason StopPayReason { get; set; }
        public string StopPayReasonDesc { get; set; }
        public bool? PreventWip { get; set; }
        public bool? PreventBilling { get; set; }
        public bool? PreventPrepayment { get; set; }
        public string State { get; set; }
        public bool? PriorArtFlag { get; set; }
        public int NoOfCases { get; set; }
    }

    public enum StatusSummary
    {
        Pending,
        Registered,
        Dead,
        None
    }

    public enum StatusType
    {
        Case,
        Renewal
    }
}


