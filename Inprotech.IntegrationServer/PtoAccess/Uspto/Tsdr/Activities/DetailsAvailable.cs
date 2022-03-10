using System;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities
{
    public class DetailsAvailable
    {
        readonly ICpaXmlConverter _cpaXmlConverter;
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;
        readonly IBufferedStringReader _bufferedStringReader;
        readonly IBufferedStringWriter _bufferedStringWriter;
        readonly IFileSystem _fileSystem;

        public DetailsAvailable(ICpaXmlConverter cpaXmlConverter, IDataDownloadLocationResolver dataDownloadLocationResolver, IBufferedStringReader bufferedStringReader, IBufferedStringWriter bufferedStringWriter,
            IFileSystem fileSystem)
        {
            _cpaXmlConverter = cpaXmlConverter;
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _bufferedStringReader = bufferedStringReader;
            _bufferedStringWriter = bufferedStringWriter;
            _fileSystem = fileSystem;
        }

        public async Task ConvertToCpaXml(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            var appDetailsPath = _dataDownloadLocationResolver.Resolve(dataDownload, PtoAccessFileNames.ApplicationDetails);
            if (!_fileSystem.Exists(appDetailsPath))
            {
                // old filename.
                appDetailsPath = _dataDownloadLocationResolver.Resolve(dataDownload, "status.xml");
            }

            var appDetails = await _bufferedStringReader.Read(appDetailsPath);

            var cpaXml = _cpaXmlConverter.Convert(dataDownload.Case, appDetails);

            await _bufferedStringWriter.Write(
                _dataDownloadLocationResolver.Resolve(dataDownload, PtoAccessFileNames.CpaXml), cpaXml);
        }
    }
}