using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Updaters;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Updaters
{
    public class CaseImageSequenceNumberReordererFacts : FactBase
    {
        [Fact]
        public void DoesNotReorderCaseImageRecordsForNotSpecifiedCase()
        {
            const string CaseRef1 = "1234/a";
            const string CaseRef2 = "1234/b";
            var f = new CaseImageSequenceNumberReordererFixture(Db).WithCaseImages(new[] {CaseRef1, CaseRef2}, 3, -2);

            var caseId1 = Db.Set<Case>().Single(_ => _.Irn == CaseRef1).Id;
            var caseId2 = Db.Set<Case>().Single(_ => _.Irn == CaseRef2).Id;

            f.Subject.Reorder(caseId1);

            Assert.Equal(new short[] {-2, -1, 0},
                         Db.Set<CaseImage>()
                           .Where(_ => _.CaseId == caseId2)
                           .OrderBy(_ => _.ImageSequence)
                           .Select(_ => _.ImageSequence));
        }

        [Fact]
        public void ReordersCaseImageRecordsForSpecifiedCase()
        {
            const string CaseRef1 = "1234/a";
            const string CaseRef2 = "1234/b";
            var f = new CaseImageSequenceNumberReordererFixture(Db).WithCaseImages(new[] {CaseRef1, CaseRef2}, 3, -2);

            var caseId1 = Db.Set<Case>().Single(_ => _.Irn == CaseRef1).Id;

            f.Subject.Reorder(caseId1);

            Assert.Equal(new short[] {0, 1, 2},
                         Db.Set<CaseImage>()
                           .Where(_ => _.CaseId == caseId1)
                           .OrderBy(_ => _.ImageSequence)
                           .Select(_ => _.ImageSequence));
        }
    }

    internal sealed class CaseImageSequenceNumberReordererFixture : IFixture<CaseImageSequenceNumberReorderer>
    {
        readonly InMemoryDbContext _db;

        public CaseImageSequenceNumberReordererFixture(InMemoryDbContext db)
        {
            _db = db;
            Subject = new CaseImageSequenceNumberReorderer(db);
        }

        public CaseImageSequenceNumberReorderer Subject { get; }

        public CaseImageSequenceNumberReordererFixture WithCaseImages(IEnumerable<string> caseRefs, int caseImageCount, short caseImageSequenceNumberStart)
        {
            foreach (var caseRef in caseRefs)
            {
                var seq = caseImageSequenceNumberStart;
                var @case = new CaseBuilder {Irn = caseRef}.Build().In(_db);
                foreach (var caseImageIndex in Enumerable.Range(0, caseImageCount))
                {
                    new CaseImageBuilder {Case = @case, ImageSequence = seq}.Build().In(_db);
                    seq += 1;
                }
            }

            return this;
        }
    }
}