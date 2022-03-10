using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Notifications
{
    public interface IBackgroundProcessMessageClient
    {
        Task SendAsync(BackgroundProcessMessage message);

        IEnumerable<BackgroundProcessMessage> Get(IEnumerable<int> identityIds, bool onlyProcessIds = false);

        bool DeleteBackgroundProcessMessages(int[] processIds);

    }
    
    /// <summary>
    /// Process Type must be handled in the Legacy Portal
    /// Handling is constraint by Inprotech Release Versions
    /// </summary>
    public enum BackgroundProcessType
    {
        NotSet,
        GlobalNameChange,
        GlobalCaseChange,
        UserAdministration,
        DebtorStatementRequest,
        StandardReportRequest,
        CpaXmlExport,
        CpaXmlForImport,
        SanityCheck,
        BillPrint,
        General
    }

    public enum StatusType
    {
        NotSet,
        Started,
        Completed,
        Error,
        Information,
        Hidden
    }

    public enum BackgroundProcessSubType
    {
        NotSet,
        Policing,
        GraphIntegrationCheckStatus,
        GraphStatus,
        ApplyRecordals,
        TimePosting,
        TimerStopped
    }

    public class BackgroundProcessMessage
    {
        public BackgroundProcessType? ProcessType { get; set; }

        public StatusType StatusType { get; set; }

        public string Message { get; set; }

        public int IdentityId { get; set; }

        public DateTime? StatusDate { get; set; }

        public int ProcessId { get; set; }

        public string StatusInfo { get; set; }

        public string FileName { get; set; }

        public BackgroundProcessSubType? ProcessSubType { get; set; }
    }
}
