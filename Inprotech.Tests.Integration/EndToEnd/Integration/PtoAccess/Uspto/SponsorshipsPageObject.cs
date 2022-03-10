using System;
using System.Collections.Generic;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Integration.PtoAccess.Uspto
{
    public class SponsorshipsPageObject : PageObject
    {
        public SponsorshipsPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public void AddSponsorship()
        {
            Driver.FindElement(By.CssSelector(".cpa-icon-plus-circle")).ClickWithTimeout();
        }

        public void ViewSchedules()
        {
            Driver.FindElement(By.Id("viewSchedules")).ClickWithTimeout();
        }
        
        public KendoGrid Sponsorships => new KendoGrid(Driver, "searchResults");

        public void DeleteSponsorshipByRowIndex(int rowNumber)
        {
            Sponsorships.Rows[rowNumber].FindElement(By.CssSelector($"button[id*=\"btnDelete_\"")).TryClick();

            new CommonPopups(Driver).ConfirmDeleteModal.Delete().ClickWithTimeout();
        }

        public void EditSponsorshipByRowIndex(int rowNumber)
        {
            Sponsorships.Rows[rowNumber].FindElement(By.CssSelector($"button[id*=\"btnModify_\"")).ClickWithTimeout();
        }

        public IEnumerable<CertificateSummary> AllSponsorshipSummary()
        {
            foreach (var s in Sponsorships.Rows)
            {
                var sponsors = s.FindElement(By.CssSelector("td:nth-child(2)")).WithJs().GetInnerText().Trim();

                var emails = s.FindElement(By.CssSelector("td:nth-child(3)")).WithJs().GetInnerText();

                var customerNumbers = s.FindElement(By.CssSelector("td:nth-child(4)")).WithJs().GetInnerText();

                yield return new CertificateSummary
                {
                    Name = sponsors,
                    Email = emails ?? string.Empty,
                    CustomerNumbers = customerNumbers.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                };
            }
        }
    }

    public class CertificateSummary
    {
        public string Name { get; set; }

        public string[] CustomerNumbers { get; set; }

        public string Email { get; set; }
    }

}