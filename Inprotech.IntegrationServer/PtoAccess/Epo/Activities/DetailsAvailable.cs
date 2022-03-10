using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.Activities
{
    public class DetailsAvailable
    {
        readonly ICpaXmlConverter _cpaXmlConverter;
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;
        readonly IBufferedStringReader _bufferedStringReader;
        readonly IBufferedStringWriter _bufferedStringWriter;

        public DetailsAvailable(ICpaXmlConverter cpaXmlConverter, IDataDownloadLocationResolver dataDownloadLocationResolver, IBufferedStringReader bufferedStringReader, IBufferedStringWriter bufferedStringWriter)
        {
            _cpaXmlConverter = cpaXmlConverter;
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _bufferedStringReader = bufferedStringReader;
            _bufferedStringWriter = bufferedStringWriter;
        }

        public async Task ConvertToCpaXml(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            var appDetailsPath = _dataDownloadLocationResolver.Resolve(dataDownload, PtoAccessFileNames.ApplicationDetails);

            var appDetails = await _bufferedStringReader.Read(appDetailsPath);

            var cpaXml = _cpaXmlConverter.Convert(appDetails);

            await _bufferedStringWriter.Write(
                _dataDownloadLocationResolver.Resolve(dataDownload, PtoAccessFileNames.CpaXml), cpaXml);
        }
    }
}