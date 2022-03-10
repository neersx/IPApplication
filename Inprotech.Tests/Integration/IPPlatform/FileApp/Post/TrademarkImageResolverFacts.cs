using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.IPPlatform.FileApp.Post;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp.Post
{
    public class TrademarkImageResolverFacts : FactBase
    {
        readonly ISiteControlReader _siteControlReader = Substitute.For<ISiteControlReader>();
        readonly int _defaultImageType = Fixture.Integer();

        [Fact]
        public async Task ResolvesDefaultTrademarkImageFromCase()
        {
            var @case = new CaseBuilder().Build().In(Db);

            var caseImage = new CaseImageBuilder
                            {
                                Case = @case,
                                ImageType = _defaultImageType
                            }
                            .WithImageDetail("image/png", Fixture.String())
                            .Build().In(Db);

            caseImage.Image.In(Db);
            caseImage.Image.Detail.In(Db);

            _siteControlReader.Read<string>(SiteControls.FILETMImageType)
                              .Returns(_defaultImageType.ToString());

            var r = await new TrademarkImageResolver(Db, _siteControlReader).Resolve(@case.Id);

            Assert.Equal(@case.Id, r.CaseId);
            Assert.Equal(@case.Irn, r.CaseReference);
            Assert.Equal(caseImage.Image.Detail.ContentType, r.ContentType);
            Assert.Equal(caseImage.CaseImageDescription, r.ImageDescription);
        }

        [Fact]
        public async Task ReturnsFirstImageBasedOnConfiguredTypeOrder()
        {
            var imageTypeOrder = new[]
            {
                Fixture.Integer(),
                Fixture.Integer(),
                _defaultImageType,
                Fixture.Integer()
            };

            var @case = new CaseBuilder().Build().In(Db);

            var caseImage1 = new CaseImageBuilder
                             {
                                 Case = @case,
                                 ImageType = imageTypeOrder.ElementAt(2),
                                 ImageSequence = 1
                             }
                             .WithImageDetail("image/png", Fixture.String())
                             .Build().In(Db);

            caseImage1.Image.In(Db);
            caseImage1.Image.Detail.In(Db);

            var caseImage2 = new CaseImageBuilder
                             {
                                 Case = @case,
                                 ImageType = imageTypeOrder.ElementAt(3),
                                 ImageSequence = 1
                             }
                             .WithImageDetail("image/png", Fixture.String())
                             .Build().In(Db);

            caseImage2.Image.In(Db);
            caseImage2.Image.Detail.In(Db);

            _siteControlReader.Read<string>(SiteControls.FILETMImageType)
                              .Returns(string.Join(",", imageTypeOrder.Select(_ => _.ToString())));

            var r = await new TrademarkImageResolver(Db, _siteControlReader).Resolve(@case.Id);

            // caseImage2 has lower image type priority

            Assert.Equal(@case.Id, r.CaseId);
            Assert.Equal(@case.Irn, r.CaseReference);
            Assert.Equal(caseImage1.Image.Detail.ContentType, r.ContentType);
            Assert.Equal(caseImage1.CaseImageDescription, r.ImageDescription);
        }

        [Fact]
        public async Task ReturnsFirstImageIfMultipleImageMatchingThePreferredImageType()
        {
            var @case = new CaseBuilder().Build().In(Db);

            var caseImage1 = new CaseImageBuilder
                             {
                                 Case = @case,
                                 ImageType = _defaultImageType,
                                 ImageSequence = 1
                             }
                             .WithImageDetail("image/png", Fixture.String())
                             .Build().In(Db);

            caseImage1.Image.In(Db);
            caseImage1.Image.Detail.In(Db);

            var caseImage2 = new CaseImageBuilder
                             {
                                 Case = @case,
                                 ImageType = _defaultImageType,
                                 ImageSequence = 0
                             }
                             .WithImageDetail("image/png", Fixture.String())
                             .Build().In(Db);

            caseImage2.Image.In(Db);
            caseImage2.Image.Detail.In(Db);

            _siteControlReader.Read<string>(SiteControls.FILETMImageType)
                              .Returns(_defaultImageType.ToString());

            var r = await new TrademarkImageResolver(Db, _siteControlReader).Resolve(@case.Id);

            // caseImage2 has lower image sequence

            Assert.Equal(@case.Id, r.CaseId);
            Assert.Equal(@case.Irn, r.CaseReference);
            Assert.Equal(caseImage2.Image.Detail.ContentType, r.ContentType);
            Assert.Equal(caseImage2.CaseImageDescription, r.ImageDescription);
        }

        [Fact]
        public async Task ReturnsNullWhenCaseDoesNotHaveConfiguredImageType()
        {
            var @case = new CaseBuilder().Build().In(Db);

            var caseImage = new CaseImageBuilder
                            {
                                Case = @case,
                                ImageType = Fixture.Integer()
                            }
                            .WithImageDetail("image/png", Fixture.String())
                            .Build().In(Db);

            caseImage.Image.In(Db);
            caseImage.Image.Detail.In(Db);

            _siteControlReader.Read<string>(SiteControls.FILETMImageType)
                              .Returns(_defaultImageType.ToString());

            var r = await new TrademarkImageResolver(Db, _siteControlReader).Resolve(@case.Id);

            Assert.Null(r);
        }
    }
}