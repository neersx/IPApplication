using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Configuration.General.NameType;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using InprotechKaizen.Model.Security;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Components
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class AuditTrail : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void RecordUserInfoForAuditTrail(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var page = new NameTypePageObject(driver);
            var popups = new CommonPopups(driver);

            const string nameTypeCode = "alt";

            var user = new Users().WithPermission(ApplicationTask.MaintainNameTypes).Create();

            SignIn(driver, "/#/configuration/general/nametypes", user.Username, user.Password);

            page.Add().Click();

            page.MaintenanceModal.NameTypeCode().Input(nameTypeCode);

            page.MaintenanceModal.NameTypeDescription().Input("Audit Log Test");

            page.MaintenanceModal.MaxAllowed().SendKeys("1");

            page.MaintenanceModal.Save().ClickWithTimeout();

            popups.FlashAlert();

            var nameTypeChangedBy = int.MinValue;
            var currentLoggedOnId = int.MaxValue;

            DbSetup.Do(x =>
                       {
                           nameTypeChangedBy = x.DbContext.SqlQuery<int>("select LOGIDENTITYID from NAMETYPE where NAMETYPE=@p0", nameTypeCode).Single();

                           currentLoggedOnId = x.DbContext.Set<User>().Single(_ => _.UserName == user.Username).Id;
                       });

            Assert.AreEqual(currentLoggedOnId, nameTypeChangedBy);
        }
    }
}