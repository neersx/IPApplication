namespace InprotechKaizen.Model.Components.Queries
{
    public class SavedQueryItem
    {
        public int QueryKey { get; set; }

        public string QueryName { get; set; }

        public string Description { get; set; }

        public bool IsPublic { get; set; }

        public bool IsMaintainable { get; set; }

        public bool IsRunable { get; set; }

        public bool IsReportOnly { get; set; }

        public bool HasPresentation { get; set; }

        public int? GroupKey { get; set; }

        public string GroupName { get; set; }

        public int? ExportFormatKey { get; set; }

        public int? ReportToolKey { get; set; }

        public string ReportToolDescription { get; set; }

        public string ReportTemplate { get; set; }

        public string ReportTitle { get; set; }

        public bool IsDefault { get; set; }

        public bool IsReadOnly { get; set; }
    }
}
