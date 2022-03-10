using System;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Persistence;
using Inprotech.IntegrationServer.PtoAccess.ContentVersioning;

namespace Inprotech.IntegrationServer.PtoAccess.Activities
{
    public interface INewCaseDetailsNotification
    {
        Task NotifyAlways(DataDownload dataDownload);
        Task NotifyIfChanged(DataDownload dataDownload);
    }

    public class NewCaseDetailsNotification : INewCaseDetailsNotification
    {
        readonly IRepository _repository;
        readonly IPtoAccessCase _ptoAccessCase;
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;
        readonly IDownloadedContent _downloadedContent;
        readonly IContentHasher _contentHasher;
        readonly ITitleExtractor _titleExtractor;
        readonly IIndex<DataSourceType, ISourceNotificationModifier> _notificationModifier;

        public NewCaseDetailsNotification(
            IRepository repository, IPtoAccessCase ptoAccessCase,
            IDataDownloadLocationResolver dataDownloadLocationResolver,
            IDownloadedContent downloadedContent,
            IContentHasher contentHasher, ITitleExtractor titleExtractor, IIndex<DataSourceType, ISourceNotificationModifier> notificationModifier)
        {
            _repository = repository;
            _ptoAccessCase = ptoAccessCase;
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _downloadedContent = downloadedContent;
            _contentHasher = contentHasher;
            _titleExtractor = titleExtractor;
            _notificationModifier = notificationModifier;
        }

        public async Task NotifyAlways(DataDownload dataDownload)
        {
            await Notify(dataDownload, true);
        }

        public async Task NotifyIfChanged(DataDownload dataDownload)
        {
            await Notify(dataDownload, false);
        }

        async Task Notify(DataDownload dataDownload, bool forceNotify)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            var content = await _downloadedContent.MakeVersionable(dataDownload);
            var hash = _contentHasher.ComputeHash(content);

            var @case =
                _repository.Set<Case>()
                    .Single(
                        c =>
                            c.Source == dataDownload.DataSourceType &&
                            c.CorrelationId == dataDownload.Case.CaseKey);

            var errorNotification =
                _repository.Set<CaseNotification>()
                .SingleOrDefault(_ => _.CaseId == @case.Id && _.Type == CaseNotificateType.Error);

            if (hash != @case.Version || forceNotify || errorNotification != null)
            {
                var title = await _titleExtractor.ExtractFrom(dataDownload);
                var cpaXmlPath = _dataDownloadLocationResolver.Resolve(dataDownload, PtoAccessFileNames.CpaXml);

                _ptoAccessCase.Update(cpaXmlPath, @case, hash, dataDownload.Case);
                var notification = _ptoAccessCase.CreateOrUpdateNotification(@case, title);

                if (_notificationModifier.TryGetValue(dataDownload.DataSourceType, out ISourceNotificationModifier m))
                {
                    m.Modify(notification, dataDownload);
                }

                _repository.SaveChanges();
            }
        }
    }
}