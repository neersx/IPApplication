using System;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;

namespace Inprotech.IntegrationServer.PtoAccess
{
    public interface ITitleExtractor
    {
        Task<string> ExtractFrom(DataDownload dataDownload);
    }

    public class TitleExtractor : ITitleExtractor
    {
        readonly XNamespace _cpaXmlNs = "http://www.cpasoftwaresolutions.com";

        readonly IDataDownloadLocationResolver _locationResolver;
        readonly IBufferedStringReader _bufferedStringReader;

        public TitleExtractor(IDataDownloadLocationResolver locationResolver, IBufferedStringReader bufferedStringReader)
        {
            _locationResolver = locationResolver;
            _bufferedStringReader = bufferedStringReader;
        }

        public async Task<string> ExtractFrom(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            var path = _locationResolver.Resolve(dataDownload, PtoAccessFileNames.CpaXml);

            var cpaxml = await _bufferedStringReader.Read(path);

            return ShortTitleFrom(cpaxml);
        }

        string ShortTitleFrom(string cpaXml)
        {
            var descriptionDetails = XElement.Parse(cpaXml)
                .Descendants(_cpaXmlNs + "DescriptionDetails")
                .ToArray();

            return descriptionDetails
                .Where(_ => (string) _.Element(_cpaXmlNs + "DescriptionCode") == "Short Title")
                .Select(_ => (string) _.Element(_cpaXmlNs + "DescriptionText"))
                .SingleOrDefault();
        }
    }
}