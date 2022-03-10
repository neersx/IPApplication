using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.Diagnostics;
using Inprotech.IntegrationServer.PtoAccess.WorkflowIntegration;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities
{
    public class DocumentList
    {
        readonly IRepository _repository;
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;
        readonly IBufferedStringWriter _bufferedStringWriter;
        readonly ITsdrClient _tsdrClient;
        readonly ITsdrSettings _tsdrSettings;
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;

        public DocumentList(IRepository repository, IDataDownloadLocationResolver dataDownloadLocationResolver,
                            IBufferedStringWriter bufferedStringWriter, ITsdrClient tsdrClient, ITsdrSettings tsdrSettings,
                            IScheduleRuntimeEvents scheduleRuntimeEvents)
        {
            _repository = repository;
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _bufferedStringWriter = bufferedStringWriter;
            _tsdrClient = tsdrClient;
            _tsdrSettings = tsdrSettings;
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
        }

        public async Task<Activity> For(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            var newDocs = (await FindNewDocuments(dataDownload)).ToArray();

            _scheduleRuntimeEvents.IncludeDocumentsForCase(dataDownload.Id, newDocs.Length);

            return newDocs.Any()
                ? Activity.Sequence(DownloadDocuments(newDocs, dataDownload), AfterDownload(dataDownload))
                : AfterDownloadWithoutDocs(dataDownload);
        }

        async Task<IEnumerable<Document>> FindNewDocuments(DataDownload dataDownload)
        {
            var serialNumber = dataDownload.Case.ApplicationNumber;
            var registrationNumber = dataDownload.Case.RegistrationNumber;

            var content = await _tsdrClient.DownloadDocumentsList(serialNumber, registrationNumber);
            var path = _dataDownloadLocationResolver.Resolve(dataDownload, KnownFileNames.DocumentList);

            await _bufferedStringWriter.Write(path, content);

            var found = DocumentsFrom(content, dataDownload).ToArray();
            var documentIds = found.Select(_ => _.DocumentObjectId);

            /* the method is to resolve items that are to be downloaded in the workflow
             items that can proceed to download state are Pending and Failed */

            var mustExclude = new[]
                              {
                                  DocumentDownloadStatus.Pending,
                                  DocumentDownloadStatus.Failed
                              };

            var existingDocs = _repository.Set<Document>()
                                          .Where(_ => !mustExclude.Contains(_.Status) && documentIds.Contains(_.DocumentObjectId))
                                          .For(dataDownload)
                                          .Select(_ => _.DocumentObjectId);

            return found.Where(_ => !existingDocs.Contains(_.DocumentObjectId));
        }

        IEnumerable<Document> DocumentsFrom(string content, DataDownload dataDownload)
        {
            var documentList = XElement.Parse(content);
            var ns = _tsdrSettings.DocsListNs;
            return documentList
                .Elements(ns + "Document")
                .Select(d => new Document
                             {
                                 DocumentObjectId = DocumentId((string) d.Element(ns + "DocumentTypeCode"), d.DateTime(ns + "ScanDateTime")),
                                 ApplicationNumber = dataDownload.Case.ApplicationNumber ?? (string) d.Element(ns + "SerialNumber"),
                                 RegistrationNumber = dataDownload.Case.RegistrationNumber ?? (string) d.Element(ns + "RegistrationNumber"),
                                 MailRoomDate = d.DateTime(ns + "MailRoomDate"),
                                 PageCount = (int?) d.Element(ns + "TotalPageQuantity"),
                                 DocumentCategory = (string) d.Element(ns + "DocumentTypeCode"),
                                 DocumentDescription = (string) d.Element(ns + "DocumentTypeCodeDescriptionText"),
                                 MediaType = MediaType(d.Element(ns + "PageMediaTypeList")),
                                 Source = DataSourceType.UsptoTsdr,
                                 SourceUrl = FindSourceUrl(d, ns)
                             });
        }

        string FindSourceUrl(XElement docElement, XNamespace ns)
        {
            var sourceSystem = (string) docElement.Element(ns + "SourceSystem");
            if (sourceSystem != "cms") return null;

            return (string) docElement.Descendants(ns + "UrlPath").FirstOrDefault();
        }

        static string DocumentId(string docTypeCode, DateTime scanDateTime)
        {
            const string docIdFormat = "{0}{1:yyyyMMddHHmmss}";

            return string.Format(docIdFormat, docTypeCode, scanDateTime);
        }

        string MediaType(XElement mediaTypeList)
        {
            /* all other mediatypes are assumed to be retrievable as PDF format except audio mediatype */
            var ns = _tsdrSettings.DocsListNs;

            return mediaTypeList?
                .Elements(ns + "PageMediaTypeName")
                .Select(_ => (string) _)
                .FirstOrDefault(_ => _.StartsWith("audio"));
        }

        static Activity DownloadDocuments(IEnumerable<Document> newDocs, DataDownload dataDownload)
        {
            return Activity.Sequence(
                                     newDocs.Select(_ =>
                                                        Activity.Run<DownloadDocument>(dd => dd.Download(dataDownload, _))
                                                                .ExceptionFilter<ErrorLogger>((ex, e) => e.LogContextError(ex, dataDownload, _.DocumentObjectId))
                                                                .Failed(Activity.Run<DownloadDocumentFailed>(d => d.NotifyFailure(dataDownload, _)))
                                                                .ThenContinue()));
        }

        static Activity AfterDownload(DataDownload dataDownload)
        {
            return Activity.Sequence(
                                     Activity.Run<DetailsAvailable>(a => a.ConvertToCpaXml(dataDownload)),
                                     Activity.Run<DocumentEvents>(d => d.UpdateFromPto(dataDownload)),
                                     Activity.Run<NewCaseDetailsNotification>(a => a.NotifyAlways(dataDownload)),
                                     Activity.Run<RuntimeEvents>(a => a.CaseProcessed(dataDownload)))
                           .AnyFailed(Activity.Run<IDownloadFailedNotification>(d => d.Notify(dataDownload)));
        }

        static Activity AfterDownloadWithoutDocs(DataDownload dataDownload)
        {
            return Activity.Sequence(
                                     Activity.Run<DetailsAvailable>(a => a.ConvertToCpaXml(dataDownload)),
                                     Activity.Run<NewCaseDetailsNotification>(a => a.NotifyIfChanged(dataDownload)),
                                     Activity.Run<RuntimeEvents>(a => a.CaseProcessed(dataDownload)))
                           .AnyFailed(Activity.Run<IDownloadFailedNotification>(d => d.Notify(dataDownload)));
        }
    }

    public static class XElementExt
    {
        public static DateTime DateTime(this XElement current, XName elementName)
        {
            var s = (string) current.Element(elementName);
            return DateTimeOffset.Parse(s).DateTime;
        }
    }
}