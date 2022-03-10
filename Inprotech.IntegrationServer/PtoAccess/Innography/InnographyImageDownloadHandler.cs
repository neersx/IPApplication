using System.IO;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Innography;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public class InnographyImageDownloadHandler : ISourceImageDownloadHandler
    {
        readonly IInnographyTrademarksImage _innographyTrademarksImage;
        readonly IInnographyIdFromCpaXml _innographyIdFromCpaXml;
        readonly IFileSystem _fileSystem;

        public InnographyImageDownloadHandler(IInnographyTrademarksImage innographyTrademarksImage,
                                                IInnographyIdFromCpaXml innographyIdFromCpaXml,
                                                IFileSystem fileSystem)  
        {
            _innographyTrademarksImage = innographyTrademarksImage;
            _innographyIdFromCpaXml = innographyIdFromCpaXml;
            _fileSystem = fileSystem;
        }

        public async Task Download(EligibleCase eligibleCase, string cpaXmlPath, string imagePath)
        {
            var ipid = _innographyIdFromCpaXml.Resolve(await ReadCpaXml(cpaXmlPath));
            await _innographyTrademarksImage.Download(eligibleCase, imagePath, ipid, true);
        }
        
        async Task<string> ReadCpaXml(string cpaXmlPath)
        {
            using (var sr = new StreamReader(_fileSystem.OpenRead(cpaXmlPath)))
            {
                return await sr.ReadToEndAsync();
            }
        }
    }
}
