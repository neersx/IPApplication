using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Web
{
    public class MenuFacts
    {
        public class MenuFixture : IFixture<Menu>
        {
            public MenuFixture()
            {
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

                Subject = new Menu(TaskSecurityProvider);
            }

            public ITaskSecurityProvider TaskSecurityProvider { get; set; }

            public Menu Subject { get; }
        }

        public class BuildMethod
        {
            [Theory]
            [InlineData(new[] {ApplicationTask.ScheduleIpOneDataDownload})]
            [InlineData(new[] {ApplicationTask.ScheduleUsptoTsdrDataDownload})]
            [InlineData(new[] {ApplicationTask.ScheduleUsptoPrivatePairDataDownload})]
            [InlineData(new[] {ApplicationTask.ScheduleUsptoPrivatePairDataDownload, ApplicationTask.ScheduleUsptoTsdrDataDownload})]
            public void ReturnsOneMenuItemForIntegrationForAnyScheduleTasks(ApplicationTask[] permittedSchedules)
            {
                var f = new MenuFixture();

                f.TaskSecurityProvider.ListAvailableTasks()
                 .Returns(
                          permittedSchedules
                              .Select(ps => new ValidSecurityTask((short) ps, false, false, false, true)));

                var r = f.Subject.Build().ToArray();

                Assert.Single(r);
                Assert.Equal("Integration", r[0].name);
                Assert.Equal("menuIntegration", r[0].TitleResId);
                Assert.Equal(1, r[0].Items.Length);
            }

            [Fact]
            public void MenuItemsHaveAttributes()
            {
                var f = new MenuFixture();

                f.TaskSecurityProvider.ListAvailableTasks()
                 .Returns(new[]
                 {
                     new ValidSecurityTask((short) ApplicationTask.BulkCaseImport, false, false, false, true)
                 });

                var r = f.Subject.Build().ToArray();

                var m = r[0].Items[0];

                Assert.NotNull(m.id);
                Assert.NotNull(m.name);
                Assert.NotNull(m.itemPath);
                Assert.NotNull(m.titleResId);
            }

            [Fact]
            public void ReturnsMenuForInprotech()
            {
                var f = new MenuFixture();

                f.TaskSecurityProvider.ListAvailableTasks()
                 .Returns(new[]
                 {
                     new ValidSecurityTask((short) ApplicationTask.BulkCaseImport, false, false, false, true)
                 });

                var r = f.Subject.Build().ToArray();

                Assert.Single(r);
                Assert.Equal("Inprotech", r[0].name);
                Assert.Equal("menuInprotech", r[0].TitleResId);
                Assert.Equal("BulkCaseImport", r[0].Items[0].name);
            }

            [Fact]
            public void ReturnsNothingIfNoTaskSecurity()
            {
                var f = new MenuFixture();

                f.TaskSecurityProvider.ListAvailableTasks()
                 .Returns(Enumerable.Empty<ValidSecurityTask>());

                var r = f.Subject.Build();

                Assert.Empty(r);
            }

            [Fact]
            public void ReturnsOneMenuItemForInprotechForFinancialReports()
            {
                var f = new MenuFixture();

                f.TaskSecurityProvider.ListAvailableTasks()
                 .Returns(new[]
                 {
                     new ValidSecurityTask((short) ApplicationTask.ViewAgedDebtorsReport, false, false, false, true),
                     new ValidSecurityTask((short) ApplicationTask.ViewRevenueAnalysisReport, false, false, false, true)
                 });

                var r = f.Subject.Build().ToArray();

                Assert.Single(r);
                Assert.Equal("Inprotech", r[0].name);
                Assert.Equal("menuInprotech", r[0].TitleResId);
                Assert.Equal(1, r[0].Items.Length);
            }
        }
    }
}