using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.CaseFiles;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Persistence;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public interface IInnographyTrademarksImage
    {
        Task Download(EligibleCase eligibleCase, string path, string ipid, bool refresh = false);
    }

    public class InnographyTrademarksImage : IInnographyTrademarksImage
    {
        readonly IPtoAccessCase _ptoAccessCase;
        readonly IInnographyTradeMarksImageClient _tradeMarksImageClient;
        readonly IChunkedStreamWriter _streamWriter;
        readonly IRepository _repository;

        public InnographyTrademarksImage(IInnographyTradeMarksImageClient tradeMarksImageClient,
                                            IPtoAccessCase ptoAccessCase,
                                            IChunkedStreamWriter streamWriter,
                                            IRepository repository)
        {
            _tradeMarksImageClient = tradeMarksImageClient;
            _ptoAccessCase = ptoAccessCase;
            _streamWriter = streamWriter;
            _repository = repository;
        }

        public async Task Download(EligibleCase eligibleCase, string path, string ipid, bool refresh = false)
        {
            if (string.IsNullOrEmpty(ipid))
                throw new ArgumentNullException(nameof(ipid));

            if (!refresh && _ptoAccessCase.CaseFileExists(eligibleCase.CaseKey,
                                                DataSourceType.IpOneData,
                                                CaseFileType.MarkImage))
                return;
            
            var response = await _tradeMarksImageClient.ImageApi(ipid);
            var tmImages = response.Result;

            if (!tmImages.Any())
                return;

            var image = tmImages.First();

            var fileName = FileName(image.Type);
            var validPath = Path.Combine(path, fileName);

            using (var stream = new MemoryStream(Convert.FromBase64String(image.Content)))
            {
                await _streamWriter.Write(validPath, stream);
            }

            _ptoAccessCase.AddCaseFile(eligibleCase, CaseFileType.MarkImage,
                                       validPath, fileName, true, image.Type);

            await _repository.SaveChangesAsync();
        }

        string FileName(string imageType)
        {
            return "markImage_" + Guid.NewGuid() + "." + imageType.Split('/').Last();
        }
    }
}
