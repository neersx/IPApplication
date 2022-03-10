using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Configuration.ValidCombinations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.ValidCombinations
{
    public class ValidActionsControllerFacts
    {
        public class ValidActionsControllerFixture : IFixture<ValidActionsController>
        {
            readonly InMemoryDbContext _db;

            public ValidActionsControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                ValidActions = Substitute.For<IValidActions>();

                Exporter = Substitute.For<ISimpleExcelExporter>();

                Subject = new ValidActionsController(_db, ValidActions, Exporter);
            }

            public IValidActions ValidActions { get; }
            public ISimpleExcelExporter Exporter { get; }

            public ValidActionsController Subject { get; }

            public dynamic SetupActions()
            {
                var validAction1 = new ValidActionBuilder
                    {
                        Country = new CountryBuilder {Id = "NZ", Name = "New Zealand"}.Build().In(_db),
                        PropertyType = new PropertyTypeBuilder {Id = "T", Name = "TradeMark"}.Build().In(_db),
                        CaseType = new CaseTypeBuilder {Id = "I", Name = "Internal"}.Build().In(_db),
                        Action = new ActionBuilder {Id = "~1", Name = "Filing"}.Build().In(_db),
                        Sequence = 0
                    }.Build()
                     .In(_db);

                var validAction2 = new ValidActionBuilder
                    {
                        Country = new CountryBuilder {Id = "GB", Name = "United Kingdom"}.Build().In(_db),
                        PropertyType = new PropertyTypeBuilder {Id = "P", Name = "Patent"}.Build().In(_db),
                        CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build().In(_db),
                        Action = new ActionBuilder {Id = "~2", Name = "Overview"}.Build().In(_db),
                        Sequence = 1
                    }.Build()
                     .In(_db);

                var validAction3 = new ValidActionBuilder
                    {
                        Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build().In(_db),
                        PropertyType = new PropertyTypeBuilder {Id = "D", Name = "Design"}.Build().In(_db),
                        CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build().In(_db),
                        Action = new ActionBuilder {Id = "~3", Name = "Examination"}.Build().In(_db),
                        Sequence = 3
                    }.Build()
                     .In(_db);

                new ValidActionBuilder
                    {
                        Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build().In(_db),
                        PropertyType = new PropertyTypeBuilder {Id = "ND", Name = "Domain Name"}.Build().In(_db),
                        CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build().In(_db),
                        Action = new ActionBuilder {Id = "~4", Name = "Preview"}.Build().In(_db),
                        Sequence = 4
                    }.Build()
                     .In(_db);

                new ValidActionBuilder
                    {
                        Country = new CountryBuilder {Id = "IN", Name = "India"}.Build().In(_db),
                        PropertyType = new PropertyTypeBuilder {Id = "D", Name = "Design"}.Build().In(_db),
                        CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build().In(_db),
                        Action = new ActionBuilder {Id = "~3", Name = "Examination"}.Build().In(_db),
                        Sequence = 5
                    }.Build()
                     .In(_db);

                new CountryBuilder {Id = "FR", Name = "France"}.Build().In(_db);
                new CountryBuilder {Id = "IT", Name = "Italy"}.Build().In(_db);
                new ValidProperty {CountryId = "NZ", PropertyTypeId = "T", PropertyName = "Valid Property"}.In(_db);

                return new
                {
                    validAction1,
                    validAction2,
                    validAction3
                };
            }
        }

        public class GetPagedResultsMethod : FactBase
        {
            [Fact]
            public void OrdersByDescription()
            {
                var f = new ValidActionsControllerFixture(Db);
                f.SetupActions();

                var result = f.Subject.GetPagedResults(Db.Set<ValidAction>(),
                                                       new CommonQueryParameters {SortBy = "PropertyType", SortDir = "asc", Skip = 0, Take = 10});

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(5, results.Length);
                Assert.Equal(Db.Set<ValidAction>().OrderBy(c => c.PropertyType.Name).First().ActionName, results[0].Action);
            }

            [Fact]
            public void SkipsAndTakes()
            {
                var f = new ValidActionsControllerFixture(Db);
                for (var i = 0; i < 10; i++) new ValidActionBuilder {Action = new ActionBuilder {Id = i.ToString(CultureInfo.InvariantCulture), Name = Fixture.String("Name" + i)}.Build()}.Build().In(Db);

                var result = f.Subject.GetPagedResults(Db.Set<ValidAction>(),
                                                       new CommonQueryParameters {SortBy = "Action", SortDir = "asc", Skip = 3, Take = 7});
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(7, results.Length);
                Assert.Equal(Db.Set<ValidAction>().First(_ => _.ActionId == "3").Action.Name, results[0].Action);
            }
        }

        public class SearchValidAction : FactBase
        {
            [Fact]
            public void SearchAllActions()
            {
                var f = new ValidActionsControllerFixture(Db);
                f.SetupActions();
                var searchCriteria = new ValidCombinationSearchCriteria();

                var result = f.Subject.SearchValidAction(searchCriteria);
                Assert.Equal(5, result.Count());
            }

            [Fact]
            public void SearchBasedOnAction()
            {
                var f = new ValidActionsControllerFixture(Db);
                f.SetupActions();
                var searchCriteria = new ValidCombinationSearchCriteria {Action = "~2"};

                var result = f.Subject.SearchValidAction(searchCriteria);
                var filteredAction = Db.Set<ValidAction>().Where(c => c.ActionId == "~2");
                Assert.Equal(filteredAction.Count(), result.Count());
                Assert.Contains(filteredAction.FirstOrDefault(), result);
            }

            [Fact]
            public void SearchBasedOnAllFilter()
            {
                var f = new ValidActionsControllerFixture(Db);
                f.SetupActions();
                var searchCriteria = new ValidCombinationSearchCriteria
                {
                    PropertyType = "D",
                    CaseType = "P",
                    Action = "~3",
                    Jurisdictions = new List<string> {"US"}
                };

                var result = f.Subject.SearchValidAction(searchCriteria);

                var filteredAction =
                    Db.Set<ValidAction>()
                      .Where(c => c.PropertyType.Code == "D" && c.CaseType.Code == "P" && c.Country.Id == "US" && c.Action.Code == "~3");

                Assert.Equal(filteredAction.Count(), result.Count());
                Assert.Contains(filteredAction.FirstOrDefault(), result);
            }

            [Fact]
            public void SearchBasedOnCaseType()
            {
                var f = new ValidActionsControllerFixture(Db);
                f.SetupActions();
                var searchCriteria = new ValidCombinationSearchCriteria {CaseType = "I"};

                var result = f.Subject.SearchValidAction(searchCriteria);
                var filteredAction = Db.Set<ValidAction>().Where(c => c.CaseTypeId == "I");
                Assert.Equal(filteredAction.Count(), result.Count());
                Assert.Contains(filteredAction.FirstOrDefault(), result);
            }

            [Fact]
            public void SearchBasedOnMultipleCountries()
            {
                var f = new ValidActionsControllerFixture(Db);
                f.SetupActions();
                var searchCriteria = new ValidCombinationSearchCriteria {Jurisdictions = new List<string> {"GB", "US"}};

                var result = f.Subject.SearchValidAction(searchCriteria);
                var filteredActions = Db.Set<ValidAction>().Where(c => c.Country.Id == "GB" || c.Country.Id == "US");

                Assert.Equal(filteredActions.Count(), result.Count());

                foreach (var validAction in filteredActions) Assert.Contains(validAction, result);
            }

            [Fact]
            public void SearchBasedOnProperty()
            {
                var f = new ValidActionsControllerFixture(Db);
                f.SetupActions();
                var searchCriteria = new ValidCombinationSearchCriteria {PropertyType = "P"};

                var result = f.Subject.SearchValidAction(searchCriteria);
                var filteredAction = Db.Set<ValidAction>().Where(c => c.PropertyTypeId == "P");
                Assert.Equal(filteredAction.Count(), result.Count());
                Assert.Contains(filteredAction.FirstOrDefault(), result);
            }
        }

        public class SearchMethod : FactBase
        {
            [Fact]
            public void ShouldReturnSearchInCorrectOrder()
            {
                var filter = new ValidCombinationSearchCriteria();
                var f = new ValidActionsControllerFixture(Db);
                f.SetupActions();

                var result = f.Subject.Search(filter);
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();
                Assert.Equal(5, results.Length);
                Assert.Equal(Db.Set<ValidAction>().OrderBy(c => c.Country.Name).First().Action.Name, results[0].Action);
            }
        }

        public class ValidActionsMethod : FactBase
        {
            [Fact]
            public void ReturnsValidActionsInAscendingOrderOfDisplaySequence()
            {
                var f = new ValidActionsControllerFixture(Db);
                f.SetupActions();

                new ValidActionBuilder
                    {
                        Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build().In(Db),
                        PropertyType = new PropertyTypeBuilder {Id = "D", Name = "Design"}.Build().In(Db),
                        CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build().In(Db),
                        Action = new ActionBuilder {Id = "EF", Name = "Electronic Filing"}.Build().In(Db),
                        Sequence = 10
                    }.Build()
                     .In(Db);

                var result = f.Subject.ValidActions(new ValidActionsController.ActionOrderCriteria
                {
                    Jurisdiction = "US",
                    PropertyType = "D",
                    CaseType = "P"
                });
                Assert.Equal(2, result.ValidActions.Count());
                Assert.Equal("~3", result.ValidActions.First().Code);
                Assert.Equal("EF", result.ValidActions.Last().Code);
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenNoActionOrderCriteria()
            {
                var f = new ValidActionsControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.ValidActions(null));

                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public void ThrowsHttpResponseExceptionWhenAnyActionOrderCriteriaIsMissing()
            {
                var f = new ValidActionsControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.ValidActions(new ValidActionsController.ActionOrderCriteria
                    {
                        CaseType = "A",
                        PropertyType = string.Empty,
                        Jurisdiction = "AU"
                    }));

                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ThrowsExceptionWhenValidPropertyNotFoundForGivenCountryAndPropertyCode()
            {
                var f = new ValidActionsControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.ValidAction(new ValidActionIdentifier("XXX", "YYY", "AAA", "DDD")));

                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void CallsValidActionsave()
            {
                var f = new ValidActionsControllerFixture(Db);

                var model = new ActionSaveDetails();

                var returnValue = new object();
                f.ValidActions.Save(model).Returns(returnValue);

                f.Subject.Save(model);

                f.ValidActions.ReceivedWithAnyArgs().Save(model);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsValidActionUpdate()
            {
                var f = new ValidActionsControllerFixture(Db);

                var model = new ActionSaveDetails();

                var returnValue = new object();
                f.ValidActions.Update(model).Returns(returnValue);

                f.Subject.Update(model);

                f.ValidActions.ReceivedWithAnyArgs().Update(model);
            }

            [Fact]
            public void ThrowsExceptionWhenResponseIsNullForUpdate()
            {
                var f = new ValidActionsControllerFixture(Db);

                var model = new ActionSaveDetails();
                f.ValidActions.Update(Arg.Any<ActionSaveDetails>()).Returns(null as object);

                var exception =
                    Record.Exception(() => f.Subject.Update(model));

                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CallsActionsDelete()
            {
                var f = new ValidActionsControllerFixture(Db);

                var model = new ValidActionIdentifier[] { };

                var returnValue = new DeleteResponseModel<ValidActionIdentifier>();
                f.ValidActions.Delete(Arg.Any<ValidActionIdentifier[]>()).Returns(returnValue);

                f.Subject.Delete(model);

                f.ValidActions.ReceivedWithAnyArgs().Delete(Arg.Any<ValidActionIdentifier[]>());
            }

            [Fact]
            public void ThrowsExceptionWhenResponseIsNullForDelete()
            {
                var f = new ValidActionsControllerFixture(Db);

                var model = new ValidActionIdentifier[] { };

                f.ValidActions.Delete(Arg.Any<ValidActionIdentifier[]>()).Returns(null as DeleteResponseModel<ValidActionIdentifier>);

                var exception =
                    Record.Exception(() => f.Subject.Delete(model));

                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class UpdateActionSequenceMethod : FactBase
        {
            [Fact]
            public void ThrowsArgumentNullExceptionWhenSaveDetailsIsPassedAsNull()
            {
                var f = new ValidActionsControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.UpdateActionSequence(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("saveDetails", exception.Message);
            }

            [Fact]
            public void ThrowsHttpResponseExceptionWhenOrderCriteriaIsMissing()
            {
                var f = new ValidActionsControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.UpdateActionSequence(new ValidActionsController.ValidActionsOrderResponse
                    {
                        OrderCriteria = new ValidActionsController.ActionOrderCriteria
                        {
                            CaseType = "A",
                            PropertyType = string.Empty,
                            Jurisdiction = "AU"
                        },
                        ValidActions = new[] {new ValidActionsController.ValidActionsOrder {Code = "A", DisplaySequence = 1}}
                    }));

                Assert.IsType<HttpResponseException>(exception);
            }

            [Fact]
            public void ThrowsHttpResponseExceptionWhenRecordCountDoNotMatch()
            {
                var f = new ValidActionsControllerFixture(Db);
                f.SetupActions();

                var exception =
                    Record.Exception(() => f.Subject.UpdateActionSequence(new ValidActionsController.ValidActionsOrderResponse
                    {
                        OrderCriteria = new ValidActionsController.ActionOrderCriteria
                        {
                            CaseType = "P",
                            PropertyType = "D",
                            Jurisdiction = "US"
                        },
                        ValidActions = new[]
                        {
                            new ValidActionsController.ValidActionsOrder {Code = "~6", DisplaySequence = 1, Id = new ValidActionIdentifier("US", "D", "P", "~6")},
                            new ValidActionsController.ValidActionsOrder {Code = "~3", DisplaySequence = 2, Id = new ValidActionIdentifier("US", "D", "P", "~3")}
                        }
                    }));

                Assert.IsType<HttpResponseException>(exception);
            }

            [Fact]
            public void ThrowsHttpResponseExceptionWhenValidActionsIsNull()
            {
                var f = new ValidActionsControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.UpdateActionSequence(new ValidActionsController.ValidActionsOrderResponse
                    {
                        OrderCriteria = new ValidActionsController.ActionOrderCriteria
                        {
                            CaseType = "A",
                            PropertyType = "T",
                            Jurisdiction = "AU"
                        },
                        ValidActions = null
                    }));

                Assert.IsType<HttpResponseException>(exception);
            }

            [Fact]
            public void UpdateActionSequenceForValidAction()
            {
                var f = new ValidActionsControllerFixture(Db);
                f.SetupActions();

                new ValidActionBuilder
                    {
                        Country = new CountryBuilder {Id = "US", Name = "United States of America"}.Build().In(Db),
                        PropertyType = new PropertyTypeBuilder {Id = "D", Name = "Design"}.Build().In(Db),
                        CaseType = new CaseTypeBuilder {Id = "P", Name = "Properties"}.Build().In(Db),
                        Action = new ActionBuilder {Id = "~6", Name = "Renewal Examination"}.Build().In(Db),
                        Sequence = 6
                    }.Build()
                     .In(Db);

                var result = f.Subject.UpdateActionSequence(new ValidActionsController.ValidActionsOrderResponse
                {
                    OrderCriteria = new ValidActionsController.ActionOrderCriteria
                    {
                        CaseType = "P",
                        PropertyType = "D",
                        Jurisdiction = "US"
                    },
                    ValidActions = new[]
                    {
                        new ValidActionsController.ValidActionsOrder {Code = "~6", DisplaySequence = 1, Id = new ValidActionIdentifier("US", "D", "P", "~6")},
                        new ValidActionsController.ValidActionsOrder {Code = "~3", DisplaySequence = 2, Id = new ValidActionIdentifier("US", "D", "P", "~3")}
                    }
                });

                Assert.Equal("success", result.Result);

                var displaySequence = Db.Set<ValidAction>()
                                        .First(
                                               va =>
                                                   va.CaseTypeId == "P" && va.CountryId == "US" && va.ActionId == "~3" &&
                                                   va.PropertyTypeId == "D").DisplaySequence;
                Assert.NotNull(displaySequence);
                if (displaySequence != null) Assert.Equal(2, (short) displaySequence);
            }
        }

        public class CopyMethod : FactBase
        {
            [Fact]
            public void ShouldCopyAllValidCombinationsForAllCountriesSpecified()
            {
                var f = new ValidActionsControllerFixture(Db);
                f.SetupActions();

                var toCountries = new[] {new CountryModel {Code = "AUT"}, new CountryModel {Code = "IT"}};

                f.Subject.Copy(new CountryModel {Code = "US"}, toCountries);

                var validActionsForAmerica = Db.Set<ValidAction>()
                                               .Where(_ => _.CountryId == "US");

                foreach (var va in validActionsForAmerica)
                {
                    var validAction = va;

                    Assert.NotNull(
                                   Db.Set<ValidAction>()
                                     .Where(_ => _.CountryId == "AUT" && _.PropertyTypeId == validAction.PropertyTypeId
                                                                      && _.CaseTypeId == validAction.CaseTypeId && _.ActionId == validAction.ActionId));
                    Assert.NotNull(
                                   Db.Set<ValidAction>()
                                     .Where(_ => _.CountryId == "IT" && _.PropertyTypeId == validAction.PropertyTypeId
                                                                     && _.CaseTypeId == validAction.CaseTypeId && _.ActionId == validAction.ActionId));
                }
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenFromCountryNotPassed()
            {
                var f = new ValidActionsControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Copy(null, new[] {new CountryModel {Code = "GB"}}));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("fromJurisdiction", exception.Message);
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenToCountriesNotPassed()
            {
                var f = new ValidActionsControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Copy(new CountryModel {Code = "US"}, new CountryModel[] { }));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("toJurisdictions", exception.Message);
            }
        }

        public class ExportToExcelMethod : FactBase
        {
            [Fact]
            public void ShouldExportSearchResults()
            {
                var f = new ValidActionsControllerFixture(Db);
                f.SetupActions();

                f.Subject
                 .ExportToExcel(new ValidCombinationSearchCriteria());

                f.Exporter.Export(Arg.Is<PagedResults>(x => x.Data.Count() == 5), "Search Result.xslx");
            }
        }

        public class ValidActionsOrderModel : FactBase
        {
            [Fact]
            public void ReturnsCyclesAsOneByDefault()
            {
                var action = new ValidActionsController.ValidActionsOrder();
                Assert.Equal((short?) 1, action.Cycles);

                var cycles = Fixture.Short();
                action.Cycles = cycles;
                Assert.Equal(cycles, action.Cycles);
            }
        }
    }
}