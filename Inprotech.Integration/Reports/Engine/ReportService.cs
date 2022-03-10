using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.ContentManagement;
using Inprotech.Infrastructure.Storage;
using InprotechKaizen.Model.Components.Reporting;

namespace Inprotech.Integration.Reports.Engine
{
    public class ReportService : IReportService
    {
        readonly IBackgroundProcessLogger<ReportService> _log;
        readonly IReportClient _reportClient;
        readonly IChunkedStreamWriter _chunkedStreamWriter;
        readonly IFileSystem _fileSystem;
        readonly IPdfUtility _pdfUtility;
        readonly IReportContentManager _reportContentManager;
        
        public ReportService(IBackgroundProcessLogger<ReportService> log,
                             IReportClient reportClient,
                             IReportContentManager reportContentManager, 
                             IChunkedStreamWriter chunkedStreamWriter,
                             IFileSystem fileSystem,
                             IPdfUtility pdfUtility)
        {
            _log = log;
            _reportClient = reportClient;
            _reportContentManager = reportContentManager;
            _chunkedStreamWriter = chunkedStreamWriter;
            _fileSystem = fileSystem;
            _pdfUtility = pdfUtility;
        }

        public async Task<bool> Render(ReportRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            try
            {
                _log.SetContext(request.RequestContextId);

                var noOfReportDefinitions = request.ReportDefinitions.Count;

                var reports = new List<string>();
                
                var path = _fileSystem.AbsoluteUniquePath("reports", $"{request.ContentId}");

                for (var i=0; i<noOfReportDefinitions; i++)
                {
                    var reportDefinition = request.ReportDefinitions.ElementAt(i);
                    
                    if (string.IsNullOrWhiteSpace(reportDefinition.FileName))
                    {
                        if (request.IsStandardReport())
                        {
                            reportDefinition.FileName = reportDefinition.GetOrGenerateFileName(path);
                        }
                        else
                        {
                            if (!request.ShouldConcatenate)
                            {
                                _log.Trace($"Skip #{i+1}, indicated to exclude from concatenation with no filename [ContentID={request.ContentId}]");
                                continue;
                            }

                            reportDefinition.FileName = reportDefinition.GenerateTemporaryFileName(path);    
                        }
                        
                        _log.Trace($"Filename created for #{i+1}, {reportDefinition.FileName} [ContentID={request.ContentId}]");
                    }

                    if (!await RenderReport(request, i, reports))
                    {
                        return false;
                    }
                }

                if (!reports.Any())
                {
                    _log.Warning($"No reports suitable to be persisted in Content Manager [ContentID={request.ContentId}]");
                    return true;
                }

                if (request.ShouldConcatenate)
                {
                    if (string.IsNullOrWhiteSpace(request.ConcatenateFileName))
                    {
                        request.ConcatenateFileName = Path.Combine(path, $"{Guid.NewGuid()}.pdf");
                        _log.Trace($"ConcatenateFileName set as {request.ConcatenateFileName}, [ContentID={request.ContentId}]");
                    }

                    if (!await ConcatenateReports(reports.ToArray(), request.ConcatenateFileName))
                    {
                        return false;
                    }

                    if (request.ShouldProtect())
                    {
                        ProtectPdf(request.ConcatenateFileName);

                        _log.Trace($"Secured {request.ConcatenateFileName} [ContentID={request.ContentId}]");
                    }
                }
                
                await _reportContentManager.Save(request.ContentId, request.FileName(), request.ContentType());
                
                await _reportContentManager.TryPutInBackground(request.UserIdentityKey, request.ContentId, request.NotificationProcessType);

                _log.Trace($"Render of {request.FileName()} Completed! [ContentID={request.ContentId}]");

                return true;
            }
            catch (Exception ex)
            {
                _log.Exception(ex, $"Error has occurred while processing [ContentID={request.ContentId}, Report={request.FileName()}]");

                _reportContentManager.LogException(ex, request.ContentId, 
                                                   $"Error has occurred while processing {request.FileName()}.{Environment.NewLine}ref: {request.RequestContextId}", 
                                                   request.NotificationProcessType);

                return false;
            }
        }

        async Task<bool> RenderReport(ReportRequest request, int i, ICollection<string> reports)
        {
            var reportDefinition = request.ReportDefinitions.ElementAt(i);
            var counter = string.Empty;
            if (request.ReportDefinitions.Count > 1)
            {
                counter = $"({i + 1}/{request.ReportDefinitions.Count}) ";
            }
            
            using (var ms = new MemoryStream())
            {
                var contentResult = await _reportClient.GetReportAsync(reportDefinition, ms);

                if (contentResult.HasError)
                {
                    var message = $"Error has occurred while generating {request.FileName()}{counter}.{Environment.NewLine}ref: {request.RequestContextId}";
                    _reportContentManager.LogException(contentResult.Exception, request.ContentId, message, request.NotificationProcessType);
                    return false;
                }

                ms.Seek(0, SeekOrigin.Begin);
                await _chunkedStreamWriter.Write(reportDefinition.FileName, ms);

                _log.Trace($"Saved {counter} to {reportDefinition.FileName} [ContentID={request.ContentId}]");
            }

            if (!reportDefinition.ShouldMakeContentModifiable &&
                request.ReportExportFormat() == Infrastructure.Formatting.Exports.ReportExportFormat.Pdf)
            {
                ProtectPdf(reportDefinition.FileName);
            }

            if (request.ShouldConcatenate)
            {
                if (!reportDefinition.ShouldExcludeFromConcatenation)
                {
                    reports.Add(reportDefinition.FileName);
                }

                _log.Trace($"Excluded {counter}{reportDefinition.ReportPath} from concatenation [ContentID={request.ContentId}]");
                return true;
            }

            reports.Add(reportDefinition.FileName);
            return true;
        }

        async Task<bool> ConcatenateReports(string[] files, string resultFileName)
        {
            if (string.IsNullOrWhiteSpace(resultFileName)) throw new ArgumentNullException(nameof(resultFileName));
            
            if (files.Length > 1)
            {
                _log.Trace($"Concatenating {files.Length} files.", files);
                
                if (!_pdfUtility.Concatenate(files, resultFileName, out var exception))
                {
                    _log.Exception(exception, $"Concatenation failure reported for {resultFileName}");
                    return false;
                }

                return true;
            }
            
            var source = files.ElementAt(0);

            if (source == resultFileName) return true;
            
            _log.Trace($"Copying '{source}' to '{resultFileName}'");

            using (var sourceStream = _fileSystem.OpenRead(source))
            {
                await _chunkedStreamWriter.Write(resultFileName, sourceStream);
            }

            return true;
        }

        void ProtectPdf(string fileName)
        {
            using (var stream = _fileSystem.CreateFileStream(fileName, FileMode.OpenOrCreate, FileAccess.ReadWrite))
            {
                // overriding existing file
                _pdfUtility.Protect(stream);
            }
        }
    }
}