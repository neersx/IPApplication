using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.TaskPlanner
{
    public class TaskPlannerConfigurationPageObject : PageObject
    {
        public TaskPlannerConfigurationPageObject(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {

        }

        public NgWebElement RevertButton => Driver.FindElement(By.CssSelector("ipx-revert-button button"));
        public NgWebElement SaveButton => Driver.FindElement(By.CssSelector("ipx-save-button button"));
        public AngularKendoGrid Grid => new AngularKendoGrid(Driver, "taskPlannerConfigGrid");
        public NgWebElement SuccessMessage => Driver.FindElement(By.ClassName("flash_alert"));
        public NgWebElement SearchButton => Driver.FindElement(By.CssSelector("ipx-picklist-search-field span.cpa-icon.cpa-icon-search"));

        public void SelectPickListItem(int gridRowIndex, string pickListName, string searchText)
        {
            var picklist = new AngularPicklist(Driver, Grid.EditableRow(gridRowIndex)).ByName(pickListName);
            picklist.Clear();
            picklist.Typeahead.Clear();
            picklist.Typeahead.SendKeys(searchText);
            picklist.Blur();
        }

        public AngularCheckbox GetLockedCheckBox(int gridRowIndex)
        {
            return new AngularCheckbox(Driver, Grid.EditableRow(gridRowIndex)).ByTagName();
        }

        public AngularPicklist GetTabPickList(int tabSequence)
        {
            return new AngularPicklist(Driver).ById("tabSavedSearch" + tabSequence);
        }
        public NgWebElement ResetToDefaultButton => Driver.FindElement(By.Id("btnResetToDefault"));
        public NgWebElement ApplyButton => Driver.FindElement(By.Id("btnSubmit"));
        public NgWebElement ConfirmMessage => Driver.FindElement(By.CssSelector("#confirmModal .modal-body p"));
        public NgWebElement ConfirmButton => Driver.FindElement(By.Name("confirm"));
    }
}
