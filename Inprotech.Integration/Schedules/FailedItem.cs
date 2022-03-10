using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;

namespace Inprotech.Integration.Schedules
{
    public enum ArtifactType
    {
        Case,
        Document
    }

    public class FailedItem
    {
        public FailedItem()
        {
            ArtifactType = ArtifactType.Case;
        }

        public int? ArtifactId { get; set; }

        public string ApplicationNumber { get; set; }

        public string RegistrationNumber { get; set; }
        
        public string PublicationNumber { get; set; }
        public string DocumentDescription { get; set; }
        public string FileWrapperDocumentCode { get; set; }

        [JsonIgnore]
        public string CorrelationId { get; set; }

        public string CorrelationIds { get; set; }

        public int ScheduleId { get; set; }

        public long? Id { get; set; }

        [JsonIgnore]
        public DataSourceType DataSourceType { get; set; }

        public ArtifactType ArtifactType { get; set; }

        [JsonIgnore]
        public byte[] Artifact { get; set; }

        public DateTime? MailRoomDate { get; set; }

        public DateTime? UpdatedOn { get; set; }
    }

    public class FailedItemsSummary
    {
        public string DataSource { get; set; }

        public IEnumerable<FailedItem> Cases { get; set; }
        public IEnumerable<FailedItem> Documents { get; set; }

        public int FailedCount { get; set; }
        public int FailedDocumentCount { get; set; }

        public IEnumerable<FailedSchedule> Schedules { get; set; }

        public bool RecoverPossible { get; set; }

        public IEnumerable<DownloadListArtefact> IndexList { get; set; }

        public IEnumerable<ScheduleMessage> ScheduleMessages { get; set; }

        public FailedItemsSummary()
        {
            IndexList = Enumerable.Empty<DownloadListArtefact>();

            Schedules = Enumerable.Empty<FailedSchedule>();
        }
    }

    public class DownloadListArtefact
    {
        [JsonIgnore]
        public DateTime Started { get; set; }
        
        public long ExecutionId { get; set; }

        [JsonIgnore]
        public DataSourceType DataSourceType { get; set; }

        [JsonIgnore]
        public byte[] ExecutionArtefact { get; set; }
    }

    public class FailedSchedule
    {
        public int ScheduleId { get; set; }

        public string Name { get; set; }

        public string CorrelationIds { get; set; }

        public int FailedCasesCount { get; set; }
        public int FailedDocumentsCount { get; set; }

        public bool AggregateFailures { get; set; }

        [JsonIgnore]
        public RecoveryScheduleStatus RecoveryStatus { get; set; }

        [JsonIgnore]
        public DataSourceType DataSource { get; set; }
    }
}