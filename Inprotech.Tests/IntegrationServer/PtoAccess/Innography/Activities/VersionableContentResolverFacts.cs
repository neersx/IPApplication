using System.Threading.Tasks;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.IntegrationServer.PtoAccess.Innography.Activities;
using InprotechKaizen.Model;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography.Activities
{
    public class VersionableContentResolverFacts
    {
        const string Sample1 = "{\"innography_id\":\"I-000033726180\",\"message\":\"Matched - validation issues\",\"validation\":[\"Check application date\",\"Check grant date\"],\"client_index\":\"-4\",\"public_data\":{\"application_number\":\"AU19900065827\",\"application_date\":\"1989-11-14\",\"publication_number\":\"AU635979B2\",\"publication_date\":\"1993-04-08\",\"grant_number\":\"AU635979B2\",\"grant_date\":\"1993-04-08\",\"type_code\":null,\"country_code\":\"AU\",\"country_name\":\"Australia\",\"title\":\"BOILING WATER UNITS\",\"inventors\":\"Raymond, Dennis Massey|Christopher, Roy Martin|Stephen, James Chaplin\"},\"confidence\":\"low\"}";
        const string Sample2 = "{\"innography_id\":0,\"client_index\":\"6\",\"message\":\"Not Matched\",\"validation\":[]}";

        readonly VersionableContentResolver _subject = new VersionableContentResolver();

        [Theory]
        [InlineData(KnownPropertyTypes.Patent)]
        [InlineData(KnownPropertyTypes.TradeMark)]
        public async Task DifferentContentShouldResolveToDifferentString(string propertyType)
        {
            var a = new DataDownload
            {
                Case = new EligibleCase {PropertyType = propertyType},
                AdditionalDetails = Sample1
            };

            var b = new DataDownload
            {
                Case = new EligibleCase {PropertyType = propertyType},
                AdditionalDetails = Sample2
            };

            var a1 = await _subject.Resolve(a);
            var b1 = await _subject.Resolve(b);

            Assert.NotEqual(a1, b1);
        }

        [Theory]
        [InlineData(KnownPropertyTypes.Patent)]
        [InlineData(KnownPropertyTypes.TradeMark)]
        public async Task SameContentShouldResolveToSameString(string propertyType)
        {
            var a = new DataDownload
            {
                Case = new EligibleCase {PropertyType = propertyType},
                AdditionalDetails = Sample1
            };

            var b = new DataDownload
            {
                Case = new EligibleCase {PropertyType = propertyType},
                AdditionalDetails = Sample1
            };

            var a1 = await _subject.Resolve(a);
            var b1 = await _subject.Resolve(b);

            Assert.Equal(a1, b1);
        }
    }
}