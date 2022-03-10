using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Builders.Model.Rules
{
    public class QuestionBuilder : IBuilder<Question>
    {
        public short Id { get; set; }
        public string QuestionString { get; set; }
        public string Instructions { get; set; }
        public short? TableType { get; set; }
        public decimal? YesNoRequired { get; set; }
        public Question Build(short tableTypeId)
        {
            return new Question(Id, QuestionString ?? Fixture.String())
            {
                TableType = tableTypeId,
                YesNoRequired = YesNoRequired,
                Instructions = Instructions
            };
        }

        public Question Build()
        {
            throw new System.NotImplementedException();
        }
    }
}