using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Updaters
{
    public interface IImportCaseImages
    {
        Task Import(int notificationId, int caseId, string title);
    }

    public class CaseImageImporter : IImportCaseImages
    {
        public const int ImportedFromPtoStatus = -1102;
        public const int TradeMarkImageType = 1201;
        readonly IReorderCaseImageSequenceNumbers _caseImageSequenceReorderer;
        readonly IDbContext _dbContext;
        readonly IWriteImageFromIntegrationFile _integrationFileImageWriter;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;

        public CaseImageImporter(IDbContext dbContext, IWriteImageFromIntegrationFile integrationFileImageWriter,
                                 ILastInternalCodeGenerator lastInternalCodeGenerator, IReorderCaseImageSequenceNumbers caseImageSequenceReorderer)
        {
            _dbContext = dbContext;
            _integrationFileImageWriter = integrationFileImageWriter;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
            _caseImageSequenceReorderer = caseImageSequenceReorderer;
        }

        public async Task Import(int notificationId, int caseId, string title)
        {
            //Replacing the existing image if it has the "Imported from PTO" Image Status.
            //Other metadata against the image remains unchanged.
            //Adding a new image and promoting it to the first image on the Case if the Image Status is not "Imported from PTO".
            //Use the Image status "Imported from PTO", Image Type "Trade Mark".
            //Use the Title to populate the Image Description and Case Image Description.
            //The existing image is not deleted from the system.

            var caseImage = await _dbContext.Set<CaseImage>()
                                      .Where(ci => ci.CaseId == caseId)
                                      .OrderBy(ci => ci.ImageSequence)
                                      .Take(1)
                                      .SingleOrDefaultAsync();

            var imageDetail = caseImage != null
                ? await _dbContext.Set<ImageDetail>().SingleOrDefaultAsync(i => i.ImageId == caseImage.ImageId)
                : null;

            if (caseImage == null || imageDetail != null && imageDetail.ImageStatus != ImportedFromPtoStatus)
            {
                // the primary case image was not at status imported from pto
                // so create a new image against the case

                var imageId = _lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Image);

                var image = new Image(imageId);
                _dbContext.Set<Image>().Add(image);
                await _dbContext.SaveChangesAsync();

                imageDetail = new ImageDetail(imageId)
                {
                    ImageStatus = ImportedFromPtoStatus,
                    ImageDescription = title,
                    ContentType = "image/png"
                };
                _dbContext.Set<ImageDetail>().Add(imageDetail);
                
                var @case = await _dbContext.Set<Case>().SingleAsync(c => c.Id == caseId);
                var sequence = (short) (caseImage?.ImageSequence - 1 ?? 0);

                caseImage = new CaseImage(@case, imageId, sequence, TradeMarkImageType)
                            {
                                CaseImageDescription = title
                            };

                _dbContext.Set<CaseImage>().Add(caseImage);
                await _dbContext.SaveChangesAsync();

                _caseImageSequenceReorderer.Reorder(caseId);
                await _dbContext.SaveChangesAsync();
            }

            // now we have an image record (either the current Imported from Pto status case image or a new one)
            // we can write the image itself to the database
            await _integrationFileImageWriter.Write(notificationId, caseImage.ImageId);
        }
    }
}