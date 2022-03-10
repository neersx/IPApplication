using System;
using System.Threading.Tasks;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Innography;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.Diagnostics;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks;
using InprotechKaizen.Model;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Activities
{
    public interface IDownloadedCase
    {
        Task Process(DataDownload dataDownload, bool linked = false);
    }

    public class DownloadedCase : IDownloadedCase
    {
        readonly IDetailsAvailable _detailsAvailable;
        readonly IInnographyIdUpdater _innographyIdUpdater;
        readonly INewCaseDetailsNotification _newCaseDetailsNotification;
        readonly IPtoAccessCase _ptoAccessCase;
        readonly IRuntimeEvents _runtimeEvents;

        public DownloadedCase(IPtoAccessCase ptoAccessCase, IInnographyIdUpdater innographyIdUpdater, IDetailsAvailable detailsAvailable, INewCaseDetailsNotification newCaseDetailsNotification, IRuntimeEvents runtimeEvents)
        {
            _ptoAccessCase = ptoAccessCase;
            _innographyIdUpdater = innographyIdUpdater;
            _detailsAvailable = detailsAvailable;
            _newCaseDetailsNotification = newCaseDetailsNotification;
            _runtimeEvents = runtimeEvents;
        }

        public async Task Process(DataDownload dataDownload, bool linked = false)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            await _ptoAccessCase.EnsureAvailable(dataDownload.Case);
            
            if (linked)
            {
                var result = dataDownload.IsPatentsDataValidation()
                                ? dataDownload.GetExtendedDetails<ValidationResult>().InnographyId
                                : dataDownload.GetExtendedDetails<TrademarkDataValidationResult>().IpId;

                await _innographyIdUpdater.Update(dataDownload.Case.CaseKey, result);
            }

            await _detailsAvailable.ConvertToCpaXml(dataDownload);

            await _newCaseDetailsNotification.NotifyIfChanged(dataDownload);  

            await _runtimeEvents.CaseProcessed(dataDownload);
        }
    }
}