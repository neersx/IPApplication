using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.RecordalTypes
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class RecordalTypes : IntegrationTest
    {
        RecordalTypesDbSetup _dbSetup;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie, Ignore = "Flakey, Will fix in other DR")]
        public void RecordalTypesList(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainRecordalType, Allow.Delete | Allow.Modify | Allow.Create).Create();
            var driver = BrowserProvider.Get(browserType);
            _dbSetup = new RecordalTypesDbSetup();
            var data = _dbSetup.SetupRecordalTypes();
            SignIn(driver, "/#/configuration/search", user.Username, user.Password);
            var page = new RecordalTypesPageObject(driver);
            page.SearchTextBox(driver).SendKeys("Recordal Types");
            page.SearchButton.ClickWithTimeout();
            page.RecordalTypeNavigationLink.ClickWithTimeout();

            Assert.True(page.RecordalTypeGrid.Rows.Count >= 3);
            page.SearchTextBoxInRecordalType(driver).SendKeys("E2e");
            page.SearchButton.ClickWithTimeout();
            var rt1 = (RecordalType)data.rt1;
            Assert.AreEqual(rt1.RequestEvent.Description, page.RecordalTypeGrid.CellText(0, 2));
            Assert.AreEqual(rt1.RequestAction.Name, page.RecordalTypeGrid.CellText(0, 3));

            // Delete
            page.RecordalTypeGrid.ClickDelete(0);
            var popups = new CommonPopups(driver);
            Assert.NotNull(popups.ConfirmDeleteModal);
            popups.ConfirmNgDeleteModal.Cancel.Click();
            page.RecordalTypeGrid.ClickDelete(0);
            popups.ConfirmNgDeleteModal.Delete.Click();
            Assert.AreEqual(page.RecordalTypeGrid.Rows.Count, 1);

            page.ClearSearchButton.ClickWithTimeout();
            Assert.True(page.RecordalTypeGrid.Rows.Count >= 2);

        }
    }
}