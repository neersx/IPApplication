using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.AssignmentRecordal;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases
{
    public class CaseAffectedCasesDbSetup : DbSetup
    {
        public ScreenCriteriaBuilder GetScreenCriteriaBuilder(Case @case, string internalProgram = KnownCasePrograms.CaseEntry)
        {
            return new ScreenCriteriaBuilder(DbContext).Create(@case, out _, internalProgram);
        }
        public (RecordalAffectedCase recordalAffectedCase1, RecordalAffectedCase recordalAffectedCase2, Case affectedCase, RecordalType recordalType1, RecordalType recordalType2) CaseAffectedCasesSetup(bool isAnyNotYetFiled = false)
        {
            var caseType = DbContext.Set<CaseType>().Single(_ => _.Code == "E");
            var @case = new CaseBuilder(DbContext).Create();
            @case.SetCaseType(caseType);

            var ownerNameType = DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Owner);
            var name1 = new NameBuilder(DbContext).Create();
            var name2 = new NameBuilder(DbContext).Create();

            var rt1 = Insert(new RecordalType
            {
                RecordalTypeName = Fixture.String(20)
            });

            var rt2 = Insert(new RecordalType
            {
                RecordalTypeName = Fixture.String(20)
            });

            var elements = DbContext.Set<Element>().ToArray();

            Insert(new RecordalElement
            {
                Element = elements[0],
                ElementId = elements[0].Id,
                ElementLabel = elements[0].Name,
                RecordalType = rt1,
                TypeId = rt1.Id,
                NameType = ownerNameType,
                NameTypeCode = ownerNameType.NameTypeCode,
                EditAttribute = "DIS"
            });

            Insert(new RecordalElement
            {
                Element = elements[1],
                ElementId = elements[1].Id,
                ElementLabel = elements[1].Name,
                RecordalType = rt1,
                TypeId = rt1.Id,
                NameType = ownerNameType,
                NameTypeCode = ownerNameType.NameTypeCode,
                EditAttribute = "MAN"
            });

            var re3 = Insert(new RecordalElement
            {
                Element = elements[1],
                ElementId = elements[1].Id,
                ElementLabel = elements[1].Name,
                RecordalType = rt2,
                TypeId = rt2.Id,
                NameType = ownerNameType,
                NameTypeCode = ownerNameType.NameTypeCode,
                EditAttribute = "MAN"
            });

            var rs1 = Insert(new RecordalStep
            {
                Id = 1,
                CaseId = @case.Id,
                RecordalType = rt1,
                StepId = 1,
                TypeId = rt1.Id,
                ModifiedDate = System.DateTime.Now
            });

            var rs2 = Insert(new RecordalStep
            {
                Id = 2,
                CaseId = @case.Id,
                RecordalType = rt2,
                StepId = 2,
                TypeId = rt2.Id,
                ModifiedDate = System.DateTime.Now
            });

            var rse1 = Insert(new RecordalStepElement
            {
                ElementValue = name1.Id.ToString(),
                NameTypeCode = ownerNameType.NameTypeCode,
                ElementId = elements[0].Id,
                ElementLabel = elements[0].Name,
                CaseId = @case.Id,
                Element = elements[0],
                EditAttribute = "DIS",
                NameType = ownerNameType,
                RecordalStepId = rs1.Id
            });

            var rse2 = Insert(new RecordalStepElement
            {
                ElementValue = name2.Id.ToString(),
                NameTypeCode = ownerNameType.NameTypeCode,
                ElementId = elements[1].Id,
                ElementLabel = elements[1].Name,
                CaseId = @case.Id,
                Element = elements[1],
                EditAttribute = "MAN",
                NameType = ownerNameType,
                RecordalStepId = rs1.Id
            });

            var rSe3 = Insert(new RecordalStepElement
            {
                ElementValue = name1.Id.ToString(),
                NameTypeCode = ownerNameType.NameTypeCode,
                ElementId = elements[1].Id,
                ElementLabel = elements[1].Name,
                CaseId = @case.Id,
                Element = elements[1],
                EditAttribute = "MAN",
                NameType = ownerNameType,
                RecordalStepId = rs2.Id
            });

            var relatedCase1 = new CaseBuilder(DbContext).Create("Aff1", true);
            var relatedCase2 = new CaseBuilder(DbContext).Create("Aff2", true);

            var rAc1 = Insert(new RecordalAffectedCase
            {
                Case = @case,
                CaseId = @case.Id,
                RecordalType = rt1,
                Status = "Recorded",
                RecordalTypeNo = rt1.Id,
                SequenceNo = 0,
                RelatedCase = relatedCase1,
                RelatedCaseId = relatedCase1.Id
            });

            var rAc2 = Insert(new RecordalAffectedCase
            {
                Case = @case,
                CaseId = @case.Id,
                RecordalType = rt1,
                Status = "Filed",
                RecordalTypeNo = rt1.Id,
                SequenceNo = 1,
                RelatedCase = relatedCase2,
                RelatedCaseId = relatedCase2.Id
            });
            if (isAnyNotYetFiled)
            {
              Insert(new RecordalAffectedCase
                {
                    Case = @case,
                    CaseId = @case.Id,
                    RecordalType = rt2,
                    Status = "Not Yet Filed",
                    RecordalTypeNo = rt2.Id,
                    SequenceNo = 2,
                    RelatedCase = relatedCase2,
                    RelatedCaseId = relatedCase2.Id
                });
            }
            return (rAc1, rAc2, @case, rt1, rt2);
        }
    }
}
