using System.Threading.Tasks;
using Inprotech.IntegrationServer.PtoAccess.Innography.SourceChanges;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Profiles;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography.SourceChanges
{
    public class MostRecentlyAppliedChangesFacts
    {
        public class ResolveMethod : FactBase
        {
            [Fact]
            public async Task ReturnsLastCheckDatePlusOneDay()
            {
                new ExternalSettings("InnographyId")
                {
                    Settings = "2001-01-01"
                }.In(Db);

                var subject = new MostRecentlyAppliedChanges(Db, Fixture.Today);
                var result = await subject.Resolve();

                Assert.Equal("2001-01-02", result.ToString("yyyy-MM-dd"));
            }

            [Fact]
            public async Task ReturnsUtcDateIfEmpty()
            {
                /* unexpected case - the date is filled */

                new ExternalSettings("InnographyId")
                {
                    Settings = null
                }.In(Db);

                var subject = new MostRecentlyAppliedChanges(Db, Fixture.Today);
                var result = await subject.Resolve();

                Assert.Equal(Fixture.Today().ToUniversalTime().Date.ToString("yyyy-MM-dd"), result.ToString("yyyy-MM-dd"));
            }
        }

        public class SetMethod : FactBase
        {
            [Fact]
            public async Task PersistsTheDate()
            {
                var es = new ExternalSettings("InnographyId")
                {
                    Settings = null
                }.In(Db);

                var subject = new MostRecentlyAppliedChanges(Db, Fixture.Today);
                await subject.Set(Fixture.Today());

                Assert.Equal(Fixture.Today().ToString("yyyy-MM-dd"), es.Settings);
            }
        }
    }
}