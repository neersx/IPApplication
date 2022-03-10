using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.FilePart
{
    [TestFixture]
    [Category(Categories.E2E)]
    public class FilePartPicklist : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddUpdateDeleteFilePartPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var user = new Users().WithPermission(ApplicationTask.MaintainFileTracking, Allow.Create | Allow.Delete | Allow.Modify).Create();
            SignIn(driver, "/#/dev/ipx-typeahead", user.Username, user.Password);
            var saveSearch = new FilePartPicklistDetailPage(driver);
            var picklist = new AngularPicklist(driver).ById("filePartPicklist");
            picklist.OpenPickList(string.Empty);
            picklist.AddAngularPicklistItem();
            saveSearch.DescriptionTextArea().SendKeys("e2e-add");
            picklist.Apply();
            picklist.SearchFor("e2e-add");
            Assert.AreEqual("e2e-add", picklist.SearchGrid.CellText(0, 0), "Should show added description");
            picklist.EditRow(0);
            saveSearch.DescriptionTextArea().Clear();
            saveSearch.DescriptionTextArea().SendKeys("e2e-edit");
            picklist.Apply();
            saveSearch.CloseButton().WithJs().Click();
            picklist.OpenPickList(string.Empty);
            picklist.SearchFor("e2e-edit");
            Assert.AreEqual("e2e-edit", picklist.SearchGrid.CellText(0, 0), "Should show added description");
            picklist.DeleteRow(0);
            var popups = new CommonPopups(driver);
            popups.ConfirmNgDeleteModal.Delete.WithJs().Click();

            picklist.SearchFor("e2e-edit");
            Assert.IsEmpty(picklist.SearchGrid.Rows);
        }
    }
}
