using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Protractor;

namespace Inprotech.Tests.Integration.Utils
{
    public static class WithinIFrame
    {
        public static void DoWithinFrame(this NgWebDriver driver, Action method)
        {
            driver.SwitchTo().Frame(0);
            method();
            driver.SwitchTo().ParentFrame();
        }
    }
}
