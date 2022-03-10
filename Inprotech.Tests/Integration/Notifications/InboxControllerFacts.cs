using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Settings;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Web;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Notifications
{
    public class InboxControllerFacts
    {
        public class ExecutionsMethod
        {
            [Fact]
            public async Task ReturnsDataSources()
            {
                var f = new InboxControllerFixture()
                    .WithDmsIntegrationEnabled(DataSourceType.Epo, true);

                f.CaseNotifications.CountByDataSourceType()
                 .Returns(new Dictionary<DataSourceType, int>
                 {
                     {DataSourceType.UsptoPrivatePair, 2},
                     {DataSourceType.UsptoTsdr, 3},
                     {DataSourceType.Epo, 4}
                 });

                var r = await f.Subject.Executions(new ExecutionNotificationsOptions());

                var dataSources = ((IEnumerable<dynamic>) r.DataSources).ToArray();

                Assert.Equal("UsptoPrivatePair", dataSources.First().Id);
                Assert.Equal("Epo", dataSources.Last().Id);
                Assert.Equal(2, dataSources.First().Count);
                Assert.True(dataSources.Last().DmsIntegrationEnabled);
                Assert.False(dataSources.First().DmsIntegrationEnabled);
            }

            [Fact]
            public async Task ReturnsResult()
            {
                var f = new InboxControllerFixture();

                // ReSharper disable once CollectionNeverUpdated.Local
                var expected = new List<CaseNotificationResponse>();

                // ReSharper disable once UnusedVariable
                f.CaseNotificationsForExecution.Fetch(Arg.Any<ExecutionNotificationsOptions>())
                 .Returns((expected, true, new Dictionary<DataSourceType, int>()));

                var r = await f.Subject.Executions(new ExecutionNotificationsOptions());

                Assert.True(r.HasMore);
                Assert.Equal(expected, r.Notifications);
            }

            [Fact]
            public async Task ThrowsExceptionWhenSearchParametersNotProvided()
            {
                await Assert.ThrowsAsync<ArgumentNullException>(
                                                                async () => await new InboxControllerFixture().Subject.Executions(null));
            }
        }

        public class NotificationsMethod
        {
            [Fact]
            public async Task ReturnsDataSources()
            {
                var f = new InboxControllerFixture()
                    .WithDmsIntegrationEnabled(DataSourceType.Epo, true);

                f.CaseNotifications.CountByDataSourceType()
                 .Returns(new Dictionary<DataSourceType, int>
                 {
                     {DataSourceType.UsptoPrivatePair, 2},
                     {DataSourceType.UsptoTsdr, 3},
                     {DataSourceType.Epo, 4}
                 });

                var r = await f.Subject.Notifications(new LastChangedNotificationsOptions());

                var dataSources = ((IEnumerable<dynamic>) r.DataSources).ToArray();

                Assert.Equal("UsptoPrivatePair", dataSources.First().Id);
                Assert.Equal("Epo", dataSources.Last().Id);
                Assert.Equal(2, dataSources.First().Count);
                Assert.True(dataSources.Last().DmsIntegrationEnabled);
                Assert.False(dataSources.First().DmsIntegrationEnabled);
            }

            [Fact]
            public async Task ReturnsResult()
            {
                var f = new InboxControllerFixture();

                // ReSharper disable once CollectionNeverUpdated.Local
                var expected = new List<CaseNotificationResponse>();

                // ReSharper disable once UnusedVariable
                f.CaseNotificationsLastChanged.Fetch(Arg.Any<LastChangedNotificationsOptions>())
                 .Returns((expected, true));

                var r = await f.Subject.Notifications(new LastChangedNotificationsOptions());

                Assert.True(r.HasMore);
                Assert.Equal(expected, r.Notifications);
            }

            [Fact]
            public void SecuredByViewCaseDataComparisonTaskSecurity()
            {
                TaskSecurity.Secures<InboxController>(ApplicationTask.ViewCaseDataComparison);
            }

            [Fact]
            public async Task ThrowsExceptionWhenSearchParametersNotProvided()
            {
                await Assert.ThrowsAsync<ArgumentNullException>(
                                                                async () => await new InboxControllerFixture().Subject.Notifications(null));
            }
        }

        public class CasesMethod
        {
            [Fact]
            [SuppressMessage("ReSharper", "UnusedVariable")]
            public async Task ReturnsDataSources()
            {
                var f = new InboxControllerFixture()
                    .WithDmsIntegrationEnabled(DataSourceType.Epo, true);

                f.CaseNotificationsForCases.Fetch(Arg.Any<SelectedCasesNotificationOptions>())
                 .Returns(x =>
                 {
                     var count = new Dictionary<DataSourceType, int>
                     {
                         {DataSourceType.UsptoPrivatePair, 2},
                         {DataSourceType.UsptoTsdr, 3},
                         {DataSourceType.Epo, 4}
                     };

                     return (Enumerable.Empty<CaseNotificationResponse>(), count, true);
                 });

                var r = await f.Subject.Cases(new SelectedCasesNotificationOptions());

                var dataSources = ((IEnumerable<dynamic>) r.DataSources).ToArray();

                Assert.Equal("UsptoPrivatePair", dataSources.First().Id);
                Assert.Equal("Epo", dataSources.Last().Id);
                Assert.Equal(2, dataSources.First().Count);
                Assert.True(dataSources.Last().DmsIntegrationEnabled);
                Assert.False(dataSources.First().DmsIntegrationEnabled);
            }

            [Fact]
            public async Task ReturnsResult()
            {
                var f = new InboxControllerFixture();

                var expected = new List<CaseNotificationResponse>();

                f.CaseNotificationsForCases
                 .Fetch(Arg.Any<SelectedCasesNotificationOptions>())
                 .Returns((expected, new Dictionary<DataSourceType, int>(), true));

                var r = await f.Subject.Cases(new SelectedCasesNotificationOptions());

                Assert.True(r.HasMore);
                Assert.Equal(expected, r.Notifications);
            }

            [Fact]
            public async Task ThrowsExceptionWhenSearchParametersNotProvided()
            {
                await Assert.ThrowsAsync<ArgumentNullException>(
                                                                async () => await new InboxControllerFixture().Subject.Cases(null));
            }
        }

        public class ReviewMethod
        {
            [Fact]
            public async Task CallsReviewMethod()
            {
                var f = new InboxControllerFixture();

                await f.Subject.Review(999);

                f.CaseNotifications.Received(1)
                 .MarkReviewed(999)
                 .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class RejectCaseMatchMethod
        {
            [Fact]
            public async Task RejectsCaseMatch()
            {
                var whatever = new { };
                var notificationId = Fixture.Integer();

                var f = new InboxControllerFixture();

                f.SourceCaseRejection.Reject(notificationId)
                 .Returns(whatever);

                var r = await f.Subject.RejectCaseMatch(notificationId);

                Assert.Equal(whatever, r);
            }

            [Fact]
            public void SecuredBySaveImportedTaskSecurity()
            {
                TaskSecurity.Secures<InboxController>("RejectCaseMatch", ApplicationTask.SaveImportedCaseData);
            }
        }

        public class ReverseCaseMatchRejectMethod
        {
            [Fact]
            public async Task ReversesTheRejectedCaseMatch()
            {
                var whatever = new { };
                var notificationId = Fixture.Integer();

                var f = new InboxControllerFixture();

                f.SourceCaseRejection.ReverseRejection(notificationId)
                 .Returns(whatever);

                var r = await f.Subject.ReverseCaseMatchReject(notificationId);

                Assert.Equal(whatever, r);
            }

            [Fact]
            public void SecuredBySaveImportedTaskSecurity()
            {
                TaskSecurity.Secures<InboxController>("ReverseCaseMatchReject", ApplicationTask.SaveImportedCaseData);
            }
        }

        public class InboxControllerFixture : IFixture<InboxController>
        {
            public InboxControllerFixture()
            {
                CaseNotificationsLastChanged = Substitute.For<ICaseNotificationsLastChanged>();

                CaseNotificationsForCases = Substitute.For<ICaseNotificationsForCases>();

                CaseNotifications = Substitute.For<ICaseNotifications>();
                CaseNotifications.CountByDataSourceType()
                                 .Returns(new Dictionary<DataSourceType, int>
                                 {
                                     {DataSourceType.UsptoPrivatePair, 2},
                                     {DataSourceType.UsptoTsdr, 3},
                                     {DataSourceType.Epo, 4}
                                 });

                SourceCaseRejection = Substitute.For<ISourceCaseRejection>();
                CaseNotificationsForExecution = Substitute.For<ICaseNotificationsForExecution>();
                Settings = Substitute.For<IDmsIntegrationSettings>();

                Subject = new InboxController(
                                              CaseNotifications,
                                              CaseNotificationsForCases,
                                              CaseNotificationsLastChanged,
                                              Settings,
                                              SourceCaseRejection, CaseNotificationsForExecution);
            }

            public ISourceCaseRejection SourceCaseRejection { get; set; }

            public ICaseNotifications CaseNotifications { get; set; }

            public ICaseNotificationsLastChanged CaseNotificationsLastChanged { get; set; }
            public ICaseNotificationsForExecution CaseNotificationsForExecution { get; set; }

            public ICaseNotificationsForCases CaseNotificationsForCases { get; set; }

            public IDmsIntegrationSettings Settings { get; set; }

            public InboxController Subject { get; set; }

            public InboxControllerFixture WithDmsIntegrationEnabled(DataSourceType dataSource,
                                                                    bool dmsIntegrationEnabled)
            {
                Settings.IsEnabledFor(dataSource).Returns(dmsIntegrationEnabled);

                return this;
            }
        }
    }
}