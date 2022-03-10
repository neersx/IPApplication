using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Accounting.Work;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Work
{
    public class WipWarningCheckFacts : FactBase
    {
        public class WipWarningCheckFixture : IFixture<WipWarningCheck>
        {
            public WipWarningCheckFixture(InMemoryDbContext db)
            {
                WipWarnings = Substitute.For<IWipWarnings>();
                Subject = new WipWarningCheck(WipWarnings);
            }

            public IWipWarnings WipWarnings { get; set; }
            public WipWarningCheck Subject { get; }
        }

        [Fact]
        public async Task ReturnsTrueIfCaseIsValid()
        {
            var f = new WipWarningCheckFixture(Db);
            f.WipWarnings.AllowWipFor(Arg.Any<int>()).Returns(true);
            f.WipWarnings.HasDebtorRestriction(Arg.Any<int>()).Returns(false);
            Assert.True(await f.Subject.For(Fixture.Integer(), null));
        }

        [Fact]
        public async Task ReturnsTrueIfNameIsValid()
        {
            var f = new WipWarningCheckFixture(Db);
            f.WipWarnings.AllowWipFor(Arg.Any<int>()).Returns(false);
            f.WipWarnings.HasDebtorRestriction(Arg.Any<int>()).Returns(true);
            f.WipWarnings.HasNameRestriction(Arg.Any<int>()).Returns(false);
            Assert.True(await f.Subject.For(null, Fixture.Integer()));
        }

        [Fact]
        public async Task ThrowsExceptionIfCaseNameIsRestricted()
        {
            var caseKey = Fixture.Integer();
            var f = new WipWarningCheckFixture(Db);
            f.WipWarnings.AllowWipFor(caseKey).Returns(false);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.For(caseKey, null));
            Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
        }

        [Fact]
        public async Task ThrowsExceptionIfCaseStatusIsRestricted()
        {
            var caseKey = Fixture.Integer();
            var f = new WipWarningCheckFixture(Db);
            f.WipWarnings.AllowWipFor(caseKey).Returns(false);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.For(caseKey, null));
            Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
        }

        [Fact]
        public async Task ThrowsExceptionIfNameForDebtorOnlyEntryIsRestricted()
        {
            var nameKey = Fixture.Integer();
            var f = new WipWarningCheckFixture(Db);
            f.WipWarnings.HasNameRestriction(nameKey).Returns(true);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.For(null, nameKey));
            Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
        }
    }
}