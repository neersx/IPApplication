using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Persistence;

namespace Inprotech.IntegrationServer.PtoAccess.DmsIntegration
{
    public class CaseAndDocuments
    {
        public Case Case { get; set; }
        public IEnumerable<Document> Documents { get; set; }

        public CaseAndDocuments(Case @case, IEnumerable<Document> documents)
        {
            Case = @case;
            Documents = documents.ToArray();
        }
    }

    public interface ILoadCaseAndDocuments
    {
        CaseAndDocuments GetCaseAndDocuments(DataDownload dataDownload);
        CaseAndDocuments GetCaseAndDocuments(ApplicationDownload applicationDownload);
        IEnumerable<Document> GetDownloadedDocumentsToSendToDms(DataSourceType source);
        IEnumerable<Document> GetAnyDocumentsAtSendToDms();
        Case GetCaseFor(Document document);
        CaseAndDocuments GetCaseAndDocumentsFor(int documentId);
        CaseAndDocuments GetCaseAndDocumentsFor(int caseId, int documentId);
    }

    public class CaseAndDocumentLoader : ILoadCaseAndDocuments
    {
        readonly IRepository _repository;

        public CaseAndDocumentLoader(IRepository repository)
        {
            _repository = repository;
        }

        public CaseAndDocuments GetCaseAndDocuments(DataDownload dataDownload)
        {
            return
                BuildCaseAndDocumentsResult(
                    c => c.CorrelationId == dataDownload.Case.CaseKey && c.Source == DataSourceType.UsptoTsdr);
        }

        public CaseAndDocuments GetCaseAndDocuments(ApplicationDownload applicationDownload)
        {
            return
                BuildCaseAndDocumentsResult(
                    c =>
                        c.ApplicationNumber == applicationDownload.Number && c.Source == DataSourceType.UsptoPrivatePair);
        }

        CaseAndDocuments BuildCaseAndDocumentsResult(Func<Case, bool> predicate)
        {
            var @case = _repository.Set<Case>().SingleOrDefault(predicate);
            return @case == null ? null : new CaseAndDocuments(@case, GetDocumentsForCase(@case));
        }

        public IEnumerable<Document> GetDownloadedDocumentsToSendToDms(DataSourceType source)
        {
            return _repository.Set<Document>()
                .Where(d => d.Source == source && d.Status == DocumentDownloadStatus.Downloaded);
        }

        public IEnumerable<Document> GetAnyDocumentsAtSendToDms()
        {
            return _repository.Set<Document>()
                .Where(d => d.Status == DocumentDownloadStatus.SendToDms);
        }

        public Case GetCaseFor(Document document)
        {
            return _repository.Set<Case>().For(document).SingleOrDefault();
        }

        public CaseAndDocuments GetCaseAndDocumentsFor(int documentId)
        {
            var doc = _repository.Set<Document>().SingleOrDefault(d => d.Id == documentId);
            if (doc == null) return null;
            var @case = GetCaseFor(doc);
            return new CaseAndDocuments(@case, new[] {doc});
        }

        public CaseAndDocuments GetCaseAndDocumentsFor(int caseId, int documentId)
        {
            var doc = _repository.Set<Document>().SingleOrDefault(d => d.Id == documentId);
            var @case = _repository.Set<Case>().SingleOrDefault(c => c.Id == caseId);
            if (doc == null || @case == null) return null;
            return new CaseAndDocuments(@case, new[] {doc});
        }

        IEnumerable<Document> GetDocumentsForCase(Case @case)
        {
            return _repository
                .Set<Document>()
                .For(@case.ApplicationNumber, @case.RegistrationNumber, @case.PublicationNumber)
                .Where(d => d.Source == @case.Source)
                .ToArray();
        }
    }
}