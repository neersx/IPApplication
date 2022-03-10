using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.Jurisdictions;
using Inprotech.Web.Configuration.Jurisdictions.Maintenance;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Jurisdictions
{
    public class JurisdictionMaintenanceControllerFacts
    {
        public class JurisdictionsMaintenanceControllerFixture : IFixture<JurisdictionsMaintenanceController>
        {
            public JurisdictionsMaintenanceControllerFixture()
            {
                CommonQueryService = Substitute.For<ICommonQueryService>();
                JurisdictionSearch = Substitute.For<IJurisdictionSearch>();
                JurisdictionDetails = Substitute.For<IJurisdictionDetails>();
                TaskSecurityProivider = Substitute.For<ITaskSecurityProvider>();
                JurisdictionMaintenance = Substitute.For<IJurisdictionMaintenance>();
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                SqlHelper = Substitute.For<ISqlHelper>();

                Subject = new JurisdictionsMaintenanceController(JurisdictionSearch, CommonQueryService, JurisdictionDetails, TaskSecurityProivider, JurisdictionMaintenance, SqlHelper, PreferredCultureResolver);
                CommonQueryParameters = CommonQueryParameters.Default;
                CommonQueryParameters.SortBy = null;
                CommonQueryParameters.SortDir = null;
               
            }

            public ICommonQueryService CommonQueryService { get; set; }
            public IJurisdictionSearch JurisdictionSearch { get; set; }
            public CommonQueryParameters CommonQueryParameters { get; set; }
            public IJurisdictionDetails JurisdictionDetails { get; set; }
            public ITaskSecurityProvider TaskSecurityProivider { get; set; }
            public IJurisdictionMaintenance JurisdictionMaintenance { get; set; }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public ISqlHelper SqlHelper { get; set; }
            public JurisdictionsMaintenanceController Subject { get; }
        }

        public class GetSearchMethod : FactBase
        {
            [Fact]
            public void FindsExactMatchByCodeFirstThenByEaxctName()
            {
                var j = new JurisdictionsMaintenanceControllerFixture();
                var s = new SearchOptions {Text = "AU"};
                var c = Db.Set<Country>();
                c.Add(new Country("EAU", "CAU", Fixture.String()));
                c.Add(new Country("ZZZ", "ZAU", Fixture.String()));
                c.Add(new Country("ABC", "AU", Fixture.String()));
                c.Add(new Country("AU", "APOO", Fixture.String()));

                j.JurisdictionSearch.Search(s).Returns(c);
                j.CommonQueryService.Filter(c, j.CommonQueryParameters).Returns(c.ToArray());
                var r = j.Subject.GetSearch(s, j.CommonQueryParameters);

                var results = ((IEnumerable<dynamic>) r.Data).ToArray();

                Assert.Equal(4, results.Length);
                Assert.True(results[0].Id == "AU");
                Assert.True(results[1].Id == "ABC");
            }

            [Fact]
            public void ReturnsAllIdsOnlyWhereSpecified()
            {
                var j = new JurisdictionsMaintenanceControllerFixture();
                var s = new SearchOptions {Text = "AU"};
                var c = Db.Set<Country>();
                c.Add(new Country("AU", "A", Fixture.String()));
                c.Add(new Country("ABC", "AU", Fixture.String()));
                c.Add(new Country("ZZZ", "C", Fixture.String()));
                c.Add(new Country("EM", "Z", Fixture.String()));

                j.CommonQueryParameters.GetAllIds = true;
                j.JurisdictionSearch.Search(s).Returns(c);
                j.CommonQueryService.Filter(c, j.CommonQueryParameters).Returns(c.ToArray());
                var r = j.Subject.GetSearch(s, j.CommonQueryParameters);

                Assert.Equal(new[] {"AU", "ABC", "ZZZ", "EM"}, r);
            }

            [Fact]
            public void SortsByName()
            {
                var j = new JurisdictionsMaintenanceControllerFixture();
                var s = new SearchOptions {Text = string.Empty};
                var c = Db.Set<Country>();
                c.Add(new Country("ZZZ", "A", Fixture.String()));
                c.Add(new Country("AU", "B", Fixture.String()));
                c.Add(new Country("EM", "C", Fixture.String()));

                j.JurisdictionSearch.Search(s).Returns(c);
                j.CommonQueryService.Filter(c, j.CommonQueryParameters).Returns(c.ToArray());
                var r = j.Subject.GetSearch(s, j.CommonQueryParameters);

                var results = ((IEnumerable<dynamic>) r.Data).ToArray();

                Assert.Equal(3, results.Length);
                Assert.True(results[0].Id == "ZZZ");
                Assert.True(results[2].Id == "EM");
            }
        }

        public class GetHolidaysMethod : FactBase
        {
            public DateTime TodayDate;

            [Fact]
            public void FindsCountryHolidays()
            {
                var j = new JurisdictionsMaintenanceControllerFixture();
                TodayDate = DateTime.UtcNow;
                var countryHolidays = new List<CountryHoliday> {new CountryHoliday("AF", TodayDate) {HolidayName = "Public Holiday"}.In(Db), new CountryHoliday("AF", TodayDate) {HolidayName = "Public Holiday 2"}.In(Db)};

                j.JurisdictionDetails.GetHolidays("AF").Returns(countryHolidays.ToArray());
                
                var r = j.Subject.GetHolidays("AF", j.CommonQueryParameters);

                var results = ((IEnumerable<dynamic>) r.Data).ToArray();

                Assert.Equal(2, results.Length);
                Assert.Equal(results[0].CountryId, "AF");
                Assert.Equal(results[1].CountryId, "AF");
            }

            [Fact]
            public void GetHolidayByIdMethod()
            {
                var j = new JurisdictionsMaintenanceControllerFixture();
                TodayDate = DateTime.UtcNow;
                var countryHoliday = new CountryHoliday("AF", TodayDate){ HolidayName = "Public Holiday"}.In(Db);

                j.JurisdictionDetails.GetHolidayById(Arg.Any<string>(), Arg.Any<int>()).Returns(countryHoliday);
                
                var r = j.Subject.GetHolidayById(countryHoliday.CountryId, countryHoliday.Id);

                Assert.NotNull(r);
                Assert.Equal(r.CountryId, countryHoliday.CountryId);
                Assert.Equal(r.Id, countryHoliday.Id);
                Assert.Equal(r.HolidayName,countryHoliday.HolidayName);
            }

        }

        public class GetFilterDataMethod : FactBase
        {
            [Fact]
            public void FilterDataHasAllValuesAndDistinct()
            {
                var j = new JurisdictionsMaintenanceControllerFixture();
                var s = new SearchOptions {Text = string.Empty};
                var c = Db.Set<Country>();
                c.Add(new Country(Fixture.String(), Fixture.String(), "B"));
                c.Add(new Country(Fixture.String(), Fixture.String(), "C"));
                c.Add(new Country(Fixture.String(), Fixture.String(), "A"));
                c.Add(new Country(Fixture.String(), Fixture.String(), "A"));

                j.JurisdictionSearch.Search(s).Returns(c);
                dynamic[] r = j.Subject.GetFilterDataForColumn("type", s).ToArray();

                Assert.Equal(3, r.Length);
                Assert.NotNull(r.SingleOrDefault(_ => _.Code == "A"));
                Assert.NotNull(r.SingleOrDefault(_ => _.Code == "B"));
                Assert.NotNull(r.SingleOrDefault(_ => _.Code == "C"));
            }

            [Fact]
            public void FilterDataIsOrderedAlphabetically()
            {
                var j = new JurisdictionsMaintenanceControllerFixture();
                var s = new SearchOptions {Text = string.Empty};
                var c = Db.Set<Country>();
                c.Add(new Country(Fixture.String(), Fixture.String(), "3"));
                c.Add(new Country(Fixture.String(), Fixture.String(), "0"));
                c.Add(new Country(Fixture.String(), Fixture.String(), "1"));

                j.JurisdictionSearch.Search(s).Returns(c);
                dynamic[] r = j.Subject.GetFilterDataForColumn("type", s).ToArray();

                Assert.Equal(r[0].Description, "Country");
                Assert.Equal(r[1].Description, "Group");
                Assert.Equal(r[2].Description, "IP Only");
            }

            [Fact]
            public void FilterDataReturnsOnlyTypesInSearchResults()
            {
                var j = new JurisdictionsMaintenanceControllerFixture();
                var s = new SearchOptions {Text = string.Empty};
                var c = Db.Set<Country>();
                c.Add(new Country(Fixture.String(), Fixture.String(), "0"));
                c.Add(new Country(Fixture.String(), Fixture.String(), "1"));

                j.JurisdictionSearch.Search(s).Returns(c);
                dynamic[] r = j.Subject.GetFilterDataForColumn("type", s).ToArray();

                Assert.Equal(2, r.Length);
                Assert.NotNull(r.SingleOrDefault(_ => _.Code == "0"));
                Assert.NotNull(r.SingleOrDefault(_ => _.Code == "1"));
            }
        }

        public class Maintenance : FactBase
        {
            [Fact]
            public void CallsDeleteAndReturnsResult()
            {
                var result = new {Result = "success"};
                var toDelete = new[] {Fixture.String(), Fixture.String(), Fixture.String()};
                var f = new JurisdictionsMaintenanceControllerFixture();
                f.JurisdictionMaintenance.Delete(Arg.Any<IEnumerable<string>>()).Returns(result);
                var output = f.Subject.DeleteJurisdiction(toDelete);
                f.JurisdictionMaintenance.Received(1).Delete(toDelete);
                Assert.Equal(result, output);
            }

            [Fact]
            public void CallsSaveAsAddAndReturnsResult()
            {
                var result = new {Result = "success"};
                var f = new JurisdictionsMaintenanceControllerFixture();
                f.JurisdictionMaintenance.Save(Arg.Any<JurisdictionModel>(), Operation.Add).Returns(result);
                var data = new JurisdictionModel {Id = Fixture.String(), Name = Fixture.String(), Type = Fixture.String()};
                var output = f.Subject.AddJurisdiction(data);
                f.JurisdictionMaintenance.Received(1).Save(data, Operation.Add);
                Assert.Equal(result, output);
            }

            [Fact]
            public void CallsSaveAsUpdate()
            {
                var f = new JurisdictionsMaintenanceControllerFixture();
                var data = new JurisdictionModel {Id = Fixture.String()};
                f.Subject.UpdateJurisdiction(Fixture.String(), data);
                f.JurisdictionMaintenance.Received(1).Save(data, Operation.Update);
            }

            [Fact]
            public void CallsUpdateJurisdictionCode()
            {
                var f = new JurisdictionsMaintenanceControllerFixture();
                var data = new ChangeJurisdictionCodeDetails {JurisdictionCode = "XX", NewJurisdictionCode = "YY"};
                f.Subject.UpdateJurisdictionCode(data);
                f.JurisdictionMaintenance.Received(1).UpdateJurisdictionCode(data);
            }
        }

        public class GetInitialData : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ReturnsMaintenancePermissions(bool canMaintain)
            {
                var viewOnly = Fixture.Boolean();
                var f = new JurisdictionsMaintenanceControllerFixture();
                f.TaskSecurityProivider.HasAccessTo(ApplicationTask.ViewJurisdiction, Arg.Any<ApplicationTaskAccessLevel>()).Returns(viewOnly);
                f.TaskSecurityProivider.HasAccessTo(ApplicationTask.MaintainJurisdiction, Arg.Any<ApplicationTaskAccessLevel>()).Returns(canMaintain);
                var result = f.Subject.InitialView();
                Assert.True(result.CanMaintain == canMaintain && result.ViewOnly == viewOnly);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ReturnsViewOnlyPermissions(bool canViewOnly)
            {
                var maintenance = Fixture.Boolean();
                var f = new JurisdictionsMaintenanceControllerFixture();
                f.TaskSecurityProivider.HasAccessTo(ApplicationTask.ViewJurisdiction, Arg.Any<ApplicationTaskAccessLevel>()).Returns(canViewOnly);
                f.TaskSecurityProivider.HasAccessTo(ApplicationTask.MaintainJurisdiction, Arg.Any<ApplicationTaskAccessLevel>()).Returns(maintenance);
                var result = f.Subject.InitialView();
                Assert.True(result.CanMaintain == maintenance && result.ViewOnly == canViewOnly);
            }
        }
    }
}