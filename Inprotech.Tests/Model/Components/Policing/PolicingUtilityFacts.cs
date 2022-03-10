using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Policing
{
    public class PolicingUtilityFacts
    {
        public class IsPoliceImmediatelyMethod : FactBase
        {
            [Fact]
            public void ReturnsFalseIfSiteControlsOff()
            {
                var f = new PolicingUtilityFixture(Db);
                new SiteControl(SiteControls.PoliceImmediately, false).In(Db);
                new SiteControl(SiteControls.PoliceImmediateInBackground, false).In(Db);
                var result = f.Subject.IsPoliceImmediately();
                Assert.False(result);
            }

            [Fact]
            public void ReturnsTrueIfPoliceImmediatelyInBackgroundSiteControlIsOn()
            {
                var f = new PolicingUtilityFixture(Db);
                new SiteControl(SiteControls.PoliceImmediateInBackground, true).In(Db);
                var result = f.Subject.IsPoliceImmediately();
                Assert.True(result);
            }

            [Fact]
            public void ReturnsTrueIfPoliceImmediatelySiteControlIsOn()
            {
                var f = new PolicingUtilityFixture(Db);
                new SiteControl(SiteControls.PoliceImmediately, true).In(Db);
                var result = f.Subject.IsPoliceImmediately();
                Assert.True(result);
            }
        }

        public class PolicingUtilityFixture : IFixture<PolicingUtility>
        {
            public PolicingUtilityFixture(InMemoryDbContext db)
            {
                DbContext = Substitute.For<IDbContext>();

                Subject = new PolicingUtility(db);
            }

            public IDbContext DbContext { get; }
            public PolicingUtility Subject { get; }
        }
    }
}