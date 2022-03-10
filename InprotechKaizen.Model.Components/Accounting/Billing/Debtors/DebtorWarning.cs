using Inprotech.Infrastructure.Notifications.Validation;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Debtors
{
    public class DebtorWarning
    {
        public int NameId { get; set; }
        public string WarningError { get; set; }
        public AlertSeverity Severity { get; set; }
    }
}
