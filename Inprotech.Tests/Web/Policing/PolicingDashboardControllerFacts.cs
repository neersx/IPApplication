using System.Collections.Generic;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Policing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingDashboardControllerFacts
    {
        public class PolicingDashboardControllerFixture : IFixture<PolicingDashboardController>
        {
            public PolicingDashboardControllerFixture()
            {
                DashboardDataProvider = Substitute.For<IDashboardDataProvider>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

                Subject = new PolicingDashboardController(DashboardDataProvider, TaskSecurityProvider);
            }

            public IDashboardDataProvider DashboardDataProvider { get; set; }

            public ITaskSecurityProvider TaskSecurityProvider { get; set; }

            public PolicingDashboardController Subject { get; set; }

            public PolicingDashboardControllerFixture WithAdministrationTaskSecurity(bool setTo)
            {
                TaskSecurityProvider.HasAccessTo(ApplicationTask.PolicingAdministration).Returns(setTo);
                return this;
            }

            public PolicingDashboardControllerFixture WithPolicingRequestTaskSecurity(bool setTo)
            {
                TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPolicingRequest).Returns(setTo);
                return this;
            }

            public PolicingDashboardControllerFixture WithExchangeIntegrationTaskSecurity(bool setTo)
            {
                TaskSecurityProvider.HasAccessTo(ApplicationTask.ExchangeIntegrationAdministration).Returns(setTo);
                return this;
            }

            public PolicingDashboardControllerFixture WithDashboardData(DashboardData data)
            {
                DashboardDataProvider.Retrieve().ReturnsForAnyArgs(
                                                                   new Dictionary<RetrieveOption, DashboardData>
                                                                   {
                                                                       {RetrieveOption.WithTrends, data}
                                                                   });
                return this;
            }
        }

        [Fact]
        public void CallsDashboardDataProvider()
        {
            var data = new DashboardData();

            var r = new PolicingDashboardControllerFixture().WithDashboardData(data).Subject.GetViewData();

            Assert.Equal(data, r);
        }

        [Fact]
        public void RequiresPolicingAdministrationTask()
        {
            var r = TaskSecurity.Secures<PolicingDashboardController>(ApplicationTask.PolicingAdministration);

            Assert.True(r);
        }

        [Fact]
        public void RequiresViewPolicingDashboardTask()
        {
            var r = TaskSecurity.Secures<PolicingDashboardController>(ApplicationTask.ViewPolicingDashboard);

            Assert.True(r);
        }

        [Fact]
        public void ReturnFalseIfNoAdministrationAcsess()
        {
            var f = new PolicingDashboardControllerFixture().WithAdministrationTaskSecurity(false);
            var r = f.Subject.Permissions();

            Assert.False(r.CanAdminister);
        }

        [Fact]
        public void ReturnFalseIfNoMaintainPolicingRequestAcsess()
        {
            var f = new PolicingDashboardControllerFixture().WithPolicingRequestTaskSecurity(false);
            var r = f.Subject.Permissions();

            Assert.False(r.CanViewOrMaintainRequests);
        }

        [Fact]
        public void ReturnFalseIfNoManageExchangeRequests()
        {
            var f = new PolicingDashboardControllerFixture().WithExchangeIntegrationTaskSecurity(false);
            var r = f.Subject.Permissions();

            Assert.False(r.CanManageExchangeRequests);
        }

        [Fact]
        public void ReturnTrueIfCanMaintainExchangeRequests()
        {
            var f = new PolicingDashboardControllerFixture().WithExchangeIntegrationTaskSecurity(true);
            var r = f.Subject.Permissions();

            Assert.True(r.CanManageExchangeRequests);
        }

        [Fact]
        public void ReturnTrueIfMaintainPolicingRequestAcsess()
        {
            var f = new PolicingDashboardControllerFixture().WithPolicingRequestTaskSecurity(true);
            var r = f.Subject.Permissions();

            Assert.True(r.CanViewOrMaintainRequests);
        }
    }
}