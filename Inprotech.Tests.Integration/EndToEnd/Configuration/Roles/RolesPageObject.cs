using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Roles
{
    class RolesPageObject : PageObject
    {
        public RolesPageObject(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            Tasks = new TasksTopic(driver);
            WebParts = new WebPartsTopic(driver);
            Subjects = new SubjectsTopic(driver);
        }
        public AngularKendoGrid Grid => new AngularKendoGrid(Driver, "taskGrid", "a123");
        public NgWebElement RoleName => Driver.FindElement(By.XPath("//ipx-text-field[@name='rolename']/div/input"));
        public NgWebElement RoleDescription => Driver.FindElement(By.XPath("//ipx-text-field[@name='roledescription']/div/input"));
        public NgWebElement RoleDescriptionTextArea => Driver.FindElement(By.XPath("//ipx-text-field[@name='roledescription']/div/textarea"));
        public AngularPicklist TaskPicklist => new AngularPicklist(Driver).ByName("TaskList");
        public AngularPicklist WebPicklist => new AngularPicklist(Driver).ByName("webPart");
        public AngularPicklist SubjectPicklist => new AngularPicklist(Driver).ByName("subjectList");
        public AngularCheckbox InternalCheckBox => new AngularCheckbox(Driver).ByName("isInternal");
        public AngularCheckbox ExternalCheckBox => new AngularCheckbox(Driver).ByName("isExternal");
        public IpxRadioButton InternalRadioButton => new IpxRadioButton(Driver).ById("isInternal");
        public IpxRadioButton ExternalRadioButton => new IpxRadioButton(Driver).ById("isExternal");
        public AngularCheckbox ExecuteCheckBox => new AngularCheckbox(Driver).ByName("execute");
        public AngularCheckbox InsertCheckBox => new AngularCheckbox(Driver).ByName("insert");
        public AngularCheckbox UpdateCheckBox => new AngularCheckbox(Driver).ByName("update");
        public AngularCheckbox DeleteCheckBox => new AngularCheckbox(Driver).ByName("delete");
        public AngularCheckbox WebPartAccessCheckBox => new AngularCheckbox(Driver).ByName("access");
        public AngularCheckbox WebPartMandatoryCheckBox => new AngularCheckbox(Driver).ByName("mandatory");
        public AngularCheckbox SubjectAccessCheckBox => new AngularCheckbox(Driver).ByName("subjectaccess");
        public NgWebElement TaskPermissionDropDown => Driver.FindElement(By.CssSelector("ipx-dropdown[name='taskPermission']"));
        public SelectElement TaskPermissionSelect => new SelectElement(TaskPermissionDropDown.FindElement(By.TagName("select")));
        public NgWebElement WebPartPermissionDropDown => Driver.FindElement(By.CssSelector("ipx-dropdown[name='webPartPermission']"));
        public SelectElement WebPartPermissionSelect => new SelectElement(WebPartPermissionDropDown.FindElement(By.TagName("select")));
        public NgWebElement SubjectPermissionDropDown => Driver.FindElement(By.CssSelector("ipx-dropdown[name='subjectPermission']"));
        public SelectElement SubjectPermissionSelect => new SelectElement(SubjectPermissionDropDown.FindElement(By.TagName("select")));
        public NgWebElement ClearButton => Driver.FindElement(By.CssSelector("div.search-options div.controls > button > span.cpa-icon-eraser"));
        public NgWebElement SearchButton => Driver.FindElement(By.CssSelector("div.search-options div.controls > button > span.cpa-icon-search"));
        public AngularKendoGrid ResultGrid => new AngularKendoGrid(Driver, "roleSearch");
        public NgWebElement SkipToFirst => Driver.FindElement(By.CssSelector(".cpa-icon-angle-double-left"));
        public NgWebElement DeleteButton => Driver.FindElement(By.Id("delete"));
        public NgWebElement Delete => Driver.FindElement(By.Name("delete"));
        public NgWebElement Cancel => Driver.FindElement(By.Name("cancel"));
        public NgWebElement SuccessMessage => Driver.FindElement(By.ClassName("flash_alert"));
        public NgWebElement AlertMessage => Driver.FindElement(By.CssSelector("#alertModal .modal-body p"));
        public NgWebElement AlertOkButton => Driver.FindElement(By.CssSelector("#alertModal .modal-footer button.btn"));
        public NgWebElement DeleteAllButton => Driver.FindElement(By.Id("bulkaction_a123_deleteAll"));
        public NgWebElement SelectAllButton => Driver.FindElement(By.Id("a123_selectall"));
        public NgWebElement SaveButton => Driver.FindElement(By.CssSelector("div.action-buttons ipx-save-button > button"));
        public NgWebElement GrantAllPermissionButton => Driver.FindElement(By.Id("bulkaction_a123_grantAll"));
        public NgWebElement DenyAllPermissionButton => Driver.FindElement(By.Id("bulkaction_a123_denyAll"));
        public NgWebElement ClearAllPermissionButton => Driver.FindElement(By.Id("bulkaction_a123_clearAll"));
        public NgWebElement AddButton => Driver.FindElement(By.CssSelector("ipx-add-button > div > button"));
        public NgWebElement AddRoleName => Driver.FindElement(By.XPath("(//ipx-text-field[@name='rolename']/div/input)[2]"));
        public NgWebElement SaveRolesButton => Driver.FindElement(By.XPath("//ipx-save-button[@name='saveRoles']/button"));
        public NgWebElement DuplicateButton => Driver.FindElement(By.Id("bulkaction_a123_duplicate"));
        public void OpenGrantPermissionBulkOption(string function)
        {
            Driver.Hover(Grid.ActionMenu.Option("grant-permission").FindElement(By.ClassName("cpa-icon-right")));
            Driver.WaitForAngularWithTimeout();
            var options = Grid.ActionMenu.Options(function).ToArray();
            options[0].WithJs().Click();
        }
        public void OpenDenyPermissionBulkOption(string function)
        {
            Driver.Hover(Grid.ActionMenu.Option("deny-permission").FindElement(By.ClassName("cpa-icon-right")));
            Driver.WaitForAngularWithTimeout();
            var options = Grid.ActionMenu.Options(function).ToArray();
            options[1].WithJs().Click();
        }
        public void OpenClearPermissionBulkOption(string function)
        {
            Driver.Hover(Grid.ActionMenu.Option("clear-permission").FindElement(By.ClassName("cpa-icon-right")));
            Driver.WaitForAngularWithTimeout();
            var options = Grid.ActionMenu.Options(function).ToArray();
            options[2].WithJs().Click();
        }
        public TasksTopic Tasks { get; set; }
        public WebPartsTopic WebParts { get; set; }
        public SubjectsTopic Subjects { get; set; }
    }

    class TasksTopic : Topic
    {
        public TasksTopic(NgWebDriver driver) : base(driver, "Tasks")
        {
        }
        public NgWebElement ToggleDescriptionColumn => Driver.FindElement(By.Id("toggleDescriptionColumn"));
        public NgWebElement TogglePermissionSets => Driver.FindElement(By.Id("togglePermissionSets"));
        public AngularKendoGrid TasksGrid => new AngularKendoGrid(Driver, "taskGrid");
        public NgWebElement SearchTasks => Driver.FindElement(By.CssSelector("ipx-picklist-search-field .input-wrap input[type=text]"));
        public NgWebElement SearchButton => Driver.FindElement(By.CssSelector("ipx-icon-button[buttonicon=search]"));
    }

    class WebPartsTopic : Topic
    {
        public WebPartsTopic(NgWebDriver driver) : base(driver, "WebPart")
        {
        }
        public AngularKendoGrid WebPartsGrid => new AngularKendoGrid(Driver, "webPartGrid");

    }

    class SubjectsTopic : Topic
    {
        public SubjectsTopic(NgWebDriver driver) : base(driver, "Subject")
        {
        }
        public AngularKendoGrid SubjectsGrid => new AngularKendoGrid(Driver, "subjectGrid");
    }
}

