using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using Newtonsoft.Json;
using NUnit.Framework;
using Event = InprotechKaizen.Model.Cases.Events.Event;

namespace Inprotech.Tests.Integration.IntegrationTests.Picklists.Events
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class EventsPicklistMaintenance : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            DatabaseRestore.CreateNegativeWorkflowSecurityTask();
        }

        [Test]
        public void CreateEventWithNegativeId()
        {
            var data = DbSetup.Do(setup =>
            {
                var lastInternalCode = setup.DbContext.Set<LastInternalCode>().FirstOrDefault(_ => _.TableName == KnownInternalCodeTable.EventsMaxim);
                if (lastInternalCode == null)
                {
                    var minEventId = setup.DbContext.Set<Event>().Select(_ => _.Id).Min();
                    lastInternalCode = setup.DbContext.Set<LastInternalCode>().Add(new LastInternalCode(KnownInternalCodeTable.EventsMaxim) {InternalSequence = minEventId});
                    setup.DbContext.SaveChanges();
                }

                var eventsMaxim = lastInternalCode.InternalSequence;
                return new
                {
                    nextEventId = eventsMaxim - 1
                };
            });

            var request = new EventSaveDetails
            {
                Description = Fixture.Prefix("NegativeIdEvent"),
                MaxCycles = 1
            };

            var user = new Users()
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .WithPermission(ApplicationTask.CreateNegativeWorkflowRules)
                       .WithPermission(ApplicationTask.MaintainWorkflowRules)
                       .WithPermission(ApplicationTask.MaintainWorkflowRulesProtected)
                       .Create();

            var result = ApiClient.Post<dynamic>("picklists/events", JsonConvert.SerializeObject(request), user.Username, user.Id);

            Assert.NotNull(result);
            Assert.AreEqual("success", (string) result.result);
            Assert.AreEqual(data.nextEventId, (int) result.key);
        }
    }
}