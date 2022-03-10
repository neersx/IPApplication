using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Search.BillSearch
{
    public class BillingSelection : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie, Ignore = "Fails consistently ni IE only")]
        public void VerifyBillDownload(BrowserType browserType)
        {
            var downloadsFolder = KnownFolders.GetPath(KnownFolder.Downloads);

            ExportHelper.DeleteFilesFromDirectory(downloadsFolder, new[] { "BillSearchList.pdf" });

            var user = new Users().WithPermission(ApplicationWebPart.BillSearch).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/search-result?queryContext=451", user.Username, user.Password);

            new BillingSelectionPageObject(driver);
            var grid = new AngularKendoGrid(driver, "searchResults", "a123");
            grid.SelectRow(0);
            grid.ActionMenu.OpenOrClose();
            Assert.IsFalse(grid.ActionMenu.Option("export-pdf").Disabled());
            grid.ActionMenu.Option("export-pdf").WithJs().Click();
            driver.WaitForAngularWithTimeout();
            new CommonPopups(driver).WaitForFlashAlert();
            var pdf = ExportHelper.GetDownloadedFile(driver, "BillSearchList.pdf");
            driver.WaitForAngularWithTimeout(5);
            Assert.AreEqual($"{downloadsFolder}\\BillSearchList.pdf", pdf);
        }
    }
}
