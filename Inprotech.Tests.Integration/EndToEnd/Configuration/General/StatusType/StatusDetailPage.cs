using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.StatusType
{
    class StatusDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;
        public StatusDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));
    }

    public class DefaultsTopic : Topic
    {
        const string TopicKey = "defaults";
        public DefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='vm.searchCriteria.text']"));
        }

        public NgWebElement ClearButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("span.cpa-icon.cpa-icon-eraser"));
        }

        public void ClickOnSelectAll(NgWebDriver driver)
        {
            driver.FindElement(By.Name("selectall")).WithJs().Click();
        }

        public NgWebElement ValidStatusPicklist(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("status")).FindElement(By.TagName("input"));
        }

        public NgWebElement SearchButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("#searchBody span.cpa-icon.cpa-icon-search"));
        }

        public int GetSearchResultCount(NgWebDriver driver)
        {
            return driver.FindElements(By.CssSelector("#searchResults .k-master-row")).Count;
        }

        public NgWebElement AddButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("addStatus"));
        }

        public NgWebElement Name(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("internalName")).FindElement(By.TagName("input"));
        }

        public NgWebElement BulkMenuDuplicate(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("bulkaction_status_duplicate"));
        }

        public NgWebElement ExternalName(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("externalName")).FindElement(By.TagName("input"));
        }

        #region StatusType
        public NgWebElement CaseStatusRadioButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("case-status"));
        }

        public NgWebElement RenewalStatusRadioButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("renewal-status"));
        }

        public NgWebElement RenewalStatusMaintenanceRadioButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("renewalStatus")).FindElement(By.TagName("input"));
        }
        #endregion

        #region StatusSummany
        public NgWebElement PendingRadioButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("pending")).FindElement(By.TagName("input"));
        }

        public NgWebElement RegisteredRadioButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("registered")).FindElement(By.TagName("input"));
        }

        public NgWebElement DeadRadioButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("pending")).FindElement(By.TagName("input"));
        }
        #endregion

        #region PolicingFuncitonsAllowed

        public NgWebElement PoliceRenewalsCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("policeRenewals")).FindElement(By.TagName("input"));
        }

        public NgWebElement PoliceExaminationCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("policeExamination")).FindElement(By.TagName("input"));
        }

        public NgWebElement PoliceOtherCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("policeOther")).FindElement(By.TagName("input"));
        }

        public NgWebElement ProduceLettersCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("produceLetters")).FindElement(By.TagName("input"));
        }

        public NgWebElement GenerateChargesCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("generateCharges")).FindElement(By.TagName("input"));
        }

        public NgWebElement PriorArtFromCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("priorArt")).FindElement(By.TagName("input"));
        }

        public NgWebElement ReminderFromCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("remindersAllowed")).FindElement(By.TagName("input"));
        }
        #endregion

        #region PreventTransactionsFor
        public NgWebElement BillingCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("billing")).FindElement(By.TagName("input"));
        }

        public NgWebElement PrepaymentCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("prepayment")).FindElement(By.TagName("input"));
        }

        public NgWebElement WipCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("wip")).FindElement(By.TagName("input"));
        }

        #endregion

        public NgWebElement ManualStatusChangeCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("manualStatusChange")).FindElement(By.TagName("input"));
        }

        public NgWebElement StopPayingDropDown(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='vm.entity.stopPayReason']"));
        }

        public NgWebElement ValidStatusDropDown(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='vm.selectedSearchOption']"));
        }

        public void ClickOnBulkActionMenu(NgWebDriver driver)
        {
            ActionMenu.OpenOrClose();
        }

        public void ClickOnDelete(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_status_delete")).WithJs().Click();
        }

        public void ClickOnEdit(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_status_edit")).WithJs().Click();
        }

        public void ClickOnDuplicate(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_status_duplicate")).WithJs().Click();
        }

        public void ClickOnValidStatus(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_status_maintainValidCombination")).WithJs().Click();
        }

        ActionMenu _actionMenu;
        public ActionMenu ActionMenu => _actionMenu ?? (_actionMenu = new ActionMenu(Driver, "status"));
    }
}
