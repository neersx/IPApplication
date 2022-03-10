using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.Keywords;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Keywords;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Keywords
{
    public class KeywordServiceFacts
    {
        public class KeywordsFixture : IFixture<KeywordsService>
        {
            public KeywordsFixture(InMemoryDbContext db)
            {
                SecurityContext = Substitute.For<ISecurityContext>();
                LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();
                Subject = new KeywordsService(db, LastInternalCodeGenerator);
            }

            public ISecurityContext SecurityContext { get; set; }
            public ILastInternalCodeGenerator LastInternalCodeGenerator { get; set; }
            public KeywordsService Subject { get; set; }
        }

        public class GetKeywords : FactBase
        {
            [Fact]
            public async Task ReturnEmptyResultSetWhenNoData()
            {
                var f = new KeywordsFixture(Db);
                var results = (await f.Subject.GetKeywords()).ToArray();
                Assert.Empty(results);
            }

            [Fact]
            public async Task ReturnKeywordsResultSet()
            {
                var k1 = new Keyword() { KeyWord = "Abc", KeywordNo = 1, StopWord = 1 }.In(Db);
                new Keyword() { KeyWord = "Xyz", KeywordNo = 1, StopWord = 1 }.In(Db);
                var f = new KeywordsFixture(Db);
                var results = (await f.Subject.GetKeywords()).ToArray();
                Assert.Equal(2, results.Length);
                Assert.Equal(k1.KeyWord, results[0].KeyWord);
            }
        }

        public class GetKeywordDetail : FactBase
        {
            [Fact]
            public async Task GetKeyWordAndSynonymDetails()
            {
                var f = new KeywordsFixture(Db);
                var k1 = new Keyword() { KeyWord = "Abc", KeywordNo = 1, StopWord = 1 }.In(Db);
                var k2 = new Keyword() { KeyWord = Fixture.String(), KeywordNo = 2, StopWord = 1 }.In(Db);
                new Synonyms() { KeywordNo = 1, KwSynonym = k2.KeywordNo }.In(Db);
                var result = await f.Subject.GetKeywordByNo(k1.KeywordNo);
                Assert.Equal(k1.KeyWord, result.KeyWord);
                Assert.Equal(result.Synonyms.Count(), 1);
                Assert.Equal(((Synonym[])result.Synonyms)[0].Id, 2);
            }
        }

        public class Delete : FactBase
        {
            [Fact]
            public async Task ShouldThrowErrorWhenIdNotExist()
            {
                var f = new KeywordsFixture(Db);
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () => { await f.Subject.DeleteKeywords(new DeleteRequestModel()); });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldDeleteKeywordAndMappedSynonyms()
            {
                var f = new KeywordsFixture(Db);
                var k1 = new Keyword() { KeyWord = "Abc", KeywordNo = 1, StopWord = 1 }.In(Db);
                var k2 = new Keyword() { KeyWord = Fixture.String(), KeywordNo = 2, StopWord = 1 }.In(Db);
                new Synonyms() { KeywordNo = 1, KwSynonym = k2.KeywordNo }.In(Db);

                var result = await f.Subject.DeleteKeywords(new DeleteRequestModel { Ids = new List<int> { k1.KeywordNo } });
                var synonyms = Db.Set<Synonyms>().FirstOrDefault();
                var keyword = Db.Set<Keyword>();
                Assert.Null(synonyms);
                Assert.Equal(keyword.Count(), 1);
                Assert.False(result.HasError);
                Assert.NotNull(keyword);
                Assert.Equal(k2.KeyWord, keyword.FirstOrDefault()?.KeyWord);
            }
        }

        public class SubmitKeyWord : FactBase
        {
            [Fact]
            public async Task ShouldEditKeyword()
            {
                var f = new KeywordsFixture(Db);
                var k1 = new Keyword() { KeyWord = "Abc", KeywordNo = 1, StopWord = 1 }.In(Db);
                var request = new KeywordItems()
                {
                    KeywordNo = k1.KeywordNo,
                    KeyWord = Fixture.String()
                };

                var result = await f.Subject.SubmitKeyWordForm(request);
                Assert.Equal(k1.KeywordNo, result);
                Assert.Equal(request.KeyWord, k1.KeyWord);
            }

            [Fact]
            public async Task ShouldAddKeyword()
            {
                var f = new KeywordsFixture(Db);
                var keywordNo = Fixture.Integer();
                f.LastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Keywords).Returns(keywordNo);
                var request = new KeywordItems()
                {
                    KeywordNo = null,
                    KeyWord = Fixture.String(),
                    CaseStopWord = Fixture.Boolean(),
                    NameStopWord = Fixture.Boolean(),
                    Synonyms = new List<Synonym> { new Synonym { Id = keywordNo, Key = Fixture.String() } }
                };

                var result = await f.Subject.SubmitKeyWordForm(request);
                var k1 = Db.Set<Keyword>().First(_ => _.KeywordNo == result);
                var s1 = Db.Set<Synonyms>();
                Assert.Equal(request.KeyWord, k1.KeyWord);
                Assert.Equal(keywordNo, result);
                Assert.Equal(s1.Count(), 1);
            }
        }

    }
}
