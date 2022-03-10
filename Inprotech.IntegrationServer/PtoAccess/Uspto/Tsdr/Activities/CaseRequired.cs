using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.IO.Compression;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseFiles;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.Diagnostics;
using Inprotech.IntegrationServer.PtoAccess.DmsIntegration;
using Inprotech.IntegrationServer.PtoAccess.Utilities;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities
{
    public class CaseRequired
    {
        const string SerialNumberUrlTemplate = "ts/cd/casedocs/sn{0}/zip-bundle-download?case=true";
        const string RegistrationNumberUrlTemplate = "ts/cd/casedocs/rn{0}/zip-bundle-download?case=true";

        readonly Dictionary<DownloadType, Func<DataDownload, Activity>> _downloadWorkflow = new Dictionary
            <DownloadType, Func<DataDownload, Activity>>
        {
            {DownloadType.All, AfterDownload},
            {DownloadType.Documents, DownloadDocuments}
        };

        readonly IZipStreamHelper _zipStreamHelper;
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;
        readonly IPtoAccessCase _ptoAccessCase;
        readonly ITsdrClient _tsdrClient;

        public CaseRequired(
            IZipStreamHelper zipStreamHelper,
            IDataDownloadLocationResolver dataDownloadLocationResolver,
            IPtoAccessCase ptoAccessCase,
            ITsdrClient tsdrClient)
        {
            _zipStreamHelper = zipStreamHelper;
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _ptoAccessCase = ptoAccessCase;
            _tsdrClient = tsdrClient;
        }
        
        public async Task<Activity> Download(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            await _ptoAccessCase.EnsureAvailable(dataDownload.Case);

            var url = string.IsNullOrEmpty(dataDownload.Case.ApplicationNumber)
                ? string.Format(RegistrationNumberUrlTemplate,
                    OfficialNumbers.ExtractSearchTerm(dataDownload.Case.RegistrationNumber))
                : string.Format(SerialNumberUrlTemplate,
                    OfficialNumbers.ExtractSearchTerm(dataDownload.Case.ApplicationNumber));

            var zipData = await _tsdrClient.DownloadStatus(url);
            var stream = zipData.Item1;
            var serialNumber = Path.GetFileNameWithoutExtension(zipData.Item2);

            var files = _zipStreamHelper.ReadEntriesFromStream(stream);

            ExtractRequiredFiles(dataDownload, files, serialNumber);

            return _downloadWorkflow[dataDownload.DownloadType](dataDownload);
        }

        void ExtractRequiredFiles(DataDownload dataDownload, ReadOnlyCollection<ZipArchiveEntry> files, string number)
        {
            var path = _dataDownloadLocationResolver.Resolve(dataDownload);

            _zipStreamHelper.ExtractIfExists(files, $"{number}_status_st96.xml", path,
                PtoAccessFileNames.ApplicationDetails);

            if (_zipStreamHelper.ExtractIfExists(files, $"{number}.png", path,
                PtoAccessFileNames.MarkImage))
            {
                _ptoAccessCase.AddCaseFile(dataDownload.Case, CaseFileType.MarkImage,
                    Path.Combine(path, PtoAccessFileNames.MarkImage), PtoAccessFileNames.MarkImage, true);
            }

            if (_zipStreamHelper.ExtractIfExists(files, "markThumbnailImage.png", path,
                PtoAccessFileNames.MarkThumbnailImage))
            {
                _ptoAccessCase.AddCaseFile(dataDownload.Case, CaseFileType.MarkThumbnailImage,
                    Path.Combine(path, PtoAccessFileNames.MarkThumbnailImage),
                    PtoAccessFileNames.MarkThumbnailImage, true);
            }
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

        static Activity DownloadDocuments(DataDownload dataDownload)
        {
            return Activity.Sequence(
                Activity.Run<DocumentList>(_ => _.For(dataDownload)),
                Activity.Run<IBuildDmsIntegrationWorkflows>(b => b.BuildTsdr(dataDownload))
                );
        }
    }
}