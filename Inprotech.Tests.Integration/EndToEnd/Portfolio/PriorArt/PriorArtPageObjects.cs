using System;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.PriorArt
{
    public class PriorArtPageObjects : PageObject
    {
        public PriorArtPageObjects(NgWebDriver driver) : base(driver)
        {
        }
        
        public string PageTitle()
        {
            return Driver.FindElements(By.CssSelector("ipx-sticky-header ipx-page-title h2 span")).Last().Text;
        }

        public NgWebElement CaseAndSourceDetails => Driver.FindElement(By.Id("caseAndSourceDetails")); 
        public NgWebElement CaseName => Driver.FindElement(By.Id("caseName")); 
        public NgWebElement SourceButton => Driver.FindElement(By.Id("source")); 
        public NgWebElement SourceName => Driver.FindElement(By.Id("sourceName"));
        public AngularPicklist Jurisdiction => new AngularPicklist(Driver, Container).ByName("jurisdiction");
        public NgWebElement ApplicationNo => Driver.FindElement(By.CssSelector("ipx-text-field[name='applicationNo'] input"));
        public NgWebElement KindCode => Driver.FindElement(By.CssSelector("ipx-text-field[name='kindCode'] input"));
        public IpxRadioButton SingleRadioButton => new IpxRadioButton(Driver).ById("singleIpo");
        public IpxRadioButton MultipleRadioButton => new IpxRadioButton(Driver).ById("multipleIpo");
        public NgWebElement MultiSearchText => Driver.FindElement(By.CssSelector("ipx-text-field[name='multipleIpoText'] textarea"));
        public NgWebElement SearchButton => Driver.FindElement(By.ClassName("btn-primary"));
        public NgWebElement ClearButton => Driver.FindElement(By.XPath("//button[@type='button']//span[contains(text(),'Clear')]"));
        public NgWebElement CancelButton => Driver.FindElement(By.CssSelector("div.search-options div.controls button:not(.btn-primary)"));
        public AngularKendoGrid NotFoundGrid => new AngularKendoGrid(Driver, "priorartNotFoundSet");
        public AngularKendoGrid PriorArtGrid => new AngularKendoGrid(Driver, "priorartResultSet");
        public AngularKendoGrid SourceSearchResultsGrid => new AngularKendoGrid(Driver, "sourceResultSet");
        public AngularKendoGrid CaseGrid => new AngularKendoGrid(Driver, "priorartInprotechCasesSet");
        public NgWebElement MessageDiv => Driver.FindElement(By.ClassName("flash_alert"));
        public ButtonInput CloseButton => new ButtonInput(Driver).ById("closeSearch");
        public NgWebElement LiteratureButton => Driver.FindElement(By.Id("literature"));
        public NgWebElement Title => Driver.FindElement(By.CssSelector("ipx-text-field[name='title'] textarea"));
        public AngularKendoGrid LiteratureGrid => new AngularKendoGrid(Driver, "literatureResultSet");
        public ButtonInput AddLiterature => new ButtonInput(Driver).ById("add");
        
        public void ProceedIpOneData()
        {
            var button = FindElements(By.CssSelector(".modal-content .btn-primary")).Last();
            button.WithJs().Click();
        }

        public void ClickAction(AngularKendoGrid grid, int rowIndex, string buttonName)
        {
            grid.RowElement(0, By.CssSelector($"ipx-icon-button[name={buttonName}] button span")).Click();
        }

        public class DetailSection : PageObject
        {
            public DetailSection(NgWebDriver driver, AngularKendoGrid grid, int rowIndex, NgWebElement container = null) : base(driver, container)
            {
                Container = grid.DetailRows[rowIndex];
            }

            public DetailSection(NgWebDriver driver) : base(driver)
            {
                Container = driver.FindElement(By.Id("add-new-literature"));
            }

            public NgWebElement Abstract => Container.FindElement(By.CssSelector("ipx-text-field[name='Abstract'] textarea"));
            public NgWebElement Comment => Container.FindElement(By.CssSelector("ipx-text-field[name='Comments'] textarea"));
            public NgWebElement Title => Container.FindElement(By.CssSelector("ipx-text-field[name='Title'] textarea"));
            public DatePicker PriorityDate => new(Driver, "priorityDate");
            public DatePicker ApplicationFilingDate => new(Driver, "applicationFiled");
            public DatePicker Published => new(Driver, "publishedDate");
            public DatePicker GrantedDate => new(Driver, "grantedDate");
            public DatePicker PtoCited => new(Driver, "ptoCited");
            public string PublishedDate => Container.FindElements(By.Id("publishedDate")).SingleOrDefault()?.Text;
            public ButtonInput SaveButton => new ButtonInput(Driver).ByCssSelector("ipx-save-button button");
            public NgWebElement Description => Container.FindElement(By.CssSelector("ipx-text-field[name='Description'] textarea"));
            public NgWebElement Name => Container.FindElement(By.CssSelector("ipx-text-field[name='Name'] textarea"));
            public NgWebElement Publisher => Container.FindElement(By.CssSelector("ipx-text-field[name='publisher'] input"));
            public void GenerateDescription()
            {
                FindElement(By.CssSelector("button[name='generateDescription']")).WithJs().Click();
            }
        }

    }

    public class ExistingPriorArtMatch : Match
    {
        NgWebDriver _driver;

        public string Kind { get; set; }
        
        protected override void Build(NgWebElement tr)
        {
            _driver = tr.CurrentDriver();

            var referenceCell = tr.FindElement(By.CssSelector("td:nth-child(2)"));

            Reference = referenceCell.Text.Trim();

            ReferenceLink = GetReferenceLink(referenceCell);

            Kind = tr.FindElement(By.CssSelector("td:nth-child(3)")).Text.Trim();

            Title = tr.FindElement(By.CssSelector("td:nth-child(4)")).Text.Trim();
        }
    }

    public class IpDataServicesMatch : Match
    {
        NgWebDriver _driver;

        public string Kind { get; set; }

        public string Abstract { get; set; }

        protected override void Build(NgWebElement tr)
        {
            _driver = tr.CurrentDriver();

            var referenceCell = tr.FindElement(By.CssSelector("td:nth-child(2)"));

            Reference = referenceCell.Text.Trim();

            ReferenceLink = GetReferenceLink(referenceCell);
            
            Kind = tr.FindElement(By.CssSelector("td:nth-child(3)")).Text.Trim();

            Title = tr.FindElement(By.CssSelector("td:nth-child(4)")).Text.Trim();

            Abstract = tr.FindElement(By.CssSelector("td:nth-child(5)")).Text.Trim();
        }
    }

    public abstract class Match
    {
        public int Index { get; set; }

        public string Reference { get; set; }

        public string Title { get; set; }

        public Uri ReferenceLink { get; set; }

        public NgWebElement Row
        {
            set => Build(value);
        }

        protected abstract void Build(NgWebElement tr);

        protected Uri GetReferenceLink(NgWebElement td)
        {
            string href = null;

            Try.Do(() =>
            {
                var a = td.FindElement(By.TagName("a"));
                if (a != null)
                {
                    href = a.GetAttribute("href");
                }
            });
            
            return string.IsNullOrWhiteSpace(href) ? null : new Uri(href);
        }
    }
}