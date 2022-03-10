using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class WipTemplatePicklistControllerFacts : FactBase
    {
        public class FilterDataMethod : FactBase
        {
            [Fact]
            public async Task ReturnsDistinctWipTypeFilter()
            {
                var f = new WipTemplatePicklistControllerFixture();

                f.WipTemplateMatcher
                 .Get(Arg.Any<string>())
                 .Returns(new []
                 {
                     new WipTemplatePicklistItem
                     {
                         TypeId = "abc"
                     },
                     new WipTemplatePicklistItem
                     {
                         TypeId = "xyz"
                     },
                     new WipTemplatePicklistItem
                     {
                         TypeId = "xyz"
                     },
                     new WipTemplatePicklistItem
                     {
                         TypeId = null
                     }
                 });

                var r = await f.Subject.GetFilterDataForColumn(Fixture.String());
                Assert.Equal(3, r.ToArray().Length);
            }
        }

        public class SearchMethod : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task CallsWipTemplateMatcherCorrectly(bool withCase)
            {
                var search = Fixture.String();
                var caseId = Fixture.Integer();
                var f = new WipTemplatePicklistControllerFixture();

                f.WipTemplateMatcher.Get(Arg.Any<string>(), true, Arg.Any<int>())
                 .Returns(new List<WipTemplatePicklistItem>());

                await f.Subject.Search(null, search, true, withCase ? (int?)caseId : null);
                await f.WipTemplateMatcher.Received(1).Get(search, true, withCase ? (int?)caseId : null);
            }
        }
    }

    public class WipTemplatePicklistControllerFixture : IFixture<WipTemplatePicklistController>
    {
        public WipTemplatePicklistControllerFixture()
        {
            WipTemplateMatcher = Substitute.For<IWipTemplateMatcher>();
            CommonQueryService = Substitute.For<ICommonQueryService>();
            CommonQueryParameters = CommonQueryParameters.Default;
            Subject = new WipTemplatePicklistController(CommonQueryService, WipTemplateMatcher);
        }

        public IWipTemplateMatcher WipTemplateMatcher { get; set; }
        public ICommonQueryService CommonQueryService { get; set; }
        public CommonQueryParameters CommonQueryParameters { get; set; }
        public WipTemplatePicklistController Subject { get; }
    }
}