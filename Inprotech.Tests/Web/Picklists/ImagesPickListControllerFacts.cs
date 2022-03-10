using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class ImagesPickListControllerFacts : FactBase
    {
        public class SearchMethod : FactBase
        {
            public class ImagesPickListControllerFixture : IFixture<ImagesPickListController>
            {
                public ImagesPickListControllerFixture(InMemoryDbContext db)
                {
                    PreferredCulture = Substitute.For<IPreferredCultureResolver>();
                    Subject = new ImagesPickListController(db, PreferredCulture);
                }

                IPreferredCultureResolver PreferredCulture { get; }
                public ImagesPickListController Subject { get; }
            }

            public dynamic Images()
            {
                var image1 = new ImageDetail
                {
                    ImageId = new Image(Fixture.Integer()) { ImageData = Fixture.RandomBytes(1) }.In(Db).Id,
                    ImageDescription = Fixture.String("balls32"),
                    ImageStatus = 1
                }.In(Db);

                var image2 = new ImageDetail
                {
                    ImageId = new Image(Fixture.Integer()) { ImageData = Fixture.RandomBytes(1) }.In(Db).Id,
                    ImageDescription = Fixture.String("balls31"),
                    ImageStatus = ProtectedTableCode.EventCategoryImageStatus
                }.In(Db);

                var image3 = new ImageDetail
                {
                    ImageId = new Image(Fixture.Integer()) { ImageData = Fixture.RandomBytes(1) }.In(Db).Id,
                    ImageDescription = @"balls3",
                    ImageStatus = ProtectedTableCode.EventCategoryImageStatus
                }.In(Db);

                return new { image1, image2, image3 };
            }

            [Fact]
            public void ReturnsAllImages()
            {
                Images();
                var queryParams = new CommonQueryParameters { SortBy = null, SortDir = null };
                var f = new ImagesPickListControllerFixture(Db);
                var s = f.Subject;

                var results = s.Search(queryParams, null);

                Assert.Equal(3, results.Data.Count());
            }

            [Fact]
            public void ReturnsExactMatchFirstResultsAndDefaultSort()
            {
                var image = Images();
                var queryParams = new CommonQueryParameters { SortBy = null, SortDir = null };
                var f = new ImagesPickListControllerFixture(Db);
                var s = f.Subject;

                PagedResults<ImageModel> results = s.Search(queryParams, image.image3.ImageDescription);
                var data = results.Data.ToArray();

                Assert.Equal(3, data.Length);
                Assert.Equal(image.image3.ImageDescription, data[0].Description);
                Assert.Equal(image.image2.ImageDescription, data[1].Description);
                Assert.Equal(image.image1.ImageDescription, data[2].Description);
            }

            [Fact]
            public void ReturnsResultWithDescSortOrder()
            {
                var image = Images();

                var qp = CommonQueryParameters.Default;
                var queryParams = new CommonQueryParameters { SortBy = "Description", SortDir = "desc" };
                qp.SortDir = "desc";
                var f = new ImagesPickListControllerFixture(Db);
                var s = f.Subject;

                var results = s.Search(queryParams, image.image3.ImageDescription);
                var data = results.Data;

                Assert.Equal(3, data.Length);
                Assert.Equal(image.image1.ImageDescription, data[0].Description);
                Assert.Equal(image.image2.ImageDescription, data[1].Description);
                Assert.Equal(image.image3.ImageDescription, data[2].Description);
            }

            [Fact]
            public void ReturnsImagesMatchingStatus()
            {
                Images();
                var queryParams = new CommonQueryParameters { SortBy = null, SortDir = null };
                var f = new ImagesPickListControllerFixture(Db);
                var s = f.Subject;

                var results = s.Search(queryParams, null, true);

                Assert.Equal(2, results.Data.Count());
            }
        }
    }
}