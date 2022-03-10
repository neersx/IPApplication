using System.Xml.Linq;
using InprotechKaizen.Model.Components.Accounting.Wip;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Wip
{
    public class WipTemplateFilterCriteriaFacts
    {
        [Fact]
        public void ShouldBuildContextCriteriaWithCaseKey()
        {
            var caseKey = Fixture.Integer();

            var filterCriteriaXml = new WipTemplateFilterCriteria
            {
                ContextCriteria = new WipTemplateFilterCriteria.ContextCriteriaFilter
                {
                    CaseKey = caseKey
                }
            }.Build().ToString(SaveOptions.DisableFormatting);

            Assert.Equal($"<wp_ListWipTemplate><FilterCriteria /><ContextCriteria><CaseKey>{caseKey}</CaseKey></ContextCriteria></wp_ListWipTemplate>", filterCriteriaXml);
        }
        
        [Theory]
        [InlineData(true, false, false, @"<IsDisbursements>1</IsDisbursements><IsServices>0</IsServices><IsOverheads>0</IsOverheads>")]
        [InlineData(false, true, false, @"<IsDisbursements>0</IsDisbursements><IsServices>1</IsServices><IsOverheads>0</IsOverheads>")]
        [InlineData(false, false, true, @"<IsDisbursements>0</IsDisbursements><IsServices>0</IsServices><IsOverheads>1</IsOverheads>")]
        [InlineData(null, null, true, @"<IsOverheads>1</IsOverheads>")]
        [InlineData(null, true, null, @"<IsServices>1</IsServices>")]
        [InlineData(true, null, null, @"<IsDisbursements>1</IsDisbursements>")]
        [InlineData(null, null, false, @"<IsOverheads>0</IsOverheads>")]
        [InlineData(null, false, null, @"<IsServices>0</IsServices>")]
        [InlineData(false, null, null, @"<IsDisbursements>0</IsDisbursements>")]
        public void ShouldBuildFilterCriteriaBasedOnWipCategory(bool? isDisbursement, bool? isServices, bool? isOverheads, string expectedFragment)
        {
            var filterCriteriaXml = new WipTemplateFilterCriteria
            {
                WipCategory = new WipTemplateFilterCriteria.WipCategoryFilter
                {
                    IsDisbursements = isDisbursement,
                    IsOverheads = isOverheads,
                    IsServices = isServices
                }
            }.Build().ToString(SaveOptions.DisableFormatting);

            Assert.Equal($"<wp_ListWipTemplate><FilterCriteria><WipCategory>{expectedFragment}</WipCategory></FilterCriteria><ContextCriteria /></wp_ListWipTemplate>", filterCriteriaXml);
        }
        
        [Theory]
        [InlineData(true, false, false, @"<IsBilling>1</IsBilling><IsWip>0</IsWip><IsTimesheet>0</IsTimesheet>")]
        [InlineData(false, true, false, @"<IsBilling>0</IsBilling><IsWip>1</IsWip><IsTimesheet>0</IsTimesheet>")]
        [InlineData(false, false, true, @"<IsBilling>0</IsBilling><IsWip>0</IsWip><IsTimesheet>1</IsTimesheet>")]
        [InlineData(null, null, true, @"<IsTimesheet>1</IsTimesheet>")]
        [InlineData(null, true, null, @"<IsWip>1</IsWip>")]
        [InlineData(true, null, null, @"<IsBilling>1</IsBilling>")]
        [InlineData(null, null, false, @"<IsTimesheet>0</IsTimesheet>")]
        [InlineData(null, false, null, @"<IsWip>0</IsWip>")]
        [InlineData(false, null, null, @"<IsBilling>0</IsBilling>")]
        public void ShouldBuildFilterCriteriaBasedOnUsedByApplication(bool? isBilling, bool? isWip, bool? isTimesheet, string expectedFragment)
        {
            var filterCriteriaXml = new WipTemplateFilterCriteria
            {
                UsedByApplication = new WipTemplateFilterCriteria.UsedByApplicationFilter
                {
                    IsTimesheet = isTimesheet,
                    IsWip = isWip,
                    IsBilling = isBilling
                }
            }.Build().ToString(SaveOptions.DisableFormatting);

            Assert.Equal($"<wp_ListWipTemplate><FilterCriteria><UsedByApplication>{expectedFragment}</UsedByApplication></FilterCriteria><ContextCriteria /></wp_ListWipTemplate>", filterCriteriaXml);
        }
    }
}