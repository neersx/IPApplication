using System.Linq;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class DefaultGoodsServicesProviderFacts
    {
        [Fact]
        public void ShouldReturnFirstInLanguageList()
        {
            var @case = new CaseBuilder().Build();

            @case.CaseTexts.Add(new CaseText(@case.Id, "G", 0, "01") {Language = 1, Text = "Not this one"});
            @case.CaseTexts.Add(new CaseText(@case.Id, "G", 0, "01") {Language = null, Text = "this one"});

            var subject = new DefaultGoodsServicesProvider();

            var r = subject.Retrieve(@case);

            Assert.Equal("this one", r.Single().Text);
        }

        [Fact]
        public void ShouldReturnGoodsServicesGroupedByClass()
        {
            var @case = new CaseBuilder().Build();

            @case.CaseTexts.Add(new CaseText(@case.Id, "G", 0, "01") {Text = "Not this one"});
            @case.CaseTexts.Add(new CaseText(@case.Id, "G", 1, "01") {Text = "this one"});

            var subject = new DefaultGoodsServicesProvider();

            var r = subject.Retrieve(@case);

            Assert.Equal("this one", r.Single().Text);
        }
    }
}