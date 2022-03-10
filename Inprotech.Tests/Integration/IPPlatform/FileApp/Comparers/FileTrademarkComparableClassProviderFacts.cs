using Inprotech.Integration.IPPlatform.FileApp.Comparers;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using Xunit;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp.Comparers
{
    public class FileTrademarkComparableClassProviderFacts
    {
        [Fact]
        public void ShouldNotReturnAnyGoodsServices()
        {
            // To block class text to be compared in case comparison.
            // The Goods Services population method is different, so when class comparison for FILE is available, it should consider the below from FileTrademarkClassBuilder;
            // It should also consider how the case text is to be applied, see IGoodsServices, IGoodsServicesUpdater

            var @case = new CaseBuilder().Build();

            @case.CaseTexts.Add(new CaseText(@case.Id, "G", 0, "01"));

            var subject = new FileTrademarkComparableClassProvider();

            Assert.Empty(subject.Retrieve(@case));
        }
    }
}