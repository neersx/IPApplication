using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.IntegrationServer.PtoAccess.Innography.CpaXmlConversion;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks;
using InprotechKaizen.Model;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Activities
{
    public interface IDetailsAvailable
    {
        Task ConvertToCpaXml(DataDownload dataDownload);
    }

    public class DetailsAvailable : IDetailsAvailable
    {
        readonly IBufferedStringWriter _bufferedStringWriter;
        readonly ICpaXmlConverter _cpaXmlConverter;
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;

        public DetailsAvailable(ICpaXmlConverter cpaXmlConverter, IDataDownloadLocationResolver dataDownloadLocationResolver, IBufferedStringWriter bufferedStringWriter)
        {
            _cpaXmlConverter = cpaXmlConverter;
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _bufferedStringWriter = bufferedStringWriter;
        }

        public async Task ConvertToCpaXml(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            string cpaXml;
            if (dataDownload.IsPatentsDataValidation())
            {
                var idsResult = dataDownload.GetExtendedDetails<ValidationResult>();
                cpaXml = _cpaXmlConverter.Convert(idsResult);
            }
            else
            {
                var tmIdsResult = dataDownload.GetExtendedDetails<TrademarkDataValidationResult>();
                cpaXml = _cpaXmlConverter.Convert(tmIdsResult, dataDownload.Case.CountryCode);
            }

            await _bufferedStringWriter.Write(
                                              _dataDownloadLocationResolver.Resolve(dataDownload, PtoAccessFileNames.CpaXml), cpaXml);
        }
    }
}