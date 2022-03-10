using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Keywords;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Keywords
{
    public class KeywordsDbSetup : DbSetup
    {
        public dynamic SetupKeyWords()
        {

            var k1 = InsertWithNewId(new Keyword() { KeyWord = "E2e", KeywordNo = 1, StopWord = 1 });
            var k2 = InsertWithNewId(new Keyword() { KeyWord = "E2eTest", KeywordNo = 2, StopWord = 0 });

            return new
            {
                k1,
                k2
            };
        }
    }
}
