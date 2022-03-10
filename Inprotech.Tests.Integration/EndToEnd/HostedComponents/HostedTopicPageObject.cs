using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.EndToEnd.Search;
using Inprotech.Tests.Integration.EndToEnd.Search.Case;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Newtonsoft.Json;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents
{
   internal class HostedTopicPageObject : PageObject
    {
        public HostedTopicPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public ButtonInput SaveButton => new ButtonInput(Driver).ByCssSelector("ipx-save-button button");
       
        public ButtonInput RevertButton => new ButtonInput(Driver).ByCssSelector("ipx-revert-button button");

    }
}