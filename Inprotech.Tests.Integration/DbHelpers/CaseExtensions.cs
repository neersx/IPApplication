using System.Linq;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Integration.DbHelpers
{
    public static class CaseExtensions
    {
        public static CaseName Staff(this Case @case)
        {
            return @case.CaseNames.SingleOrDefault(_ => _.NameTypeId == "EMP");
        }

        public static CaseName Debtor1(this Case @case)
        {
            return @case.CaseNames.Where(_ => _.NameTypeId == "D").OrderBy(_ => _.Sequence).ElementAtOrDefault(0);
        }

        public static CaseName Debtor2(this Case @case)
        {
            return @case.CaseNames.Where(_ => _.NameTypeId == "D").OrderBy(_ => _.Sequence).ElementAtOrDefault(1);
        }

        public static CaseName Instructor(this Case @case)
        {
            return @case.CaseNames.SingleOrDefault(_ => _.NameTypeId == "I");
        }
    }
}