using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists;
using NSubstitute;
using Xunit;
using DateOfLaw = Inprotech.Web.Picklists.DateOfLaw;

namespace Inprotech.Tests.Web.Picklists
{
    public class DatesOfLawPicklistControllerFacts : FactBase
    {
        public class DatesOfLawMethod : FactBase
        {
            public DatesOfLawMethod()
            {
                FormatDateOfLaw = Substitute.For<IFormatDateOfLaw>();
                DateOfLawPicklistMaintenance = Substitute.For<IDateOfLawPicklistMaintenance>();

                FormatDateOfLaw.AsId(Arg.Any<DateTime>()).Returns(_ => _.ArgAt<DateTime>(0).ToString(CultureInfo.InvariantCulture));
                FormatDateOfLaw.Format(Arg.Any<DateTime>()).Returns(_ => _.ArgAt<DateTime>(0).ToString("dd-MMM-yyyy"));
            }

            public IFormatDateOfLaw FormatDateOfLaw { get; set; }

            public IDateOfLawPicklistMaintenance DateOfLawPicklistMaintenance { get; set; }

            [Theory]
            [InlineData("AU", "")]
            [InlineData("", "T")]
            [InlineData("", "")]
            public void ReturnsEmptyListIfCriteriaNotValid(string countryCode, string propertyTypeId)
            {
                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-01-01")}.Build
                    ().In(Db);

                var r = new DatesOfLawPicklistController(Db, DateOfLawPicklistMaintenance, FormatDateOfLaw).DatesOfLaw(null, null, countryCode, propertyTypeId);

                var dates = r.Data.OfType<DateOfLaw>().ToArray();

                Assert.Empty(dates);
            }

            [Fact]
            public void MatchesOnDateIfValid()
            {
                var d1 =
                    new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-01-01")}
                        .Build().In(Db);
                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2014-02-01")}.Build
                    ().In(Db);
                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2014-03-01")}.Build
                    ().In(Db);

                var r = new DatesOfLawPicklistController(Db, DateOfLawPicklistMaintenance, FormatDateOfLaw).DatesOfLaw(null, "01-Jan-2015", "AU", "T");

                var dates = r.Data.OfType<DateOfLaw>().ToArray();

                Assert.Single(dates);
                Assert.Equal(d1.Date.ToString(CultureInfo.InvariantCulture), dates.Single().Date.ToString(CultureInfo.InvariantCulture));
            }

            [Fact]
            public void OnlyReturnsValidDatesOfLaw()
            {
                var d1 =
                    new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-01-01")}
                        .Build().In(Db);
                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "P", Date = Fixture.Date("2015-02-02")}.Build
                    ().In(Db);
                new DateOfLawBuilder {CountryCode = "US", PropertyTypeId = "T", Date = Fixture.Date("2015-02-02")}.Build
                    ().In(Db);

                var r = new DatesOfLawPicklistController(Db, DateOfLawPicklistMaintenance, FormatDateOfLaw).DatesOfLaw(null, null, "AU", "T");

                var date = r.Data.OfType<DateOfLaw>().ToArray();

                Assert.Single(date);
                Assert.Equal(d1.Date.ToString(CultureInfo.InvariantCulture), date.Single().Date.ToString(CultureInfo.InvariantCulture));
            }

            [Fact]
            public void ReturnDateOfLawWithMatchedId()
            {
                var dol = new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-02-25"), IsDefault = true}
                          .Build().In(Db);
                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-08-01")}
                    .Build().In(Db);
                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-01-15")}
                    .Build().In(Db);

                var r = new DatesOfLawPicklistController(Db, DateOfLawPicklistMaintenance, FormatDateOfLaw).DateOfLaw(dol.Id);

                Assert.Equal(dol.Date.ToString(CultureInfo.InvariantCulture), r.DefaultDateOfLaw.Date.ToString(CultureInfo.InvariantCulture));
            }

            [Fact]
            public void ReturnsPagedResults()
            {
                var target =
                    new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-01-01")}
                        .Build().In(Db);
                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2014-12-31")}.Build
                    ().In(Db);
                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-01-02")}.Build
                    ().In(Db);

                var qParams = new CommonQueryParameters {Skip = 1, Take = 1};
                var r = new DatesOfLawPicklistController(Db, DateOfLawPicklistMaintenance, FormatDateOfLaw).DatesOfLaw(qParams, null, "AU", "T");
                var dates = r.Data.OfType<DateOfLaw>().ToArray();

                Assert.Equal(3, r.Pagination.Total);
                Assert.Single(dates);
                Assert.Equal(target.Date.ToString(CultureInfo.InvariantCulture), dates.Single().Date.ToString(CultureInfo.InvariantCulture));
            }

            [Fact]
            public void ReturnsRelatedActionAndEvents()
            {
                var d1 =
                    new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-01-01")}
                        .Build().In(Db);

                var r = new DatesOfLawPicklistController(Db, DateOfLawPicklistMaintenance, FormatDateOfLaw).DatesOfLaw(null, null, "AU", "T");

                var date = r.Data.OfType<DateOfLaw>().Single();

                Assert.Equal(d1.Date.ToString(CultureInfo.InvariantCulture), date.Date.ToString(CultureInfo.InvariantCulture));
                Assert.Equal("01-Jan-2015", date.Value);
            }

            [Fact]
            public void SearchesByPartialStringMatchOnFormattedDate()
            {
                var d1 =
                    new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-01-01")}
                        .Build().In(Db);
                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2014-02-01")}.Build
                    ().In(Db);
                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2014-03-01")}.Build
                    ().In(Db);

                var r = new DatesOfLawPicklistController(Db, DateOfLawPicklistMaintenance, FormatDateOfLaw).DatesOfLaw(null, "JaN", "AU", "T");

                var date = r.Data.OfType<DateOfLaw>().ToArray();

                Assert.Single(date);
                Assert.Equal(d1.Date.ToString(CultureInfo.InvariantCulture), date.Single().Date.ToString(CultureInfo.InvariantCulture));
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new DatesOfLawPicklistController(Db, DateOfLawPicklistMaintenance, FormatDateOfLaw).GetType();
                var picklistAttribute =
                    // ReSharper disable once AssignNullToNotNullAttribute
                    subjectType.GetMethod("DatesOfLaw").GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal("DateOfLaw", picklistAttribute.Name);
            }

            [Fact]
            public void ShouldNotReturnDateOfLawWhenIdNotMatched()
            {
                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-02-25")}
                    .Build().In(Db);

                var exception =
                    Record.Exception(() => new DatesOfLawPicklistController(Db, DateOfLawPicklistMaintenance, FormatDateOfLaw).DateOfLaw(Fixture.Integer()));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ShouldReturnAffectedActionsInOrderByActionThenByDeterminingEventThenByRetroEvent()
            {
                var defaultDol = new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-02-25"), IsDefault = true}
                                 .Build().In(Db);
                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-02-25"), IsDefault = true}
                    .Build().In(Db);
                var affectedAction1 = new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-02-25"), RetroActionPrefix = "abc", RetroActionId = "A"}
                                      .Build().In(Db);

                var affectedAction2 = new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-02-25"), RetroActionPrefix = "xyz", RetroActionId = "B"}
                                      .Build().In(Db);

                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-08-01")}
                    .Build().In(Db);
                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-01-15")}
                    .Build().In(Db);

                var result =
                    new DatesOfLawPicklistController(Db, DateOfLawPicklistMaintenance, FormatDateOfLaw).DateOfLaw(defaultDol.Id);

                var affectedActions = ((IEnumerable<AffectedActions>) result.AffectedActions).ToArray();

                Assert.Equal(3, affectedActions.Length);
                //order first by retro action
                Assert.Null(affectedActions[0].RetrospectiveAction);
                Assert.Equal(affectedAction1.RetroAction.Name, affectedActions[1].RetrospectiveAction.Value);
                Assert.Equal(affectedAction2.RetroAction.Name, affectedActions[2].RetrospectiveAction.Value);
            }

            [Fact]
            public void ShouldReturnErrorIfNoDefaultDateOfLawExists()
            {
                var dateOfLaw = new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-02-25")}
                                .Build().In(Db);

                var result =
                    new DatesOfLawPicklistController(Db, DateOfLawPicklistMaintenance, FormatDateOfLaw).DateOfLaw(dateOfLaw.Id);

                Assert.NotNull(result.Error);
                Assert.Equal(result.Error.Message, "picklist.dateoflaw.invalidDateOfLaw");
                Assert.Equal(result.Error.Field, "dateOfLaw");
            }

            [Fact]
            public void SortsFormattedDateStringByDate()
            {
                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-02-25")}
                    .Build().In(Db);
                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-08-01")}
                    .Build().In(Db);
                new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "T", Date = Fixture.Date("2015-01-15")}
                    .Build().In(Db);

                var qParams = new CommonQueryParameters {SortBy = "dateOfLawFormatted", SortDir = "asc"};
                var r = new DatesOfLawPicklistController(Db, DateOfLawPicklistMaintenance, FormatDateOfLaw).DatesOfLaw(qParams, null, "AU", "T");
                var dates = r.Data.OfType<DateOfLaw>().ToArray();

                Assert.Equal("15-Jan-2015", dates[0].Value);
                Assert.Equal("25-Feb-2015", dates[1].Value);
                Assert.Equal("01-Aug-2015", dates[2].Value);
            }
        }
    }
}