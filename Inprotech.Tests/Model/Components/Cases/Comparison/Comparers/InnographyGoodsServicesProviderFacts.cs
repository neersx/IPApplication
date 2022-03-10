using System.Linq;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class InnographyGoodsServicesProviderFacts
    {
        [Fact]
        public void ShouldReturnGoodsServicesTextForMultipleLanguageList()
        {
            var @case = new CaseBuilder().Build();

            @case.CaseTexts.Add(new CaseText(@case.Id, "G", 0, "01") {Language = 1, Text = "Not this one"});
            @case.CaseTexts.Add(new CaseText(@case.Id, "G", 0, "01") {Language = null, Text = "Not this one"});
            @case.CaseTexts.Add(new CaseText(@case.Id, "G", 1, "01") {Language = 1, Text = "This one"});
            @case.CaseTexts.Add(new CaseText(@case.Id, "G", 1, "01") {Language = null, Text = "Also this one"});

            var subject = new InnographyGoodsServicesProvider();

            var r = subject.Retrieve(@case).ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal("This one", r[0].Text);
            Assert.Equal("Also this one", r[1].Text);
        }
    }
}