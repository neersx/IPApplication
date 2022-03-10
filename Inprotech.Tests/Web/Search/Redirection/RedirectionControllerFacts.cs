using System;
using Inprotech.Infrastructure.Legacy;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Search.Redirection;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Redirection
{
    public class RedirectionControllerFacts : FactBase
    {
        readonly IDataService _dataService = Substitute.For<IDataService>();

        [Fact]
        public void RedirectsToCasesWithIrn()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var linkData = $"%7BcaseKey%3A{@case.Id}%7D";

            _dataService.GetParentUri(Arg.Any<string>()).ReturnsForAnyArgs(new Uri("http://www.someplace.com/TheUrl"));
            var result = new RedirectionController(Db, _dataService).RouteToOldInprotechWeb(linkData);

            Assert.Equal("http://www.someplace.com/TheUrl", result.Location.AbsoluteUri);
            _dataService.Received(1).GetParentUri("?caseref=" + @case.Irn);
        }

        [Fact]
        public void RedirectsToNamesWithNameKey()
        {
            var nameKey = Fixture.Integer();
            var linkData = $"%7BnameKey_IIIII_%3A{nameKey}%7D";

            _dataService.GetParentUri(Arg.Any<string>()).ReturnsForAnyArgs(new Uri("http://www.someplace.com/TheUrl"));
            var result = new RedirectionController(Db, _dataService).RouteToOldInprotechWeb(linkData);

            Assert.Equal("http://www.someplace.com/TheUrl", result.Location.AbsoluteUri);
            _dataService.Received(1).GetParentUri("?nameid=" + nameKey);
        }
    }
}