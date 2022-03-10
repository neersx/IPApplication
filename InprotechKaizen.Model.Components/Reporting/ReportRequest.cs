using System;
using System.Collections.Generic;
using Inprotech.Infrastructure.Notifications;

namespace InprotechKaizen.Model.Components.Reporting
{
    public class ReportRequest
    {
        public ReportRequest()
        {
            
        }

        public ReportRequest(params ReportDefinition[] reportDefinitions)
        {
            ReportDefinitions = new List<ReportDefinition>(reportDefinitions);
        }

        public ReportRequest(IEnumerable<ReportDefinition> reportDefinitions)
        {
            ReportDefinitions = new List<ReportDefinition>(reportDefinitions);
        }

        public int UserIdentityKey { get; set; }

        public string UserCulture { get; set; }

        public IReadOnlyCollection<ReportDefinition> ReportDefinitions { get; } = new List<ReportDefinition>();

        public int ContentId { get; set; }

        public bool ShouldConcatenate { get; set; }

        public string ConcatenateFileName { get; set; }
        
        public BackgroundProcessType NotificationProcessType { get; set; } = BackgroundProcessType.StandardReportRequest;

        public Guid RequestContextId { get; set; }
    }
}