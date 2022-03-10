using System.Collections.Generic;
using Inprotech.Infrastructure.Formatting.Exports;

namespace InprotechKaizen.Model.Components.Reporting
{

    public class ReportDefinition
    {
        public string ReportPath { get; set; }

        public ReportExportFormat ReportExportFormat { get; set; }

        public Dictionary<string, string> Parameters { get; set; } = new Dictionary<string, string>();

        public bool ShouldMakeContentModifiable { get; set; }

        public bool ShouldExcludeFromConcatenation { get; set; }

        public string FileName { get; set; }
    }
}