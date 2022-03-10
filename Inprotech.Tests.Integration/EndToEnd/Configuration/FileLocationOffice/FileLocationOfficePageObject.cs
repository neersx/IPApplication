using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.FileLocationOffice
{
    public class FileLocationOfficePageObject : PageObject
    {
        public FileLocationOfficePageObject(NgWebDriver driver) : base(driver)
        {
        }

        public AngularKendoGrid FileLocationOfficeGrid => new AngularKendoGrid(Driver, "fileLocationOffice");
        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='vm.searchCriteria.text']"));
        }
        public NgWebElement SearchButton => Driver.FindElement(By.XPath("//span[@class='cpa-icon cpa-icon-search']"));
        public NgWebElement FileLocationOfficeNavigationLink => Driver.FindElement(By.XPath("//tbody/tr[1]/td[2]/a[1]"));
        public NgWebElement SaveButton => Driver.FindElement(By.CssSelector(".page-title .btn-save"));
        public NgWebElement RevertButton => Driver.FindElement(By.CssSelector(".page-title .cpa-icon-revert")).GetParent();
        
    }

    public class EditFileLocationOfficeRow : PageObject
    {
        public EditFileLocationOfficeRow(NgWebDriver driver, NgWebElement container) : base(driver, container)
        {
        }

        public AngularPicklist Office => new AngularPicklist(Driver, Container).ByName("office");
    }
}
