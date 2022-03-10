using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseViewImagesControllerFacts
    {
        public class GetPackageFiles : FactBase
        {
            [Fact]
            public void ReturnsCorrectCaseImages()
            {
                var @case = new CaseBuilder().Build();
                var imageType1 = new TableCodeBuilder().For(TableTypes.ImageType).Build().In(Db);
                var imageType2 = new TableCodeBuilder().For(TableTypes.ImageType).Build().In(Db);
                new TableCodeBuilder {TableCode = KnownImageTypes.Attachment}.For(TableTypes.ImageType).Build().In(Db);
                var imageType4 = new TableCodeBuilder().For(TableTypes.ImageType).Build().In(Db);
                var imageType5 = new TableCodeBuilder().For(TableTypes.ImageType).Build().In(Db);
                var de1 = new DesignElement(@case.Id, 1) {FirmElementId = Fixture.String()};
                var de2 = new DesignElement(@case.Id, 2) {FirmElementId = Fixture.String()};
                new CaseImage(@case, 4, 4, imageType4.Id).In(Db);
                var image3 = new CaseImage(@case, 3, 3, KnownImageTypes.Attachment).In(Db);
                new CaseImage(@case, 2, 2, imageType2.Id).In(Db);
                var image5 = new CaseImage(@case, 5, 5, imageType5.Id).In(Db);
                var image1 = new CaseImage(@case, 1, 1, imageType1.Id).In(Db);
                image1.FirmElementId = de1.FirmElementId;
                image5.FirmElementId = de2.FirmElementId;
                
                var s = new CaseViewEfilingControllerFixture(Db);

                IEnumerable<dynamic> result = s.Subject.GetCaseImages(@case.Id);

                Assert.Equal(4, result.Count());
                Assert.Equal(result.First().ImageKey, image1.ImageId);
                Assert.Equal(result.Last().ImageKey, image5.ImageId);
                Assert.DoesNotContain(result, v => v.ImageKey == image3.ImageId);
                Assert.Equal(result.First().FirmElementId, image1.FirmElementId);
                Assert.Equal(result.Last().FirmElementId, image5.FirmElementId);
            }
        }

        public class CaseViewEfilingControllerFixture : IFixture<CaseViewImagesController>
        {
            public CaseViewImagesController Subject { get; set; }

            public CaseViewEfilingControllerFixture(InMemoryDbContext db)
            {
                Subject = new CaseViewImagesController(db);
            }
        }
    }
}
