using System.Linq;
using Inprotech.IntegrationServer;
using Inprotech.IntegrationServer.Scheduling;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Scheduling
{
    public class DueScheduleActivitiesFacts
    {
        [Fact]
        public void AllActivitiesThatCanFailScheduleIntialisationAreDeclared()
        {
            var integrationServerAssembly = typeof(Configuration).Assembly;

            var allScheduleInitialiserTypes = from t in integrationServerAssembly.GetTypes()
                                              where t.Name.EndsWith("DueSchedule") || t.Name.EndsWith("BackgroundIdentityConfiguration")
                                              let shorten = t.FullName.Replace("Inprotech.IntegrationServer.", string.Empty)
                                              orderby shorten
                                              select shorten;

            var actual = from a in DueScheduleActivities.List
                         let shorten = a.FullName.Replace("Inprotech.IntegrationServer.", string.Empty)
                         orderby shorten
                         select shorten;

            Assert.Empty(allScheduleInitialiserTypes.Except(actual));
        }
    }
}