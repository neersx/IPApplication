using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;
using InprotechKaizen.Model.Components.Cases;
using ServiceStack;
using Xunit;

namespace Inprotech.Tests.Web.Cases
{
    public class CasePicklistSearchFilterFacts
    {

        [Fact]
        public void ShouldNotReturnDemoConfigurations()
        {
            var searchFilter = new CaseSearchFilter
            {
                IsRegistered = true,
                CaseOffices = new List<int>() { 77 },
                CaseTypes = new List<string>() { "Patent" },
                CountryCodes = new List<string>() { "AU" },
                NameKeys = new List<int>() { 1 },
                NameType = "T",
                PropertyTypes = new List<string>() { "Trademark" },
            };

            var xElement = XElement.Parse(@"<csw_ListCase><FilterCriteriaGroup><FilterCriteria><CaseNameGroup><CaseName Operator=""0""><TypeKey>I</TypeKey><NameKeys>1</NameKeys></CaseName></CaseNameGroup><CaseKey />
                    <PickListSearch></PickListSearch><CaseTypeKey IncludeCRMCases=""1"" /></FilterCriteria></FilterCriteriaGroup></csw_ListCase>");
            var result = CasePicklistSearchFilter.ConstructSearchFilter(xElement, searchFilter);

            Assert.Equal("1", result.Descendants("IsRegistered").First().Value);
            Assert.Equal("77", result.Descendants("OfficeKeys").First().Value);
            Assert.Equal("Patent", result.Descendants("CaseTypeKeys").First().Value);
            Assert.Equal("AU", result.Descendants("CountryCodes").First().Value);
            Assert.Equal("Trademark", result.Descendants("PropertyTypeKey").First().Value);
        }
    }
}

