using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Innography.PrivatePair;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities.CpaXml
{
    public interface IConvertApplicationDetailsToCpaXml
    {
        Task Convert(ApplicationDownload application);
    }

    public class ConvertApplicationDetailsToCpaXml : IConvertApplicationDetailsToCpaXml
    {
        readonly IArtifactsLocationResolver _artifactsLocationResolver;
        readonly CpaXmlConverter _cpaXmlConverter;
        readonly IBufferedStringWriter _bufferedStringWriter;
        readonly IBiblioStorage _biblioStorage;

        public ConvertApplicationDetailsToCpaXml(IArtifactsLocationResolver artifactsLocationResolver,
                                                 CpaXmlConverter cpaXmlConverter,
                                                 IBufferedStringWriter bufferedStringWriter, IBiblioStorage biblioStorage)
        {
            _artifactsLocationResolver = artifactsLocationResolver;
            _cpaXmlConverter = cpaXmlConverter;
            _bufferedStringWriter = bufferedStringWriter;
            _biblioStorage = biblioStorage;
        }
        public async Task Convert(ApplicationDownload application)
        {
            var biblioFile = await _biblioStorage.Read(application);

            var cpaXml = _cpaXmlConverter.Convert(biblioFile, application.Number);

            await _bufferedStringWriter.Write(
                                              _artifactsLocationResolver.Resolve(application, KnownFileNames.CpaXml), cpaXml);
        }
    }
}
