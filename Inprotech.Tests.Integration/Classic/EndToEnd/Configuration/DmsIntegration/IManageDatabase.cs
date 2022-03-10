using System.Linq;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.Dms;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.Configuration.DmsIntegration
{
    [TestFixture]
    [Category(Categories.E2E)]
    public class IManageDatabase : IntegrationTest
    {
        public enum SiteDbGridCellIndex
        {
            Database = 2,
            ServerOrUrl = 1,
            CustomerId = 4,
            DownloadManifest = 7,
            Status = 6
        }

        [TestCase(BrowserType.Chrome, Ignore = "To be reinstated in DR-48352, Issue: Https url required to save, e2e server is http")]
        public void Database(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/dmsintegration");

            driver.With<DmsIntegrationPage>(page =>
            {
                const string database1 = "database1";
                const string url = "http://localhost/e2e/";
                var topic = new DmsIntegrationPage.DatabaseTopic(driver);
                topic.Grid.Add();
                Assert.NotNull(topic.Modal);
                Assert.AreEqual(false, topic.ModalApply.Enabled);
                Assert.AreEqual(true, topic.ModalCancel.Enabled);

                topic.Server.Input.SendKeys("http://localhost/e2e/");
                topic.Server.Input.Click();
                Assert.False(topic.Server.HasError);
                Assert.AreEqual(false, topic.ModalApply.Enabled);
                topic.Server.Input.Clear();
                topic.Server.Input.SendKeys(url);
                topic.Server.Input.Click();
                Assert.False(topic.Server.HasError);

                topic.Database.Input.SendKeys(database1);
                Assert.AreEqual(false, topic.ModalApply.Enabled);
                topic.IntegrationType.Input.SelectByText("iManage Work API V1");
                topic.IntegrationType.Input.SelectByIndex(1);
                topic.ClientId.Text = "client id";
                topic.ClientSecret.Text = "client secret";
                Assert.AreEqual(true, topic.ModalApply.Enabled);

                topic.ModalCancel.ClickWithTimeout();
                var modalDiscard = topic.DiscardChangesModal;
                Assert.NotNull(modalDiscard);
                modalDiscard.CancelDiscard();

                topic.ModalApply.ClickWithTimeout();
                Assert.True(topic.Grid.Cell(0, (int) SiteDbGridCellIndex.DownloadManifest).FindElements(By.TagName("button")).Any(), "Showing download manifest button");

                Assert.AreEqual(topic.Grid.Rows.Count, topic.NumberOfRecordsInSection(), "Topic displays count");
                Assert.AreEqual(1, topic.Grid.Rows.Count);
                Assert.AreEqual(database1, topic.Grid.CellText(0, (int) SiteDbGridCellIndex.Database));
                Assert.AreEqual(url, topic.Grid.CellText(0, (int) SiteDbGridCellIndex.ServerOrUrl));

                topic.Grid.ClickEdit(0);
                Assert.NotNull(topic.Modal);
                Assert.AreEqual(true, topic.ModalApply.Enabled);
                Assert.AreEqual(true, topic.ModalCancel.Enabled);
                topic.IntegrationType.Input.SelectByIndex(1);
                topic.ClientId.Text = string.Empty;

                Assert.AreEqual(false, topic.ModalApply.Enabled);
                Assert.AreEqual(true, topic.ClientId.Element.Displayed);
                Assert.AreEqual(true, topic.ClientSecret.Element.Displayed);

                topic.ClientSecret.Input.SendKeys("test secret");
                topic.ClientId.Input.SendKeys("test id");
                Assert.AreEqual(true, topic.ModalApply.Enabled);

                topic.ClientSecret.Input.Clear();
                topic.ClientId.Input.Clear();
                Assert.AreEqual(false, topic.ModalApply.Enabled);

                topic.IntegrationType.Input.SelectByIndex(0);
                topic.LoginType.Input.SelectByIndex(0);
                Assert.AreEqual(true, topic.ModalApply.Enabled);

                topic.ModalApply.ClickWithTimeout();
                Assert.AreEqual(string.Empty, topic.Grid.CellText(0, (int) SiteDbGridCellIndex.CustomerId));
                Assert.False(topic.Grid.Cell(0, (int) SiteDbGridCellIndex.DownloadManifest).FindElements(By.TagName("button")).Any(), "Not showing download manifest button");

                topic.Enabled.ClickWithTimeout();
                page.Save();
                driver.WaitForAngular();

                Assert.NotNull(topic.Notification);
                Assert.AreEqual(true, topic.NotificationYes.Enabled);
                Assert.AreEqual("Enable DMS configuration", topic.NotificationTitle.Text);
                topic.NotificationYes.ClickWithTimeout();
                driver.WaitForAngular();
                topic.TestUsername.Text = "username";
                topic.TestPassword.Text = "password";
                topic.TestSaveButton(driver).Click();
                driver.WaitForAngular();
                Assert.AreEqual(false, page.SaveButton.Enabled);

                Assert.AreEqual(1, topic.Grid.Rows.Count);
                Assert.AreEqual(database1, topic.Grid.CellText(0, (int) SiteDbGridCellIndex.Database));
                Assert.False(topic.Grid.Cell(0, (int) SiteDbGridCellIndex.DownloadManifest).FindElements(By.TagName("button")).Any(), "Not showing download manifest button");
                Assert.AreEqual(url, topic.Grid.CellText(0, (int) SiteDbGridCellIndex.ServerOrUrl));
                Assert.AreEqual(string.Empty, topic.Grid.CellText(0, (int) SiteDbGridCellIndex.CustomerId));

                topic.Grid.ClickEdit(0);
                topic.IntegrationType.Input.SelectByIndex(0);

                topic.Database.Input.Clear();
                topic.Database.Input.SendKeys(database1);

                Assert.AreEqual(true, topic.ModalApply.Enabled);
                topic.ModalApply.ClickWithTimeout();
                Assert.False(topic.Grid.Cell(0, (int) SiteDbGridCellIndex.DownloadManifest).FindElements(By.TagName("button")).Any(), "Not showing download manifest button");
                topic.Enabled.ClickWithTimeout();
                page.Save();
                driver.WaitForAngular();
                Assert.NotNull(topic.Notification);
                Assert.AreEqual(true, topic.NotificationNo.Enabled);
                topic.NotificationNo.ClickWithTimeout();
                driver.WaitForAngular();
                Assert.False(page.SaveButton.Enabled, "should successfully save without prompting for credentials");

                topic.Grid.ClickDelete(0);
                Assert.AreEqual(1, topic.Grid.Rows.Count);
                Assert.AreEqual(true, topic.Grid.IsRowDeleteMode(0));
                page.Revert();
                page.DiscardChangesModal.Discard();
                Assert.AreEqual(false, topic.Grid.IsRowDeleteMode(0));
                topic.Grid.ClickDelete(0);
                topic.Enabled.ClickWithTimeout();
                page.Save();
                driver.WaitForAngular();
                Assert.NotNull(topic.Notification);
                topic.NotificationCancel.ClickWithTimeout();

                page.Revert();
                page.DiscardChangesModal.Discard();
                var workspace = new DmsIntegrationPage.WorkSpaceTopic(driver);
                workspace.SubClass.Input.SendKeys("abc");
                page.Save();
                driver.WaitForAngular();
                Assert.NotNull(topic.Notification);
                Assert.AreEqual(true, topic.NotificationYes.Enabled);
                Assert.AreEqual("Enable DMS configuration", topic.NotificationTitle.Text);
                topic.NotificationYes.ClickWithTimeout();
                driver.WaitForAngular();
                Assert.False(page.SaveButton.Enabled, "should successfully save without prompting for credentials");
            });
        }

        [TestCase(BrowserType.Chrome)]
        public void TestConnectionExistingValidSetup(BrowserType browserType)
        {
            new DocumentManagementDbSetup().Setup();
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/dmsintegration");

            driver.With<DmsIntegrationPage>(page =>
            {
                var topic = new DmsIntegrationPage.DatabaseTopic(driver);
                topic.TestButton(driver).Click();

                Assert.True(topic.Grid.Cell(0, (int) SiteDbGridCellIndex.Status).FindElements(By.ClassName("cpa-icon-check-circle")).Any(), "Showing Valid Icon");
                Assert.False(topic.Grid.Cell(0, (int) SiteDbGridCellIndex.Status).FindElements(By.ClassName("cpa-icon-exclamation-triangle")).Any(), "Not Showing Invalid Icon");
            });
        }

        [TestCase(BrowserType.Chrome)]
        public void TestConnectionExistingInValidSetup(BrowserType browserType)
        {
            new DocumentManagementDbSetup().Setup(overrideServerName: "failingServerName");
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/dmsintegration");

            driver.With<DmsIntegrationPage>(page =>
            {
                var topic = new DmsIntegrationPage.DatabaseTopic(driver);
                topic.TestButton(driver).Click();

                Assert.False(topic.Grid.Cell(0, (int) SiteDbGridCellIndex.Status).FindElements(By.ClassName("cpa-icon-check-circle")).Any(), "Not Showing Valid Icon");
                Assert.True(topic.Grid.Cell(0, (int) SiteDbGridCellIndex.Status).FindElements(By.ClassName("cpa-icon-exclamation-triangle")).Any(), "Showing Invalid Icon");
            });
        }

        [TestCase(BrowserType.Chrome)]
        public void EditTestConfiguration(BrowserType browserType)
        {
            new DocumentManagementDbSetup().Setup();
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/dmsintegration");

            driver.With<DmsIntegrationPage>(page =>
            {
                var topic = new DmsIntegrationPage.DatabaseTopic(driver);

                topic.Grid.ClickEdit(0);
                Assert.NotNull(topic.Modal);
                topic.Server.Text = "Fail Validation";
                driver.WaitForAngular();
                topic.Server.Text = "http://validServerThatWontWorkOnConnection.fake";
                driver.WaitForAngular();
                Assert.False(topic.Server.HasError);

                Assert.AreEqual(true, topic.ModalApply.Enabled);
                topic.ModalApply.Click();

                driver.WaitForAngular();
                topic.TestButton(driver).Click();

                Assert.False(topic.Grid.Cell(0, (int) SiteDbGridCellIndex.Status).FindElements(By.ClassName("cpa-icon-check-circle")).Any(), "Not Showing Valid Icon");
                Assert.True(topic.Grid.Cell(0, (int) SiteDbGridCellIndex.Status).FindElements(By.ClassName("cpa-icon-exclamation-triangle")).Any(), "Showing Invalid Icon");
            });
        }

        [TestCase(BrowserType.Chrome)]
        public void EditAndSaveTestConfiguration(BrowserType browserType)
        {
            new DocumentManagementDbSetup().Setup();
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/dmsintegration");

            driver.With<DmsIntegrationPage>(page =>
            {
                var topic = new DmsIntegrationPage.DatabaseTopic(driver);

                topic.Grid.ClickEdit(0);
                Assert.NotNull(topic.Modal);
                topic.Server.Text = "Fail Validation";
                driver.WaitForAngular();
                topic.Server.Text = "http://validServerThatWontWorkOnConnection.fake";
                driver.WaitForAngular();
                Assert.False(topic.Server.HasError);

                Assert.AreEqual(true, topic.ModalApply.Enabled);
                topic.ModalApply.Click();

                driver.WaitForAngular();
                topic.SaveButton(driver).Click();

                Assert.False(topic.Grid.Cell(0, (int) SiteDbGridCellIndex.Status).FindElements(By.ClassName("cpa-icon-check-circle")).Any(), "Not Showing Valid Icon");
                Assert.True(topic.Grid.Cell(0, (int) SiteDbGridCellIndex.Status).FindElements(By.ClassName("cpa-icon-exclamation-triangle")).Any(), "Showing Invalid Icon");
            });
        }
    }
}