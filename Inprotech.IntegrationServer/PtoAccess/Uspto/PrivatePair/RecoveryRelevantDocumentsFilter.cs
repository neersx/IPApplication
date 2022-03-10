using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Recovery;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public interface IRelevantDocumentsFilter
    {
        Task<IEnumerable<AvailableDocument>> For(Session session, ApplicationDownload applicationDownload,
                                            string sourceXmlPath);
    }
    public class RecoveryRelevantDocumentsFilter : IRelevantDocumentsFilter
    {
        readonly IReadScheduleSettings _scheduleSettingsReader;
        readonly IManageRecoveryInfo _recoveryInfoReader;
        readonly IProvideDocumentsToRecover _recoveryDocumentsProvider;

        public RecoveryRelevantDocumentsFilter(IReadScheduleSettings scheduleSettingsReader,
            IManageRecoveryInfo recoveryInfoReader, IProvideDocumentsToRecover recoveryDocumentsProvider)
        {
            _scheduleSettingsReader = scheduleSettingsReader;
            _recoveryInfoReader = recoveryInfoReader;
            _recoveryDocumentsProvider = recoveryDocumentsProvider;
        }

        public async Task<IEnumerable<AvailableDocument>> For(Session session, ApplicationDownload applicationDownload,
            string sourceXmlPath)
        {
            var tempStorageId = _scheduleSettingsReader.GetTempStorageId(session.ScheduleId);
            var recoveryids = _recoveryInfoReader.GetIds(tempStorageId).Single(_ => _.CorrelationId == session.CustomerNumber);

            if (recoveryids.DocumentIds.Any())
            {
                return _recoveryDocumentsProvider.GetDocumentsToRecover(recoveryids.DocumentIds);
            }
            
            return await _recoveryDocumentsProvider.GetDocumentsToRecover(session, applicationDownload);
        }
    }
}