using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using InprotechKaizen.Model.Components.Cases.Comparison.CpaXml;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.FileApp.Activities
{
    public class VersionableContentResolver : IVersionableContentResolver
    {
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;
        readonly ICpaXmlCaseDetailsLoader _cpaXmlCaseDetails;
        readonly IBufferedStringReader _reader;

        public VersionableContentResolver(IDataDownloadLocationResolver dataDownloadLocationResolver, ICpaXmlCaseDetailsLoader cpaXmlCaseDetails, IBufferedStringReader reader)
        {
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _cpaXmlCaseDetails = cpaXmlCaseDetails;
            _reader = reader;
        }

        public async Task<string> Resolve(DataDownload dataDownload)
        {
            var cpaXmlPath = _dataDownloadLocationResolver.Resolve(dataDownload, PtoAccessFileNames.CpaXml);

            var cpaXml = await _reader.Read(cpaXmlPath);

            var caseDetails = _cpaXmlCaseDetails.Load(cpaXml);
            
            return JsonConvert.SerializeObject(caseDetails, Formatting.None);
        }
    }
}