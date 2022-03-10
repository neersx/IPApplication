using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Persistence;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.PctOneTimeJob
{
    public class CheckPctCase
    {
        readonly IRepository _repository;
        readonly IUpdateAssociatedRelationCountry _updateAssociatedRelationCountry;
        readonly IBufferedStringReader _stringReader;
        readonly IBufferedStringWriter _bufferedStringWriter;
        readonly Func<DateTime> _now;

        public CheckPctCase(IRepository repository,
            IUpdateAssociatedRelationCountry updateAssociatedRelationCountry, 
            IBufferedStringReader stringReader, IBufferedStringWriter bufferedStringWriter, Func<DateTime> now)
        {
            _repository = repository;
            _updateAssociatedRelationCountry = updateAssociatedRelationCountry;
            _stringReader = stringReader;
            _bufferedStringWriter = bufferedStringWriter;
            _now = now;
        }

        public async Task CheckAndUpdateCase(int notificationId)
        {
            var caseNotification = _repository.Set<CaseNotification>()
                                              .Include(cn => cn.Case)
                                              .First(_ => _.Id == notificationId);

            if (string.IsNullOrWhiteSpace(caseNotification.Case.FileStore?.Path))
                return;

            var cpaXml = await _stringReader.Read(caseNotification.Case.FileStore.Path);

            if (_updateAssociatedRelationCountry.TryUpdate(cpaXml, out string updatedCpaXml))
            {
                await _bufferedStringWriter.Write(caseNotification.Case.FileStore.Path, updatedCpaXml);

                caseNotification.UpdatedOn = _now();
                _repository.SaveChanges();
            }
        }
    }
}