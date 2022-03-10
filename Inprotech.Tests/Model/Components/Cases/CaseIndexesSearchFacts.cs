using System.Linq;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases
{
    public class CaseIndexesSearchFacts : FactBase
    {
        public CaseIndexesSearchFacts()
        {
            _f = new CaseIndexesSearch(Db);
            CreatData();
        }

        readonly ICaseIndexesSearch _f;

        void CreatData()
        {
            new CaseIndexes("irn value", 101, CaseIndexSource.Irn).In(Db);
            new CaseIndexes("title value", 102, CaseIndexSource.Title).In(Db);
            new CaseIndexes("official no", 103, CaseIndexSource.OfficialNumbers).In(Db);
        }

        [Theory]
        [InlineData(CaseIndexSource.Irn, "irn", 101)]
        [InlineData(CaseIndexSource.Title, "title", 102)]
        [InlineData(CaseIndexSource.OfficialNumbers, "official", 103)]
        public void ReturnsCaseIdsForIndexContainingSearchText(CaseIndexSource source, string searchText, int caseId)
        {
            var r = _f.Search(searchText, source).ToArray();

            Assert.Single(r);
            Assert.Equal(caseId, r.First());
        }

        [Fact]
        public void ReturnsCaseIdsForIndexesContainingSearchText()
        {
            var r = _f.Search("value", CaseIndexSource.Irn, CaseIndexSource.Title).ToArray();

            Assert.Equal(2, r.Length);
            Assert.Contains(101, r);
            Assert.Contains(102, r);
        }
    }
}