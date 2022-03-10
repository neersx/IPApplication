using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.Notifications;
using InprotechKaizen.Model.Components.Reporting;

namespace Inprotech.Integration.Reports
{
    public static class KnownReportComponents
    {
        public static readonly Dictionary<ReportExportFormat, ContentDetails> Map =
            new()
            {
                {ReportExportFormat.Pdf, new ContentDetails {ContentType = "application/pdf", FileExtension = "pdf"}},
                {ReportExportFormat.Word, new ContentDetails {ContentType = "application/x-msword", FileExtension = "doc"}},
                {ReportExportFormat.Xml, new ContentDetails {ContentType = "text/xml", FileExtension = "xml"}},
                {ReportExportFormat.Excel, new ContentDetails {ContentType = "application/vnd.ms-excel", FileExtension = "xls"}},
                {ReportExportFormat.Mhtml, new ContentDetails {ContentType = "multipart/related", FileExtension = "mhtml"}}
            };

        public static string GetFileNameFromReportDefinition(ReportDefinition reportDefinition)
        {
            if (reportDefinition == null) throw new ArgumentNullException(nameof(reportDefinition));

            if (!string.IsNullOrEmpty(reportDefinition.FileName)) return reportDefinition.FileName;

            var reportName = reportDefinition.ReportPath.IndexOf('/') > -1
                ? reportDefinition.ReportPath.Substring(reportDefinition.ReportPath.LastIndexOf('/') + 1)
                : reportDefinition.ReportPath;

            var fileExtension = Map[reportDefinition.ReportExportFormat].FileExtension;
            return reportName + "." + fileExtension;
        }
    }
    
    public static class ReportDefinitionExtension
    {
        public static string GetOrGenerateFileName(this ReportDefinition reportDefinition, string path = null)
        {
            string SafeCombine(string p, string fileName)
            {
                return string.IsNullOrWhiteSpace(p) ? fileName : Path.Combine(p, fileName);
            }

            reportDefinition.FileName ??= SafeCombine(path, KnownReportComponents.GetFileNameFromReportDefinition(reportDefinition));
            return reportDefinition.FileName;
        }

        public static string GenerateTemporaryFileName(this ReportDefinition reportDefinition, string path)
        {
            return Path.Combine(path, $"{Guid.NewGuid()}.{KnownReportComponents.Map[reportDefinition.ReportExportFormat].FileExtension}");
        }
    }

    public static class ReportRequestExtension
    {
        public static ReportExportFormat ReportExportFormat(this ReportRequest request)
        {
            if (request == null) throw new ArgumentNullException();

            return request.ReportDefinitions.Count switch
            {
                1 => request.ReportDefinitions.Single().ReportExportFormat,
                _ => request.ReportDefinitions.First().ReportExportFormat
            };
        }

        public static string FileName(this ReportRequest request)
        {
            if (request == null) throw new ArgumentNullException();

            return request.ReportDefinitions.Count switch
            {
                1 => request.ReportDefinitions.Single().GetOrGenerateFileName(),
                _ => request.ConcatenateFileName
            };
        }

        public static bool ShouldProtect(this ReportRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            return request.ReportExportFormat() == Infrastructure.Formatting.Exports.ReportExportFormat.Pdf 
                   && !request.ReportDefinitions.Any(_ => _.ShouldMakeContentModifiable);
        }

        public static bool IsStandardReport(this ReportRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            return request.NotificationProcessType == BackgroundProcessType.StandardReportRequest;
        }

        public static string ContentType(this ReportRequest request)
        {
            return KnownReportComponents.Map[request.ReportExportFormat()].ContentType;
        }
    }
}