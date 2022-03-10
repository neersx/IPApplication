using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Search.Case;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using System.Linq;
using Xunit;
using CaseListItem = InprotechKaizen.Model.Components.Cases.Search.CaseListItem;

namespace Inprotech.Tests.Web.Picklists
{
    public class CasesPicklistControllerFacts : FactBase
    {
        public class CasesMethod : FactBase
        {
            [Fact]
            public void PassesCorrectQueryParameters()
            {
                var f = new CasesPicklistControllerFixture();
                var qParams = new CommonQueryParameters {SortBy = Fixture.String(), SortDir = Fixture.String(), Skip = Fixture.Integer(), Take = Fixture.Integer()};
                var searchString = Fixture.String();
                var searchFilter = new CaseSearchFilter();
                int rowCount;
                f.Subject.Cases(qParams, searchString, null, searchFilter);
                f.ListCase.Received(1)
                 .Get(out rowCount, searchString, qParams.SortBy, qParams.SortDir, qParams.Skip, qParams.Take, null, null, searchFilter);
            }

            [Fact]
            public void ReturnsRowCountWithCaseDetails()
            {
                var f = new CasesPicklistControllerFixture();
                var rc = Fixture.Integer();
                var cli = new CaseListItem
                {
                    Id = Fixture.Integer(),
                    CaseRef = Fixture.String(),
                    CountryName = Fixture.String(),
                    OfficialNumber = Fixture.String(),
                    PropertyTypeDescription = Fixture.String(),
                    Title = Fixture.String()
                };

                f.ListCase.Get(out rc, Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<bool?>(), Arg.Any<CaseSearchFilter>())
                 .ReturnsForAnyArgs(_ =>
                 {
                     _[0] = rc;
                     return new[] {cli};
                 });

                var result = f.Subject.Cases();
                var @case = (Case) result.Data.Single();

                Assert.Equal(rc, result.Pagination.Total);
                Assert.Equal(@case.Key, cli.Id);
                Assert.Equal(@case.Code, cli.CaseRef);
                Assert.Equal(@case.CountryName, cli.CountryName);
                Assert.Equal(@case.OfficialNumber, cli.OfficialNumber);
                Assert.Equal(@case.PropertyTypeDescription, cli.PropertyTypeDescription);
                Assert.Equal(@case.Value, cli.Title);
            }
        }
    }

    public class CasesPicklistControllerFixture : IFixture<CasesPicklistController>
    {
        public CasesPicklistControllerFixture()
        {
            ListCase = Substitute.For<IListCase>();

            Subject = new CasesPicklistController(ListCase);
        }

        public IListCase ListCase { get; set; }

        public CasesPicklistController Subject { get; }
    }
}