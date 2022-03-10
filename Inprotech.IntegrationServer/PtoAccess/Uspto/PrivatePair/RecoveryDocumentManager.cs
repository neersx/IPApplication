using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Persistence;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public interface IProvideDocumentsToRecover
    {
        IEnumerable<AvailableDocument> GetDocumentsToRecover(IEnumerable<int> documentIds);

        Task<IEnumerable<AvailableDocument>> GetDocumentsToRecover(Session session, ApplicationDownload applicationDownload);
    }

    public class RecoveryDocumentManager : IProvideDocumentsToRecover
    {
        readonly IRepository _repository;
        readonly IScheduleDocumentStartDate _scheduleDocumentStartDate;
        readonly IBiblioStorage _biblioStorage;

        public RecoveryDocumentManager(IRepository repository,
                                       IScheduleDocumentStartDate scheduleDocumentStartDate, IBiblioStorage biblioStorage)
        {
            _repository = repository;
            _scheduleDocumentStartDate = scheduleDocumentStartDate;
            _biblioStorage = biblioStorage;
        }

        public IEnumerable<AvailableDocument> GetDocumentsToRecover(IEnumerable<int> documentIds)
        {
            if (documentIds == null) throw new ArgumentNullException(nameof(documentIds));

            return _repository.Set<Document>().Where(d => documentIds.Contains(d.Id))
                              .ToArray()
                              .Select(d => new AvailableDocument
                              {
                                  DocumentCategory = d.DocumentCategory,
                                  DocumentDescription = d.DocumentDescription,
                                  FileWrapperDocumentCode = d.FileWrapperDocumentCode,
                                  MailRoomDate = d.MailRoomDate,
                                  PageCount = d.PageCount.GetValueOrDefault(),
                              });
        }

        public async Task<IEnumerable<AvailableDocument>> GetDocumentsToRecover(Session session,
                                                                                ApplicationDownload applicationDownload)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));
            if (applicationDownload == null) throw new ArgumentNullException(nameof(applicationDownload));

            var scheduleDocumentStartDate = _scheduleDocumentStartDate.Resolve(session);

            return (await _biblioStorage.Read(applicationDownload))
                   .ImageFileWrappers
                   .Select(_ => _.ToAvailableDocument())
                   .Where(d => d.MailRoomDate >= scheduleDocumentStartDate)
                   .Select(d => new AvailableDocument
                   {
                       DocumentCategory = d.DocumentCategory,
                       DocumentDescription = d.DocumentDescription,
                       FileWrapperDocumentCode = d.FileWrapperDocumentCode,
                       MailRoomDate = d.MailRoomDate,
                       PageCount = d.PageCount
                   });
        }
    }
}