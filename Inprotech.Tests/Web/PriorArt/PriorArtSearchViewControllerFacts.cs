using System.Net;
using System.Web;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.PriorArt;
using Inprotech.Web.PriorArt;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt
{
    public class PriorArtSearchViewControllerFacts : FactBase
    {
        PriorArtSearchViewController CreateSubject()
        {
            return new PriorArtSearchViewController(Db);
        }

        [Fact]
        public void RequiresMaintainPriorArtCreatePermission()
        {
            var r = TaskSecurity.Secures<PriorArtSearchViewController>(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Create);
            Assert.True(r);
        }

        [Fact]
        public void ReturnsEmptyPriorArtSearchModelWithoutParameters()
        {
            var subject = CreateSubject();

            var r = (PriorArtSearchViewModel) subject.Get();

            Assert.Null(r.CaseKey);

            Assert.Null(r.SourceDocumentData);
        }

        [Fact]
        public void ReturnsModelWithCase()
        {
            var @case = new CaseBuilder().Build().In(Db);

            var subject = CreateSubject();

            var r = (PriorArtSearchViewModel) subject.Get(caseKey: @case.Id);

            Assert.Equal(@case.Id, r.CaseKey);
        }

        [Fact]
        public void ReturnsModelWithSourceDocumentData()
        {
            var source = new PriorArtBuilder().BuildSourceDocument().In(Db);

            var subject = CreateSubject();

            var r = (PriorArtSearchViewModel) subject.Get(source.Id);

            Assert.NotNull(r.SourceDocumentData);

            Assert.Equal(source.Id, r.SourceDocumentData.SourceId);
            Assert.Equal(source.SourceType.Name, r.SourceDocumentData.SourceType.Name);
        }

        [Fact]
        public void ThrowsBadRequestIfSourceProvidedNotASourceDocument()
        {
            var source = new InprotechKaizen.Model.PriorArt.PriorArt
            {
                IsSourceDocument = false
            }.In(Db);

            var subject = CreateSubject();

            var exception = Assert.Throws<HttpException>(() => subject.Get(source.Id));

            Assert.Equal((int) HttpStatusCode.BadRequest, exception.GetHttpCode());
            Assert.Equal("Not a source document.", exception.Message);
        }

        [Fact]
        public void ThrowsNotFoundIfSourceProvidedDoNotExist()
        {
            var subject = CreateSubject();

            var exception = Assert.Throws<HttpException>(() => subject.Get(Fixture.Integer()));

            Assert.Equal((int) HttpStatusCode.NotFound, exception.GetHttpCode());
            Assert.Equal("Source not found.", exception.Message);
        }
    }
}