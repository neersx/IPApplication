using System;
using System.Linq;
using System.Text;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.ExchangeIntegration;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.ExchangeIntegration
{
    [Category(Categories.Integration)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release14)]
    public class RequestQueueTriggers : IntegrationTest
    {
        [Test]
        public void RequestsNotGeneratedWhenDisabled()
        {
            using (var setup = new ExchangeRequestsDbSetup())
            {
                setup.DisableService();
                setup.InsertStaffReminder(setup.StaffName.Id, DateTime.Today.Date);
                setup.UpdateStaffReminder(setup.StaffName.Id, DateTime.Today.Date);
                setup.DeleteStaffReminder(setup.StaffName.Id, DateTime.Today.Date);
            }

            var results = ApiClient.Post<PagedResults<RequestQueueItem>>("exchange/requests/view", JsonConvert.SerializeObject(CommonQueryParameters.Default));

            Assert.AreEqual(0, results.Data.Count());
        }

        //[Test]
        // Ignored because there is a faulty condition to be fixed
        //- see last bit in http://aus-inpbldvd001/repository/download/E2eRunner_Default/111397:id/integrationserver/integrationserver-AUS-INPBDVT008.log
        public void RequestsAreGeneratedWhenEnabled()
        {
            using (var setup = new ExchangeRequestsDbSetup())
            {
                setup.EnableService();
                setup.InsertStaffReminder(setup.StaffName.Id, DateTime.Today.Date);
                setup.UpdateStaffReminder(setup.StaffName.Id, DateTime.Today.Date);
                setup.DeleteStaffReminder(setup.StaffName.Id, DateTime.Today.Date);
            }

            var results = ApiClient.Post<PagedResults<RequestQueueItem>>("exchange/requests/view", JsonConvert.SerializeObject(CommonQueryParameters.Default));

            Assert.AreEqual(3, results.Data.Count());
            Assert.AreEqual(1, results.Data.Count(_ => _.RequestTypeId == (short)ExchangeRequestType.Add));
            Assert.AreEqual(1, results.Data.Count(_ => _.RequestTypeId == (short)ExchangeRequestType.Update));
            Assert.AreEqual(1, results.Data.Count(_ => _.RequestTypeId == (short)ExchangeRequestType.Delete));
        }
    }

    public class ExchangeRequestsDbSetup : DbSetup
    {
        public ExchangeRequestsDbSetup()
        {
            var loginUser = new Users()
                            .WithLicense(LicensedModule.CasesAndNames)
                            .WithPermission(ApplicationTask.ExchangeIntegration)
                            .Create();

            StaffName = DbContext.Set<User>().Single(_ => _.Id == loginUser.Id).Name;
        }

        public Name StaffName { get; set; }
        public DateTime DateCreated { get; set; }

        public void DisableService()
        {
            var exchangeConfigurationSettings = new ExchangeConfigurationSettings
            {
                Domain = Fixture.String(3),
                Password = Convert.ToBase64String(Encoding.ASCII.GetBytes(Fixture.String(100))),
                Server = "https://server.thefirm",
                UserName = Fixture.String(20)
            };

            var externalSetting = DbContext.Set<ExternalSettings>().Single(v => v.ProviderName == KnownExternalSettings.ExchangeSetting);
            externalSetting.Settings = JObject.FromObject(exchangeConfigurationSettings).ToString();
            DbContext.SaveChanges();
        }

        public void EnableService()
        {
            var exchangeConfigurationSettings = new ExchangeConfigurationSettings
            {
                Domain = Fixture.String(3),
                Password = Convert.ToBase64String(Encoding.ASCII.GetBytes(Fixture.String(100))),
                Server = "https://server.thefirm",
                UserName = Fixture.String(20)
            };

            var externalSetting = DbContext.Set<ExternalSettings>().Single(v => v.ProviderName == KnownExternalSettings.ExchangeSetting);
            externalSetting.Settings = JObject.FromObject(exchangeConfigurationSettings).ToString();
            DbContext.SaveChanges();
        }

        public void InsertStaffReminder(int staffId, DateTime dateCreated)
        {
            DbContext.Set<StaffReminder>()
                     .Add(new StaffReminder(staffId, dateCreated)
                     {
                         DueDate = DateTime.Today.AddDays(10)
                     });
            DbContext.SaveChanges();
        }

        public void UpdateStaffReminder(int staffId, DateTime dateCreated)
        {
            var reminder = DbContext.Set<StaffReminder>().Single(_ => _.StaffId == staffId && _.DateCreated == dateCreated);
            reminder.ShortMessage = Guid.NewGuid().ToString();
            DbContext.SaveChanges();
        }

        public void DeleteStaffReminder(int staffId, DateTime dateCreated)
        {
            DbContext.Delete<StaffReminder>(_ => _.StaffId == staffId && _.DateCreated == dateCreated);
            DbContext.SaveChanges();
        }
    }
}