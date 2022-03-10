using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Integration;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Web.Builders.Model.Cases;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Tests.Integration.Notifications
{
    public class CaseNotificationsForDuplicatesFacts
    {
        [Fact]
        public async Task CallsAppropriateMethods()
        {
            const int forId = 1;
            var case1 = new CaseBuilder().Build();
            var case2 = new CaseBuilder().Build();
            var notification1 = new CaseNotification {Id = 90, Case = new Inprotech.Integration.Case {Source = DataSourceType.IpOneData}};
            var notification2 = new CaseNotification {Id = 91, Case = new Inprotech.Integration.Case {Source = DataSourceType.IpOneData}};

            var f = new CaseNotificationsForDuplicatesFixture().WithDuplicatesFinder()
                                                               .WithDuplicateCases(new[] {case1.Id, case2.Id})
                                                               .WithRequestedCases(new Dictionary<CaseNotification, Case>
                                                               {
                                                                   {notification1, case1},
                                                                   {notification2, case2}
                                                               })
                                                               .WithNotificationsResponse(new List<CaseNotificationResponse>
                                                               {
                                                                   new CaseNotificationResponse(notification1, "Case1-title"),
                                                                   new CaseNotificationResponse(notification2, "Case2-title")
                                                               });

            var result = await f.Subject.FetchDuplicatesFor(DataSourceType.IpOneData, forId);

            f.DuplicateCasesFinder.Received(1).FindFor(forId).IgnoreAwaitForNSubstituteAssertion();
            f.RequestedCases.Received(1).LoadNotifications(Arg.Any<string[]>(), Arg.Any<DataSourceType[]>()).IgnoreAwaitForNSubstituteAssertion();
            f.NotificationResponse.Received(1).For(Arg.Any<IEnumerable<CaseNotification>>());

            Assert.Equal(2, result.Length);

            var response1 = result.SingleOrDefault(_ => _.NotificationId == notification1.Id);
            Assert.NotNull(response1);
            Assert.Equal(case1.Id, response1.CaseId);
            Assert.Equal(case1.Irn, response1.CaseRef);

            var response2 = result.SingleOrDefault(_ => _.NotificationId == notification2.Id);
            Assert.NotNull(response2);
        }

        [Fact]
        public async Task ThrowsExceptionIfDuplicateCaseFinderNotDefined()
        {
            var f = new CaseNotificationsForDuplicatesFixture();
            await Assert.ThrowsAsync<NotImplementedException>(
                                                              async () => await f.Subject.FetchDuplicatesFor(DataSourceType.IpOneData, 1));
        }
    }

    public class CaseNotificationsForDuplicatesFixture : IFixture<CaseNotificationsForDuplicates>
    {
        public CaseNotificationsForDuplicatesFixture()
        {
            DuplicateCasesFinder = Substitute.For<IDuplicateCasesFinder>();

            DuplicateCasesFinders = Substitute.For<IIndex<DataSourceType, IDuplicateCasesFinder>>();

            RequestedCases = Substitute.For<IRequestedCases>();

            NotificationResponse = Substitute.For<INotificationResponse>();

            Subject = new CaseNotificationsForDuplicates(DuplicateCasesFinders, RequestedCases, NotificationResponse);
        }

        public IDuplicateCasesFinder DuplicateCasesFinder { get; }

        public IIndex<DataSourceType, IDuplicateCasesFinder> DuplicateCasesFinders { get; }

        public IRequestedCases RequestedCases { get; }

        public INotificationResponse NotificationResponse { get; }

        public CaseNotificationsForDuplicates Subject { get; }

        public CaseNotificationsForDuplicatesFixture WithDuplicatesFinder()
        {
            DuplicateCasesFinders.TryGetValue(Arg.Any<DataSourceType>(), out _)
                                 .Returns(x =>
                                 {
                                     x[1] = DuplicateCasesFinder;
                                     return true;
                                 });

            return this;
        }

        public CaseNotificationsForDuplicatesFixture WithDuplicateCases(int[] caseIds)
        {
            DuplicateCasesFinder.FindFor(Arg.Any<int>())
                                .Returns(caseIds);

            return this;
        }

        public CaseNotificationsForDuplicatesFixture WithRequestedCases(Dictionary<CaseNotification, Case> result)
        {
            RequestedCases.LoadNotifications(Arg.Any<string[]>(), Arg.Any<DataSourceType[]>())
                          .Returns(result);

            return this;
        }

        public CaseNotificationsForDuplicatesFixture WithNotificationsResponse(List<CaseNotificationResponse> result)
        {
            NotificationResponse.For(Arg.Any<IEnumerable<CaseNotification>>())
                                .Returns(result.AsEnumerable());

            return this;
        }
    }
}