using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Configuration.Search;
using Inprotech.Web.Portal;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Portal
{
    public class AppsMenuFacts
    {
        public class AppsMenuFixture : IFixture<AppsMenu>
        {
            public AppsMenuFixture(InMemoryDbContext db)
            {
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                ConfigurableItems = Substitute.For<IConfigurableItems>();

                DbContext = db ?? throw new ArgumentNullException(nameof(db));
                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(InternalWebApiUser());

                Subject = new AppsMenu(TaskSecurityProvider, ConfigurableItems, SecurityContext);
            }

            public ITaskSecurityProvider TaskSecurityProvider { get; set; }

            public IConfigurableItems ConfigurableItems { get; set; }

            public ISecurityContext SecurityContext { get; set; }

            public AppsMenu Subject { get; }

            public InMemoryDbContext DbContext { get; set; }

            User InternalWebApiUser()
            {
                return UserBuilder.AsInternalUser(DbContext, "internal").Build().In(DbContext);
            }
        }

        public class BuildMethod : FactBase
        {
            [Theory]
            [InlineData(new[] {ApplicationTask.ScheduleIpOneDataDownload})]
            [InlineData(new[] {ApplicationTask.ScheduleUsptoTsdrDataDownload})]
            [InlineData(new[] {ApplicationTask.ScheduleUsptoPrivatePairDataDownload})]
            [InlineData(new[] {ApplicationTask.ScheduleUsptoPrivatePairDataDownload, ApplicationTask.ScheduleUsptoTsdrDataDownload})]
            public void ReturnsOneMenuItemForIntegrationForAnyScheduleTasks(ApplicationTask[] permittedSchedules)
            {
                var f = new AppsMenuFixture(Db);

                f.TaskSecurityProvider.ListAvailableTasks()
                 .Returns(
                          permittedSchedules
                              .Select(ps => new ValidSecurityTask((short) ps, false, false, false, true)));

                var r = f.Subject.Build().ToArray();

                Assert.Single(r);
                Assert.Equal("SchedulePtoDataDownload", r[0].Key);
                Assert.Equal("Schedule Data Downloads", r[0].Text);
                Assert.Equal("#/integration/ptoaccess/schedules", r[0].Url);
                Assert.Null(r[0].Items);
            }

            [Fact]
            public void ReturnsLegacyInprotechLinkWhenHasPermission()
            {
                var f = new AppsMenuFixture(Db);

                f.TaskSecurityProvider.ListAvailableTasks()
                 .Returns(new ValidSecurityTask[] {new ValidSecurityTask((short)ApplicationTask.ShowLinkstoWeb, false, false, false,true)});

                var r = f.Subject.Build().ToArray();

                Assert.Single(r);
                Assert.Equal("InprotechClassic", r[0].Key);
                Assert.Equal("Inprotech", r[0].Text);
                Assert.Equal("../", r[0].Url);
                Assert.Null(r[0].Items);
                Assert.Equal(AppsMenu.MenuTypes.newtab, r[0].Type);
            }

            [Fact]
            public void NotReturnsLegacyInprotechLinkWithoutPermission()
            {
                var f = new AppsMenuFixture(Db);

                f.TaskSecurityProvider.ListAvailableTasks()
                 .Returns(
                          Enumerable.Empty<ValidSecurityTask>());

                var r = f.Subject.Build().ToArray();
                Assert.Empty(r);
            }

            [Fact]
            public void MenuItemsHaveAttributes()
            {
                var f = new AppsMenuFixture(Db);

                f.TaskSecurityProvider.ListAvailableTasks()
                 .Returns(new[]
                 {
                     new ValidSecurityTask((short) ApplicationTask.BulkCaseImport, false, false, false, true)
                 });

                var r = f.Subject.Build().ToArray();

                var m = r[0];

                Assert.NotNull(m.Key);
                Assert.NotNull(m.Icon);
                Assert.NotNull(m.Url);
                Assert.NotNull(m.Text);
            }

            [Fact]
            public void PreventReturningOfConfigurationMenuIfNoConfigurationAccessAvailable()
            {
                var f = new AppsMenuFixture(Db);
                f.ConfigurableItems.Any().Returns(false);

                var r = f.Subject.Build().ToArray();

                Assert.DoesNotContain("SystemMaintenance", r.Select(_ => _.Key));
            }

            [Fact]
            public void ReturnsConfigurationMenuIfAuthorised()
            {
                var f = new AppsMenuFixture(Db);
                f.ConfigurableItems.Any().Returns(true);

                var r = f.Subject.Build().ToArray();

                Assert.Contains("SystemMaintenance", r.Select(_ => _.Key));
            }

            [Fact]
            public void ReturnsCaseSearchSavedMenuIfAuthorised()
            {
                var f = new AppsMenuFixture(Db);
                f.ConfigurableItems.Any().Returns(true);
                f.TaskSecurityProvider.ListAvailableTasks()
                 .Returns(new[]
                 {
                     new ValidSecurityTask((short) ApplicationTask.AdvancedCaseSearch, false, false, false, true),
                     new ValidSecurityTask((short) ApplicationTask.RunSavedCaseSearch, false, false, false, true)
                 });
                var r = f.Subject.Build().ToArray();

                var caseSearchMenu = r.FirstOrDefault(_ => _.Key == "CaseSearch");
                Assert.NotNull(caseSearchMenu);
                Assert.Equal(AppsMenu.MenuTypes.searchPanel, caseSearchMenu.Type);
                Assert.Equal((int)QueryContext.CaseSearch, caseSearchMenu.QueryContextKey);
            }

            [Fact]
            public void ReturnsCaseSearchMenuIfAuthorised()
            {
                var f = new AppsMenuFixture(Db);
                f.ConfigurableItems.Any().Returns(true);

                f.TaskSecurityProvider.ListAvailableTasks()
                 .Returns(new[]
                 {
                     new ValidSecurityTask((short) ApplicationTask.AdvancedCaseSearch, false, false, false, true)
                 });

                var r = f.Subject.Build().ToArray();

                var caseSearchMenu = r.FirstOrDefault(_ => _.Key == "CaseSearch");
                Assert.NotNull(caseSearchMenu);
                Assert.Equal(AppsMenu.MenuTypes.simple, caseSearchMenu.Type);
            }

            [Fact]
            public void ReturnsCaseSearchExternalMenuIfAuthorised()
            {
                var f = new AppsMenuFixture(Db);
                f.ConfigurableItems.Any().Returns(true);

                f.TaskSecurityProvider.ListAvailableTasks()
                 .Returns(new[]
                 {
                     new ValidSecurityTask((short) ApplicationTask.AdvancedCaseSearch, false, false, false, true),
                     new ValidSecurityTask((short) ApplicationTask.RunSavedCaseSearch, false, false, false, true)
                 });

                var user = new User("user", true).In(Db);
                f.SecurityContext.User.Returns(user);

                var r = f.Subject.Build().ToArray();

                var caseSearchMenu = r.FirstOrDefault(_ => _.Key == "CaseSearch");
                Assert.NotNull(caseSearchMenu);
                Assert.Equal((int)QueryContext.CaseSearchExternal, caseSearchMenu.QueryContextKey);
            }

            [Fact]
            public void ReturnContainerMenuIfAnyChildMenu ()
            {
                var f = new AppsMenuFixture(Db);

                f.TaskSecurityProvider.ListAvailableTasks()
                 .Returns(new[]
                 {
                     new ValidSecurityTask((short) ApplicationTask.NamesConsolidation, false, false, false, true)
                 });

                var r = f.Subject.Build().ToArray();

                var m = r[0];

                Assert.NotNull(m.Key);
                Assert.NotNull(m.Icon);
                Assert.Equal("Utilities", m.Key);

                var sm = m.Items;
                Assert.NotNull(sm[0].Key);
                Assert.NotNull(sm[0].Url);
                Assert.Equal("NamesConsolidation",sm[0].Key);
            }

            [Fact]
            public void HideContainerMenuWithoutChildMenu ()
            {
                var f = new AppsMenuFixture(Db);

                f.TaskSecurityProvider.ListAvailableTasks()
                 .Returns(new[]
                 {
                     new ValidSecurityTask((short) ApplicationTask.NamesConsolidation, false, false, false, true)
                 });

                var r = f.Subject.Build().ToArray();
                Assert.NotNull(r);
                Assert.Single(r);
                Assert.Equal("Utilities", r[0].Key);
            }
        }
    }
}