using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Settings;

namespace Inprotech.Integration.DmsIntegration
{
    public interface ICalculateDownloadStatus
    {
        DocumentDownloadStatus GetDownloadStatus(DataSourceType type);

        bool CanChangeDmsStatus(DocumentDownloadStatus currentStatus, DocumentDownloadStatus targetStatus);
    }

    public class DownloadStatusCalculator : ICalculateDownloadStatus
    {
        readonly IDmsIntegrationSettings _settings;

        public DownloadStatusCalculator(IDmsIntegrationSettings settings)
        {
            if (settings == null) throw new ArgumentNullException("settings");
            _settings = settings;
        }

        public DocumentDownloadStatus GetDownloadStatus(DataSourceType type)
        {
            return _settings.IsEnabledFor(type)
                ? DocumentDownloadStatus.ScheduledForSendingToDms
                : DocumentDownloadStatus.Downloaded;
        }

        public bool CanChangeDmsStatus(DocumentDownloadStatus currentStatus, DocumentDownloadStatus targetStatus)
        {
            return AllowableDmsStateTrasition(targetStatus).Contains(currentStatus);
        }

        static IEnumerable<DocumentDownloadStatus> AllowableDmsStateTrasition(DocumentDownloadStatus status)
        {
            switch (status)
            {
                case DocumentDownloadStatus.SendToDms:
                    yield return DocumentDownloadStatus.Downloaded;
                    yield return DocumentDownloadStatus.ScheduledForSendingToDms;
                    yield return DocumentDownloadStatus.FailedToSendToDms;
                    yield break;

                case DocumentDownloadStatus.ScheduledForSendingToDms:
                    yield return DocumentDownloadStatus.Downloaded;
                    yield return DocumentDownloadStatus.SendToDms;
                    yield return DocumentDownloadStatus.FailedToSendToDms;
                    yield break;
                    
                case DocumentDownloadStatus.SendingToDms:
                    yield return DocumentDownloadStatus.ScheduledForSendingToDms;
                    yield break;
                    
                default:
                    /* no restrictions - return all possible statuses */
                    foreach (var downloadStatus in Enum.GetValues(typeof(DocumentDownloadStatus)))
                        yield return (DocumentDownloadStatus)downloadStatus;
                    break;
            }
        }
    }
}