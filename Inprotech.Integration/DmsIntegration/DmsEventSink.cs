using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Integration.DmsIntegration
{
    public interface IDmsEventSink
    {
        IEnumerable<DocumentManagementEvent> GetEvents(Status status, params string[] key);

        IEnumerable<string> GetNameTypes();
    }

    public interface IDmsEventCapture : IDmsEventSink
    {
        void Capture(DocumentManagementEvent e);
    }

    public class DmsEventSink : IDmsEventCapture
    {
        public DmsEventSink()
        {
            Events = Events ?? new List<DocumentManagementEvent>();
        }

        List<DocumentManagementEvent> Events { get; } = new List<DocumentManagementEvent>();

        public void Capture(DocumentManagementEvent e)
        {
            Events.Add(e);
        }

        public IEnumerable<DocumentManagementEvent> GetEvents(Status status, params string[] keys)
        {
            return Events.Where(_ => _.Status == status && keys.Contains(_.Key));
        }

        public IEnumerable<string> GetNameTypes()
        {
            return Events.Where(_ => !string.IsNullOrEmpty(_.NameType)).Select(_ => _.NameType).Distinct();
        }
    }

    public class DocumentManagementEvent
    {
        public DocumentManagementEvent() {}

        public DocumentManagementEvent(Status status, string key, string value)
        {
            Key = key;
            Status = status;
            Value = value;
        }

        public DocumentManagementEvent(Status status, string key, string value, string nameType)
        {
            Key = key;
            Status = status;
            Value = value;
            NameType = nameType;
        }

        public string Key { get; set; }
        public Status Status { get; set; }
        public string Value { get; set; }
        public string NameType { get; set; }
    }

    public enum Status
    {
        Error,
        Info
    }

    public class KnownDocumentManagementEvents
    {
        public const string MissingTaskPermission = "taskPermission";
        public const string IncompleteConfiguration = "incompleteConfiguration";
        public const string FailedLoginOrPasswordPreferences = "failedLoginOrPasswordPreferences";
        public const string MissingLoginPreference = "missingLoginPreference";
        public const string LoginType = "loginType";
        public const string FailedConnection = "failedConnection"; 
        public const string FailedConnectionIfImpersonationAuthenticationFailure = "failedConnectionIfImpersonationAuthenticationFailure";
        public const string NotSupported = "Not Supported";
        public const string OAuth2Required = "oauth2Required";
        public const string ServerNotFound = "serverNotFound";
        public const string CaseWorkspaceCustomField1 = "caseWorkspaceCustomField1";
        public const string CaseWorkspaceCustomField2 = "caseWorkspaceCustomField2";
        public const string CaseWorkspaceCustomField3 = "caseWorkspaceCustomField3";
        public const string NameWorkspaceCustomField1 = "nameWorkspaceCustomField1";
        public const string CaseSubClass = "caseSubClass";
        public const string NameSubClass = "nameSubClass";
        public const string CaseWorkspace = "caseWorkspace";
        public const string NameWorkspace = "nameWorkspace";
        public const string CaseSubType = "caseSubType";
        public const string NameSubType = "nameSubType";
        public const string NoWorkspaceFound = "noWorkspaceFound";
    }
}