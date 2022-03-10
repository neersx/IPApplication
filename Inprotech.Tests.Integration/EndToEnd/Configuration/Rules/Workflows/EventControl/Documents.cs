using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class DocumentsTest : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainDocuments(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
                                  {
                                      var eventBuilder = new EventBuilder(setup.DbContext);
                                      var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                                      var criteriaBuilder = new CriteriaBuilder(setup.DbContext);
                                      var documentBuilder = new DocumentBuilder(setup.DbContext);
                                      var feeBuilder = new ChargeTypeBuilder(setup.DbContext);

                                      var evet = eventBuilder.Create("event");
                                      var criteria = criteriaBuilder.Create("criteria");
                                      var importance = importanceBuilder.Create();

                                      var document1 = documentBuilder.Create("doc1");
                                      var document2 = documentBuilder.Create("doc2");
                                      var fee1 = feeBuilder.Create("fee1");

                                      var validEvent = new ValidEvent(criteria, evet, "Apple")
                                                       {
                                                           NumberOfCyclesAllowed = 2,
                                                           Inherited = 1,
                                                           Importance = importance
                                                       };
                                      setup.Insert(validEvent);

                                      return new
                                             {
                                                 Event = evet.Description,
                                                 EventId = evet.Id.ToString(),
                                                 CriteriaId = criteria.Id.ToString(),
                                                 DocumentName = document1.Name,
                                                 DocumentName2 = document2.Name,
                                                 ChargeType = fee1.Description
                                             };
                                  });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.Documents.NavigateTo();

            // add
            eventControlPage.Documents.Add();
            var modal = new DocumentsModal(driver);

            modal.Document.EnterAndSelect(data.DocumentName);
            modal.ProduceEventOccurs.Click();

            Assert.True(modal.StartSending.IsDisabled);
            Assert.True(modal.RepeatEvery.IsDisabled);
            Assert.True(modal.StopAfter.IsDisabled);
            Assert.True(modal.MaxDocuments.Input.IsDisabled());

            modal.ProduceRecurring.Click();

            modal.StartSending.Text = "1";
            modal.StartSending.SelectElement.SelectByText("Days");

            Assert.IsTrue(modal.RepeatEvery.TextInput.IsDisabled());
            Assert.IsTrue(modal.StopAfter.TextInput.IsDisabled());

            modal.Recurring.Click();
            modal.RepeatEvery.Text = "2";
            modal.RepeatEvery.SelectElement.SelectByText("Weeks");
            modal.StopAfter.Text = "3";
            modal.StopAfter.SelectElement.SelectByText("Years");
            modal.MaxDocuments.Text = "99";

            Assert.IsTrue(modal.Charge.PayFee.IsDisabled);
            Assert.IsTrue(modal.Charge.RaiseCharge.IsDisabled);
            Assert.IsTrue(modal.Charge.UseEstimate.IsDisabled);
            Assert.IsTrue(modal.Charge.DirectPay.IsDisabled);

            modal.Charge.ChargeType.EnterAndSelect(data.ChargeType);
            Assert.IsTrue(modal.Charge.RaiseCharge.IsChecked);
            modal.Charge.PayFee.Click();

            modal.CheckCycleForSubstitute.Click();

            modal.Apply();

            eventControlPage.Save();

            var documents = eventControlPage.Documents;
            documents.NavigateTo();

            Assert.AreEqual(1, documents.GridRowsCount);
            Assert.AreEqual(data.DocumentName, documents.Document);
            Assert.AreEqual("As Scheduled", documents.Produce);
            Assert.AreEqual("1 Days", documents.StartBefore);
            Assert.AreEqual("2 Weeks", documents.RepeatEvery);
            Assert.AreEqual("3 Years", documents.StopAfter);
            Assert.AreEqual("99", documents.MaxDocuments);

            // edit
            eventControlPage.Documents.Grid.ClickEdit(0);
            modal = new DocumentsModal(driver);
            Assert.AreEqual(data.DocumentName, modal.Document.InputValue);
            Assert.IsTrue(modal.ProduceRecurring.IsChecked);
            Assert.AreEqual("1", modal.StartSending.Text);
            Assert.AreEqual("Days", modal.StartSending.SelectElement.SelectedOption.Text);
            Assert.IsTrue(modal.Recurring.IsChecked);
            Assert.AreEqual("2", modal.RepeatEvery.Text);
            Assert.AreEqual("Weeks", modal.RepeatEvery.SelectElement.SelectedOption.Text);
            Assert.AreEqual("3", modal.StopAfter.Text);
            Assert.AreEqual("Years", modal.StopAfter.SelectElement.SelectedOption.Text);
            Assert.AreEqual("99", modal.MaxDocuments.Text);

            Assert.AreEqual(data.ChargeType, modal.Charge.ChargeType.InputValue);
            Assert.IsTrue(modal.Charge.RaiseCharge.IsChecked);
            Assert.IsTrue(modal.Charge.PayFee.IsChecked);
            Assert.IsTrue(modal.CheckCycleForSubstitute.IsChecked);

            modal.Document.EnterAndSelect(data.DocumentName2);
            modal.ProduceEventOccurs.Click();
            modal.Charge.PayFee.Click();
            modal.CheckCycleForSubstitute.Click();

            modal.Apply();
            eventControlPage.Save();

            documents.NavigateTo();
            Assert.AreEqual(data.DocumentName2, documents.Document);
            Assert.AreEqual("When Event Occurs", documents.Produce);

            //// delete
            documents.Grid.ToggleDelete(0);
            eventControlPage.Save();
            documents.NavigateTo();
            Assert.AreEqual(0, documents.GridRowsCount);
        }
    }
}