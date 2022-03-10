using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Web.Builders.Model.ValidCombinations
{
    public class ValidChecklistBuilder : IBuilder<ValidChecklist>
    {
        public short? ChecklistType { get; set; }
        public string ChecklistDesc { get; set; }
        public CaseType CaseType { get; set; }
        public Country Country { get; set; }
        public PropertyType PropertyType { get; set; }
        public CheckList CheckList { get; set; }

        public ValidChecklist Build()
        {
            if (CheckList != null)
            {
                return new ValidChecklist(
                                          Country ?? new CountryBuilder().Build(),
                                          PropertyType ?? new PropertyTypeBuilder().Build(),
                                          CaseType ?? new CaseTypeBuilder().Build(),
                                          CheckList);
            }

            return new ValidChecklist(
                                      Country ?? new CountryBuilder().Build(),
                                      PropertyType ?? new PropertyTypeBuilder().Build(),
                                      CaseType ?? new CaseTypeBuilder().Build(),
                                      ChecklistType ?? Fixture.Short(),
                                      ChecklistDesc ?? Fixture.String());
        }
    }
}