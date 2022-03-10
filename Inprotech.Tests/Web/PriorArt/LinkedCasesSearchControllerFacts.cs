using System.Collections.Generic;
using System.IdentityModel.Protocols.WSTrust;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Web.PriorArt;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt
{
    public class LinkedCasesSearchControllerFacts : FactBase
    {
        public class SearchMethod
        {
            [Fact]
            public async Task ShouldCallSubComponent()
            {
                var fixture = new LinkedCasesSearchControllerFixture();
                var componentResponse = new[]
                {
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer()
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer()
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer()
                    }
                };
                fixture.LinkedCaseSearch.Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(componentResponse.AsQueryable());
                var result = await fixture.Subject.Search(new SearchRequest(), new CommonQueryParameters());

                fixture.LinkedCaseSearch
                       .Received().Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>())
                       .IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(3, result.Data.Count());
                Assert.Equal(componentResponse[0].Id, result.Data.ToList()[0].Id);
                Assert.Equal(componentResponse[1].Id, result.Data.ToList()[1].Id);
                Assert.Equal(componentResponse[2].Id, result.Data.ToList()[2].Id);
            }

            [Fact]
            public async Task ShouldReturnOrderedResults()
            {
                var fixture = new LinkedCasesSearchControllerFixture();
                var componentResponse = new[]
                {
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        CaseReference = "abc"
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        CaseReference = "ghi"
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        CaseReference = "def"
                    }
                };
                fixture.LinkedCaseSearch.Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(componentResponse.AsQueryable());
                var result = await fixture.Subject.Search(new SearchRequest(), new CommonQueryParameters { Take = 2, SortBy = "CaseReference" });

                fixture.LinkedCaseSearch
                       .Received().Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>())
                       .IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(2, result.Data.Count());
                Assert.Equal(componentResponse[0].Id, result.Data.ToList()[0].Id);
                Assert.Equal(componentResponse[2].Id, result.Data.ToList()[1].Id);
            }

            [Fact]
            public async Task ShouldReturnPagedResults()
            {
                var fixture = new LinkedCasesSearchControllerFixture();
                var componentResponse = new[]
                {
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer()
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer()
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer()
                    }
                };
                fixture.LinkedCaseSearch.Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(componentResponse.AsQueryable());
                var result = await fixture.Subject.Search(new SearchRequest(), new CommonQueryParameters { Take = 2 });

                fixture.LinkedCaseSearch
                       .Received().Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>())
                       .IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(2, result.Data.Count());
                Assert.Equal(componentResponse[0].Id, result.Data.ToList()[0].Id);
                Assert.Equal(componentResponse[1].Id, result.Data.ToList()[1].Id);
            }
        }

        public class GetFilterDataForColumnMethod
        {
            [Fact]
            public async Task ShouldCallSubComponentAndThrowExceptionWhenColumnIsInvalid()
            {
                var fixture = new LinkedCasesSearchControllerFixture();
                var componentResponse = new[]
                {
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer()
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer()
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer()
                    }
                };
                fixture.LinkedCaseSearch.Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(componentResponse.AsQueryable());

                await Assert.ThrowsAsync<InvalidRequestException>(async () => await fixture.Subject.GetFilterDataForColumn("invalidColumn", new SearchRequest(), new CommonQueryParameters()));
            }

            [Fact]
            public async Task ShouldReturnCaseRefsAndKeys()
            {
                var fixture = new LinkedCasesSearchControllerFixture();
                var componentResponse = new[]
                {
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        CaseReference = "abc",
                        CaseKey = 123
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        CaseKey = 456,
                        CaseReference = "def"
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        CaseReference = "abc",
                        CaseKey = 123
                    }
                };
                fixture.LinkedCaseSearch.Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(componentResponse.AsQueryable());
                var result = (await fixture.Subject.GetFilterDataForColumn("caseReference", new SearchRequest(), new CommonQueryParameters())).ToList();

                fixture.LinkedCaseSearch
                       .Received().Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>())
                       .IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(2, result.Count());
                Assert.Equal(componentResponse[0].CaseReference, result[0].Description);
                Assert.Equal(componentResponse[0].CaseKey.ToString(), result[0].Code);
                Assert.Equal(componentResponse[1].CaseReference, result[1].Description);
                Assert.Equal(componentResponse[1].CaseKey.ToString(), result[1].Code);
            }

            [Fact]
            public async Task ShouldReturnOfficialNumbers()
            {
                var fixture = new LinkedCasesSearchControllerFixture();
                var componentResponse = new[]
                {
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        OfficialNumber = "abc",
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        OfficialNumber = "def"
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        OfficialNumber = "abc"
                    }
                };
                fixture.LinkedCaseSearch.Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(componentResponse.AsQueryable());
                var result = (await fixture.Subject.GetFilterDataForColumn("officialnumber", new SearchRequest(), new CommonQueryParameters())).ToList();

                fixture.LinkedCaseSearch
                       .Received().Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>())
                       .IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(2, result.Count());
                Assert.Equal(componentResponse[0].OfficialNumber, result[0].Description);
                Assert.Equal(componentResponse[0].OfficialNumber, result[0].Code);
                Assert.Equal(componentResponse[1].OfficialNumber, result[1].Description);
                Assert.Equal(componentResponse[1].OfficialNumber, result[1].Code);
            }

            [Fact]
            public async Task ShouldReturnCaseStatusAndCode()
            {
                var fixture = new LinkedCasesSearchControllerFixture();
                var componentResponse = new[]
                {
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        CaseStatus = "abc",
                        CaseStatusCode = 123
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        CaseStatusCode = 456,
                        CaseStatus = "def"
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        CaseStatus = "abc",
                        CaseStatusCode = 123
                    }
                };
                fixture.LinkedCaseSearch.Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(componentResponse.AsQueryable());
                var result = (await fixture.Subject.GetFilterDataForColumn("CaseStatus", new SearchRequest(), new CommonQueryParameters())).ToList();

                fixture.LinkedCaseSearch
                       .Received().Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>())
                       .IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(2, result.Count());
                Assert.Equal(componentResponse[0].CaseStatus, result[0].Description);
                Assert.Equal(componentResponse[0].CaseStatusCode.ToString(), result[0].Code);
                Assert.Equal(componentResponse[1].CaseStatus, result[1].Description);
                Assert.Equal(componentResponse[1].CaseStatusCode.ToString(), result[1].Code);
            }

            [Fact]
            public async Task ShouldReturnFamilyAndCode()
            {
                var fixture = new LinkedCasesSearchControllerFixture();
                var componentResponse = new[]
                {
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        Family = "abc",
                        FamilyCode = "123"
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        FamilyCode = "456",
                        Family = "def"
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        Family = "abc",
                        FamilyCode = "123"
                    }
                };
                fixture.LinkedCaseSearch.Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(componentResponse.AsQueryable());
                var result = (await fixture.Subject.GetFilterDataForColumn("Family", new SearchRequest(), new CommonQueryParameters())).ToList();

                fixture.LinkedCaseSearch
                       .Received().Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>())
                       .IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(2, result.Count());
                Assert.Equal(componentResponse[0].Family, result[0].Description);
                Assert.Equal(componentResponse[0].FamilyCode, result[0].Code);
                Assert.Equal(componentResponse[1].Family, result[1].Description);
                Assert.Equal(componentResponse[1].FamilyCode, result[1].Code);
            }

            [Fact]
            public async Task ShouldReturnPriorArtStatusAndCode()
            {
                var fixture = new LinkedCasesSearchControllerFixture();
                var componentResponse = new[]
                {
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        PriorArtStatus = "abc",
                        PriorArtStatusCode = 123
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        PriorArtStatusCode = 456,
                        PriorArtStatus = "def"
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        PriorArtStatus = "abc",
                        PriorArtStatusCode = 123
                    }
                };
                fixture.LinkedCaseSearch.Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(componentResponse.AsQueryable());
                var result = (await fixture.Subject.GetFilterDataForColumn("PriorArtStatus", new SearchRequest(), new CommonQueryParameters())).ToList();

                fixture.LinkedCaseSearch
                       .Received().Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>())
                       .IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(2, result.Count());
                Assert.Equal(componentResponse[0].PriorArtStatus, result[0].Description);
                Assert.Equal(componentResponse[0].PriorArtStatusCode.ToString(), result[0].Code);
                Assert.Equal(componentResponse[1].PriorArtStatus, result[1].Description);
                Assert.Equal(componentResponse[1].PriorArtStatusCode.ToString(), result[1].Code);
            }

            [Fact]
            public async Task ShouldReturnJurisdictionAndCode()
            {
                var fixture = new LinkedCasesSearchControllerFixture();
                var componentResponse = new[]
                {
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        Jurisdiction = "abc",
                        JurisdictionCode = "123"
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        JurisdictionCode = "456",
                        Jurisdiction = "def"
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        Jurisdiction = "abc",
                        JurisdictionCode = "123"
                    }
                };
                fixture.LinkedCaseSearch.Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(componentResponse.AsQueryable());
                var result = (await fixture.Subject.GetFilterDataForColumn("Jurisdiction", new SearchRequest(), new CommonQueryParameters())).ToList();

                fixture.LinkedCaseSearch
                       .Received().Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>())
                       .IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(2, result.Count());
                Assert.Equal(componentResponse[0].Jurisdiction, result[0].Description);
                Assert.Equal(componentResponse[0].JurisdictionCode, result[0].Code);
                Assert.Equal(componentResponse[1].Jurisdiction, result[1].Description);
                Assert.Equal(componentResponse[1].JurisdictionCode, result[1].Code);
            }

            [Fact]
            public async Task ShouldReturnTrueFalseForRelationship()
            {
                var fixture = new LinkedCasesSearchControllerFixture();
                var result = (await fixture.Subject.GetFilterDataForColumn("relationship", new SearchRequest(), new CommonQueryParameters())).ToList();

                fixture.LinkedCaseSearch
                       .Received().Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>())
                       .IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(2, result.Count());
                Assert.Equal("True", result[0].Description);
                Assert.Equal("True", result[0].Code);
                Assert.Equal("False", result[1].Description);
                Assert.Equal("False", result[1].Code);
            }

            [Fact]
            public async Task ShouldReturnCastList()
            {
                var fixture = new LinkedCasesSearchControllerFixture();
                var componentResponse = new[]
                {
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        CaseLists = new List<string> {"A", "B", "C"},
                        CaseList = "A, B, C"
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        CaseLists = new List<string> {"A", "B"},
                        CaseList = "A, B"
                    },
                    new LinkedCaseModel
                    {
                        Id = Fixture.Integer(),
                        CaseLists = new List<string> {"A"},
                        CaseList = "A"
                    }
                };
                fixture.LinkedCaseSearch.Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(componentResponse.AsQueryable());
                var result = (await fixture.Subject.GetFilterDataForColumn("CaseList", new SearchRequest(), new CommonQueryParameters())).ToList();

                fixture.LinkedCaseSearch
                       .Received().Search(Arg.Any<SearchRequest>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>())
                       .IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(3, result.Count);
                Assert.Equal(componentResponse[0].CaseLists.ToArray()[0], result[0].Code);
                Assert.Equal(componentResponse[0].CaseLists.ToArray()[1], result[1].Code);
                Assert.Equal(componentResponse[0].CaseLists.ToArray()[2], result[2].Code);
            }
        }
        public class LinkedCasesSearchControllerFixture : IFixture<LinkedCasesSearchController>
        {
            public LinkedCasesSearchControllerFixture()
            {
                LinkedCaseSearch = Substitute.For<ILinkedCaseSearch>();
                Subject = new LinkedCasesSearchController(LinkedCaseSearch);
            }

            public ILinkedCaseSearch LinkedCaseSearch { get; set; }
            public LinkedCasesSearchController Subject { get; }
        }
    }
}