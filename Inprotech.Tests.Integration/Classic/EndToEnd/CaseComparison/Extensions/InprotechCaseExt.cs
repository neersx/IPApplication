using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Integration;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison.Extensions
{
    public static class InprotechCaseExt
    {
        public static Case WithOfficialNumber(this Case @case, string numberTypeCode, string number)
        {
            using (var db = new DbSetup())
            {
                var ctx = db.DbContext;
                var numberType = ctx.Set<NumberType>().Single(_ => _.NumberTypeCode == numberTypeCode);
                var @case1 = ctx.Set<Case>().Single(_ => _.Id == @case.Id);
                db.Insert(new OfficialNumber(numberType, @case1, number)
                          {
                              IsCurrent = 1
                          });

                return @case;
            }
        }

        public static Case WithParentPctCase(this Case @case, Case parentCountryCase)
        {
            using (var db = new DbSetup())
            {
                var ctx = db.DbContext;

                var relationNpc = ctx.Set<CaseRelation>().Single(_ => _.Relationship == KnownRelations.PctParentApp);
                var relatedCaseChild = new RelatedCase(@case.Id, null, null, relationNpc, parentCountryCase.Id);

                ctx.Set<RelatedCase>().Add(relatedCaseChild);

                ctx.SaveChanges();

                var @case1 = ctx.Set<Case>().Single(_ => _.Id == @case.Id);
                return @case1;
            }
        }

        public static void LinkInnographyId(this Case @case, string innographyId)
        {
            using (var db = new DbSetup())
            {
                var newInnographyLink = new CpaGlobalIdentifier {CaseId = @case.Id, InnographyId = innographyId, IsActive = true};
                db.DbContext.Set<CpaGlobalIdentifier>().Add(newInnographyLink);

                db.DbContext.SaveChanges();
            }
        }
    }
}