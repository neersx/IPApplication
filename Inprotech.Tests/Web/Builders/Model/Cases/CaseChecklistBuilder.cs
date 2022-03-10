using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class CaseChecklistBuilder : IBuilder<CaseChecklist>
    {
        public int CaseId { get; set; }

        public short QuestionNo { get; set; }

        public short CheckListTypeId { get; set; }

        public int? CriteriaId { get; set; }

        public int? EmployeeId { get; set; }

        public int? TableCode { get; set; }

        public decimal? YesNoAnswer { get; set; }

        public int? ProductCode { get; set; }

        public decimal? ProcessedFlag { get; set; }

        public string ChecklistText { get; set; }

        public int? CountAnswer { get; set; }

        public decimal? ValueAnswer { get; set; }
        public CaseChecklist Build()
        {
            return new CaseChecklist(CheckListTypeId != 0 ? CheckListTypeId : Fixture.Short(), CaseId != 0 ? CaseId : Fixture.Integer(), QuestionNo != 0 ? QuestionNo : Fixture.Short())
            {
                CriteriaId = CriteriaId,
                EmployeeId = EmployeeId,
                TableCode = TableCode,
                YesNoAnswer = YesNoAnswer,
                ProductCode = ProductCode,
                ProcessedFlag = ProcessedFlag,
                ChecklistText = ChecklistText,
                CountAnswer = CountAnswer,
                ValueAnswer = ValueAnswer
            };
        }
    }
}