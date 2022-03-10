using System;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.BillingWizard.DebitNote
{
    public class DebitNotePageObjects : PageObject
    {
        public DebitNotePageObjects(NgWebDriver driver) : base(driver)
        {
        }
        public NgWebElement GetStepButton(string stepNo)
        {
            return Driver.FindElement(By.XPath("//ipx-step-button[@id='step_" + stepNo + "']/button"));
        }

        public NgWebElement ItemDate => Driver.FindElement(By.XPath("//ipx-date-picker[@name='transactionDate']/div/span/input"));
        public AngularDropdown Entity => new AngularDropdown(Driver, "ipx-dropdown").ByName("entity");
        public NgWebElement CurrentAction => Driver.FindElement(By.XPath("//ipx-typeahead[@name='currentAction']/div/div/input"));
        public AngularKendoGrid CaseGrid => new AngularKendoGrid(Driver, "caseGrid");
        public AngularKendoGrid WipSelectionGrid => new AngularKendoGrid(Driver, "wipGrid");
        public ContextMenu ContextMenu => new ContextMenu(Driver, CaseGrid);
        public AngularKendoGrid DebtorGrid => new AngularKendoGrid(Driver, "debtorGrid");
        public NgWebElement CasePickList => Driver.FindElement(By.XPath("//ipx-typeahead[@name='case']/div/div/div/input"));
        public NgWebElement CaseListPickList => Driver.FindElement(By.XPath("//ipx-typeahead[@name='caseList']/div/div/input"));
        public NgWebElement DebtorPickList => Driver.FindElement(By.XPath("//ipx-typeahead[@name='newDebtor']/div/div/input"));
        public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));
        public NgWebElement ModalApply => Driver.FindElement(By.CssSelector(".modal-dialog .btn-save"));
        public NgWebElement ModalCancel => Driver.FindElement(By.CssSelector(".modal-dialog .btn-discard"));
        public NgWebElement MainCaseIcon => Driver.FindElement(By.CssSelector("span.cpa-icon-star"));
        public NgWebElement SelectAllBtn => Driver.FindElement(By.Id("btnSelectAll"));
        public NgWebElement DeSelectAllBtn => Driver.FindElement(By.Id("btnDeSelectAll"));
        public NgWebElement TotalBilled => Driver.FindElement(By.XPath("//*[@id=\"totalBilled\"]/div[2]/span"));
        public NgWebElement TotalLocalBalance => Driver.FindElement(By.XPath("//*[@id=\"totalBalance\"]/div[2]/span"));
        public IpxNumericField LocalBilledInput => new IpxNumericField(Driver, Container).ByName("localBilled");
        public NgWebElement ForeignBilledInput => Driver.FindElement(By.Id("foreignBilledNumeric"));
        public NgWebElement WriteUpRadioBtn => Driver.FindElement(By.Id("rdbWriteUp"));
        public AngularDropdown ReasonDropDown => new AngularDropdown(Driver, "ipx-dropdown").ById("reason");
        public NgWebElement RemoveCase => new AngularKendoGridContextMenu(Driver).Option("delete");

        //Step 2
        public NgWebElement ReferenceText => Driver.FindElement(By.XPath("//ipx-text-field[@name='referenceText']/div/textarea"));
        public NgWebElement RegardingText => Driver.FindElement(By.XPath("//ipx-text-field[@name='regardingText']/div/textarea"));
        public NgWebElement StatementText => Driver.FindElement(By.XPath("//ipx-text-field[@name='statementText']/div/textarea"));
        public NgWebElement NarrativePickList => Driver.FindElement(By.XPath("//ipx-typeahead[@name='narrative']/div/div/input"));
        public NgWebElement CopyCaseTitleButton => Driver.FindElement(By.Name("btnCopyCaseTitle"));

    }

    public class ContextMenu
    {
        readonly NgWebDriver _driver;
        readonly AngularKendoGrid _grid;

        public Action<int> _removeCase;

        public ContextMenu(NgWebDriver driver, AngularKendoGrid grid)
        {
            _driver = driver;
            _grid = grid;

            _removeCase = rowIndex => ClickContextMenu(rowIndex, "delete");
        }

        void ClickContextMenu(int rowIndex, string id)
        {
            _grid.OpenContexualTaskMenu(rowIndex);
            _driver.WaitForAngular();
            WaitHelper.Wait(100);

            Menu(id).FindElement(By.TagName("span")).ClickWithTimeout();

            _driver.WaitForAngular();
        }

        NgWebElement Menu(string id)
        {
            return new AngularKendoGridContextMenu(_driver).Option(id);
        }
    }
}
