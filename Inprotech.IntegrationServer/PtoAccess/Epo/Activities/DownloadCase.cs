using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.Diagnostics;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.Activities
{
    public class DownloadCase
    {
        readonly IBufferedStringWriter _bufferedStringWriter;
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;

        readonly Dictionary<DownloadType, Func<DataDownload, Activity>> _downloadWorkflow =
            new Dictionary<DownloadType, Func<DataDownload, Activity>>
                {
                    {DownloadType.All, AfterDownload},
                    {DownloadType.Documents, DownloadDocuments}
                };

        readonly IOpsClient _opsClient;
        readonly IOpsData _opsData;
        readonly IPtoAccessCase _ptoAccessCase;

        public DownloadCase(IOpsClient opsClient, IBufferedStringWriter bufferedStringWriter, IDataDownloadLocationResolver dataDownloadLocationResolver, IPtoAccessCase ptoAccessCase, IOpsData opsData)
        {
            _opsClient = opsClient;
            _bufferedStringWriter = bufferedStringWriter;
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _ptoAccessCase = ptoAccessCase;
            _opsData = opsData;
        }

        public async Task<Activity> Download(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            var @case = dataDownload.Case;

            await _ptoAccessCase.EnsureAvailable(dataDownload.Case);

            string xmlString = null;

            if (!string.IsNullOrEmpty(@case.PublicationNumber))
            {
                xmlString = await _opsClient.DownloadApplicationData(OpsClient.DownloadByNumberType.Publication,
                                                                     @case.PublicationNumber);
            }

            if (string.IsNullOrEmpty(xmlString) && !string.IsNullOrEmpty(@case.ApplicationNumber))
            {
                xmlString = await _opsClient.DownloadApplicationData(OpsClient.DownloadByNumberType.Application,
                                                                     @case.ApplicationNumber);
            }

            if (string.IsNullOrEmpty(xmlString))
            {
                throw new ExternalCaseNotFoundException();
            }

            await _bufferedStringWriter.Write(
                                              _dataDownloadLocationResolver.Resolve(dataDownload, PtoAccessFileNames.ApplicationDetails),
                                              xmlString);

            if (string.IsNullOrEmpty(@case.ApplicationNumber))
            {
                dataDownload.Case.ApplicationNumber = _opsData.GetBibliographicData(xmlString).ApplicationNumber();
            }

            return _downloadWorkflow[dataDownload.DownloadType](dataDownload);
        }

        static Activity DownloadDocuments(DataDownload arg)
        {
            return Activity.Run<DocumentList>(d => d.For(arg));
        }

        static Activity AfterDownload(DataDownload dataDownload)
        {
            return Activity.Sequence
                (
                 Activity.Run<DetailsAvailable>(a => a.ConvertToCpaXml(dataDownload)),
                 Activity.Run<NewCaseDetailsNotification>(a => a.NotifyIfChanged(dataDownload)),
                 Activity.Run<RuntimeEvents>(r => r.CaseProcessed(dataDownload))
                );
        }
    }
}