using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Policing;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingBackgroundServerFacts
    {
        public class TurnOffMethod : FactBase
        {
            [Fact]
            public void TurnOffPolicingContinuous()
            {
                var f = new PolicingBackgroundServerFixture(Db).WithPolicingContinuouslyAs(true);
                f.Subject.TurnOff();

                var siteControl = Db.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.PoliceContinuously);

                Assert.False(siteControl.BooleanValue);
            }
        }

        public class TurnOnMethod : FactBase
        {
            [Fact]
            public void TurnOnPolicingContinuous()
            {
                var pollingInterval = Fixture.Short();

                var f = new PolicingBackgroundServerFixture(Db)
                    .WithPolicingContinuouslyAs(false)
                    .WithPolicingContinuouslyPollingTime(pollingInterval);
               
                f.Subject.TurnOn();

                f.PolicingServerSps.Received(1).PolicingStartContinuously(Arg.Any<int?>(), pollingInterval);
            }
        }

        public class PolicingBackgroundServerFixture : IFixture<PolicingBackgroundServer>
        {
            public PolicingBackgroundServerFixture(IDbContext context = null)
            {
                Reader = Substitute.For<ISiteControlReader>();
                Db = context ?? Substitute.For<IDbContext>();
                PolicingServerSps = Substitute.For<IPolicingServerSps>();

                Subject = new PolicingBackgroundServer(Db, Reader, PolicingServerSps);
            }

            public ISiteControlReader Reader { get; set; }

            public IPolicingServerSps PolicingServerSps { get; set; }

            public IDbContext Db { get; set; }

            public PolicingBackgroundServer Subject { get; }

            public PolicingBackgroundServerFixture WithPolicingContinuouslyAs(bool policingStatus)
            {
                Reader.Read<bool>(SiteControls.PoliceContinuously).Returns(policingStatus);

                new SiteControl(SiteControls.PoliceContinuously)
                    {
                        BooleanValue = policingStatus
                    }
                    .In((InMemoryDbContext) Db);

                return this;
            }

            public PolicingBackgroundServerFixture WithPolicingContinuouslyPollingTime(int? interval)
            {
                Reader.Read<int?>(SiteControls.PolicingContinuouslyPollingTime).Returns(interval);

                new SiteControl(SiteControls.PolicingContinuouslyPollingTime)
                    {
                        IntegerValue = interval
                    }
                    .In((InMemoryDbContext) Db);

                return this;
            }
        }

        public class StatusMethod : FactBase
        {
            [Fact]
            public void ReturnsRunningStatus()
            {
                var f = new PolicingBackgroundServerFixture();
                f.PolicingServerSps.PolicingBackgroundProcessExists().Returns(true);

                var r = f.Subject.Status();
                Assert.True(r == PolicingServerStatus.Running);
            }

            [Fact]
            public void ReturnsStoppedStatus()
            {
                var f = new PolicingBackgroundServerFixture();
                f.PolicingServerSps.PolicingBackgroundProcessExists().Returns(false);

                var r = f.Subject.Status();
                Assert.True(r == PolicingServerStatus.Stopped);
            }
        }
    }
}