using System;
using System.Linq;
using Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using InprotechKaizen.Model.Policing;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.SavedRequest
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestType(TestTypes.Regression)]
    public class SavedRequestsDeleting : SavedRequestsTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TryDeleteSelectedDeclineConfirm(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var savedRequest = new SavedRequestsPageObject(driver);
            var popups = new CommonPopups(savedRequest.Driver);

            using (var setup = new RequestsDbSetup())
            {
                Enumerable.Range(0, 3)
                          .ToList()
                          .ForEach(x =>
                          {
                              setup.Insert(new PolicingRequest(null)
                              {
                                  IsSystemGenerated = 0,
                                  Name = "A" + RandomString.Next(x),
                                  DateEntered = Helpers.UniqueDateTime()
                              });
                          });
            }

            SignIn(driver, "/#/policing-saved-requests", _loginUser.Username, _loginUser.Password);

            var originalCount = savedRequest.SavedRequestGrid.Rows.Count;
            Assert.LessOrEqual(3, savedRequest.SavedRequestGrid.Rows.Count);
            savedRequest.SavedRequestGrid.SelectIpCheckbox(0);
            savedRequest.SavedRequestGrid.SelectIpCheckbox(1);

            savedRequest.ActionMenu.OpenOrClose();
            savedRequest.ActionMenu.DeleteOption().ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            popups.ConfirmDeleteModal.Cancel().Click();

            Assert.AreEqual(originalCount, savedRequest.SavedRequestGrid.Rows.Count);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CannotDeleteWhenSelectedRequestHasRequestLogInProgress(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var savedRequest = new SavedRequestsPageObject(driver);
            var popups = new CommonPopups(savedRequest.Driver);
            using (var setup = new RequestsDbSetup())
            {
                Enumerable.Range(0, 3)
                          .ToList()
                          .ForEach(x =>
                          {
                              var request = setup.Insert(new PolicingRequest(null)
                              {
                                  IsSystemGenerated = 0,
                                  Name = "1A New Request" + x.ToString(),
                                  DateEntered = Helpers.UniqueDateTime()
                              });

                              setup.Insert(new PolicingLog(request.DateEntered)
                              {
                                  PolicingName = request.Name,
                                  FinishDateTime = x == 2 ? Helpers.UniqueDateTime() : (DateTime?) null
                              });
                          });
            }

            SignIn(driver, "/#/policing-saved-requests", _loginUser.Username, _loginUser.Password);

            Assert.LessOrEqual(3, savedRequest.SavedRequestGrid.Rows.Count);
            var originalCount = savedRequest.SavedRequestGrid.Rows.Count;

            savedRequest.SavedRequestGrid.SelectIpCheckbox(0);
            savedRequest.SavedRequestGrid.SelectIpCheckbox(1);
            savedRequest.SavedRequestGrid.SelectIpCheckbox(2);

            savedRequest.ActionMenu.OpenOrClose();
            savedRequest.ActionMenu.DeleteOption().ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            Assert.IsTrue(popups.AlertModal.Modal.Text.Contains("This process has been partially completed."), "This process has been partially completed.");
            Assert.IsTrue(popups.AlertModal.Modal.Text.Contains("Items highlighted in red cannot be deleted as they are in use."), "Items which can not be deleted are highlighted in red");

            popups.AlertModal.Ok();

            Assert.AreEqual(originalCount - 1, savedRequest.SavedRequestGrid.Rows.Count, "One of the requests is successfully deleted, since they were deletable");
        }
    }
}