using System.Linq;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison.Tsdr
{
    public class TsdrDocumentSummary : DocumentSummary
    {
        public string CreateOrMailDate { get; set; }

        public string DocumentCode { get; set; }

        protected override void Build(NgWebElement tr)
        {
            CreateOrMailDate = tr.FindElement(By.CssSelector("td:nth-child(1)")).Text.Trim();

            DocumentDescription = tr.FindElement(By.CssSelector("td:nth-child(2) div")).Text.Trim();

            HasDownloadLink = tr.FindElements(By.CssSelector("td:nth-child(2) div a")).FirstOrDefault() != null;

            DocumentCode = tr.FindElement(By.CssSelector("td:nth-child(3)")).Text.Trim();

            Status = tr.FindElement(By.CssSelector("td:nth-child(4) span")).Text.Trim();
        }
    }
}