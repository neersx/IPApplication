using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Updaters
{
    public interface IWriteImageFromIntegrationFile
    {
        Task Write(int notificationId, int imageId);
    }

    public class IntegrationFileImageWriter : IWriteImageFromIntegrationFile
    {
        readonly IIntegrationServerClient _client;
        readonly IDbContext _dbContext;
        readonly IConvertImagesToPng _pngConverter;

        [SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "png")]
        public IntegrationFileImageWriter(IDbContext dbContext, IIntegrationServerClient client, IConvertImagesToPng pngConverter)
        {
            _dbContext = dbContext;
            _client = client;
            _pngConverter = pngConverter;
        }

        public async Task Write(int notificationId, int imageId)
        {
            using (var raw = await _client.DownloadContent($"api/dataextract/storage/image?notificationId={notificationId}"))
            using (var pngStream = raw != Stream.Null ? _pngConverter.Convert(raw) : Stream.Null)
            {
                var image = await _dbContext.Set<Image>().SingleAsync(_ => _.Id == imageId);
                image.ImageData = pngStream != null ? await ReadAsync(pngStream) : null;

                await _dbContext.SaveChangesAsync();
            }
        }

        static async Task<byte[]> ReadAsync(Stream input)
        {
            using (var ms = new MemoryStream())
            {
                await input.CopyToAsync(ms);
                return ms.ToArray();
            }
        }
    }
}