using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Updaters;
using InprotechKaizen.Model.Components.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Updaters
{
    public class CaseImageImporterFacts : FactBase
    {
        [Fact]
        public async Task AddsCaseImageWhenCaseImageDoesNotExist()
        {
            var f = new CaseImageImporterFixture(Db);

            await f.Subject.Import(f.NotificationId, f.Case.Id, f.Title);

            Assert.NotNull(Db.Set<CaseImage>()
                             .Single(ci => ci.CaseId == f.Case.Id && ci.CaseImageDescription == f.Title));
        }

        [Fact]
        public async Task AddsCaseImageWhenCaseImageWithLowestSequenceIsNotImportedFromPto()
        {
            var f = new CaseImageImporterFixture(Db).WithCaseImages(3, imageStatus: 100);

            Assert.Equal(3, Db.Set<CaseImage>().Count());

            await f.Subject.Import(f.NotificationId, f.Case.Id, f.Title);

            Assert.Equal(4, Db.Set<CaseImage>().Count());

            var result = Db.Set<CaseImage>().OrderBy(_ => _.ImageSequence).Take(1).Single();
            Assert.Equal(f.Title, result.CaseImageDescription);
        }

        [Fact]
        public async Task AddsImageDetailWhenCaseImageDoesNotExist()
        {
            var f = new CaseImageImporterFixture(Db);

            await f.Subject.Import(f.NotificationId, f.Case.Id, f.Title);

            var caseImage = Db.Set<CaseImage>()
                              .Single(ci => ci.CaseId == f.Case.Id && ci.CaseImageDescription == f.Title);

            Assert.NotNull(Db.Set<ImageDetail>()
                             .Single(id => id.ImageId == caseImage.ImageId && id.ImageStatus == -1102 && id.ImageDescription == f.Title));
        }

        [Fact]
        public async Task AddsImageWhenCaseImageDoesNotExist()
        {
            var f = new CaseImageImporterFixture(Db);

            await f.Subject.Import(f.NotificationId, f.Case.Id, f.Title);

            var caseImage = Db.Set<CaseImage>()
                              .Single(ci => ci.CaseId == f.Case.Id && ci.CaseImageDescription == f.Title);

            Assert.NotNull(Db.Set<Image>().Single(i => i.Id == caseImage.ImageId));
        }

        [Fact]
        public async Task AttemptsToWriteImageFileWhenCaseImageDoesNotExist()
        {
            var f = new CaseImageImporterFixture(Db);

            await f.Subject.Import(f.NotificationId, f.Case.Id, f.Title);

            var caseImage = Db.Set<CaseImage>()
                              .Single(ci => ci.CaseId == f.Case.Id && ci.CaseImageDescription == f.Title);

            f.IntegrationFileImageWriter.Received(1).Write(f.NotificationId, caseImage.ImageId).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task CaseImageSequenceNumbersAreReordered()
        {
            var f = new CaseImageImporterFixture(Db);
            await f.Subject.Import(f.NotificationId, f.Case.Id, f.Title);
            f.CaseImageSequenceReorderer.Received(1).Reorder(f.Case.Id);
        }

        [Fact]
        public async Task CreatesCaseImageWhenCurrentImageStatusIsNull()
        {
            const int imageId = 200;
            var f = new CaseImageImporterFixture(Db).WithCaseImages(imageStatus: null);
            var caseImage = Db.Set<CaseImage>().Single(_ => _.CaseId == f.Case.Id);

            f.WithWriterThatUpdates(caseImage.ImageId);
            f.WithWriterThatUpdates(imageId);
            f.WithGeneratedImageId(imageId);

            Assert.Null(Db.Set<Image>().SingleOrDefault(_ => _.Id == imageId));

            await f.Subject.Import(f.NotificationId, f.Case.Id, f.Title);

            Assert.Equal(2, Db.Set<Image>().Count());
            Assert.Equal(f.UpdatedImageData, Db.Set<Image>().Single(_ => _.Id == imageId).ImageData);
            Assert.Equal(new byte[0], Db.Set<Image>().Single(_ => _.Id == caseImage.ImageId).ImageData);
        }

        [Fact]
        public async Task DoesNotAddCaseImageWhenCaseImageWithLowestSequenceIsImportedFromPto()
        {
            var f = new CaseImageImporterFixture(Db).WithCaseImages(3);

            await f.Subject.Import(f.NotificationId, f.Case.Id, f.Title);

            Assert.NotNull(Db.Set<CaseImage>()
                             .Single(ci => ci.CaseId == f.Case.Id && ci.CaseImageDescription == "case image description 1"));
            Assert.Null(Db.Set<CaseImage>()
                          .SingleOrDefault(ci => ci.CaseId == f.Case.Id && ci.CaseImageDescription == f.Title));
            Assert.Equal(3, Db.Set<CaseImage>().Count());
        }

        [Fact]
        public async Task DoesNotAddImageDetailWhenCaseImageWithLowestSequenceIsImportedFromPto()
        {
            var f = new CaseImageImporterFixture(Db).WithCaseImages(3);

            var caseImage =
                Db.Set<CaseImage>().Single(ci => ci.CaseId == f.Case.Id && ci.ImageSequence == 0);

            await f.Subject.Import(f.NotificationId, f.Case.Id, f.Title);

            Assert.NotNull(Db.Set<ImageDetail>()
                             .Single(i => i.ImageId == caseImage.ImageId && i.ImageDescription == "image description 1"));
            Assert.Null(Db.Set<ImageDetail>()
                          .SingleOrDefault(i => i.ImageId == caseImage.ImageId && i.ImageDescription == f.Title));
        }

        [Fact]
        public async Task DoesNotAddImageWhenCaseImageWithLowestSequenceIsImportedFromPto()
        {
            var f = new CaseImageImporterFixture(Db).WithCaseImages(3);

            var caseImage =
                Db.Set<CaseImage>().Single(ci => ci.CaseId == f.Case.Id && ci.ImageSequence == 0);

            f.WithWriterThatUpdates(caseImage.ImageId);

            await f.Subject.Import(f.NotificationId, f.Case.Id, f.Title);

            var result = Db.Set<Image>().Single(_ => _.Id == caseImage.ImageId);
            Assert.Equal(f.UpdatedImageData, result.ImageData);
        }

        [Fact]
        public async Task UpdatesImageDataWhenCaseImageImportedFromPtoIsLowestSequence()
        {
            var f = new CaseImageImporterFixture(Db).WithCaseImages();
            var caseImage = Db.Set<CaseImage>().Single(_ => _.CaseId == f.Case.Id);

            f.WithWriterThatUpdates(caseImage.ImageId);

            Assert.Equal(new byte[0], Db.Set<Image>().Single(_ => _.Id == caseImage.ImageId).ImageData);

            await f.Subject.Import(f.NotificationId, f.Case.Id, f.Title);

            Assert.Equal(1, Db.Set<Image>().Count());
            Assert.Equal(f.UpdatedImageData, Db.Set<Image>().Single(_ => _.Id == caseImage.ImageId).ImageData);
        }

        [Fact]
        public async Task WritesImageDataWhenCaseImageDoesNotExist()
        {
            const int imageId = 101;
            var f = new CaseImageImporterFixture(Db).WithWriterThatUpdates(imageId).WithGeneratedImageId(imageId);

            await f.Subject.Import(f.NotificationId, f.Case.Id, f.Title);

            Assert.Equal(1, Db.Set<Image>().Count());
            Assert.Equal(f.UpdatedImageData, Db.Set<Image>().Single(_ => _.Id == imageId).ImageData);
        }

        [Fact]
        public async Task WritesImageDataWhenCaseImageNotImportedFromPtoIsLowestSequence()
        {
            const int imageId = 200;
            var f = new CaseImageImporterFixture(Db).WithCaseImages(imageStatus: 100);
            var caseImage = Db.Set<CaseImage>().Single(_ => _.CaseId == f.Case.Id);

            f.WithWriterThatUpdates(caseImage.ImageId);
            f.WithWriterThatUpdates(imageId);
            f.WithGeneratedImageId(imageId);

            Assert.Null(Db.Set<Image>().SingleOrDefault(_ => _.Id == imageId));

            await f.Subject.Import(f.NotificationId, f.Case.Id, f.Title);

            Assert.Equal(2, Db.Set<Image>().Count());
            Assert.Equal(f.UpdatedImageData, Db.Set<Image>().Single(_ => _.Id == imageId).ImageData);
            Assert.Equal(new byte[0], Db.Set<Image>().Single(_ => _.Id == caseImage.ImageId).ImageData);
        }
    }

    internal class CaseImageImporterFixture : IFixture<CaseImageImporter>
    {
        readonly InMemoryDbContext _db;
        public readonly int NotificationId = 1;
        public readonly string Title = "title";

        public readonly IEnumerable<byte> UpdatedImageData;
        public IReorderCaseImageSequenceNumbers CaseImageSequenceReorderer = Substitute.For<IReorderCaseImageSequenceNumbers>();
        public IWriteImageFromIntegrationFile IntegrationFileImageWriter = Substitute.For<IWriteImageFromIntegrationFile>();
        public ILastInternalCodeGenerator LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();

        public CaseImageImporterFixture(InMemoryDbContext db)
        {
            _db = db;
            Subject = new CaseImageImporter(db, IntegrationFileImageWriter, LastInternalCodeGenerator,
                                            CaseImageSequenceReorderer);
            Case = new CaseBuilder().Build().In(db);
            LastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Image).Returns(400);
            UpdatedImageData = Encoding.ASCII.GetBytes("updated");
        }

        public Case Case { get; }
        public CaseImageImporter Subject { get; }

        public CaseImageImporterFixture WithCaseImages(int count = 1, int imageType = CaseImageImporter.TradeMarkImageType, string contentType = "image/png", int? imageStatus = CaseImageImporter.ImportedFromPtoStatus)
        {
            foreach (var ci in Enumerable.Range(1, count)
                                         .Select(i => new
                                         {
                                             Index = i,
                                             CaseImage = new CaseImageBuilder {Case = Case, ImageId = 100 + i, ImageSequence = (short) (i - 1), ImageType = imageType}.Build(),
                                             ImageDetail = new ImageDetail(100 + i) {ContentType = contentType, ImageDescription = string.Format("image description {0}", i), ImageStatus = imageStatus}
                                         }))
            {
                ci.CaseImage.CaseImageDescription = string.Format("case image description {0}", ci.Index);
                ci.CaseImage.In(_db);
                ci.ImageDetail.In(_db);
            }

            return this;
        }

        public CaseImageImporterFixture WithWriterThatUpdates(int imageId)
        {
            IntegrationFileImageWriter.When(x => x.Write(NotificationId, imageId)).Do(c =>
            {
                _db.Set<Image>()
                   .Single(i => i.Id == (int) c[1])
                   .ImageData = UpdatedImageData.ToArray();
            });
            return this;
        }

        public CaseImageImporterFixture WithGeneratedImageId(int imageId)
        {
            LastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Image).Returns(imageId);
            return this;
        }
    }
}