using InprotechKaizen.Model.Keywords;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class KeyWordBuilder : IBuilder<Keyword>
    {
        public int KeywordNo { get; set; }

        public string KeyWord { get; set; }

        public decimal StopWord { get; set; }

        public Keyword Build()
        {
            return new Keyword() {KeywordNo = KeywordNo != 0 ? KeywordNo : Fixture.Integer(), KeyWord = KeyWord ?? Fixture.String()};
        }
    }
}
